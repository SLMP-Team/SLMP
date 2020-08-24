local SConfig =
{
  general =
  {
    serverName = 'SL:MP Server',
    version = 'SL:MP 0.0.1',
    gamemode = 'gamemode',
    maxSlots = 10, 
    stream = 300.0
  },
  connection =
  {
    address = '*',
    port = 7777
  }
}

local SPool =
{
  players = {},
  vehicles = {}
}

_G['server'] = {}

local gamemodeFile = io.open(string.format('../gamemodes/%s.lua', SConfig.general.gamemode))
if not gamemodeFile then
  print("SL:MP: Gamemode doesn`t exists")
  print("SL:MP: Server is shutting down")
  return false
end
gamemodeFile:close()
dofile(string.format('../gamemodes/%s.lua', SConfig.general.gamemode))

local socket = require "socket"
local udp = socket.udp()
local json = require "dkjson"
local LibDeflate = require("LibDeflate")

local function getClientConnected(ip, port)
  if not ip or not port then return false end
  for i = 1, #SPool.players do
    if SPool.players[i].address[1] and SPool.players[i].address[2] and SPool.players[i].address[1] == ip and SPool.players[i].address[2] == port then
      return true, i
    end
  end
  return false
end

--[[local function stringToData(str)
  local data = ""
  for i in (tostring(str)):gmatch('.') do
    data = data .. tostring(string.byte(i)) .. 'O'
  end
  return LibDeflate:CompressDeflate(data, {level = 9})
end

local function dataToString(data)
  data = LibDeflate:DecompressDeflate(data)
  local str = ""
  for i in (tostring(data)):gmatch('(%d+)O') do
    str = str .. string.char(tonumber(i))
  end
  return str
end]]

local function stringToData(str)
  return LibDeflate:CompressDeflate(str, {level = 9})
end

local function dataToString(data)
  return LibDeflate:DecompressDeflate(data)
end

local function generatePacket(type, id, content)
  if type == 'R' then return string.format('%s[%s]{%s}', type, tonumber(id), tonumber(content)) end
  return string.format('%s[%s]{%s}', type, tonumber(id), stringToData(content))
end

local function getFreeId()
  local testId = -1
  ::gotoBeginId::
  testId = testId + 1
  for i = 1, #SPool.players do
    if SPool.players[i].playerid == testId then
      goto gotoBeginId
    end
  end
  return testId
end

local function getFreeIdVeh()
  local testId = 0
  ::gotoBeginId::
  testId = testId + 1
  for i = 1, #SPool.vehicles do
    if SPool.vehicles[i].vehicleid == testId then
      goto gotoBeginId
    end
  end
  return testId
end

local function UDPSendPacket(content, ip, port)
  if not content or not ip or not port then return false end
  if content == nil or ip == nil or port == nil then return false end
  return udp:sendto(content, ip, port)
end

local function getDistBetweenPoints(x1, y1, z1, x2, y2, z2)
  return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

local function removePlayerFromPool(clientId)
  for i = #SPool.players, 1, -1 do
    if i == clientId then
      table.remove(SPool.players, clientId)
    end
  end
end

function server.getPlayerName(playerid)
  local slot = 0
  for i = 1, #SPool.players do
    if SPool.players[i].playerid == playerid then
      slot = i
      break
    end
  end
  if slot == 0 then return false end
  return SPool.players[slot].nickname
end
function server.setPlayerPos(playerid, position)
  local slot = 0
  for i = 1, #SPool.players do
    if SPool.players[i].playerid == playerid then
      slot = i
      break
    end
  end
  if slot == 0 then return false end
  SPool.players[slot].position = {position[1], position[2], position[3], position[4]}
  UDPSendPacket(generatePacket('P', 8, json.encode({
    position = SPool.players[slot].position
  })), SPool.players[slot].address[1], SPool.players[slot].address[2])
end
function server.getPlayerPos(playerid)
  local slot = 0
  for i = 1, #SPool.players do
    if SPool.players[i].playerid == playerid then
      slot = i
      break
    end
  end
  if slot == 0 then return false end
  return SPool.players[slot].position
end
function server.getPlayersCount()
  return #SPool.players
