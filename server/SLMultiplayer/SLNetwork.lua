S_PACKETS =
{
  SERVER_INFO = 0,
  CONNECT = 1,
  DISCONNECT = 2,
  ONFOOT_SYNC = 3,
  CONNECTION_FAIL = 4,
  CONNECTION_SUCCESS = 5
}

S_RPC =
{
  PING_SERVER = 0,
  PLAYER_JOIN = 1,
  PLAYER_LEAVE = 2,
  CLIENT_MESSAGE = 3,
  SET_PLAYER_POS = 4,
  PING_BACK = 5,
  SEND_MESSAGE = 6,
  SEND_COMMAND = 7
}

SPool =
{
  sPlayers = {},
  sVehicles = {}
}

SPool.sendPacket = function(packetID, packetData, address, port)
  if type(address) ~= 'string' or 
  type(port) ~= 'number' then
    return false
  end
  if type(packetID) ~= 'number' or 
  type(packetData) ~= 'table' then
    return false
  end
  packetData = json.encode(packetData)
  packetData = SPool.encodeString(('P[%s]{%s}'):format(packetID, packetData))
  packetData = ('SLMP{%s}'):format(packetData)
  udp:sendto(packetData, address, port)
  return true
end

SPool.encodeString = function(str)
  return LEncoder:CompressDeflate(str, {level = 9})
end

SPool.decodeString = function(str)
  return LEncoder:DecompressDeflate(str)
end

SPool.sendRPC = function(rpcID, rpcData, address, port)
  if type(address) ~= 'string' or 
  type(port) ~= 'number' then
    return false
  end
  if type(rpcID) ~= 'number' or 
  type(rpcData) ~= 'table' then
    return false
  end
  rpcData = json.encode(rpcData)
  rpcData = SPool.encodeString(('R[%s]{%s}'):format(rpcID, rpcData))
  rpcData = ('SLMP{%s}'):format(rpcData)
  udp:sendto(rpcData, address, port)
  return true
end

SPool.findFreePlayerId = function()
  local playerid = -1
  local findID = false
  while not findID do
    local wasID = false
    playerid = playerid + 1
    for i = 1, #SPool.sPlayers do
      if SPool.sPlayers[i].playerid == playerid then
        wasID = true
        break
      end
    end
    if not wasID then 
      findID = true
    end
  end
  return playerid
end

SPool.getClient = function(pAddress, pPort)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].bindedIP == pAddress 
    and SPool.sPlayers[i].bindedPort == pPort then
      return true, i
    end
  end
  return false
end

function SPool.onPacketReceive(pID, pData, pAddress, pPort)
  local connected, clientID = SPool.getClient(pAddress, pPort)
  if pID == S_PACKETS.CONNECT then 
    pcall(Packet_Connect, pData, pAddress, pPort)
  elseif connected and pID == S_PACKETS.DISCONNECT then 
    pcall(Packet_Disconnect, pData, pAddress, pPort)
  elseif connected and pID == S_PACKETS.ONFOOT_SYNC then 
    pcall(Packet_OnFoot, pData, pAddress, pPort)
  elseif pID == S_PACKETS.SERVER_INFO then
    local pPool = {}
    for i = 1, #SPool.sPlayers do
      table.insert(pPool, {SPool.sPlayers[i].nickname, SPool.sPlayers[i].ping})
    end
    SPool.sendPacket(S_PACKETS.SERVER_INFO, {
      name = SConfig.serverName,
      players = #SPool.sPlayers,
      maxPlayers = SConfig.maxSlots,
      website = 'www.sl-mp.com',
      language = 'English',
      version = SInfo.sVersion,
      gamemode = SConfig.gamemodeScript,
      playersPool = pPool
    }, pAddress, pPort)
  end
end

function SPool.onRPCReceive(pID, pData, pAddress, pPort)
  local connected, clientID = SPool.getClient(pAddress, pPort)
  if pID == S_RPC.PING_SERVER then
    SPool.sendRPC(S_RPC.PING_BACK, {a = 1}, pAddress, pPort)
  elseif connected and pID == S_RPC.PING_BACK then
    SPool.sPlayers[clientID].ping = (os.clock() - SPool.sPlayers[clientID].ltPingBackMS) * 1000
    SPool.sPlayers[clientID].ltPingServer = os.time()
  elseif connected and pID == S_RPC.SEND_MESSAGE and type(pData.message) == 'string' then
    pcall(onPlayerChat, SPool.sPlayers[clientID].playerid, pData.message)
  elseif connected and pID == S_RPC.SEND_COMMAND and type(pData.command) == 'string' then
    pcall(onPlayerCommand, SPool.sPlayers[clientID].playerid, pData.command)
  end
end