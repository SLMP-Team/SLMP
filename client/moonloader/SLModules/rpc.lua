function RPC_Player_Connect(bitStream)
  local playerid = bitStream:readUInt16()
  local nameLen = bitStream:readUInt8()
  local name = bitStream:readString(nameLen)
  Players:new(playerid, name)
end

function RPC_Player_Disconnect(bitStream)
  local playerid = bitStream:readUInt16()
  if playerid == Player.ID then
    Client:disconnect(false, 0)
    Game:addChatMessage('Server closed the connection', 0x939393FF)
    Game:addChatMessage('Use /disconnect to return to menu', 0x939393FF)
  end
  local slot = Players:getSlotByID(playerid)
  if slot ~= -1 then
    Players:remove(slot)
  end
end

function RPC_Update_Ping_Score(bitStream)
  General.LastPingTime = os.time()
  local total = bitStream:readUInt16()
  for i = 1, total do
    local playerid = bitStream:readUInt16()
    local slot = Players:getSlotByID(playerid)
    local ping = bitStream:readUInt16()
    local score = bitStream:readInt16()
    local color = bitStream:readUInt32()
    if slot ~= -1 then
      Players[slot].ping = ping
      Players[slot].score = score
      Players[slot].color = color
    end
  end
end

function RPC_SetPlayerPos(bitStream)
  local pos = {}
  for i = 1, 3 do
    pos[i] = bitStream:readFloat()
  end
  setCharCoordinates(PLAYER_PED, pos[1], pos[2], pos[3])
end

function RPC_SendMessage(bitStream)
  local len = bitStream:readUInt8()
  local str = bitStream:readString(len)
  local color = bitStream:readUInt32()
  Game:addChatMessage(str, color)
end

function RPC_ChatBubble(bitStream)
  local client = bitStream:readUInt16()
  local len = bitStream:readUInt8()
  local text = bitStream:readString(len)
  local color = bitStream:readUInt32()
  local dist = bitStream:readFloat()
  local time = bitStream:readUInt16()
  local slot = Players:getSlotByID(client)
  if slot ~= -1 then
    Players[slot].chatBubble =
    {
      text = text,
      time = time / 1000 + os.clock(),
      color = color,
      dist = dist
    }
  end
end