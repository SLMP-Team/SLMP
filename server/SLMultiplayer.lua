mpFolder = '../SLMultiplayer/'
dofile(mpFolder .. "init.lua") -- SL:MP Header File
dofile(mpFolder .. "Utilities/encoder.lua") -- Network Base Module
dofile(mpFolder .. "net.lua") -- SL:MP Network Base File
dofile(mpFolder .. "network.lua") -- SL:MP Network File
dofile(mpFolder .. "packets.lua") -- SL:MP Packets Proccessing File
dofile(mpFolder .. "functions.lua") -- SL:MP Server Functions File

debugPacketsAndRPC = false

SConfig =
{
  serverName = 'SL:MP Server',
  maxSlots = 10,
  streamDistance = 300.0,
  bindAddress = '*',
  bindPort = 7777,
  gamemodeScript = 'gamemode',
  nametagsDistance = 20.0
}

local CFile = io.open('../server.cfg', 'r+')
if CFile then
  CFile:close()
  SConfig = json.load('../server.cfg', SConfig)
  if type(SConfig) ~= 'table' then
    SConfig =
    {
      serverName = 'SL:MP Server',
      maxSlots = 10,
      streamDistance = 300.0,
      bindAddress = '*',
      bindPort = 7777,
      gamemodeScript = 'gamemode'
    }
  end
end

if SConfig.maxSlots < 1 then
  SConfig.maxSlots = 1
end
json.save('../server.cfg', SConfig)

udp:settimeout(0)
udp:setsockname(SConfig.bindAddress, SConfig.bindPort)

print(' ')
print('SL:MP Dedicated Server')
print('-----------------------------------')
print(string.format('%s | SL-TEAM 2020', SInfo.sVersion))
print(' ')
print(string.format('Server started on port %s, max players: %s', SConfig.bindPort, SConfig.maxSlots))
print(' ')

local gmFile = io.open(string.format('../gamemodes/%s.lua', SConfig.gamemodeScript))
if not gmFile then
  print("[ERROR] Gamemode File Not Found, SL:MP Cannot Load Correctly")
  print("[ERROR] Please, check server.cfg and change gamemode name to correct")
  return false
end
gmFile:close()
dofile(string.format('../gamemodes/%s.lua', SConfig.gamemodeScript))

onGamemodeInit()
print('-----------------------------------')
print(string.format('TOTAL VEHICLES LOADED: %s', #SPool.sVehicles))

while true do
  for i = #CTimer.Timers, 1, -1 do
    if os.clock() >= CTimer.Timers[i].time then
      pcall(CTimer.Timers[i].callback, unpack(CTimer.Timers[i].arguments))
      if CTimer.Timers[i].repeatTimer then
        CTimer.Timers[i].time = os.clock() + CTimer.Timers[i].interval
      else table.remove(CTimer.Timers, i) end
    end
  end

  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i] and os.time() - SPool.sPlayers[i].ltPingUpdate > 30 then
      SPool.sPlayers[i].ltPingUpdate = os.time()
      SPool.sPlayers[i].ltPingBackMS = os.clock()
      local bitStream = SLNet.createBitStream()
      SLNet.writeInt16(bitStream, S_RPC.PING_SERVER)
      SPool.sendRPC(bitStream, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      SLNet.deleteBitStream(bitStream)
    elseif SPool.sPlayers[i] and os.time() - SPool.sPlayers[i].ltPingServer > (2 * 60) then
      SPool.sPlayers[i].ltPingServe = os.time()
      local bs = SLNet.createBitStream()
      SLNet.writeInt8(bs, 1)
      pcall(Packet_Disconnect, bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      SLNet.deleteBitStream(bs)
    end
  end
  
  local data, msg_or_ip, port_or_nil = udp:receivefrom()
  if data then
    local NetType = data:sub(1, 6)
    local NetData = data:sub(7, data:len())
    local bitStream = SLNet.createBitStream()
    if NetType == 'SLMP-R' then
      SLNet.importBytes(bitStream, NetData)
      pcall(SPool.onRPCReceive, bitStream, msg_or_ip or '', port_or_nil or 0)
    elseif NetType == 'SLMP-P' then
      SLNet.importBytes(bitStream, NetData)
      pcall(SPool.onPacketReceive, bitStream, msg_or_ip or '', port_or_nil or 0)
    end
    SLNet.deleteBitStream(bitStream)
  end

  socket.sleep(0.01)
end