end
function server.sendClientMessageToAll(text, color)
  for i = 1, #SPool.players do
    server.sendClientMessage(SPool.players[i].playerid, text, color)
  end
end
function server.sendClientMessage(playerid, text, color)
  local slot = 0
  for i = 1, #SPool.players do
    if SPool.players[i].playerid == playerid then
      slot = i
      break
    end
  end
  if slot == 0 then return end
  UDPSendPacket(generatePacket('P', 4, json.encode({
    messageColor = color or 0xFFFFFFFF,
    messageText = text or ''
  })), SPool.players[slot].address[1], SPool.players[slot].address[2])
end
function server.kickPlayer(playerid)
  local slot = 0
  for i = 1, #SPool.players do
    if SPool.players[i].playerid == playerid then
      slot = i
      break
    end
  end
  if slot == 0 then return end
  local dreasion = 2
  for i = 1, #SPool.players do
    for i2, v2 in ipairs(SPool.players[i].streaming.players) do
      if v2 == SPool.players[slot].playerid then
        for i3 = #SPool.players[i].streaming.players, 1, -1 do
          if i3 == i2 then
            table.remove(SPool.players[i].streaming.players, i2)
          end
        end
      end
    end
    UDPSendPacket(generatePacket('P', 3, json.encode({
      playerid = SPool.players[slot].playerid
    })), SPool.players[i].address[1], SPool.players[i].address[2])
  end
  print(string.format('[DISCONNECTION] %s [%s:%s:%s] disconnected from server', SPool.players[slot].nickname, SPool.players[slot].address[1], SPool.players[slot].address[2], dreasion))
  pcall(onPlayerDisconnect, SPool.players[slot].playerid, dreasion)
  pcall(removePlayerFromPool, slot)
end
function server.createVehicle(model, position, colors)
  if #SPool.vehicles > 1000 then return false end
  local slot = #SPool.vehicles+1
  SPool.vehicles[slot] =
  {
    vehicleid = getFreeIdVeh(),
    model = model,
    position = position,
    colors = colors
  }
  for i = 1, #SPool.players do
    UDPSendPacket(generatePacket('P', 6, json.encode({
      vehicleid = SPool.vehicles[slot].vehicleid,
      model = SPool.vehicles[slot].model,
      position = SPool.vehicles[slot].position,
      colors = SPool.vehicles[slot].colors
    })), SPool.players[i].address[1], SPool.players[i].address[2])
  end
  return SPool.vehicles[slot].vehicleid
end
function server.deleteVehicle(vehicleid)
  local slot = 0
  for i = 1, #SPool.vehicles do
    if SPool.vehicles[i].vehicleid == vehicleid then
      slot = i
      break
    end
  end
  if slot == 0 then return false end
  for i = 1, #SPool.players do
    UDPSendPacket(generatePacket('P', 7, json.encode({
      vehicleid = SPool.vehicles[slot].vehicleid
    })), SPool.players[i].address[1], SPool.players[i].address[2])
  end
  for i = #SPool.vehicles, 1, -1 do
    if i == slot then
      table.remove(SPool.vehicles, slot)
    end
  end
  return true
end

udp:settimeout(0)
udp:setsockname(SConfig.connection.address, SConfig.connection.port)

print("SL:MP: Server is turning on")
print(string.format("SL:MP: Gamemode \"%s\" loaded", SConfig.general.gamemode))

assert(pcall(main), 'SL:MP: Main Function Not Found in Gamemode')

