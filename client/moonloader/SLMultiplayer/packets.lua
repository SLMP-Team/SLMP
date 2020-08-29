function Packet_Connection_Fail(bitStream)
  local pData = {}
  pData.errorCode = SLNet.readInt8(bitStream)
  if pData.errorCode == 1 then
    CGraphics.tClientPopupText = 'Server not responding to connection request!'
  elseif pData.errorCode == 2 then
    CGraphics.tClientPopupText = 'Your player name might be from 1 to 24 symbols!'
  elseif pData.errorCode == 3 then
    CGraphics.tClientPopupText = 'Your player name might only contains letters and numbers!'
  elseif pData.errorCode == 4 then
    CGraphics.tClientPopupText = 'No free slots on this server, please try later!'
  elseif pData.errorCode == 5 then
    CGraphics.tClientPopupText = 'Your client version not equals to server version!'
  elseif pData.errorCode == 6 then
    CGraphics.tClientPopupText = 'Your nickname already taken on this server!'
  else CGraphics.tClientPopupText = 'Unknown Connection Error!' end
  SPool.disconnect(0)
end

function Packet_Connection_Success(bitStream)
  local pData = {}
  pData.playerid = SLNet.readInt16(bitStream)
  CGraphics.wClient[0] = false
  CGraphics.wChat[0] = true
  LPlayer.lpGameState = S_GAMESTATES.GS_CONNECTED
  ltPingServerTime = os.time()
  ltServerAnswerPing = os.time()
  LPlayer.lpPlayerId = pData.playerid
  LPlayer.lpPlayerState = S_PLAYERSTATE.PS_ONFOOT
  setCharCoordinates(PLAYER_PED, 0.0, 0.0, 1.0)
  requestModel(14)
  loadAllModelsNow()
  setPlayerModel(PLAYER_HANDLE, 14)
  markModelAsNoLongerNeeded(14)
  CGraphics.tClientPopupText = 'Connected to server, enjoy playing!'
  setPlayerControl(PLAYER_HANDLE, true)
  lockPlayerControl(false)
  CGraphics.wLockMove[0] = false
  setCharInterior(PLAYER_PED, 0)
end

function Packet_OnFoot_Sync(bitStream)
  local pData = {}
  pData.playerid = SLNet.readInt16(bitStream)
  pData.streamedForPlayer = SLNet.readBool(bitStream)
  if pData.streamedForPlayer then
    pData.health = SLNet.readInt8(bitStream)
    pData.armour = SLNet.readInt8(bitStream)
    pData.skin = SLNet.readInt16(bitStream)
    pData.position =
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
    pData.quaternion =
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
    pData.velocity =
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
    pData.facingAngle = SLNet.readFloat(bitStream)
    pData.interior = SLNet.readInt16(bitStream)
  end
  for i = 1, #GPool.GPlayers do
    if pData.playerid == GPool.GPlayers[i].playerid
    and GPool.GPlayers[i].playerid ~= LPlayer.lpPlayerId then
      local player = GPool.GPlayers[i]
      if not pData.streamedForPlayer and player.handle and doesCharExist(player.handle) then
        deleteChar(player.handle)
        return false
      elseif pData.streamedForPlayer and (not player.handle or not doesCharExist(player.handle) or GPool.GPlayers[i].skin ~= pData.skin) then
        if player.handle and doesCharExist(player.handle)
        and GPool.GPlayers[i].skin ~= pData.skin then
          deleteChar(player.handle)
        end
        --requestModel(pData.skin)
        --loadAllModelsNow()
        --GPool.GPlayers[i].handle = createChar(4, pData.skin, pData.position[1], pData.position[2], pData.position[3])
        GPool.GPlayers[i].handle = CGame.createCharNet(4, pData.skin, pData.position[1], pData.position[2], pData.position[3])
        local dec = loadCharDecisionMaker(65543)
        setCharDecisionMaker(GPool.GPlayers[i].handle, dec)
        setCharProofs(GPool.GPlayers[i].handle, true, true, true, true, true)
        setCharDropsWeaponsWhenDead(GPool.GPlayers[i].handle, false)
        setCharKindaStayInSamePlace(GPool.GPlayers[i].handle, true)
        --markModelAsNoLongerNeeded(pData.skin)
        GPool.GPlayers[i].inCar = 0
        GPool.GPlayers[i].interior = 0
        GPool.GPlayers[i].skin = pData.skin
      end
      if GPool.GPlayers[i].interior ~= pData.interior then
        GPool.GPlayers[i].interior = pData.interior
        setCharInterior(GPool.GPlayers[i].handle, pData.interior)
      end
      if GPool.GPlayers[i].inCar == 1 then
        taskLeaveAnyCar(GPool.GPlayers[i].handle)
      end
      GPool.GPlayers[i].position = {pData.position[1], pData.position[2], pData.position[3] - 1.0}
      setCharCoordinates(player.handle, pData.position[1], pData.position[2], pData.position[3] - 1.0)
      setCharQuaternion(player.handle, pData.quaternion[1], pData.quaternion[2], pData.quaternion[3], pData.quaternion[4])
      setCharHeading(player.handle, pData.facingAngle)
      setCharVelocity(player.handle, pData.velocity[1], pData.velocity[2], pData.velocity[3])
      setCharHealth(player.handle, pData.health)
      GPool.GPlayers[i].health = pData.health
      GPool.GPlayers[i].armour = pData.armour
      return true
    end
  end
