Clients = {} -- here we will store our clients
function Clients:new(name, ip, port, gpci)
  local freeID = -1
  while true do
    local used = false
    freeID = freeID + 1
    for i = 1, #self do
      if self[i].id == freeID then
        used = true
        break
      end
    end
    if not used then
      break
    end
  end
  table.insert(self, {
    id = freeID,
    name = name,
    ip = ip,
    port = port,
    GPCI = gpci,
    lastPing = os.time(),
    ping = 65535,
    score = 0,
    skin = 0,
    pos = {0.0, 0.0, 5.0},
    vel = {0.0, 0.0, 0.0},
    ang = 0.0, -- facing angle
    quat = {0.0, 0.0, 0.0, 0.0},
    health = 100.0,
    armour = 100.0,
    stream =
    {
      clients = {}
    },
    world = 0,
    interior = 0,
    gamestate = GAMESTATE.ONFOOT,
    lastSync = os.clock(),
    color = 0xFFFFFF50,
    lastDialog = -1
  })
  return freeID
end
function Clients:getSlotByID(clientID)
  for i = 1, #self do
    if self[i].id == clientID then
      return i
    end
  end
  return -1
end
function Clients:getIDBySlot(slot)
  return self[slot] and self[slot].id or -1
end
function Clients:getSlotByAddress(ip, port)
  for i = 1, #self do
    if self[i].ip == ip and self[i].port == port then
      return i
    end
  end
  return -1
end
function Clients:getAddressBySlot(slot)
  if self[slot] then
    return self[slot].ip, self[slot].port
  end
  return '', 0
end
function Clients:count()
  return #self
end
function Clients:remove(slotID)
  table.remove(self, slotID)
end
function Clients:checkLostConnection()
  for i = #self, 1, -1 do
    if os.time() - Clients[i].lastPing > 100 then
      Clients:disconnect(i, 1)
    end
  end
end
function Clients:sendRPC(PacketID, PacketPriority, PacketData)
  for i = 1, #self do
    local ip, port = self:getAddressBySlot(i)
    sendRPC(PacketID, PacketPriority, PacketData, ip, port)
  end
end
function Clients:sendPacket(PacketID, PacketPriority, PacketData)
  for i = 1, #self do
    local ip, port = self:getAddressBySlot(i)
    sendPacket(PacketID, PacketPriority, PacketData, ip, port)
  end
end
function Clients:disconnect(slotID, reason)
  pcall(onPlayerDisconnect, Clients[slotID].id, reason)
  print('[LEFT] Player ' .. Clients[slotID].name .. ' [' .. Clients[slotID].ip .. ':' .. Clients[slotID].port .. ':' .. reason .. '] left the server')
  -- any stuff until disconnection here
  local bs = BitStream:new()
  bs:writeUInt16(Clients[slotID].id)
  self:sendRPC(RPC.PLAYER_DISCONNECT, true, bs)
  Clients:remove(slotID)
end
function Clients:isClientStreamed(slot, clientid)
  for i = 1, #self[slot].stream.clients do
    if self[slot].stream.clients[i] == clientid then
      return true
    end
  end
  return false
end
function Clients:getDistance(slot, slot2)
  local x1, y1, z1 = Clients[slot].pos[1], Clients[slot].pos[2], Clients[slot].pos[3]
  local x2, y2, z2 = Clients[slot2].pos[1], Clients[slot2].pos[2], Clients[slot2].pos[3]
  return getDistanceBetweenCoords3d(x1, y1, z1, x2, y2, z2)
end
function Clients:setStreamStatus(slot, clientid, status)
  local streamed = false
  for i = #self[slot].stream.clients, 1, -1 do
    if self[slot].stream.clients[i] == clientid then
      streamed = true
      if not status then
        table.remove(self[slot].stream.clients, i)
      end
      break
    end
  end
  if not streamed and status then
    table.insert(self[slot].stream.clients, clientid)
  end
end
function Clients:updateStream()
  for i = 1, Clients:count() do
    for ii = 1, Clients:count() do
      if i ~= ii then
        local clientid = self:getIDBySlot(ii)
        local streamed = self:isClientStreamed(i, clientid)
        local dist = self:getDistance(i, ii)
        if not streamed and dist <= Config.Stream and self[i].world == self[ii].world  then
          self:setStreamStatus(i, clientid, true)
          local bs = BitStream:new()
          bs:writeUInt8(1) -- players
          bs:writeUInt16(clientid)
          bs:writeBool(true)
          bs:writeUInt16(self[ii].skin)
          bs:writeUInt8(self[ii].health)
          bs:writeUInt8(self[ii].armour)
          for iii = 1, 3 do
            bs:writeFloat(self[ii].pos[iii])
          end
          for iii = 1, 3 do
            bs:writeFloat(self[ii].vel[iii])
          end
          for iii = 1, 4 do
            bs:writeFloat(self[ii].quat[iii])
          end
          bs:writeFloat(self[ii].ang)
          sendPacket(PACKET.UPDATE_STREAM, true, bs, self[i].ip, self[i].port)
        elseif streamed and (dist > Config.Stream or self[i].world ~= self[ii].world) then
          self:setStreamStatus(i, clientid, false)
          local bs = BitStream:new()
          bs:writeUInt8(1) -- players
          bs:writeUInt16(clientid)
          bs:writeBool(false)
          sendPacket(PACKET.UPDATE_STREAM, true, bs, self[i].ip, self[i].port)
        end
      end
    end
  end
