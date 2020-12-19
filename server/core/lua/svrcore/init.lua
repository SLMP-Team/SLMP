------------------------------------------------------------
-- Simple Lua Multiplayer v.1.0.0-R1
-- Contributors: Pavel Akulichev & Vadim Vinogradov
-- Licence: Apache License, Version 2.0
-- GitHub Repository: https://github.com/SLMP-Team/SLMP
------------------------------------------------------------

function console_log(...)
  for i, v in ipairs({select(1, ...)}) do print(v) end
end

console_log("======================================", "Simple Lua Multiplayer Server Started", "======================================\n", "Contributors: Pavel Akulichev & Vadim Vinogradov",
"License: Apache License, Version 2.0", "GitHub Repository: https://github.com/SLMP-Team/SLMP", "Special Thanks: FYP, imring, Akionka and other testers\n")

WORKING_DIRECTORY = "../" -- move to server directory [../CORE]
-- in CORE directory we have to collect ONLY SL:MP CORE FILES

GM_FUNCS = {} -- exported data from gamemode script
FS_FUNCS = {} -- exported data from filterscripts

snetwork = require("snet")
socket = require("socket")

config = require("svrcore.config")["init"]()
packets = require("svrcore.packets")
rpc = require("svrcore.rpc")
sync = require("svrcore.sync")
clients = require("svrcore.clients")
objects = require("svrcore.objects")
functions = require("svrcore.functions")
strcomp = require("lualzw")

bstream = snetwork.bstream
sleep = socket.sleep

server = snetwork.server(config.address, config.port)
console_log("Listening to UDP Port "..config.port.."; players limit: "..config.players, "You can change configuration editing SERVER.CFG file\n")

-- fill clients array with 0 to work with keys, not indexes
for i = 1, config.players do clients.list[i] = 0 end
for i = 1, 0xFFFF do objects.list[i] = 0 end

server:add_event_handler("onReceivePacket",
function(id, bs, address, port)
  if id == SNET_CONFIRM_PRIORITY then return end
  local is_rpc = bs:read(BS_BOOLEAN)
  bs = bstream.new(bs.bytes:sub(2, #bs.bytes))
  if is_rpc then rpc.process(id, bs, address, port)
  else packets.process(id, bs, address, port) end
end)
server:add_event_handler("onClientUpdate",
function(address, port, event)
  if event == "connected" then
    console_log(("[SERVER] Incoming connection from %s:%s"):format(address, port))
  elseif event == "timeout" then
    local client = clients.by_address(address, port)
    if client ~= 0 then
      console_log("[SERVER] Client disconnected: "..clients.list[client].nickname.." [" .. client .. "] (reason: timeout)")
      inner_function("onPlayerDisconnect", true, true, client, 0) -- callback onPlayerDisconnect [PlayerID] [Reason]
      packets.send(packets["list"]["ID_CONNECTION_LOST"], nil, address, port)
      clients.remove(client)
      local data = bstream.new()
      data:write(BS_UINT16, client)
      data:write(BS_UINT8, 0) -- timeout
      clients.foreach(function(index, value)
        for i = #value.stream.players, 1, -1 do
          if value.stream.players[i] == client then
            table.remove(value.stream.players, i)
            break
          end
        end
        rpc.send(rpc["list"]["ID_SERVER_QUIT"],
        data, value.address, value.port)
      end)
    end
  end
end)

local path_to_gamemode = WORKING_DIRECTORY.."gamemodes/"..config.gamemode..".lua"
local file = io.open(path_to_gamemode, "r")
if not file then
  console_log("Gamemode file not found, verify SERVER.CFG settings")
  console_log("Your gamemode file has to be in gamemodes directory\n")
  return
end; file:close()

local function load_gamemode(script_path)
  local gamemode_funcs = {}
  for k, v in pairs(require("svrcore.functions")) do gamemode_funcs[k] = v end
  for k, v in pairs(require("svrcore.safe")) do gamemode_funcs[k] = v end
  setmetatable(gamemode_funcs, {__index = gamemode_funcs})
  assert(pcall(setfenv(assert(loadfile(script_path)), gamemode_funcs)))
  setmetatable(gamemode_funcs, nil)
  return gamemode_funcs
end

GM_FUNCS = load_gamemode(path_to_gamemode)
if type(GM_FUNCS) ~= "table" then
  console_log("Unable to laod gamemode, unknown error\n")
  return
else pcall(GM_FUNCS["onGamemodeInit"]) end

function load_filterscript(script_path)
  local script_funcs = {}
  for k, v in pairs(require("svrcore.functions")) do script_funcs[k] = v end
  for k, v in pairs(require("svrcore.safe")) do script_funcs[k] = v end
  setmetatable(script_funcs, {__index = script_funcs})
  assert(pcall(setfenv(assert(loadfile(script_path)), script_funcs)))
  setmetatable(script_funcs, nil)
  return script_funcs
end

for str in config.scripts:gmatch("%S+") do
  local script_full_path = WORKING_DIRECTORY.."filterscripts/"..str..".lua"
  local file = io.open(path_to_gamemode, "r")
  if file then
    file:close()
    local result = load_filterscript(script_full_path)
    if type(result) == "table" then
      FS_FUNCS[str] = result
      pcall(FS_FUNCS[str]["onFilterscriptInit"])
    end
  end
end

function inner_function(funcname, in_gamemode, in_scripts, ...)
  local args = {select(1, ...)}
  if in_scripts then
    for k, v in pairs(FS_FUNCS) do
      local res, result = pcall(FS_FUNCS[k][funcname], unpack(args))
      if res and result == false then return end
    end
  end
  if in_gamemode then
    local res, result = pcall(GM_FUNCS[funcname], unpack(args))
    if res then return result end
  end; return false
end

while true do
  server:process()
end