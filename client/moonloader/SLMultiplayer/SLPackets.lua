function Packet_Connection_Fail(pData)
  if type(pData.errorCode) ~= 'number' then 
    return false 
  end
  LPlayer.lpGameState = S_GAMESTATES.GS_DISCONNECTED
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
  else
    CGraphics.tClientPopupText = 'Unknown Connection Error!'
  end
end

function Packet_Connection_Success(pData)
  if type(pData.playerid) ~= 'number' then
    return false
  end
  CGraphics.wClient[0] = false
  CGraphics.wChat[0] = true
  LPlayer.lpGameState = S_GAMESTATES.GS_CONNECTED
  CGraphics.tClientPopupText = 'Connected to Server!'
  ltPingServerTime = os.time()
  ltServerAnswerPing = os.time()
  LPlayer.lpPlayerId = pData.playerid
  LPlayer.lpPlayerState = S_PLAYERTATE.PS_ONFOOT
  requestModel(0)
  loadAllModelsNow()
  setPlayerModel(PLAYER_HANDLE, 0)
  markModelAsNoLongerNeeded(0)
  setCharCoordinates(PLAYER_PED, 0.0, 0.0, 1.0)
  setPlayerControl(PLAYER_HANDLE, true)
end

function Packet_OnFoot(pData)
  for i = 1, #GPool.GPlayers do
    if pData.playerid == GPool.GPlayers[i].playerid and GPool.GPlayers[i].playerid ~= LPlayer.lpPlayerId then
      local player = GPool.GPlayers[i]
      if pData.streamedForPlayer == 0 and player.handle and doesCharExist(player.handle) then
        deleteChar(player.handle)
        return false
      elseif pData.streamedForPlayer == 1 and (not player.handle or not doesCharExist(player.handle) or GPool.GPlayers[i].skin ~= pData.skin) then
        if player.handle and doesCharExist(player.handle) and GPool.GPlayers[i].skin ~= pData.skin then deleteChar(player.handle) end
        requestModel(pData.skin)
        loadAllModelsNow()
        GPool.GPlayers[i].handle = createChar(21, pData.skin, pData.data.position[1], pData.data.position[2], pData.data.position[3])
        markModelAsNoLongerNeeded(pData.skin)
        GPool.GPlayers[i].inCar = 0
        GPool.GPlayers[i].skin = pData.skin
      end
      if GPool.GPlayers[i].inCar == 1 then
        taskLeaveAnyCar(GPool.GPlayers[i].handle)
      end
      GPool.GPlayers[i].position = {pData.data.position[1], pData.data.position[2], pData.data.position[3] - 1.0}
      setCharCoordinates(player.handle, pData.data.position[1], pData.data.position[2], pData.data.position[3] - 1.0)
      setCharQuaternion(player.handle, pData.data.quaternion[1], pData.data.quaternion[2], pData.data.quaternion[3], pData.data.quaternion[4])
      setCharHeading(player.handle, pData.data.facingAngle)
      setCharVelocity(player.handle, pData.data.velocity[1], pData.data.velocity[2], pData.data.velocity[3])
      setCharHealth(player.handle, pData.data.health)
      GPool.GPlayers[i].health = pData.data.health
      GPool.GPlayers[i].armour = pData.data.armour
      return true
    end
  end
end

function Packet_UnoccupiedSync(pData)
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

  GPool.GVehicles[car].position = pData.position
  if GPool.GVehicles[car].handle and doesVehicleExist(GPool.GVehicles[car].handle) then
    setCarCoordinates(GPool.GVehicles[car].handle, pData.position[1], pData.position[2], pData.position[3])
    setCarHeading(GPool.GVehicles[car].handle, pData.facingAngle)
    setVehicleQuaternion(GPool.GVehicles[car].handle, pData.quaternion[1], pData.quaternion[2], pData.quaternion[3], pData.quaternion[4])
    setCarRoll(GPool.GVehicles[car].handle, pData.roll)
  end

  return true
end

