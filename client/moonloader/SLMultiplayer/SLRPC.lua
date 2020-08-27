function RPC_CreateVehicle(pData)
  local slot = #GPool.GVehicles + 1
  GPool.GVehicles[slot] = 
  {
    vehicleid = pData.vehicleid,
    model = pData.model,
    colors = pData.colors,
    position = {0.0, 0.0, 0.0}
  }
  return true
end

function RPC_DestroyVehicle(pData)
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