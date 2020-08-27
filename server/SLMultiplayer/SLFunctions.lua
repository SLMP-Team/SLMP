function sendClientMessage(playerid, message, color)
  if not color then color = 0xFFFFFFFF end
  if type(message) ~= 'string' then return false end
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      SPool.sendRPC(S_RPC.CLIENT_MESSAGE, {message = message, color = color}, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      return true
    end
  end
  return false
end
function sendClientMessageToAll(message, color)
  if type(message) ~= 'string' then return false end
  if not color then color = 0xFFFFFFFF end
  for i = 1, #SPool.sPlayers do
    SPool.sendRPC(S_RPC.CLIENT_MESSAGE, {message = message, color = color}, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
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
  for i = 1, #SPool.sPlayers do
    SPool.sendRPC(S_RPC.CREATE_VEHICLE, {
      vehicleid = SPool.sVehicles[slot].vehicleid,
      colors = SPool.sVehicles[slot].colors,
      model = SPool.sVehicles[slot].model
    }, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
  end
  return vehicleid
end
function destroyVehicle(vehicleid)
  for car = #SPool.sVehicles, 1, -1 do
    if SPool.sVehicles[car].vehicleid == vehicleid then
      for i = 1, #SPool.sPlayers do
        SPool.sendRPC(S_RPC.DESTROY_VEHICLE, {
          vehicleid = SPool.sVehicles[car].vehicleid
        }, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      end
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
      SPool.sendRPC(S_RPC.SET_PLAYER_POS, {
        position = {posX, posY, posZ}
      }, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
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
      SPool.sendRPC(S_RPC.SET_PLAYER_SKIN, {
        skin = SPool.sPlayers[i].skin
      }, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      return true
    end
  end
  return false
end