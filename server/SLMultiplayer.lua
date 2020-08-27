mpFolder = '../SLMultiplayer/'
dofile(mpFolder .. "SLMultiplayer.lua") -- SL:MP Header File
dofile(mpFolder .. "SLNetwork.lua") -- SL:MP Network File
dofile(mpFolder .. "SLPackets.lua") -- SL:MP Packets Proccessing File
dofile(mpFolder .. "SLFunctions.lua") -- SL:MP Server Functions File

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

local FloodFilterList = {}

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

    -- Flood Saver
    local listedInList = false
    for ii = 1, #FloodFilterList do
      if FloodFilterList[ii].ip == msg_or_ip 
      and FloodFilterList[ii].port == port_or_nil then
        if os.clock() - FloodFilterList[ii].time <= 0.005 then
          goto UDP_Receiver_End
        else
          FloodFilterList[ii].time = os.clock()
          listedInList = true
        end
      end
    end
    if not listedInList then
      table.insert(FloodFilterList, {ip = msg_or_ip, port = port_or_nil, time = os.clock()})
    end
    -- Flood Saver

    if not data:find('^SLMP') then goto UDP_Receiver_End end
    data = data:match('^SLMP%{(.+)%}')
    if not data then goto UDP_Receiver_End end

    data = SPool.decodeString(data)
    if type(data) ~= 'string' then return false end
    local netType, id, data = data:match('^(%S)%[(%d+)%]%{(.+)%}$')
    if not netType then goto UDP_Receiver_End end

    data = json.decode(data)
    if type(data) ~= 'table' then return false end
    if netType == 'P' then
      if debugPacketsAndRPC then print('p', id, json.encode(data)) end
      pcall(SPool.onPacketReceive, tonumber(id), data, msg_or_ip or '', port_or_nil or 0)
    elseif netType == 'R' then
      if debugPacketsAndRPC then print('r', id, json.encode(data)) end
      pcall(SPool.onRPCReceive, tonumber(id), data, msg_or_ip or '', port_or_nil or 0)
    end
    
  end
  ::UDP_Receiver_End::
  socket.sleep(0.01)
end