end
function Clients:sendOnFoot(i)
  for ii = 1, Clients:count() do
    if i ~= ii then
      local clientid = self:getIDBySlot(ii)
      if self:getGamestate(ii) == GAMESTATE.ONFOOT
      and self:isClientStreamed(i, clientid) then
        local bs = BitStream:new()
        bs:writeUInt16(clientid)
        bs:writeUInt8(self[ii].health)
        bs:writeUInt8(self[ii].armour)
        bs:writeUInt16(self[ii].skin)
        for iii = 1, 3 do
          bs:writeFloat(self[ii].pos[iii])
        end
        for iii = 1, 3 do
          bs:writeFloat(self[ii].vel[iii])
        end
        for iii = 1, 4 do
          bs:writeFloat(self[ii].quat[iii])
        end
        bs:writeFloat(self[ii].ang)
        sendPacket(PACKET.ONFOOT_SYNC, false, bs, self[i].ip, self[i].port)
      end
    end
  end
end
function Clients:getGamestate(clientSlot)
  return self[clientSlot] and self[clientSlot].gamestate or -1
end
function Clients:setSkin(clientSlot, skinid)
  self[clientSlot].skin = skinid
  local bs = BitStream:new()
  bs:writeUInt16(skinid)
  sendRPC(RPC.SET_PLAYER_SKIN, true, bs, self[clientSlot].ip, self[clientSlot].port)
end
function Clients:setPos(clientSlot, x, y, z)
  local bs = BitStream:new()
  bs:writeFloat(x); bs:writeFloat(y); bs:writeFloat(z)
  sendRPC(RPC.SET_PLAYER_POS, true, bs, self[clientSlot].ip, self[clientSlot].port)
end
function Clients:setAngle(clientSlot, angle)
  local bs = BitStream:new()
  bs:writeFloat(angle)
  sendRPC(RPC.SET_PLAYER_ANGLE, true, bs, self[clientSlot].ip, self[clientSlot].port)
end
function Clients:setInterior(clientSlot, interior)
  self[clientSlot].interior = interior
  local bs = BitStream:new()
  bs:writeUInt16(interior)
  sendRPC(RPC.SET_PLAYER_INTERIOR, true, bs, self[clientSlot].ip, self[clientSlot].port)
end
function Clients:sendMessage(slot, text, color)
  local bs = BitStream:new()
  bs:writeUInt8(#text:gsub('%%', '%%%%')) -- imgui formatting crash fix
  bs:writeString(text:gsub('%%', '%%%%')) -- imgui formatting crash fix
  bs:writeUInt32(color)
  sendRPC(RPC.SEND_MESSAGE, true, bs, self[slot].ip, self[slot].port)
end
function Clients:sendMessageAll(text, color)
  local bs = BitStream:new()
  bs:writeUInt8(#text:gsub('%%', '%%%%')) -- imgui formatting crash fix
  bs:writeString(text:gsub('%%', '%%%%')) -- imgui formatting crash fix
  bs:writeUInt32(color)
  for i = 1, self:count() do
    sendRPC(RPC.SEND_MESSAGE, true, bs, self[i].ip, self[i].port)
  end
end
function Clients:setChatBubble(clientSlot, text, time, color, dist)
  local bs = BitStream:new()
  local clientID = self:getIDBySlot(clientSlot)
  bs:writeUInt16(clientID)
  bs:writeUInt8(#text:gsub('%%', '%%%%')) -- imgui formatting crash fix
  bs:writeString(text:gsub('%%', '%%%%')) -- imgui formatting crash fix
  bs:writeUInt32(color)
  bs:writeFloat(dist)
  bs:writeUInt16(time)
  for i = 1, self:count() do
    if i ~= clientSlot and Clients:isClientStreamed(i, clientID) then
      sendRPC(RPC.SET_CHAT_BUBBLE, false, bs, self[i].ip, self[i].port)
    end
  end
end
function Clients:showDialog(clientSlot, id, dType, title, text, button1, button2)
  self[clientSlot].lastDialog = id -- protect from fake-dialog responses
  local bs = BitStream:new()
  bs:writeUInt16(id)
  bs:writeUInt8(dType)
  bs:writeUInt8(#title:gsub('%%', '%%%%')); bs:writeString(title:gsub('%%', '%%%%')) -- imgui formatting crash fix
  bs:writeUInt8(#button1:gsub('%%', '%%%%')); bs:writeString(button1:gsub('%%', '%%%%')) -- imgui formatting crash fix
  bs:writeUInt8(#button2:gsub('%%', '%%%%')); bs:writeString(button2:gsub('%%', '%%%%')) -- imgui formatting crash fix
  bs:writeUInt32(#text:gsub('%%', '%%%%')); bs:writeString(text:gsub('%%', '%%%%')) -- imgui formatting crash fix
  sendRPC(RPC.SHOW_DIALOG, true, bs, self[clientSlot].ip, self[clientSlot].port)
end