end

function Packet_Pickups_Sync(bitStream)
  local pData = {}
  pData.pickupid = SLNet.readInt16(bitStream)
  pData.streamedForPlayer = SLNet.readBool(bitStream)
  if pData.streamedForPlayer then
    pData.position =
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
  end
  for i = 1, #GPool.GPickups do
    if GPool.GPickups[i].pickupid == pData.pickupid then
      if not pData.streamedForPlayer and GPool.GPickups[i].handle and doesPickupExist(GPool.GPickups[i].handle) then
        removePickup(GPool.GPickups[i].handle)
      elseif pData.streamedForPlayer and (not GPool.GPickups[i].handle or not doesPickupExist(GPool.GPickups[i].handle)) then
        requestModel(GPool.GPickups[i].modelid)
        loadAllModelsNow()
        local x, y, z = pData.position[1], pData.position[2], pData.position[3]
        GPool.GPickups[i].handle = select(2, createPickup(GPool.GPickups[i].modelid, GPool.GPickups[i].pickuptype, x, y, z))
        markModelAsNoLongerNeeded(GPool.GPickups[i].modelid)
      end
      return true
    end
  end
end

function Packet_Vehicle_Sync(bitStream)
  local pData = {}
  pData.vehicleid = SLNet.readInt16(bitStream)
  pData.streamedForPlayer = SLNet.readBool(bitStream)
  if pData.streamedForPlayer then
    pData.position =
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
    pData.quaternion =
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
    pData.facingAngle = SLNet.readFloat(bitStream)
    pData.roll = SLNet.readFloat(bitStream)
    pData.health = SLNet.readInt16(bitStream)
  end
  for i = 1, #GPool.GVehicles do
    if GPool.GVehicles[i].vehicleid == pData.vehicleid then
      if not pData.streamedForPlayer and GPool.GVehicles[i].handle and doesVehicleExist(GPool.GVehicles[i].handle) then
        deleteCar(GPool.GVehicles[i].handle)
      elseif pData.streamedForPlayer and (not GPool.GVehicles[i].handle or not doesVehicleExist(GPool.GVehicles[i].handle)) then
        requestModel(GPool.GVehicles[i].model)
        loadAllModelsNow()
        GPool.GVehicles[i].handle = createCar(GPool.GVehicles[i].model, pData.position[1], pData.position[2], pData.position[3])
        GPool.GVehicles[i].position = pData.position
        markModelAsNoLongerNeeded(GPool.GVehicles[i].model)
        changeCarColour(GPool.GVehicles[i].handle, GPool.GVehicles[i].colors[1], GPool.GVehicles[i].colors[2])
        setCarCoordinates(GPool.GVehicles[i].handle, pData.position[1], pData.position[2], pData.position[3])
        setVehicleQuaternion(GPool.GVehicles[i].handle, pData.quaternion[1], pData.quaternion[2], pData.quaternion[3], pData.quaternion[4])
        setCarHeading(GPool.GVehicles[i].handle, pData.facingAngle)
        setCarRoll(GPool.GVehicles[i].handle, pData.roll)
        setCarHealth(GPool.GVehicles[i].handle, pData.health)
      end
      return true
    end
  end
