S_PACKETS =
{
  SERVER_INFO = 0,
  CONNECT = 1,
  DISCONNECT = 2,
  ONFOOT_SYNC = 3,
  CONNECTION_FAIL = 4,
  CONNECTION_SUCCESS = 5,
  INCAR_SYNC = 6,
  VEHICLES_SYNC = 7,
  UNOCCUPIED_SYNC = 8
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
  SEND_COMMAND = 7,
  CREATE_VEHICLE = 8,
  DESTROY_VEHICLE = 9,
  ENTER_VEHICLE = 10,
  EXIT_VEHICLE = 11,
  CAR_JACKED = 12,
  SET_PLAYER_SKIN = 13,
  PLAYER_CONTROLABLE = 14,
  SET_PLAYER_INTERIOR = 15
}

S_PLAYERSTATE =
{
  PS_ONFOOT = 0,
  PS_DRIVER = 1,
  PS_PASSANGER = 2
}

SPool =
{
  sPlayers = {},
  sVehicles = {}
}

SPool.sendPacket = function(bitStream, address, port)
  if type(address) ~= 'string' 
  or type(port) ~= 'number' then
    return false
  end
  udp:sendto('SLMP-P'..SLNet.exportBytes(bitStream), address, port)
  return true
end

SPool.sendRPC = function(bitStream, address, port)
  if type(address) ~= 'string' 
  or type(port) ~= 'number' then
    return false
  end
  udp:sendto('SLMP-R'..SLNet.exportBytes(bitStream), address, port)
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
      return playerid
    end
  end
  return -1
end
SPool.findFreeVehicleId = function()
  local vehicleid = 0
  local findID = false
  while not findID do
    local wasID = false
    vehicleid = vehicleid + 1
    for i = 1, #SPool.sVehicles do
      if SPool.sVehicles[i].vehicleid == vehicleid then
        wasID = true
        break
      end
    end
    if not wasID then 
      findID = true
    end
  end
  return vehicleid
end

SPool.getClient = function(pAddress, pPort)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].bindedIP == pAddress 
    and SPool.sPlayers[i].bindedPort == pPort then
      return true, i
    end
  end
  return false, -1
end

function SPool.onPacketReceive(bitStream, pAddress, pPort)
  local res, ans = pcall(onIncomingPacket, bitStream, pAddress, pPort)
  if res and not ans then return false end
  SLNet.resetReadPointer(bitStream)
  SLNet.resetWritePointer(bitStream)
  local connected, clientID = SPool.getClient(pAddress, pPort)
  local pID = SLNet.readInt16(bitStream) or -1
  --print('PACKET' .. pID)
  if pID == S_PACKETS.CONNECT then 
    pcall(Packet_Connect, bitStream, pAddress, pPort)
  elseif connected and pID == S_PACKETS.DISCONNECT then 
    pcall(Packet_Disconnect, bitStream, pAddress, pPort)
  elseif connected and pID == S_PACKETS.ONFOOT_SYNC then 
    pcall(Packet_OnFoot, bitStream, pAddress, pPort)
  elseif connected and pID == S_PACKETS.INCAR_SYNC then 
    pcall(Packet_InCar, bitStream, pAddress, pPort)
  --[[elseif connected and pID == S_PACKETS.UNOCCUPIED_SYNC then 
    pcall(Packet_UnoccupiedSync, bitStream, pAddress, pPort)]]
  elseif pID == S_PACKETS.SERVER_INFO then
    local bs = SLNet.createBitStream()
    SLNet.writeInt16(bs, S_PACKETS.SERVER_INFO)
    SLNet.writeString(bs, SConfig.serverName)
    SLNet.writeInt16(bs, #SPool.sPlayers)
    SLNet.writeInt16(bs, SConfig.maxSlots)
    SLNet.writeString(bs, SConfig.website)
    SLNet.writeString(bs, SConfig.language)
    SLNet.writeString(bs, SInfo.sVersion)
    SLNet.writeString(bs, SConfig.gamemodeScript)
    SLNet.writeFloat(bs, SConfig.nametagsDistance)
    for i = 1, #SPool.sPlayers do
      SLNet.writeString(bs, SPool.sPlayers[i].nickname)
      SLNet.writeInt16(bs, SPool.sPlayers[i].ping)
    end
    SPool.sendPacket(bs, pAddress, pPort)
    SLNet.deleteBitStream(bs)
  end
end

function SPool.onRPCReceive(bitStream, pAddress, pPort)
  local res, ans = pcall(onIcomingRPC, bitStream, pAddress, pPort)
  if res and not ans then return false end
  SLNet.resetReadPointer(bitStream)
  SLNet.resetWritePointer(bitStream)
  local connected, clientID = SPool.getClient(pAddress, pPort)
  local pID = SLNet.readInt16(bitStream) or -1
  --print('RPC' .. pID)
  if pID == S_RPC.PING_SERVER then
    local bs = SLNet.createBitStream()
    SLNet.writeInt16(bs, S_RPC.PING_BACK)
    SPool.sendRPC(bs, pAddress, pPort)
    SLNet.deleteBitStream(bs)
  elseif connected and pID == S_RPC.PING_BACK then
    SPool.sPlayers[clientID].ping = (os.clock() - SPool.sPlayers[clientID].ltPingBackMS) * 1000
    SPool.sPlayers[clientID].ltPingServer = os.time()
  elseif connected and pID == S_RPC.SEND_MESSAGE then
    local pData = {}
    pData.message = SLNet.readString(bitStream)
    pcall(onPlayerChat, SPool.sPlayers[clientID].playerid, pData.message:gsub('[%%%[%]%{%}]', '#'))
  elseif connected and pID == S_RPC.SEND_COMMAND then
    local pData = {}
    pData.command = SLNet.readString(bitStream)
    pcall(onPlayerCommand, SPool.sPlayers[clientID].playerid, pData.command:gsub('[%%%[%]%{%}]', '#'))
  elseif connected and pID == S_RPC.ENTER_VEHICLE then
    local pData = {}
    pData.vehicleid = SLNet.readInt16(bitStream)
    pData.seatID = SLNet.readInt8(bitStream)
    local bs = SLNet.createBitStream()
    SLNet.writeInt16(bs, S_RPC.CAR_JACKED)
    SLNet.writeInt16(bs, pData.vehicleid)
    for i = 1, #SPool.sPlayers do
      if clientID ~= i and SPool.sPlayers[i].vehicleID == pData.vehicleid 
      and SPool.sPlayers[i].vehicleSeatID == pData.seatID then
        SPool.sPlayers[i].vehicleID = 0
        SPool.sPlayers[i].vehicleSeatID = 0
        SPool.sPlayers[i].playerState = S_PLAYERSTATE.PS_ONFOOT
        SPool.sendRPC(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      end
    end
    SLNet.deleteBitStream(bs)
    SPool.sPlayers[clientID].playerState = (pData.seatID == 0 and S_PLAYERSTATE.PS_DRIVER or S_PLAYERSTATE.PS_PASSANGER)
    SPool.sPlayers[clientID].vehicleID = pData.vehicleid 
    SPool.sPlayers[clientID].vehicleSeatID = pData.seatID
  elseif connected and pID == S_RPC.EXIT_VEHICLE then
    SPool.sPlayers[clientID].playerState = S_PLAYERSTATE.PS_ONFOOT
    SPool.sPlayers[clientID].vehicleID = 0
    SPool.sPlayers[clientID].vehicleSeatID = 0
  end
end