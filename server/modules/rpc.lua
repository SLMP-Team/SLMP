function RPC_Update_Ping_Score(clientSlot, IP, PORT)
  Clients[clientSlot].lastPing = os.time()
  local bs = BitStream:new()
  bs:writeUInt16(Clients:count())
  for i = 1, Clients:count() do
    bs:writeUInt16(Clients[i].id)
    bs:writeUInt16(Clients[i].ping)
    bs:writeInt16(Clients[i].score)
    bs:writeUInt32(Clients[i].color)
  end
  sendRPC(RPC.UPDATE_PING_AND_SCORE, false, bs, IP, PORT)
end

function RPC_Send_Message(clientSlot, bitStream, IP, PORT)
  local len = bitStream:readUInt8()
  local str = bitStream:readString(len)
  local playerid = Clients:getIDBySlot(clientSlot)
  local isFunc, result = pcall(onPlayerChat, playerid, str)
  if not isFunc or isFunc and result then
    str = Clients[clientSlot].name .. ' (' .. Clients:getIDBySlot(clientSlot) .. '):{939393} ' .. str
    Clients:sendMessageAll(str, Clients[clientSlot].color)
  end
end

function RPC_Send_Command(clientSlot, bitStream, IP, PORT)
  local len = bitStream:readUInt8()
  local str = bitStream:readString(len)
  local playerid = Clients:getIDBySlot(clientSlot)
  local isFunc, result = pcall(onPlayerChatCommand, playerid, str)
  if not isFunc or not result then
    str = 'Server command not found, use {FFFFFF}/help{939393} to show commands list'
    Clients:sendMessage(clientSlot, str, 0x939393FF)
  end
end