local serverStatus = true
while serverStatus do
  local data, msg_or_ip, port_or_nil = udp:receivefrom()
  if data then
    local isConnected, clientId = getClientConnected(msg_or_ip, port_or_nil)
    local msgType, msgId = data:match("^(%u)%[(%d+)%]")
    if msgType and msgId then
      if msgType == 'P' then
        local pData = data:match('^%u%[%d+%]%{(.+)%}')
        if pData then
          pData = json.decode(tostring(dataToString(pData))) or {}
          msgId = tonumber(msgId)
          -- Packets Processing
          if msgId == 0 then
            UDPSendPacket(generatePacket('P', 0, json.encode({
              serverName = SConfig.general.serverName,
              players = server.getPlayersCount(),
              version = SConfig.general.version,
              maxSlots = SConfig.general.maxSlots
            })), msg_or_ip, port_or_nil)
            goto loopEnd
          elseif msgId == 1 then
            if isConnected then goto loopEnd end
            print(string.format('[CONNECTION] %s:%s trying to connect to server', msg_or_ip or '0.0.0.0', port_or_nil or '0000'))
            if type(pData.nickname) ~= 'string' or type(pData.token) ~= 'string' or type(pData.version) ~= 'string' 
            or pData.nickname:len() < 1 or pData.nickname:len() > 25 or pData.token:len() < 1 then
              UDPSendPacket(generatePacket('R', 1, 1), msg_or_ip, port_or_nil)
              goto loopEnd
            end
            if server.getPlayersCount() >= SConfig.general.maxSlots then
              UDPSendPacket(generatePacket('R', 1, 2), msg_or_ip, port_or_nil)
              goto loopEnd
            end
            if pData.version ~= SConfig.general.version then
              UDPSendPacket(generatePacket('R', 1, 3), msg_or_ip, port_or_nil)
              goto loopEnd
            end
            for i = 1, #SPool.players do
              if SPool.players[i].nickname and SPool.players[i].nickname == pData.nickname then
                UDPSendPacket(generatePacket('R', 1, 4), msg_or_ip, port_or_nil)
                goto loopEnd
              end
            end
            UDPSendPacket(generatePacket('R', 1, 0), msg_or_ip, port_or_nil)
            local playerid = getFreeId()
            local slot = #SPool.players+1
            SPool.players[slot] = 
            {
              playerid = playerid,
              nickname = pData.nickname,
              token = pData.token,
              address = {msg_or_ip, port_or_nil},
              score = 0, ping = 999,
              streaming = {players = {}, vehicles = {}},
              position = {0.0, 0.0, 0.0, 0.0},
              vehicle = 0, vehicleSeat = 0
            }
            for i = 1, #SPool.players do
              UDPSendPacket(generatePacket('P', 2, json.encode({
                playerid = SPool.players[i].playerid,
                nickname = SPool.players[i].nickname
              })), msg_or_ip, port_or_nil)
              if SPool.players[i].playerid ~= playerid then
                UDPSendPacket(generatePacket('P', 2, json.encode({
                  playerid = playerid,
                  nickname = pData.nickname
                })), SPool.players[i].address[1], SPool.players[i].address[2])
              end
            end
            for i = 1, #SPool.vehicles do
              UDPSendPacket(generatePacket('P', 6, json.encode({
                vehicleid = SPool.vehicles[i].vehicleid,
                model = SPool.vehicles[i].model,
                position = SPool.vehicles[i].position,
                rotation = SPool.vehicles[i].rotation,
                colors = SPool.vehicles[i].colors
              })), msg_or_ip, port_or_nil)
            end
            print(string.format('[CONNECTION] %s [%s:%s:%s] connected to the server', SPool.players[slot].nickname, SPool.players[slot].address[1], SPool.players[slot].address[2], SPool.players[slot].playerid))
            pcall(onPlayerConnect, playerid)
          elseif msgId == 3 then
            if not isConnected then goto loopEnd end
            local dreasion = pData.reason or 0
            for i = 1, #SPool.players do
              for i2, v2 in ipairs(SPool.players[i].streaming.players) do
                if v2 == SPool.players[clientId].playerid then
                  for i3 = #SPool.players[i].streaming.players, 1, -1 do
                    if i3 == i2 then
                      table.remove(SPool.players[i].streaming.players, i2)
                    end
                  end
                end
              end
              UDPSendPacket(generatePacket('P', 3, json.encode({
                playerid = SPool.players[clientId].playerid
              })), SPool.players[i].address[1], SPool.players[i].address[2])
            end
            print(string.format('[DISCONNECTION] %s [%s:%s:%s] disconnected from server', SPool.players[clientId].nickname, SPool.players[clientId].address[1], SPool.players[clientId].address[2], dreasion))
            pcall(onPlayerDisconnect, playerid, dreasion)
            pcall(removePlayerFromPool, clientId)
          elseif msgId == 4 then
            if not isConnected then goto loopEnd end
            if type(pData.message) ~= 'string' then goto loopEnd end
            pcall(onPlayerChat, SPool.players[clientId].playerid, pData.message)
          elseif msgId == 5 then
            if not isConnected then goto loopEnd end
            if type(pData.position) ~= 'table' or type(pData.position[1]) ~= 'number' or type(pData.position[2]) ~= 'number' 
            or type(pData.position[3]) ~= 'number' or type(pData.position[4]) ~= 'number' or type(pData.velocity[1]) ~= 'number' 
            or type(pData.velocity[2]) ~= 'number' or type(pData.velocity[3]) ~= 'number' then goto loopEnd end
            SPool.players[clientId].position = {pData.position[1], pData.position[2], pData.position[3], pData.position[4]}
            local FootSync =
            {
              playerid = SPool.players[clientId].playerid, inStream = 1,
              position = {pData.position[1], pData.position[2], pData.position[3], pData.position[4]},
              velocity = {pData.velocity[1], pData.velocity[2], pData.velocity[3]},
              vehicle = SPool.players[clientId].vehicle, vehicleSeat = SPool.players[clientId].vehicleSeat
            }
            for i = 1, #SPool.players do
              if SPool.players[i].playerid ~= SPool.players[clientId].playerid then
                local dist = getDistBetweenPoints(pData.position[1], pData.position[2], pData.position[3],
                SPool.players[i].position[1], SPool.players[i].position[2], SPool.players[i].position[3])
                -- ONFOOT SYNC
                if dist >= SConfig.general.stream then
                  local wereStreamed = false
                  for i2, v2 in ipairs(SPool.players[i].streaming.players) do
                    if v2 == SPool.players[clientId].playerid then
                      wereStreamed = true
                      break
                    end
                  end
                  if wereStreamed then
                    FootSync.inStream = 0
                    UDPSendPacket(generatePacket('P', 5, json.encode(FootSync)), SPool.players[i].address[1], SPool.players[i].address[2])
                    for i2 = #SPool.players[i].streaming.players, 1, -1 do
                      if SPool.players[i].streaming.players[i2] == SPool.players[clientId].playerid then
                        table.remove(SPool.players[i].streaming.players, i2)
                      end
                    end
                  end
                else
                  FootSync.inStream = 1
                  UDPSendPacket(generatePacket('P', 5, json.encode(FootSync)), SPool.players[i].address[1], SPool.players[i].address[2])
                  local wereStreamed = false
                  for i2, v2 in ipairs(SPool.players[i].streaming.players) do
                    if v2 == SPool.players[clientId].playerid then
                      wereStreamed = true
                      break
                    end
                  end
                  if wereStreamed == false then 
                    table.insert(SPool.players[i].streaming.players, SPool.players[clientId].playerid)
                  end
                end
                -- ONFOOT SYNC
              end
            end
          elseif msgId == 9 then
            if not isConnected then goto loopEnd end
            if pData.vehicleid and pData.seat then
              SPool.players[clientId].vehicle = pData.vehicleid
              SPool.players[clientId].vehicleSeat = pData.seat
              pcall(onPlayerEnterVehicle, SPool.players[clientId].playerid, SPool.players[clientId].vehicle, SPool.players[clientId].vehicleSeat)
            end
          elseif msgId == 10 then
            if not isConnected then goto loopEnd end
            if pData.vehicleid then
              pcall(onPlayerExitVehicle, SPool.players[clientId].playerid, SPool.players[clientId].vehicle)
              SPool.players[clientId].vehicle = 0
            end
          end
          -- End Packets Processing
          pcall(onIncomingPacket, msgId, pData)
        end
      elseif msgType == 'R' then
        local rData = data:match('^%u%[%d+%]%{(%d+)%}')
          if rData then
            rData = tonumber(rData)
            msgId = tonumber(msgId)
            -- Responses Proccessing

            -- End Responses Proccessing
            pcall(onIncomingRPC, msgId, rData)
          end
      end
    end
  end
  ::loopEnd::
  socket.sleep(0.01)
end

print("SL:MP: Server is shutting down")