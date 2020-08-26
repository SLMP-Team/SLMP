function sendClientMessage(playerid, message, color)
  if not color then color = 0xFFFFFFFF end
  if type(message) ~= 'string' then return false end
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      SPool.sendRPC(S_RPC.SEND_MESSAGE, {message = message, color = color}, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      return true
    end
  end
  return false
end
function sendClientMessageToAll(message, color)
  for i = 1, #SPool.sPlayers do
    sendClientMessage(SPool.sPlayers[i].playerid, message, color)
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
    health = 0.0,
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
  print('created vehicle with id ' .. vehicleid)
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