dofile(modules..'/packets.lua')
dofile(modules..'/rpc.lua')

local confirmPackets = {}
function confirmPackets:getID()
  local freeID = 1
  while true do
    local usedID = false
    for i = 1, #confirmPackets do
      if confirmPackets[i].id == freeID then
        usedID = true
        break
      end
    end
    if not usedID then
      break
    end
    freeID = freeID + 1
  end
  return freeID
end
function confirmPackets:delete(uid)
  for i = #confirmPackets, 1, -1 do
    if confirmPackets[i].id == uid then
      table.remove(confirmPackets, i)
      break
    end
  end
end

local function preparePacket(isRPC, PacketID, PacketPriority, PacketData, pTry)
  local str = ''
  isRPC = type(isRPC) == 'boolean' and isRPC or false
  local str = 'SLMP' .. (isRPC and 'R' or 'P')
  PacketID = type(PacketID) == 'number' and PacketID or 0
  str = str .. tostring(PacketID)
  PacketPriority = type(PacketPriority) == 'boolean' and PacketPriority or false
  if type(PacketData) == 'string' and PacketPriority and pTry < 5 then
    local freeID = confirmPackets:getID()
    table.insert(confirmPackets, {
      id = freeID,
      pID = PacketID,
      pData = PacketData,
      pRPC = isRPC,
      time = os.time() + 5,
      try = pTry
    })
    local bs = BitStream:new()
    bs:import(PacketData)
    bs:setWritePointer(1)
    bs:writeUInt16(freeID)
    PacketData = bs:export()
  end
  PacketData = type(PacketData) == 'string' and PacketData or ''
  str = str .. (PacketPriority and '1' or '0') .. PacketData
  return str
end

function sendPacket(PacketID, PacketPriority, PacketData, pTry)
  pTry = type(pTry) == 'number' and pTry or 0
  if type(PacketData) ~= 'table' then return end
  local str = preparePacket(false, PacketID, PacketPriority, PacketData:export(), pTry)
  udp:send(str)
end

function sendRPC(PacketID, PacketPriority, PacketData, pTry)
  pTry = type(pTry) == 'number' and pTry or 0
  if type(PacketData) ~= 'table' then return end
  local str = preparePacket(true, PacketID, PacketPriority, PacketData:export(), pTry)
  udp:send(str)
end

function NetworkLoop()
  while true do
    local message = udp:receive()
    if message then -- proccess only if have data
      -- structure of data should be: SLMP[P/R][ID][1/0][DATA]
      -- if PRIORITY equals 1 first UINT_16 in DATA will be unique ID
      if message:sub(1,4) == 'SLMP' then
        local dataID = tonumber(message:sub(6,6))
        local dataPriority = tonumber(message:sub(7,7))
        local dataMessage = message:sub(8,#message)
        if dataID and dataPriority and dataMessage then
          if dataPriority == 1 then
            local bitStream = BitStream:new()
            bitStream:import(dataMessage)
            local uniqueID = bitStream:readUInt16()
            bitStream:clear()
            bitStream:writeUInt16(uniqueID)
            sendPacket(PACKET.CONFIRM_RECEIVING, false, bitStream)
          end
          local bitStream = BitStream:new()
          -- Don`t forget to DELETE 2 bytes of UINT_16 UNIQUE ID
          bitStream:import(dataPriority == 1 and dataMessage:sub(3, #dataMessage) or dataMessage)
          if message:sub(5,5) == 'R' then
            RPC_Receiver(dataID, bitStream)
          elseif message:sub(5,5) == 'P' then
            if dataID == PACKET.CONFIRM_RECEIVING then
              local uID = bitStream:readUInt16()
              confirmPackets:delete(uID)
            else
              Packet_Receiver(dataID, bitStream)
            end
          end
        end
      end
    end
    if Player.GameState == GAMESTATE.CONNECTING
    and os.time() - General.ConnectingTime > 10 then
      Player.GameState = GAMESTATE.DISCONNECTED
      Graphics.tClientPopupText = 'Unable to Connect to Server'
    end
    if (os.clock() - General.SendSyncTime) * 1000
    > Server.OnFootRate and not isGamePaused() then
      General.SendSyncTime = os.clock()
      Client:sendSync()
    end
    if os.time() - General.Timer >= 5 then
      -- Check some important stuff here
      General.Timer = os.time()
      for i = #confirmPackets, 1, -1 do
        if os.time() >= confirmPackets[i].time then
          if confirmPackets[i].pRPC then
            sendRPC(confirmPackets[i].pID, true, confirmPackets[i].pData, confirmPackets[i].try)
          else
            sendPacket(confirmPackets[i].pID, true, confirmPackets[i].pData, confirmPackets[i].try)
          end
          table.remove(confirmPackets, i)
        end
      end
      Client:updatePingAndScore()
    end
    wait(0)
  end
end

function RPC_Receiver(PacketID, bitStream)
  print('Got RPC with ID ' .. PacketID)
  if Player.GameState == GAMESTATE.CONNECTED then
    if PacketID == RPC.PLAYER_CONNECT then
      RPC_Player_Connect(bitStream)
    elseif PacketID == RPC.PLAYER_DISCONNECT then
      RPC_Player_Disconnect(bitStream)
    elseif PacketID == RPC.UPDATE_PING_AND_SCORE then
      RPC_Update_Ping_Score(bitStream)
    elseif PacketID == RPC.SET_PLAYER_SKIN then
      Game:setPlayerSkin(bitStream:readUInt16())
    elseif PacketID == RPC.SET_PLAYER_POS then
      RPC_SetPlayerPos(bitStream)
    elseif PacketID == RPC.SET_PLAYER_ANGLE then
      setCharHeading(PLAYER_PED, bitStream:readFloat())
    elseif PacketID == RPC.SET_PLAYER_INTERIOR then
      setCharInterior(PLAYER_PED, bitStream:readUInt16())
    elseif PacketID == RPC.SEND_MESSAGE then
      RPC_SendMessage(bitStream)
    end
  end
end

function Packet_Receiver(PacketID, bitStream)
  print('Got PACKET with ID ' .. PacketID)
  if PacketID == PACKET.PING_SERVER then
    Packet_Ping_Server(bitStream)
  end
  if Player.GameState == GAMESTATE.DISCONNECTED then
    -- player not connected
  elseif Player.GameState == GAMESTATE.CONNECTING then
    if PacketID == PACKET.CONNECTION_REQUEST_SUCCESS then
      Packet_Connection_Success(bitStream)
    elseif PacketID == PACKET.CONNECTION_REQUEST_FAIL then
      Packet_Connection_Fail(bitStream)
    end
  elseif Player.GameState == GAMESTATE.CONNECTED then
    if PacketID == PACKET.UPDATE_STREAM then
      Packet_Update_Stream(bitStream)
    elseif PacketID == PACKET.ONFOOT_SYNC then
      Packet_OnFoot_Sync(bitStream)
    end
  end
end