function Packet_InCar(pData)
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
    if pData.data.vehicleid == GPool.GVehicles[i].vehicleid then
      car = i
      break
    end
  end
  if car == -1 then
    return false
  end

  if pData.streamedForPlayer == 0 then
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
      GPool.GVehicles[car].handle = createCar(GPool.GVehicles[car].model, pData.data.position[1], pData.data.position[2], pData.data.position[3])
      markModelAsNoLongerNeeded(GPool.GVehicles[car].model)
      changeCarColour(GPool.GVehicles[car].handle, GPool.GVehicles[car].colors[1], GPool.GVehicles[car].colors[2])
    end
    if not GPool.GPlayers[player].handle or not doesCharExist(GPool.GPlayers[player].handle) or GPool.GPlayers[player].skin ~= pData.skin then
      if GPool.GPlayers[player].handle and doesCharExist(GPool.GPlayers[player].handle) and GPool.GPlayers[player].skin ~= pData.skin then
        deleteChar(GPool.GPlayers[player].handle)
      end
      requestModel(pData.skin)
      loadAllModelsNow(pData.skin)
      GPool.GPlayers[player].handle = createChar(21, pData.skin, pData.data.position[1], pData.data.position[2], pData.data.position[3])
      markModelAsNoLongerNeeded(pData.skin)
      GPool.GPlayers[player].inCar = 0
      GPool.GPlayers[player].skin = pData.skin
    end
    if GPool.GPlayers[player].inCar ~= 1 then
      GPool.GPlayers[player].inCar = 1
      if pData.data.seatID < 1 then taskEnterCarAsDriver(GPool.GPlayers[player].handle, GPool.GVehicles[car].handle, 1000)
      else taskEnterCarAsPassenger(GPool.GPlayers[player].handle, GPool.GVehicles[car].handle, 1000, pData.data.seatID) end
    end
    if pData.data.seatID < 1 then
      GPool.GVehicles[car].position = pData.data.position
      setCarCoordinates(GPool.GVehicles[car].handle, pData.data.position[1], pData.data.position[2], pData.data.position[3])
      setVehicleQuaternion(GPool.GVehicles[car].handle, pData.data.quaternion[1], pData.data.quaternion[2], pData.data.quaternion[3], pData.data.quaternion[4])
      setCarHeading(GPool.GVehicles[car].handle, pData.data.facingAngle)
      setCarRoll(GPool.GVehicles[car].handle, pData.data.roll)
      setCarHealth(GPool.GVehicles[car].handle, pData.data.health)
      -- vehicle movespeed function ????
      if isCharInAnyCar(PLAYER_PED) then
        local carHandle = storeCarCharIsInNoSave(PLAYER_PED)
        if carHandle == GPool.GVehicles[car].handle then 
          CGame.setVehicleDamagable(GPool.GVehicles[car].handle, true)
        else CGame.setVehicleDamagable(GPool.GVehicles[car].handle, false) end
      else CGame.setVehicleDamagable(GPool.GVehicles[car].handle, false) end
    end
  end
end

function Packet_VehicleSync(pData)
  for i = 1, #GPool.GVehicles do
    if GPool.GVehicles[i].vehicleid == pData.vehicleid then
      if pData.streamedForPlayer == 0 and GPool.GVehicles[i].handle and doesVehicleExist(GPool.GVehicles[i].handle) then
        deleteCar(GPool.GVehicles[i].handle)
      elseif pData.streamedForPlayer == 1 and (not GPool.GVehicles[i].handle or not doesVehicleExist(GPool.GVehicles[i].handle)) then
        requestModel(GPool.GVehicles[i].model)
        loadAllModelsNow()
        GPool.GVehicles[i].handle = createCar(GPool.GVehicles[i].model, pData.position[1], pData.position[2], pData.position[3])
        GPool.GVehicles[i].position = pData.position
        markModelAsNoLongerNeeded(GPool.GVehicles[i].model)
        changeCarColour(GPool.GVehicles[i].handle, GPool.GVehicles[i].colors[1], GPool.GVehicles[i].colors[2])
        setCarCoordinates(GPool.GVehicles[i].handle, pData.position[1], pData.position[2], pData.position[3])
        setVehicleQuaternion(GPool.GVehicles[i].handle, pData.quaternion[1], pData.quaternion[2], pData.quaternion[3], pData.quaternion[4])
        setCarHeading(GPool.GVehicles[i].handle, pData.facingAngle)
        setCarHealth(GPool.GVehicles[i].handle, pData.health)
        if isCharInAnyCar(PLAYER_PED) then
          local carHandle = storeCarCharIsInNoSave(PLAYER_PED)
          if carHandle == GPool.GVehicles[i].handle then
            CGame.setVehicleDamagable(GPool.GVehicles[i].handle, true)
          else CGame.setVehicleDamagable(GPool.GVehicles[i].handle, false) end
        else CGame.setVehicleDamagable(GPool.GVehicles[i].handle, false) end
      end
      return true
    end
  end
end