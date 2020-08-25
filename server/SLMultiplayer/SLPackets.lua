function Packet_Connect(pData, pAddress, pPort)
  print(string.format('[PLAYER] %s:%s trying to connect to server', pAddress, pPort))
  if type(pData.nickname) ~= 'string' or type(pData.version) ~= 'string' or type(pData.token) ~= 'number'then
    SPool.sendPacket(S_PACKETS.CONNECTION_FAIL, {errorCode = 1}, pAddress, pPort)
    return false
  elseif pData.nickname:len() < 1 or pData.nickname:len() > 24 then
    SPool.sendPacket(S_PACKETS.CONNECTION_FAIL, {errorCode = 2}, pAddress, pPort)
    return false
  elseif not pData.nickname:match('^[a-zA-Z0-9]+$') then
    SPool.sendPacket(S_PACKETS.CONNECTION_FAIL, {errorCode = 3}, pAddress, pPort)
    return false
  elseif #SPool.sPlayers >= SConfig.maxSlots then
    print(#SPool.sPlayers, SConfig.maxSlots)
    SPool.sendPacket(S_PACKETS.CONNECTION_FAIL, {errorCode = 4}, pAddress, pPort)
    return false
  elseif pData.version ~= SInfo.sVersion then
    print(pData.version, SInfo.sVersion)
    SPool.sendPacket(S_PACKETS.CONNECTION_FAIL, {errorCode = 5}, pAddress, pPort)
    return false
  end
  for i = 1, #SPool.sPlayers do
    if pData.nickname:lower() == SPool.sPlayers[i].nickname:lower() then
      SPool.sendPacket(S_PACKETS.CONNECTION_FAIL, {errorCode = 6}, pAddress, pPort)
      return false
    end
  end
  local playerid = SPool.findFreePlayerId()
  SPool.sendPacket(S_PACKETS.CONNECTION_SUCCESS, {playerid = playerid}, pAddress, pPort)
  local slot = #SPool.sPlayers + 1
  SPool.sPlayers[slot] =
  {
    playerid = playerid,
    nickname = pData.nickname,
    token = pData.token,
    bindedIP = pAddress or '',
    bindedPort = pPort or 0,
    ping = 999, 
    ltPingUpdate = os.time(),
    ltPingBackMS = os.clock(),
    ltPingServer = os.time(),
    position = {0.0, 0.0, 0.0},
    quaternion = {0.0, 0.0, 0.0, 0.0},
    velocity = {0.0, 0.0, 0.0},
    facingAngle = 0.0,
    health = 100.0,
    armour = 0.0,
    stream = 
    {
      players = {}, 
      vehicles = {}
    }
  }
  for i = 1, #SPool.sPlayers do
    SPool.sendRPC(S_RPC.PLAYER_JOIN, {
      playerid = SPool.sPlayers[i].playerid,
      nickname = SPool.sPlayers[i].nickname
    }, pAddress, pPort)
    if SPool.sPlayers[i].bindedIP ~= pAddress and SPool.sPlayers[i].bindedPort ~= pPort then
      SPool.sendRPC(S_RPC.PLAYER_JOIN, {
        playerid = playerid,
        nickname = pData.nickname
      }, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
    end
  end
  pcall(onPlayerConnect, playerid)
  print(string.format('[PLAYER] %s [%s:%s:%s] connected to server', pData.nickname, pAddress, pPort, playerid))
  return true
end

local function checkOnFootPacket(pData)
  if type(pData.position[1]) ~= 'number' or type(pData.position[2]) ~= 'number' 
  or type(pData.position[3]) ~= 'number' or type(pData.facingAngle) ~= 'number' then
    return false
  end
  if type(pData.quaternion[1]) ~= 'number' or type(pData.quaternion[2]) ~= 'number' 
  or type(pData.quaternion[3]) ~= 'number' or type(pData.quaternion[4]) ~= 'number' then
    return false
  end
  if type(pData.health) ~= 'number' or type(pData.armour) ~= 'number' then
    return false
  end
  if type(pData.velocity[1]) ~= 'number' or type(pData.velocity[2]) ~= 'number' 
  or type(pData.velocity[3]) ~= 'number' then 
    return false 
  end
  return true
end

function Packet_OnFoot(pData, pAddress, pPort)
  if not checkOnFootPacket(pData) then
    return false
  end
  local connected, clientID = SPool.getClient(pAddress, pPort)
  if not connected then return false end
  
  SPool.sPlayers[clientID].position = pData.position
  SPool.sPlayers[clientID].quaternion = pData.quaternion
  SPool.sPlayers[clientID].velocity = pData.velocity
  SPool.sPlayers[clientID].health = pData.health
  SPool.sPlayers[clientID].armour = pData.armour

  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[clientID].playerid ~= SPool.sPlayers[i].playerid then
      local dist = getDistBetweenPoints(pData.position[1], pData.position[2], pData.position[3],
      SPool.sPlayers[i].position[1], SPool.sPlayers[i].position[2], SPool.sPlayers[i].position[3])
      if dist > SConfig.streamDistance then
        local wereStreamed = false
        for ii = #SPool.sPlayers[i].stream.players, 1, -1 do
          if SPool.sPlayers[i].stream.players[ii] == SPool.sPlayers[clientID].playerid then
            wereStreamed = true
            table.remove(SPool.sPlayers[i].stream.players, ii)
            break
          end
        end
        if wereStreamed then
          SPool.sendPacket(S_PACKETS.ONFOOT_SYNC, {playerid = SPool.sPlayers[clientID].playerid, streamedForPlayer = 0}, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
        end
      else
        SPool.sendPacket(S_PACKETS.ONFOOT_SYNC, {playerid = SPool.sPlayers[clientID].playerid, streamedForPlayer = 1, data = pData}, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
        local wereStreamed = false
        for ii = #SPool.sPlayers[i].stream.players, 1, -1 do
          if SPool.sPlayers[i].stream.players[ii] == SPool.sPlayers[clientID].playerid then
            wereStreamed = true
            break
          end
        end
        if not wereStreamed then
          table.insert(SPool.sPlayers[i].stream.players, SPool.sPlayers[clientID].playerid)
        end
      end
    end
  end
  return true
end

function Packet_Disconnect(pData, pAddress, pPort)
  if type(pData.reason) ~= 'number' then return false end
  local connected, clientID = SPool.getClient(pAddress, pPort)
  if not connected then return false end
  print(string.format('[PLAYER] %s [%s:%s:%s] disconnected from server', SPool.sPlayers[clientID].nickname, SPool.sPlayers[clientID].bindedIP, SPool.sPlayers[clientID].bindedPort, pData.reason))
  for i = 1, #SPool.sPlayers do
    SPool.sendRPC(S_RPC.PLAYER_LEAVE, {playerid = SPool.sPlayers[clientID].playerid}, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
  end
  pcall(onPlayerDisconnect, SPool.sPlayers[clientID].playerid, pData.reason)
  for i = #SPool.sPlayers, 1, -1 do
    if i == clientID then
      table.remove(SPool.sPlayers, clientID)
    end
  end
  return true
end