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

local function preparePacket(isRPC, PacketID, PacketPriority, PacketData, ClientIP, ClientPort, pTry)
  local str = ''
  isRPC = type(isRPC) == 'boolean' and isRPC or false
  local str = 'SLMP' .. (isRPC and 'R' or 'P')
  PacketID = type(PacketID) == 'number' and PacketID or 0
  str = str .. ('%.3d'):format(PacketID)
  PacketPriority = type(PacketPriority) == 'boolean' and PacketPriority or false
  if type(PacketData) == 'string' and PacketPriority and pTry < 5 then
    local freeID = confirmPackets:getID()
    table.insert(confirmPackets, {
      id = freeID,
      pID = PacketID,
      pData = PacketData,
      pRPC = isRPC,
      time = os.time() + 5,
      ip = ClientIP,
      port = ClientPort,
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

function sendPacket(PacketID, PacketPriority, PacketData, ClientIP, ClientPort, pTry)
  pTry = type(pTry) == 'number' and pTry or 0
  ClientIP = type(ClientIP) == 'string' and ClientIP or ''
  ClientPort = type(ClientPort) == 'number' and ClientPort or 0
  if type(PacketData) ~= 'table' then return end
  local str = preparePacket(false, PacketID, PacketPriority, PacketData:export(), ClientIP, ClientPort, pTry)
  udp:sendto(str, ClientIP, ClientPort)
end

function sendRPC(PacketID, PacketPriority, PacketData, ClientIP, ClientPort, pTry)
  pTry = type(pTry) == 'number' and pTry or 0
  ClientIP = type(ClientIP) == 'string' and ClientIP or ''
  ClientPort = type(ClientPort) == 'number' and ClientPort or 0
  if type(PacketData) ~= 'table' then return end
  local str = preparePacket(true, PacketID, PacketPriority, PacketData:export(), ClientIP, ClientPort, pTry)
  udp:sendto(str, ClientIP, ClientPort)
end

function MainLoop()
  while true do
    local message, ip, port = udp:receivefrom()
    if message then -- proccess only if have data
      -- structure of data should be: SLMP[P/R][ID][1/0][DATA]
      -- if PRIORITY equals 1 first UINT_16 in DATA will be unique ID
      if message:sub(1,4) == 'SLMP' then
        local dataID = tonumber(message:sub(6,8))
        local dataPriority = tonumber(message:sub(9,9))
        local dataMessage = message:sub(10,#message)
        if dataID and dataPriority and dataMessage then
          if dataPriority == 1 then
            local bitStream = BitStream:new()
            bitStream:import(dataMessage)
            local uniqueID = bitStream:readUInt16()
            bitStream:clear()
            bitStream:writeUInt16(uniqueID)
            sendPacket(PACKET.CONFIRM_RECEIVING, false, bitStream, ip, port)
          end
          local bitStream = BitStream:new()
          -- Don`t forget to DELETE 2 bytes of UINT_16 UNIQUE ID
          bitStream:import(dataPriority == 1 and dataMessage:sub(3, #dataMessage) or dataMessage)
          local clientSlot = Clients:getSlotByAddress(ip, port)
          if message:sub(5,5) == 'R' then
            local isFunc, result = pcall(onReceiveRPC, Clients:getIDBySlot(clientSlot), dataID, bitStream)
            if not isFunc or (isFunc and result) then
              RPC_Receiver(clientSlot, dataID, bitStream, ip, port)
            end
          elseif message:sub(5,5) == 'P' then
            if dataID == PACKET.CONFIRM_RECEIVING then
              local uID = bitStream:readUInt16()
              confirmPackets:delete(uID)
            else
              local isFunc, result = pcall(onReceivePacket, Clients:getIDBySlot(clientSlot), dataID, bitStream)
              if not isFunc or (isFunc and result) then
                Packet_Receiver(clientSlot, dataID, bitStream, ip, port)
              end
            end
          end
        end
      end
    end
    --[[if (os.clock() - General.OnFootUpdate) * 1000 > Config.OnFootRate then
      General.OnFootUpdate = os.clock()
      Clients:sendOnFoot()
    end]]
    if (os.clock() - General.StreamUpdate) * 1000 > Config.StreamRate then
      General.StreamUpdate = os.clock()
      Clients:updateStream()
    end
    if os.time() - General.Timer >= 5 then
      -- Check some important stuff here
      General.Timer = os.time()
      for i = #confirmPackets, 1, -1 do
        if os.time() >= confirmPackets[i].time then
          if confirmPackets[i].pRPC then
            sendRPC(confirmPackets[i].pID, true, confirmPackets[i].pData,
            confirmPackets[i].ip, confirmPackets[i].port, confirmPackets[i].try)
          else
            sendPacket(confirmPackets[i].pID, true, confirmPackets[i].pData,
            confirmPackets[i].ip, confirmPackets[i].port, confirmPackets[i].try)
          end
          table.remove(confirmPackets, i)
        end
      end
      Clients:checkLostConnection()
    end
    socket.sleep(0.01)
  end
end

function RPC_Receiver(clientSlot, PacketID, bitStream, IP, PORT)
  --print('Got RPC with ID ' .. PacketID .. ' from client ID ' .. clientSlot)
  if clientSlot == -1 then
    -- if client not connected
  else
    if PacketID == RPC.UPDATE_PING_AND_SCORE then
      RPC_Update_Ping_Score(clientSlot, IP, PORT)
    elseif PacketID == RPC.SEND_MESSAGE then
      RPC_Send_Message(clientSlot, bitStream, IP, PORT)
    elseif PacketID == RPC.SEND_COMMAND then
      RPC_Send_Command(clientSlot, bitStream, IP, PORT)
    end
  end
end

function Packet_Receiver(clientSlot, PacketID, bitStream, IP, PORT)
  --print('Got PACKET with ID ' .. PacketID .. ' from client ID ' .. clientSlot)
  if clientSlot == -1 then
    if PacketID == PACKET.CONNECTION_REQUEST then
      Packet_Connection_Request(bitStream, IP, PORT)
    elseif PacketID == PACKET.PING_SERVER then
      Packet_Ping_Server(bitStream, IP, PORT)
    end
  else
    if PacketID == PACKET.CONNECTION_REQUEST_SUCCESS then
      Packet_Player_Connected(clientSlot, bitStream, IP, PORT)
    elseif PacketID == PACKET.ONFOOT_SYNC
    and Clients:getGamestate(clientSlot) == GAMESTATE.ONFOOT then
      Packet_OnFoot_Sync(clientSlot, bitStream, IP, PORT)
    elseif PacketID == PACKET.DISCONNECT_NOTIFICATION then
      Packet_Disconnect_Notification(clientSlot, bitStream, IP, PORT)
    end
  end
end