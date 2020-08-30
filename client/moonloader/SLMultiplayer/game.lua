CGame =
{
  cVersion = 'SL:MP 0.0.1-RC7',
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
CGame.disableBlueFog = function()
  pcall(memory.fill, 0x00575B0E, 0x90, 5, true)
end
CGame.disableWasted = function()
  pcall(memory.fill, 0x56E5AD, 0x90, 5, true)
end
CGame.getGamestate = function()
  return memory.getuint32(0xC8D4C0, true)
end
CGame.setGamestate = function(gamestate)
  memory.setuint32(0xC8D4C0, gamestate, true)
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
      if not isCarPassengerSeatFree(car, i)
      and getCharInCarPassengerSeat(car, i) == ped then
        return i+1
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
  setCarCanBeVisiblyDamaged(handle, status)
  setCarCanBeDamaged(handle, status)
  setCanBurstCarTires(handle, status)
end
CGame.disableHazeEffect = function()
  memory.write(0x72C1B7, 0xEB, 1, true)
end
CGame.disableCJWalkAnimation = function()
  pcall(memory.fill, 0x609A4E, 0x90, 6, true)
end
CGame.disableIdleAnimation = function ()
  pcall(memory.setuint8, 0x86D1EC, 0x90, 0, true)
end

CGame.getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
CGame.getBodyPartCoordinates = function(id, handle)
  local pedptr = getCharPointer(handle)
  local vec = ffi.new("float[3]")
  CGame.getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
  return vec[0], vec[1], vec[2]
end

CGame.SpecialSkins={[3]='ANDRE',[4]='BBTHIN',[5]='BB',[298]='CAT',[292]='CESAR',[190]='COPGRL3',[299]='CLAUDE',[194]='CROGRL3',[268]='DWAYNE',
[6]='EMMET',[272]='FORELLI',[195]='GANGRL3',[191]='GUNGRL3',[267]='HERN',[8]='JANITOR',[42]='JETHRO',[296]='JIZZY',[65]='KENDL',[2]='MACCER',
[297]='MADDOGG',[192]='MECGRL3',[193]='NURGRL2',[293]='OGLOC',[291]='PAUL',[266]='PULASKI',[290]='ROSE',[271]='RYDER',[86]='RYDER3',[119]='SINDACO',
[269]='SMOKE',[149]='SMOKEV',[208]='SUZIE',[270]='SWEET',[273]='TBONE',[265]='TENPEN',[295]='TORINO',[1]='TRUTH',[294]='WUZIMU',[289]='ZERO',
[300]='LAPDNA',[301]='SFPDNA',[302]='LVPDNA',[303]='LAPDPC',[304]='LAPDPD',[305]='LVPDPC',[306]='WFYCLPD',[307]='VBFYCPD',[308]='WFYCLEM',
[309]='WFYCLLV',[310]='CSHERNA',[311]='DSHERNA',[312]='COPGRL1'}
CGame.createCharNet = function(pedtype, skinid, atX, atY, atZ)
  local isSpec = false
  if CGame.SpecialSkins[skinid] then
    isSpec = true
    loadSpecialCharacter(CGame.SpecialSkins[skinid], 1)
  else
    requestModel(skinid)
    loadAllModelsNow()
  end
  local ped = createChar(pedtype, isSpec and 290 or skinid, atX, atY, atZ)
  if isSpec then unloadSpecialCharacter(1)
  else markModelAsNoLongerNeeded(skinid) end
  return ped
end
CGame.setPlayerSkin = function(skinid)
  local isSpec = false
  if CGame.SpecialSkins[skinid] then
    isSpec = true
    loadSpecialCharacter(CGame.SpecialSkins[skinid], 1)
    while not hasSpecialCharacterLoaded(1) do wait(0) end
  else
    requestModel(skinid)
    loadAllModelsNow()
    while not hasModelLoaded(skinid) do wait(0) end
  end
  local x, y, z = getCharCoordinates(PLAYER_PED)
  setPlayerModel(PLAYER_HANDLE, isSpec and 290 or skinid)
  if isSpec then unloadSpecialCharacter(1)
  else markModelAsNoLongerNeeded(skinid) end
end
CGame.hookPickupCollected = function()
  while true do
    if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
      for i = 1, #GPool.GPickups do
        if GPool.GPickups[i].handle and doesPickupExist(GPool.GPickups[i].handle) then
          if hasPickupBeenCollected(GPool.GPickups[i].handle) then
            local bs = SLNet.createBitStream()
            SLNet.writeInt16(bs, S_RPC.PLAYER_PICK_PICKUP)
            SLNet.writeInt16(bs, GPool.GPickups[i].pickupid)
            SPool.sendRPC(bs)
            SLNet.deleteBitStream(bs)
          end
        end
      end
    end
    wait(100)
  end
end
CGame.weaponSync = function()
  while true do
    wait(100)
    if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
      local updated = false
      if getCurrentCharWeapon(PLAYER_PED) ~= LPlayer.lpCurrentWeapon then
        updated = true
      end
      for i = 1, 13 do
        local weapon, ammo, modelid = getCharWeaponInSlot(PLAYER_PED, i-1)
        if weapon < 0 or weapon > 255 then weapon = 0 end
        if ammo < 0 or ammo > 32767 then ammo = 0 end
        if not LPlayer.lpWeapons[i] or weapon ~= LPlayer.lpWeapons[i][1]
        or ammo ~= LPlayer.lpWeapons[i][2] then
          updated = true
          break
        end
      end
      if updated then
        ltSendUpdateWeapons = os.time() + 1
        local bs = SLNet.createBitStream()
        SLNet.writeInt16(bs, S_PACKETS.WEAPONS_SYNC)
        for i = 1, 13 do
          local weapon, ammo, modelid = getCharWeaponInSlot(PLAYER_PED, i-1)
          if weapon < 0 or weapon > 255 then weapon = 0 end
          if ammo < 0 or ammo > 32767 then ammo = 0 end
          SLNet.writeUInt8(bs, weapon)
          SLNet.writeUInt16(bs, ammo)
          LPlayer.lpWeapons[i] = {weapon, ammo}
        end
        local currentWeapon = getCurrentCharWeapon(PLAYER_PED)
        LPlayer.lpCurrentWeapon = currentWeapon
        SLNet.writeInt8(bs, currentWeapon)
        SPool.sendPacket(bs)
        SLNet.deleteBitStream(bs)
      end
    end
  end
end