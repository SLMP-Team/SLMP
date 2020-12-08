-- GTA: SAN ANDREAS MULTIPLAYER BASED ON LUA
-- SIMPLE LUA MULTIPLAYER IS AN OPENSOURCE PROJECT
-- WE ASK YOU TO SUPPORT OUR WORK ON GITHUB

-- Developers: Pakulichev & Seven.ExE
-- Special Thanks: Akionka, imring, FYP,
-- SL Team members and other guys, who
-- participated in SL:MP development

script_properties('work-in-pause')
require 'moonloader' -- SL:MP based on MoonLoader by FYP

imgui = require 'mimgui' -- imgui the best
bit = require 'bit' -- client uses Bit to encode data
socket = require 'socket' -- client uses LuaSocket
--udp = socket.udp() -- client uses UDP method to send data
memory = require 'memory' -- some memory focuses, okay?
ffi = require 'ffi' -- one more focus
FA = require 'FA5Pro' -- just icons

encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

ffi.cdef[[
  void *malloc(size_t size);
  void free(void *ptrmem);

  typedef char CHAR;
  typedef CHAR *LPSTR;
  LPSTR GetCommandLineA();
]]

function GetArguments()
  local import = ffi.string(ffi.C.GetCommandLineA())
  import = import:sub(11, #import)
  import = import:match('^%s*(.+)%s*$')
  local args = {}
  for str in import:gmatch('[^%-]+') do
    local name, data = str:match('^(%S+)%s*(.*)$')
    table.insert(args, {name, data})
  end
  return args
end

startMultiplayer = false
conData =
{
  host = nil,
  port = nil,
  name = nil
}
local args = GetArguments()
for i, v in pairs(args) do
  if v[1] == 'multiplayer' then
    startMultiplayer = true
  elseif v[1] == 'h' then
    conData.host = v[2]:gsub('%s', '')
  elseif v[1] == 'p' then
    conData.port = v[2]:gsub('%s', '')
  elseif v[1] == 'n' then
    conData.name = v[2]:gsub('%s', '')
  end
end

if not startMultiplayer then
  thisScript():unload()
  return
end

gMenuPatch = true
if memory.getuint32(0xC8D4C0, false) < 9 then
  gMenuPatch = false -- notify client that game is not loaded
  pcall(memory.copy, 0x866CCC, memory.strptr("slmp_load"..string.char(0x0)), 10)
  pcall(memory.fill, 0x747483, 0x90, 6, true) -- bypass vids
  pcall(memory.setuint32, 0xC8D4C0, 5, true) -- skip intros by changing game state
  pcall(memory.write, 0x5B8E6A, 134217728, 4, true) -- multipling streaming value
end

local SLModulesDir = getGameDirectory() .. '\\moonloader\\SLModules\\'
package.path = package.path .. ';' .. SLModulesDir .. '?.lua;' .. SLModulesDir .. '?.luac'
package.cpath = package.cpath .. ';' .. SLModulesDir .. '?.dll'

modules = getWorkingDirectory() .. '/SLModules' -- some server modules located there
require('utilities.encoder') -- data to bytes encoder by Akionka
require('utilities.snippets') -- useful snippets and functions
require('bitstream') -- method to work with data using encoder
require('defines') -- just defines, nothing interesting
require('networking') -- sending and receiving data from server
require('initialization') -- some operations to get client ready

if memory.getuint32(0xC8D4C0, false) < 9 then
  local dir = ffi.C.malloc(5) ffi.copy(dir, "moonloader\\SLModules\\resources\\sa-files\0")
  local name_script = ffi.C.malloc(11) ffi.copy(name_script, "script.scm\0")
  local name_loadscreen = ffi.C.malloc(15) ffi.copy(name_loadscreen, "loadscreen.txd\0")
  Patches.setMainScriptPath(dir, name_script)
  Patches.setLoadScreensTxd(dir, name_loadscreen)
end

function main() -- moonloader script header function
  print('SL:MP Initialization Finished')

  displayZoneNames(false)
  disableAllEntryExits(true)
  Patches.improveAllLimites() -- peds, vehicles, etc.
  Patches.applyPatches()
  Patches.workInPause()
  setPlayerDisplayVitalStatsButton(PLAYER_HANDLE, false)
  setCharCoordinates(PLAYER_PED, 1.0, 1.0, 3.0)

  lua_thread.create(NetworkLoop)
  lua_thread.create(RenderLoop)

  DiscordRPC.Discord_Initialize("754014924543623240", 0, 0, "")
	dRPC.startTimestamp = os.time()

  if conData.host and conData.port and conData.name then

    setTimeOfDay(8, 0); forceWeatherNow(1)
    displayHud(false); displayRadar(false)
    setCharProofs(PLAYER_PED, true, true, true, true, true)
    setCharCoordinates(PLAYER_PED, 1775.92, -1506.60, 0.0)
    setCharVisible(PLAYER_PED, false)
    setPlayerControl(PLAYER_HANDLE, false)
    setFixedCameraPosition(1775.92, -1506.60, 190.0, 0.0, 0.0, 0.0)
    pointCameraAtPoint(1387.26, -1122.99, 248.52, 2)

    Game:addChatMessage('SL:MP ' .. General.VersionS .. ' started.', 0xCFCFCFFF)
    Game:addChatMessage('Connecting to ' .. conData.host .. ':' .. conData.port .. '...', 0xCFCFCFFF)
    wait(10000)
    print(conData.host, conData.port, conData.name)
    Socket:init(conData.host, conData.port)
    --[[local bs = BitStream:new()
    sendPacket(PACKET.PING_SERVER, false, bs)]]
    Client:connect(conData.name)
    Config.playerName = conData.name
    Config.serverAddress = tostring(conData.host .. ':' .. conData.port)
  end

  while true do
    wait(0)

    dRPC.largeImageKey = 'game'
		if Player.GameState == GAMESTATE.CONNECTED then
      dRPC.largeImageText = Config.serverAddress
      dRPC.details = 'Playing ' .. ClientData.sName
      dRPC.state = ClientData.sWebsite .. ' (' .. ClientData.sPlayers[1] .. ' of ' .. ClientData.sPlayers[2] .. ')'
      dRPC.partySize = ClientData.sPlayers[1]
      dRPC.partyMax = ClientData.sPlayers[2]
      dRPC.partyId = Config.serverAddress
    else
      dRPC.largeImageText = 'In Menu'
      dRPC.details = 'Idle'
      dRPC.state = ''
    end
    DiscordRPC.Discord_UpdatePresence(dRPC)

  end
end

function onD3DPresent()
  if memory.getuint32(0xC8D4C0, true) == 7 and not gMenuPatch then
    -- if game is not loaded, lets skip all videos
    gMenuPatch = true -- notify client that everything done
    memory.setuint8(0xBA6831, 1, true) -- game state = 1
    memory.setuint32(0xC8D4C0, 8, true) -- game state = 8
    memory.setuint8(0xBA67A4, 0, true) -- disable a menu
    memory.setuint8(0xBA677B, 0, true) -- start game
  end
end

function onScriptTerminate(script, quitGame)
  if script == thisScript() then
    --[[ffi.C.free(dir)
    ffi.C.free(name_script)
    ffi.C.free(name_loadscreen)]]
    -- IT CRASH FUCKING GAME!
    Client:disconnect(true)
    local file = io.open(configFolder..'\\conf.json', 'w+')
    if file then
      file:write(encodeJson(Config))
      file:close()
    end
  end
end

function onWindowMessage(msg, wparam, lparam)
  if msg == 0x100 then
    if Graphics.wChat[0] then
      if wparam == 0x75 then
        Graphics.tChatOpen = not Graphics.tChatOpen
      elseif wparam == 0x1B and Graphics.tChatOpen then
        Graphics.tChatOpen = false
      elseif wparam == 0x54 and not Graphics.tChatOpen then
        Graphics.tChatOpen = true
      end
    end
    --[[if not CGraphics.tChatOpen and wparam == 0x47 then
      local data = {-1, -1}
      local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
      for i = 1, #GPool.GVehicles do
        if GPool.GVehicles[i].handle and doesVehicleExist(GPool.GVehicles[i].handle) then
          local cX, cY, cZ = getCarCoordinates(GPool.GVehicles[i].handle)
          local dist = getDistanceBetweenCoords3d(cX, cY, cZ, pX, pY, pZ)
          if dist <= 20.0 then
            if data[1] == -1 or dist < data[2] then
              data[2] = dist
              data[1] = GPool.GVehicles[i].handle
            end
          end
        end
      end
      if data[1] ~= -1 then
        taskEnterCarAsPassenger(PLAYER_PED, data[1], 5000, -1)
      end
    end]]
  end
end
