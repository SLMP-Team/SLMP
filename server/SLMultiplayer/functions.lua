function sendClientMessage(playerid, message, color)
  if not color then color = 0xFFFFFFFF end
  if type(message) ~= 'string' then return false end
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      local bs = SLNet.createBitStream()
      SLNet.writeInt16(bs, S_RPC.CLIENT_MESSAGE)
      SLNet.writeString(bs, message)
      SLNet.writeInteger(bs, color)
      SPool.sendRPC(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      SLNet.deleteBitStream(bs)
      return true
    end
  end
  return false
end
function sendClientMessageToAll(message, color)
  if type(message) ~= 'string' then return false end
  if not color then color = 0xFFFFFFFF end
  for i = 1, #SPool.sPlayers do
    local bs = SLNet.createBitStream()
    SLNet.writeInt16(bs, S_RPC.CLIENT_MESSAGE)
    SLNet.writeString(bs, message)
    SLNet.writeInteger(bs, color)
    SPool.sendRPC(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
    SLNet.deleteBitStream(bs)
  end
  return true
end
function getPlayerName(playerid)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      return SPool.sPlayers[i].nickname
    end
  end
  return false
end
function createVehicle(model, posX, posY, posZ, color1, color2)
  local slot = #SPool.sVehicles + 1
  local vehicleid = SPool.findFreeVehicleId()
  SPool.sVehicles[slot] = 
  {
    vehicleid = vehicleid,
    model = model,
    position = {posX, posY, posZ},
    quaternion = {0.0, 0.0, 0.0, 0.0},
    facingAngle = 0.0, 
    health = 1000.0,
    roll = 0.0,
    colors = {color1, color2},
    streamedFor = {}
  }
  local bs = SLNet.createBitStream()
  SLNet.writeInt16(bs, S_RPC.CREATE_VEHICLE)
  SLNet.writeInt16(bs, SPool.sVehicles[slot].vehicleid)
  SLNet.writeInt16(bs, SPool.sVehicles[slot].model)
  SLNet.writeInt16(bs, SPool.sVehicles[slot].colors[1])
  SLNet.writeInt16(bs, SPool.sVehicles[slot].colors[2])
  for i = 1, #SPool.sPlayers do
    SPool.sendRPC(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
  end
  SLNet.deleteBitStream(bs)
  return vehicleid
end
function destroyVehicle(vehicleid)
  for car = #SPool.sVehicles, 1, -1 do
    if SPool.sVehicles[car].vehicleid == vehicleid then
      local bs = SLNet.createBitStream()
      SLNet.writeInt16(bs, S_RPC.DESTROY_VEHICLE)
      SLNet.writeInt16(bs, SPool.sVehicles[car].vehicleid)
      for i = 1, #SPool.sPlayers do
        SPool.sendRPC(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      end
      SLNet.deleteBitStream(bs)
      table.remove(SPool.sVehicles, car)
      return true
    end
  end
  return false
end
function getPlayerPos(playerid)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      return SPool.sPlayers[i].position[1], SPool.sPlayers[i].position[2], SPool.sPlayers[i].position[3]
    end
  end
  return false
end
function setPlayerPos(playerid, posX, posY, posZ)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      local bs = SLNet.createBitStream()
      SLNet.writeInt16(bs, S_RPC.SET_PLAYER_POS)
      SLNet.writeFloat(bs, posX)
      SLNet.writeFloat(bs, posY)
      SLNet.writeFloat(bs, posZ)
      SPool.sendRPC(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      SLNet.deleteBitStream(bs)
      SPool.sPlayers[i].position = {posX, posY, posZ}
      return true
    end
  end
end
function isPlayerConnected(playerid)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      return true
    end
  end
  return false
end
function getPlayerSkin(playerid)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      return SPool.sPlayers[i].skin
    end
  end
  return 0
end
function setPlayerSkin(playerid, skin)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      SPool.sPlayers[i].skin = skin
      local bs = SLNet.createBitStream()
      SLNet.writeInt16(bs, S_RPC.SET_PLAYER_SKIN)
      SLNet.writeInt16(bs, SPool.sPlayers[i].skin)
      SPool.sendRPC(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      SLNet.deleteBitStream(bs)
      return true
    end
  end
  return false
end
function kickPlayer(playerid)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      local bs = SLNet.createBitStream()
      SLNet.writeInt16(bs, S_PACKETS.DISCONNECT)
      SPool.sendPacket(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      SLNet.deleteBitStream(bs)
      bs = SLNet.createBitStream()
      SLNet.writeInt8(bs, 2)
      pcall(Packet_Disconnect, bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      SLNet.deleteBitStream(bs)
      return true
    end
  end
  return false
end