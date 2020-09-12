function Packet_Connection_Request(bitStream, IP, PORT)
  -- This call when player trys to connected to server
  local bs = BitStream:new()
  if Clients:count() >= Config.Slots then
    bs:writeUInt8(1)
    sendPacket(PACKET.CONNECTION_REQUEST_FAIL, false, bs, IP, PORT)
    return
  end
  local nameLen = bitStream:readUInt8()
  local name = bitStream:readString(nameLen)
  if nameLen > 25 or nameLen < 1 or not name:match('^[a-zA-Z0-9_%.]+$') then
    bs:writeUInt8(2)
    sendPacket(PACKET.CONNECTION_REQUEST_FAIL, false, bs, IP, PORT)
    return
  end
  local clientGPCI = bitStream:readInt32()
  local clientVersion = bitStream:readUInt16()
  if clientVersion ~= General.Version then
    bs:writeUInt8(3)
    sendPacket(PACKET.CONNECTION_REQUEST_FAIL, false, bs, IP, PORT)
    return
  end
  for i = 1, Clients:count() do
    if Clients[i].name:lower() == name:lower() then
      bs:writeUInt8(4)
      sendPacket(PACKET.CONNECTION_REQUEST_FAIL, false, bs, IP, PORT)
      return
    end
  end
  local clientID = Clients:new(name, IP, PORT, clientGPCI)
  bs:writeUInt16(clientID)
  bs:writeUInt16(Config.OnFootRate)
  sendPacket(PACKET.CONNECTION_REQUEST_SUCCESS, true, bs, IP, PORT)
end

function Packet_Player_Connected(clientSlot, bitStream, IP, PORT)
  local backID = bitStream:readUInt16()
  local clientID = Clients:getIDBySlot(clientSlot)
  if backID == clientID then
    print('[JOIN] Player ' .. Clients[clientSlot].name .. ' [' .. Clients[clientSlot].ip .. ':' .. Clients[clientSlot].port .. ':' .. clientID .. '] joined the server')
    pcall(onPlayerConnect, clientID)
    -- Here we have to send all data player need when login
    local bs = BitStream:new()
    bs:writeUInt16(clientID)
    bs:writeUInt8(Clients[clientSlot].name:len())
    bs:writeString(Clients[clientSlot].name)
    Clients:sendRPC(RPC.PLAYER_CONNECT, true, bs)
    for i = 1, Clients:count() do
      if i ~= clientSlot then
        bs:clear()
        bs:writeUInt16(Clients[i].id)
        bs:writeUInt8(Clients[i].name:len())
        bs:writeString(Clients[i].name)
        sendRPC(RPC.PLAYER_CONNECT, true, bs, IP, PORT)
      end
    end
  end
end

function Packet_OnFoot_Sync(clientSlot, bitStream, IP, PORT)
  if (os.clock() - Clients[clientSlot].lastSync) * 1000 < Config.OnFootRate then
    return
  end
  if Clients[clientSlot].gamestate ~= GAMESTATE.ONFOOT then
    return
  end
  Clients[clientSlot].lastSync = os.clock()
  Clients[clientSlot].health = bitStream:readUInt8()
  Clients[clientSlot].armour = bitStream:readUInt8()
  Clients[clientSlot].pos = {0.0, 0.0, 0.0}
  for i = 1, 3 do
    Clients[clientSlot].pos[i] = bitStream:readFloat()
  end
  Clients[clientSlot].vel = {0.0, 0.0, 0.0}
  for i = 1, 3 do
    Clients[clientSlot].vel[i] = bitStream:readFloat()
  end
  Clients[clientSlot].quat = {0.0, 0.0, 0.0, 0.0}
  for i = 1, 4 do
    Clients[clientSlot].quat[i] = bitStream:readFloat()
  end
  Clients[clientSlot].ang = bitStream:readFloat()
  Clients:sendOnFoot(clientSlot)
  pcall(onPlayerUpdate, Clients:getIDBySlot(clientSlot))
end

function Packet_Query(IP, PORT)
	local query = 'SLMP'
	query = query .. '//|' .. Clients:count()
	query = query .. '//|' .. Config.Slots
	query = query .. '//|' .. Config.Hostname
	query = query .. '//|' .. General.VersionS
	query = query .. '//|' .. Config.Language
	query = query .. '//|' .. Config.Website
	for i = 1, Clients:count() do
		query = query .. '//|' .. Clients[i].id
		query = query .. '//|' .. Clients[i].name
		query = query .. '//|' .. Clients[i].ping
	end
	udp:sendto(query, IP, PORT)
end

function Packet_Ping_Server(bitStream, IP, PORT)
  local bs = BitStream:new()
  bs:writeUInt16(Clients:count())
  bs:writeUInt16(Config.Slots)
  bs:writeUInt16(#Config.Hostname)
  bs:writeString(Config.Hostname)
  bs:writeUInt8(#General.VersionS)
  bs:writeString(General.VersionS)
  bs:writeUInt8(#Config.Language)
  bs:writeString(Config.Language)
  bs:writeUInt8(#Config.Website)
  bs:writeString(Config.Website)
  for i = 1, Clients:count() do
    bs:writeUInt8(#Clients[i].name)
    bs:writeString(Clients[i].name)
  end
  sendPacket(PACKET.PING_SERVER, false, bs, IP, PORT)
end

function Packet_Disconnect_Notification(clientSlot, bitStream, IP, PORT)
  local reason = bitStream:readUInt8()
  Clients:disconnect(clientSlot, reason)
end