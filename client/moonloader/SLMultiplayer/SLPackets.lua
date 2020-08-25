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
  requestModel(0)
  loadAllModelsNow()
  setPlayerModel(PLAYER_HANDLE, 0)
  markModelAsNoLongerNeeded(0)
  setCharCoordinates(PLAYER_PED, 0.0, 0.0, 1.0)
  setPlayerControl(PLAYER_HANDLE, true)
  ltSendOnFootSync = os.clock()
end

function Packet_OnFoot(pData)
  for i = 1, #GPool.GPlayers do
    if pData.playerid == GPool.GPlayers[i].playerid and GPool.GPlayers[i].playerid ~= LPlayer.lpPlayerId then
      local player = GPool.GPlayers[i]
      if pData.streamedForPlayer == 0 and player.handle and doesCharExist(player.handle) then
        deleteChar(player.handle)
        return false
      elseif pData.streamedForPlayer == 1 and (not player.handle or not doesCharExist(player.handle)) then
        requestModel(0)
        loadAllModelsNow(0)
        GPool.GPlayers[i].handle = createChar(21, 0, pData.data.position[1], pData.data.position[2], pData.data.position[3])
        markModelAsNoLongerNeeded(0)
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