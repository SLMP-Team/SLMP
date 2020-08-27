S_PACKETS =
{
  SERVER_INFO = 0,
  CONNECT = 1,
  DISCONNECT = 2,
  ONFOOT_SYNC = 3,
  CONNECTION_FAIL = 4,
  CONNECTION_SUCCESS = 5,
  INCAR_SYNC = 6,
  VEHICLES_SYNC = 7,
  UNOCCUPIED_SYNC = 8
}

S_RPC =
{
  PING_SERVER = 0,
  PLAYER_JOIN = 1,
  PLAYER_LEAVE = 2,
  CLIENT_MESSAGE = 3,
  SET_PLAYER_POS = 4,
  PING_BACK = 5,
  SEND_MESSAGE = 6,
  SEND_COMMAND = 7,
  CREATE_VEHICLE = 8,
  DESTROY_VEHICLE = 9,
  ENTER_VEHICLE = 10,
  EXIT_VEHICLE = 11,
  CAR_JACKED = 12,
  SET_PLAYER_SKIN = 13
}

SPool =
{
  sName = '',
  sIP = '',
  sPort = 0,
  sPing = 999,
  sNametag = 20.0
}

SPool.setAddress = function(ip, port)
  SPool.sIP = tostring(ip) or ''
  SPool.sPort = tonumber(port) or 0
end

SPool.connect = function()
  SPool.disconnect(0)
  if LPlayer.lpGameState ~= S_GAMESTATES.GS_DISCONNECTED then 
    return false
  end
  LPlayer.lpGameState = S_GAMESTATES.GS_CONNECTING
  udp:settimeout(0)
  udp:setpeername(SPool.sIP, SPool.sPort)
  lua_thread.create(UDP_Receiver)
  SPool.sendPacket(S_PACKETS.CONNECT, {nickname = LPlayer.lpNickname, token = sVolumeToken[0], version = CGame.cVersion})
  return true
end

SPool.disconnect = function(reason)
  if type(reason) ~= 'number' then
    reason = 0
  end
  if LPlayer.lpGameState == S_GAMESTATES.GS_DISCONNECTED then 
    return false
  end
  LPlayer.lpGameState = S_GAMESTATES.GS_DISCONNECTED
  SPool.sendPacket(S_PACKETS.DISCONNECT, {reason = reason})
  udp:close()
  return true
end

SPool.sendPacket = function(packetID, packetData)
  if type(packetID) ~= 'number' or 
  type(packetData) ~= 'table' then
    return false
  end
  packetData = encodeJson(packetData)
  if LPlayer.lpGameState == S_GAMESTATES.GS_DISCONNECTED then
    return false
  end
  packetData = SPool.encodeString(('P[%s]{%s}'):format(packetID, packetData))
  udp:send(('SLMP{%s}'):format(packetData))
  return true
end

SPool.encodeString = function(str)
  return LEncoder:CompressDeflate(str, {level = 9})
end

SPool.decodeString = function(str)
  return LEncoder:DecompressDeflate(str)
end

SPool.sendRPC = function(rpcID, rpcData)
  if type(rpcID) ~= 'number' or 
  type(rpcData) ~= 'table' then
    return false
  end
  rpcData = encodeJson(rpcData)
  if LPlayer.lpGameState == S_GAMESTATES.GS_DISCONNECTED then
    return false
  end
  rpcData = SPool.encodeString(('R[%s]{%s}'):format(rpcID, rpcData))
  udp:send(('SLMP{%s}'):format(rpcData))
  return true
end

SPool.onPacketReceive = function(pID, pData)
  print('p', pID, encodeJson(pData))
  if pID == S_PACKETS.CONNECTION_FAIL then
    pcall(Packet_Connection_Fail, pData)
  elseif pID == S_PACKETS.CONNECTION_SUCCESS then
    pcall(Packet_Connection_Success, pData)
  elseif pID == S_PACKETS.ONFOOT_SYNC then
    pcall(Packet_OnFoot, pData)
  elseif pID == S_PACKETS.INCAR_SYNC then
    pcall(Packet_InCar, pData)
  elseif pID == S_PACKETS.UNOCCUPIED_SYNC then
    pcall(Packet_UnoccupiedSync, pData)
  elseif pID == S_PACKETS.VEHICLES_SYNC then
    Packet_VehicleSync(pData)
  elseif pID == S_PACKETS.SERVER_INFO then
    if clUpdatingInfo then
      clUpdatingInfo = false
      LPlayer.lpGameState = S_GAMESTATES.GS_DISCONNECTED
      clUpdatingMS = (os.clock() - clUpdatingMS) * 1000
      CConfig.servers[CGraphics.tClientSelectedServer].ping = clUpdatingMS
      CConfig.servers[CGraphics.tClientSelectedServer].name = pData.name
      CConfig.servers[CGraphics.tClientSelectedServer].gamemode = pData.gamemode
      CConfig.servers[CGraphics.tClientSelectedServer].language = pData.language
      CConfig.servers[CGraphics.tClientSelectedServer].players = pData.players
      CConfig.servers[CGraphics.tClientSelectedServer].maxPlayers = pData.maxPlayers
      CConfig.servers[CGraphics.tClientSelectedServer].playersPool = pData.playersPool
      CConfig.servers[CGraphics.tClientSelectedServer].website = pData.website
      CConfig.servers[CGraphics.tClientSelectedServer].version = pData.version
      SPool.sName = pData.name
      SPool.sNametag = pData.nametagsDistance
    end
  end
