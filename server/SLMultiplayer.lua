mpFolder = '..\\SLMultiplayer'
dofile(mpFolder .. "\\SLMultiplayer.lua") -- SL:MP Header File
dofile(mpFolder .. "\\SLNetwork.lua") -- SL:MP Network File
dofile(mpFolder .. "\\SLPackets.lua") -- SL:MP Packets Proccessing File
dofile(mpFolder .. "\\SLFunctions.lua") -- SL:MP Server Functions File

SConfig =
{
  serverName = 'SL:MP Server',
  maxSlots = 10,
  streamDistance = 300.0,
  bindAddress = '*',
  bindPort = 7777,
  gamemodeScript = 'gamemode'
}

local CFile = io.open('..\\server.cfg', 'r+')
if CFile then
  CFile:close()
  SConfig = json.load('..\\server.cfg', SConfig)
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
json.save('..\\server.cfg', SConfig)

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

print('-----------------------------------')
print(string.format('TOTAL VEHICLES LOADED: %s', #SPool.sVehicles))

while true do
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i] and os.time() - SPool.sPlayers[i].ltPingUpdate > 10 then
      SPool.sPlayers[i].ltPingUpdate = os.time()
      SPool.sPlayers[i].ltPingBackMS = os.clock()
      SPool.sendRPC(S_RPC.PING_SERVER, {a = 1}, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
    end
    if SPool.sPlayers[i] and os.time() - SPool.sPlayers[i].ltPingServer > (2 * 60) then
      SPool.sPlayers[i].ltPingServe = os.time()
      pcall(Packet_Disconnect, {reason = 1}, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
    end
  end
  do
    local data, msg_or_ip, port_or_nil = udp:receivefrom()
    if not data then goto UDP_Receiver_End end
    if not data:find('^SLMP') then goto UDP_Receiver_End end
    local data = data:match('^SLMP%{(.+)%}')
    if not data then goto UDP_Receiver_End end

    data = SPool.decodeString(data)
    local type, id, data = data:match('^(%S)%[(%d+)%]%{(.+)%}$')
    if not type then goto UDP_Receiver_End end

    local data = json.decode(data)
    if type == 'P' then
      --print('p', id, json.encode(data))
      pcall(SPool.onPacketReceive, tonumber(id), data, msg_or_ip or '', port_or_nil or 0)
    elseif type == 'R' then
      --print('r', id, json.encode(data))
      pcall(SPool.onRPCReceive, tonumber(id), data, msg_or_ip or '', port_or_nil or 0)
    end
    
  end
  ::UDP_Receiver_End::
  socket.sleep(0.01)
end