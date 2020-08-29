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
  print(pData.vehicleid, pData.model)
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
    inCar = 0, skin = 0
  }
  return true
end