function RPC_CreateVehicle(bitStream)
  local pData = {}
  pData.vehicleid = SLNet.readInt16(bitStream)
  pData.model = SLNet.readInt16(bitStream)
  pData.colors = {
    SLNet.readInt16(bitStream),
    SLNet.readInt16(bitStream)
  }
  local slot = #GPool.GVehicles + 1
  GPool.GVehicles[slot] =
  {
    vehicleid = pData.vehicleid,
    model = pData.model,
    colors = pData.colors,
    position = {0.0, 0.0, 0.0}
  }
  --print(pData.vehicleid, pData.model)
  return true
end

function RPC_DestroyVehicle(bitStream)
  local pData = {}
  pData.vehicleid = SLNet.readInt16(bitStream)
  for car = #GPool.GVehicles, 1, -1 do
    if GPool.GVehicles[car].vehicleid == pData.vehicleid then
      if GPool.GVehicles[car].handle and doesVehicleExist(GPool.GVehicles[car].handle) then
        deleteCar(GPool.GVehicles[car].handle)
      end
      table.remove(GPool.GVehicles, car)
      return true
    end
  end
end

function RPC_PlayerJoin(bitStream)
  local pData = {}
  pData.playerid = SLNet.readInt16(bitStream)
  pData.nickname = SLNet.readString(bitStream)
  local slot = #GPool.GPlayers + 1
  GPool.GPlayers[slot] =
  {
    playerid = pData.playerid,
    nickname = pData.nickname,
    position = {0.0, 0.0, 0.0},
    health = 100.0, armour = 0.0,
    inCar = 0, skin = 0,
    chatBubble = {
      text = '',
      color = 0,
      time = 0,
      distance = 0.0
    }
  }
  --print('connected ' .. pData.nickname .. ' with ID ' .. pData.playerid)
  return true
end

function RPC_CreatePickup(bitStream)
  local pData = {}
  pData.pickupid = SLNet.readInt16(bitStream)
  pData.modelid = SLNet.readInt16(bitStream)
  pData.pickuptype = SLNet.readInt8(bitStream)
  local slot = #GPool.GPickups + 1
  GPool.GPickups[slot] =
  {
    pickupid = pData.pickupid,
    modelid = pData.modelid,
    pickuptype = pData.pickuptype
  }
  return true
end

function RPC_DestroyPickup(bitStream)
  local pickupid = SLNet.readInt16(bitStream)
  for i = #GPool.GPickups, 1, -1 do
    if GPool.GPickups[i].pickupid == pickupid then
      if GPool.GPickups[i].handle and doesPickupExist(GPool.GPickups[i].handle) then
        removePickup(GPool.GPickups[i].handle)
      end
      table.remove(GPool.GPickups, i)
      return true
    end
  end
  return false
end