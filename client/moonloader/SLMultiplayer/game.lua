CGame = 
{
  cVersion = 'SL:MP 0.0.1-Alpha-R4',
  cScreen = {x = 0, y = 0}
}
CGame.cScreen.x, CGame.cScreen.y = getScreenResolution()

CGame.disableVehicleName = function()
  pcall(memory.fill, 0x58FBE9, 0x90, 5, true)
end
CGame.disableReplays = function()
  pcall(memory.fill, 0x53C090, 0x90, 5, true)
end
CGame.disableCharacters = function()
  pcall(memory.setfloat, 0x8D2530, 0.0, true)
end
CGame.disableVehicles = function()
  pcall(memory.setfloat, 0x8A5B20, 0.0, true)
end
CGame.disableWasted = function()
  pcall(memory.fill, 0x56E5AD, 0x90, 5, true)
end
CGame.getGamestate = function()
  return memory.getuint32(0xC8D4C0, false)
end
CGame.setGamestate = function(gamestate)
  pcall(memory.setuint32, 0xC8D4C0, gamestate, true)
end
CGame.disableBlurEffect = function()
  pcall(memory.fill, 0x704E8A, 0x90, 5, true)
end
CGame.disableCheats = function()
  pcall(memory.write, 0x4384D0, 0x9090, 2)
  pcall(memory.write, 0x4384D2, 0x90, 1)
  pcall(memory.write, 0x4384D3, 0xE9, 1)
  pcall(memory.write, 0x4384D4, 0x000000CD, 4)
end
CGame.disableWanted = function()
  pcall(memory.write, 0x58DB5F, 0xBD, 1, true)
  pcall(memory.fill, 0x58DB60, 0x00, 4, true)
  pcall(memory.fill, 0x58DB64, 0x90, 4, true)
end
CGame.disableSpawnCars = function()
  pcall(memory.fill, 0x53C1C1, 0x90, 5, true)
  pcall(memory.fill, 0x434272, 0x90, 5, true)
end
CGame.disableInteriorPeds = function()
  pcall(memory.fill, 0x440833, 0x90, 8, true)
end
CGame.disableMessagePrint = function()
  pcall(memory.write, 0x588BE0, 0xC3, 1, true)
end
CGame.disableWeaponPickups = function()
  pcall(memory.write, 0x5B47B0, 0xC3, 1, true)
end
CGame.disableAllFuckingCity = function()
  setPedDensityMultiplier(0.0) -- Disable all ped`s
  setCarDensityMultiplier(0.0) -- Disable all vehicle`s
  setMaxWantedLevel(0) -- Set max wanted level 0
  setOnlyCreateGangMembers(true) -- unknown_disable_gang_wars
  setCreateRandomGangMembers(false) -- Disable generate gang members
  enableBurglaryHouses(false) -- disable houses
  setFreeResprays(true) -- Enable free resprays
  switchRandomTrains(false) -- Disable train spawn and traffic
  setCreateRandomCops(false) -- Disable fucking cops
  switchEmergencyServices(false) -- Disable emergency
  switchAmbientPlanes(false) -- disable air traffic
end
CGame.workInPause = function()
  memory.setuint8(7634870, 1) 
  memory.setuint8(7635034, 1)
  memory.fill(7623723, 144, 8)
  memory.fill(5499528, 144, 6)
  memory.fill(0x748063, 0x90, 5, true)
end
CGame.getVehicleSeat = function(ped)
  if doesCharExist(ped) and isCharInAnyCar(ped) then
    local car = storeCarCharIsInNoSave(ped)
    for i = 0, getMaximumNumberOfPassengers(car) - 1 do
      if not isCarPassengerSeatFree(car, i) and getCharInCarPassengerSeat(car, i) == ped then
        return i
      end
    end
  end
  return 0
end
CGame.disableParkedCars = function()
  memory.write(0x9690A0, 0, 4, true)
end
CGame.setVehicleDamagable = function(handle, status)
  if not doesVehicleExist(handle) then return end
  setCarProofs(handle, not status, not status, not status, not status, not status)
  setCarCanBeDamaged(handle, status)
end
CGame.disableHazeEffect = function()
  memory.write(0x72C1B7, 0xEB, 1, true)
end

CGame.getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
CGame.getBodyPartCoordinates = function(id, handle)
  local pedptr = getCharPointer(handle)
  local vec = ffi.new("float[3]")
  CGame.getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
  return vec[0], vec[1], vec[2]
end