end

function Packet_InCar_Sync(bitStream)
  local pData = {}
  pData.playerid = SLNet.readInt16(bitStream)
  pData.streamedForPlayer = SLNet.readBool(bitStream)
  if pData.streamedForPlayer then
    pData.pHealth = SLNet.readInt8(bitStream)
    pData.armour = SLNet.readInt8(bitStream)
    pData.skin = SLNet.readInt16(bitStream)
    pData.vehicleid = SLNet.readInt16(bitStream)
    pData.seatID = SLNet.readInt8(bitStream)
    pData.position =
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
    if pData.seatID == 0 then
      pData.health = SLNet.readInt16(bitStream)
      pData.quaternion =
      {
        SLNet.readFloat(bitStream),
        SLNet.readFloat(bitStream),
        SLNet.readFloat(bitStream),
        SLNet.readFloat(bitStream)
      }
      pData.velocity =
      {
        SLNet.readFloat(bitStream),
        SLNet.readFloat(bitStream),
        SLNet.readFloat(bitStream)
      }
      pData.facingAngle = SLNet.readFloat(bitStream)
      pData.roll = SLNet.readFloat(bitStream)
    end
  end

  local player = -1
  for i = 1, #GPool.GPlayers do
    if pData.playerid == GPool.GPlayers[i].playerid then
      player = i
      break
    end
  end
  if player == -1 or GPool.GPlayers[player].playerid == LPlayer.lpPlayerId then
    return false
  end

  local car = -1
  for i = 1, #GPool.GVehicles do
    if pData.vehicleid == GPool.GVehicles[i].vehicleid then
      car = i
      break
    end
  end
  if car == -1 then
    return false
  end

  if not pData.streamedForPlayer then
    if GPool.GPlayers[player].handle and doesCharExist(GPool.GPlayers[player].handle) then
      deleteChar(GPool.GPlayers[player].handle)
    end
    if GPool.GVehicles[car].handle and doesVehicleExist(GPool.GVehicles[car].handle) then
      deleteCar(GPool.GVehicles[car].handle)
    end
  else
    if not GPool.GVehicles[car].handle or not doesVehicleExist(GPool.GVehicles[car].handle) then
      requestModel(GPool.GVehicles[car].model)
      loadAllModelsNow()
      GPool.GVehicles[car].handle = createCar(GPool.GVehicles[car].model, pData.position[1], pData.position[2], pData.position[3])
      markModelAsNoLongerNeeded(GPool.GVehicles[car].model)
      changeCarColour(GPool.GVehicles[car].handle, GPool.GVehicles[car].colors[1], GPool.GVehicles[car].colors[2])
    end
    if not GPool.GPlayers[player].handle or not doesCharExist(GPool.GPlayers[player].handle) or GPool.GPlayers[player].skin ~= pData.skin then
      if GPool.GPlayers[player].handle and doesCharExist(GPool.GPlayers[player].handle) and GPool.GPlayers[player].skin ~= pData.skin then
        deleteChar(GPool.GPlayers[player].handle)
      end
      --requestModel(pData.skin)
      --loadAllModelsNow(pData.skin)
      --GPool.GPlayers[player].handle = createChar(4, pData.skin, pData.position[1], pData.position[2], pData.position[3])
      GPool.GPlayers[player].handle = CGame.createCharNet(4, pData.skin, pData.position[1], pData.position[2], pData.position[3])
      local dec = loadCharDecisionMaker(65543)
      setCharDecisionMaker(GPool.GPlayers[player].handle, dec)
      setCharProofs(GPool.GPlayers[player].handle, true, true, true, true, true)
      setCharDropsWeaponsWhenDead(GPool.GPlayers[player].handle, false)
      setCharKindaStayInSamePlace(GPool.GPlayers[player].handle, true)
      --markModelAsNoLongerNeeded(pData.skin)
      GPool.GPlayers[player].inCar = 0
      GPool.GPlayers[player].skin = pData.skin
    end
    if GPool.GPlayers[player].interior ~= 0 then
      GPool.GPlayers[player].interior = 0
      setCharInterior(GPool.GPlayers[player].handle, 0)
    end
    if GPool.GPlayers[player].inCar ~= 1 then
      GPool.GPlayers[player].inCar = 1
      if pData.seatID == 0 then taskEnterCarAsDriver(GPool.GPlayers[player].handle, GPool.GVehicles[car].handle, 1000)
      else taskEnterCarAsPassenger(GPool.GPlayers[player].handle, GPool.GVehicles[car].handle, 1000, pData.seatID - 1) end
    end
    if not isCharInAnyCar(GPool.GPlayers[player].handle) then
      if pData.seatID == 0 then taskEnterCarAsDriver(GPool.GPlayers[player].handle, GPool.GVehicles[car].handle, 1000)
      else taskEnterCarAsPassenger(GPool.GPlayers[player].handle, GPool.GVehicles[car].handle, 1000, pData.seatID - 1) end
    end
    if pData.seatID == 0 then
      GPool.GVehicles[car].position = pData.position
      setCarCoordinates(GPool.GVehicles[car].handle, pData.position[1], pData.position[2], pData.position[3])
      setVehicleQuaternion(GPool.GVehicles[car].handle, pData.quaternion[1], pData.quaternion[2], pData.quaternion[3], pData.quaternion[4])
      setCarHeading(GPool.GVehicles[car].handle, pData.facingAngle)
      setCarRoll(GPool.GVehicles[car].handle, pData.roll)
      setCarHealth(GPool.GVehicles[car].handle, pData.health)
      setCharHealth(GPool.GPlayers[player].handle, pData.pHealth)
      GPool.GPlayers[player].health = pData.pHealth
      GPool.GPlayers[player].armour = pData.armour
      -- vehicle movespeed function ????
      local carSpeed = math.floor(math.sqrt(pData.velocity[1]^2+pData.velocity[2]^2+pData.velocity[3]^2))
      setCarForwardSpeed(GPool.GVehicles[car].handle, carSpeed)
    end
  end
