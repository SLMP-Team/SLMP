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
  sName = 'Unknown',
  sIP = '127.0.0.1',
  sPort = 7777,
  sPing = 0,
  sNametag = 20.0,
  sVersion = 'Unknown',
  sLanguage = 'Unknown',
  sWebsite = 'Unknown',
  sPlayers = {0, 0},
  sGamemode = 'Unknown',
  sPList = {}
}

SPool.setAddress = function(ip, port)
  SPool.sIP = tostring(ip) or ''
  SPool.sPort = tonumber(port) or 0
end

SPool.connect = function()
  udp:settimeout(0)
  udp:setpeername(SPool.sIP, SPool.sPort)
  LPlayer.lpGameState = S_GAMESTATES.GS_CONNECTING
  local bs = SLNet.createBitStream()
  SLNet.writeInt16(bs, S_PACKETS.CONNECT)
  SLNet.writeString(bs, LPlayer.lpNickname)
  SLNet.writeUInt32(bs, sVolumeToken[0])
  SLNet.writeString(bs, CGame.cVersion)
  SPool.sendPacket(bs)
  SLNet.deleteBitStream(bs)
  ltStartConnectingTime = os.time()
  ltWasConnected = true
  return
end

SPool.disconnect = function(reason)
  if not ltWasConnected then return false end
  LPlayer.lpGameState = S_GAMESTATES.GS_DISCONNECTED
  local bs = SLNet.createBitStream()
  SLNet.writeInt16(bs, S_PACKETS.DISCONNECT)
  SLNet.writeInt8(bs, tonumber(reason))
  SPool.sendPacket(bs)
  SLNet.deleteBitStream(bs)
  return true
end

SPool.sendPacket = function(bitStream)
  udp:send('SLMP-P'..SLNet.exportBytes(bitStream))
  return true
end

SPool.sendRPC = function(bitStream)
  udp:send('SLMP-R'..SLNet.exportBytes(bitStream))
  return true
end

function SPool.onRPCReceive(bitStream)
  local pID = SLNet.readInt16(bitStream) or -1
  if pID == S_RPC.PING_SERVER then
    local bs = SLNet.createBitStream()
    SLNet.writeInt16(bs, S_RPC.PING_BACK)
    SPool.sendRPC(bs)
    SLNet.deleteBitStream(bs)
  elseif pID == S_RPC.PING_BACK and ltPingTestMS then
    SPool.sPing = (os.clock() - ltPingTestMS) * 1000
    ltServerAnswerPing = os.time()
  end
  if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
    if pID == S_RPC.CREATE_VEHICLE then
      pcall(RPC_CreateVehicle, bitStream)
    elseif pID == S_RPC.DESTROY_VEHICLE then
      pcall(RPC_DestroyVehicle, bitStream)
    elseif pID == S_RPC.CLIENT_MESSAGE then
      local pData = {}
      pData.message = SLNet.readString(bitStream)
      pData.color = SLNet.readInteger(bitStream)
      CGraphics.addMessage(pData.message, pData.color)
    elseif pID == S_RPC.PLAYER_JOIN then
      pcall(RPC_PlayerJoin, bitStream)
    elseif pID == S_RPC.PLAYER_LEAVE then
      local pData = {}
      pData.playerid = SLNet.readInt16(bitStream)
      for i = #GPool.GPlayers, 1, -1 do
        if GPool.GPlayers[i].playerid == pData.playerid then
          if GPool.GPlayers[i].handle and doesCharExist(GPool.GPlayers[i].handle) then
            deleteChar(GPool.GPlayers[i].handle)
          end
          table.remove(GPool.GPlayers, i)
        end
      end
    elseif pID == S_RPC.CAR_JACKED then
      if isCharInAnyCar(PLAYER_PED) then
        local carHandle = storeCarCharIsInNoSave(PLAYER_PED)
        taskLeaveCar(PLAYER_PED, carHandle)
        printStyledString('~r~CAR JACKED', 2000, 4)
      end
    elseif pID == S_RPC.SET_PLAYER_SKIN then
      local pData = {}
      pData.skin = SLNet.readInt16(bitStream)
      requestModel(pData.skin)
      loadAllModelsNow()
      setPlayerModel(PLAYER_HANDLE, pData.skin)
      markModelAsNoLongerNeeded(pData.skin)
    elseif pID == S_RPC.SET_PLAYER_POS then
      local pData = {}
      pData.position =
      {
        SLNet.readFloat(bitStream),
        SLNet.readFloat(bitStream),
        SLNet.readFloat(bitStream)
      }
      setCharCoordinates(PLAYER_PED, pData.position[1], pData.position[2], pData.position[3])
    end
  end
  return true
end

function SPool.onPacketReceive(bitStream)
  local pID = SLNet.readInt16(bitStream) or -1
  --print('PACKET' .. pID)
  if pID == S_PACKETS.CONNECTION_SUCCESS then
    pcall(Packet_Connection_Success, bitStream)
  elseif pID == S_PACKETS.CONNECTION_FAIL then
    pcall(Packet_Connection_Fail, bitStream)
  elseif pID == S_PACKETS.SERVER_INFO then
    pcall(Packet_Server_Info, bitStream)
  elseif pID == S_PACKETS.DISCONNECT then
    pcall(Packet_Disconnect, bitStream)
  end
  if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
    if pID == S_PACKETS.ONFOOT_SYNC then
      pcall(Packet_OnFoot_Sync, bitStream)
    elseif pID == S_PACKETS.INCAR_SYNC then
      pcall(Packet_InCar_Sync, bitStream)
    elseif pID == S_PACKETS.VEHICLES_SYNC then
      pcall(Packet_Vehicle_Sync, bitStream)
    end
  end
  return true
end

function networkLoop()
  while true do

    if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTING then
      if os.time() - ltStartConnectingTime > 10 then
        LPlayer.lpGameState = S_GAMESTATES.GS_DISCONNECTED
        CGraphics.tClientPopupText = 'Server didn`t respond on the request!'
        SPool.disconnect(0)
      end
    end
    if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
      if ltServerAnswerPing and os.time() - ltServerAnswerPing > 60 then
        LPlayer.lpGameState = S_GAMESTATES.GS_DISCONNECTED
        SPool.disconnect(0)
        CGraphics.addMessage('Connection to Server Lost.', 0xF5F5F5FF)
        CGraphics.addMessage('Use /disconnect to return to menu.', 0xF5F5F5FF)
      elseif ltPingServerTime and os.time() - ltPingServerTime > 10 then
        ltPingServerTime = os.time()
        ltPingTestMS = os.clock()
        local bs = SLNet.createBitStream()
        SLNet.writeInt16(bs, S_RPC.PING_SERVER)
        SPool.sendRPC(bs)
        SLNet.deleteBitStream(bs)
      end
    end

    local data, msg = udp:receive()
    if data then
      local NetType = data:sub(1, 6)
      local NetData = data:sub(7, data:len())
      local bitStream = SLNet.createBitStream()
      if NetType == 'SLMP-R' then
        SLNet.importBytes(bitStream, NetData)
        pcall(SPool.onRPCReceive, bitStream)
      elseif NetType == 'SLMP-P' then
        SLNet.importBytes(bitStream, NetData)
        pcall(SPool.onPacketReceive, bitStream)
      end
      SLNet.deleteBitStream(bitStream)
    end

    wait(0)
  end
end