end

SPool.onRPCReceive = function(pID, pData)
  print('r', pID, encodeJson(pData))
  if pID == S_RPC.PING_SERVER then
    SPool.sendRPC(S_RPC.PING_BACK, {a = 1})
  elseif pID == S_RPC.PING_BACK and ltPingTestMS then
    SPool.sPing = (os.clock() - ltPingTestMS) * 1000
    ltServerAnswerPing = os.time()
    print(SPool.sPing)
  elseif pID == S_RPC.PLAYER_JOIN then
    local slot = #GPool.GPlayers + 1
    GPool.GPlayers[slot] =
    {
      playerid = pData.playerid,
      nickname = pData.nickname,
      position = {0.0, 0.0, 0.0},
      health = 100.0, armour = 0.0,
      inCar = 0, skin = 0
    }
  elseif pID == S_RPC.PLAYER_LEAVE then
    for i = #GPool.GPlayers, 1, -1 do
      if GPool.GPlayers[i].playerid == pData.playerid then
        if GPool.GPlayers[i].handle and doesCharExist(GPool.GPlayers[i].handle) then
          deleteChar(GPool.GPlayers[i].handle)
        end
        table.remove(GPool.GPlayers, i)
      end
    end
  elseif pID == S_RPC.CLIENT_MESSAGE then
    CGraphics.addMessage(pData.message, pData.color)
  elseif pID == S_RPC.CREATE_VEHICLE then
    pcall(RPC_CreateVehicle, pData)
  elseif pID == S_RPC.DESTROY_VEHICLE then
    pcall(RPC_DestroyVehicle, pData)
  elseif pID == S_RPC.SET_PLAYER_POS then
    setCharCoordinates(PLAYER_PED, pData.position[1], pData.position[2], pData.position[3])
  elseif pID == S_RPC.CAR_JACKED then
    if isCharInAnyCar(PLAYER_PED) then
      local carHandle = storeCarCharIsInNoSave(PLAYER_PED)
      taskLeaveCar(PLAYER_PED, carHandle)
      printStyledString('~r~CAR JACKED', 2000, 4)
    end
  elseif pID == S_RPC.SET_PLAYER_SKIN then
    requestModel(pData.skin)
    loadAllModelsNow()
    setPlayerModel(PLAYER_HANDLE, pData.skin)
    markModelAsNoLongerNeeded(pData.skin)
  end
end

function UDP_Receiver()
  while true do
    if LPlayer.lpGameState == S_GAMESTATES.GS_DISCONNECTED and not clUpdatingInfo then
      return
    end
    if lpConnectionTime and LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTING and os.time() - lpConnectionTime > 5 then
      CGraphics.tClientPopupText = 'Server not responding to request!'
      LPlayer.lpGameState = GS_DISCONNECTED
      clUpdatingInfo = false
      return
    end
    if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
      if ltServerAnswerPing and os.time() - ltServerAnswerPing > (2 * 60) then
        SPool.disconnect(1) -- disconnect with reason Lost Connection
        return -- close UDP update thread
      end
      if ltPingServerTime and os.time() - ltPingServerTime > 10 then
        ltPingServerTime = os.time()
        ltPingTestMS = os.clock()
        SPool.sendRPC(S_RPC.PING_SERVER, {a = 1})
      end
    end
    do
      wait(0)
      local data, msg = udp:receive()
      if data then
        if not data or not data:find('^SLMP') then goto UDP_Receiver_End end
        local data = data:match('^SLMP%{(.+)%}')
        if not data then goto UDP_Receiver_End end

        data = SPool.decodeString(data)
        local type, id, data = data:match('^(%S)%[(%d+)%]%{(.+)%}$')
        if not type then goto UDP_Receiver_End end

        local data = decodeJson(data)
        if type == 'P' then
          pcall(SPool.onPacketReceive, tonumber(id), data)
        elseif type == 'R' then
          pcall(SPool.onRPCReceive, tonumber(id), data)
        end
      end
    end
    ::UDP_Receiver_End::
    socket.sleep(0.01)
  end
end