end

function Packet_Server_Info(bitStream)
  if ltServerAns then
    SPool.sPing = (os.clock() - ltServerAns) * 1000
  end
  SPool.sName = SLNet.readString(bitStream)
  SPool.sPlayers[1] = SLNet.readInt16(bitStream)
  SPool.sPlayers[2] = SLNet.readInt16(bitStream)
  SPool.sWebsite = SLNet.readString(bitStream)
  SPool.sLanguage = SLNet.readString(bitStream)
  SPool.sVersion = SLNet.readString(bitStream)
  SPool.sGamemode = SLNet.readString(bitStream)
  SPool.sNametag = SLNet.readFloat(bitStream)
  SPool.sPList = {}
  for i = 1, SPool.sPlayers[1] do
    SPool.sPList[#SPool.sPList+1] = {}
    SPool.sPList[#SPool.sPList][1] = SLNet.readString(bitStream)
    SPool.sPList[#SPool.sPList][2] = SLNet.readInt16(bitStream)
  end
  return true
end

function Packet_Disconnect(bitStream)
  CGraphics.addMessage('Server Closed the Connection.', 0xF5F5F5FF)
  CGraphics.tClientPopupText = 'Server Closed the Connection.'
  CGraphics.addMessage('Use /disconnect to return to menu.', 0xF5F5F5FF)
  SPool.disconnect(1)
  removeAllServerStuff()
  return true
end

function Packet_Weapons_Sync(bitStream)
  local playerid = SLNet.readInt16(bitStream)
  for i = 1, #GPool.GPlayers do
    if GPool.GPlayers[i].playerid == playerid then
      if GPool.GPlayers[i].handle and doesCharExist(GPool.GPlayers[i].handle) then
        removeAllCharWeapons(GPool.GPlayers[i].handle)
        for ii = 1, 13 do
          local weapon = SLNet.readUInt8(bitStream)
          local ammo = SLNet.readUInt16(bitStream)
          giveWeaponToChar(GPool.GPlayers[i].handle, weapon, ammo)
        end
        local currentWeapon = SLNet.readInt8(bitStream)
        local weaponModel = getWeapontypeModel(currentWeapon)
        requestModel(weaponModel)
        loadAllModelsNow()
        setCurrentCharWeapon(GPool.GPlayers[i].handle, currentWeapon)
        markModelAsNoLongerNeeded(weaponModel)
      end
      return true
    end
  end
  return false
end