local server = {}
local bstream = require("snet.bstream")

server.address = "*"
server.port = 13322
server.unique_id = 0
server.last_ids = {}
server.events = {}
server.clients = {}
server.packets = {}
server.blacklist = {}

function server:add_event_handler(event, callback)
  table.insert(self.events, {event, callback})
end

local function is_blacklisted(handle, address)
  if type(address) ~= 'string' then
    return false
  end

  for i, v in ipairs(handle.blacklist) do
    if v[1] == address then
      return true, i
    end
  end

  return false
end

function server:block_address(address)
  if type(address) ~= 'string' then
    return false
  end

  for i, v in ipairs(self.blacklist) do
    if v[1] == address then
      return false
    end
  end

  table.insert(self.blacklist, {address, 0})
  return true
end

function server:unblock_address(address)
  if type(address) ~= 'string' then
    return false
  end

  for i, v in ipairs(self.blacklist) do
    if v[1] == address then
      table.remove(self.blacklist, i)
      return true
    end
  end

  return false
end

local function get_packet(object)
  local data, address, port = object.socket:receivefrom()
  if data and address and port then
    local is_block, list_id = is_blacklisted(object, tostring(address))
    if is_block then
      if os.time() >= object.blacklist[list_id][2] then
        object.blacklist[list_id][2] = os.time() + 60
        object:send(SNET_BLOCK_PACKET, bstream.new(),
        SNET_BYPASS_PRIORITY, address, port)
      end
      return false
    end
    if data:sub(1, 1):byte() ~= 0x0 then return false end
    data = data:sub(2, #data)
    return data, address, port
  end
  return false
end

local function receive_packet(object)
  local data, address, port = get_packet(object)
  if not data then return false end

  local clean_data = data:sub(10, #data)
  data = bstream.new(data)
  local unique_id = data:read(BS_UINT32)
  local packet_id = data:read(BS_UINT32)
  local priority = data:read(BS_UINT8)

	if priority > 0 then
    local new_bs = bstream.new()
    new_bs:write(BS_UINT32, unique_id)
    object:send(SNET_CONFIRM_PRIORITY, new_bs, SNET_BYPASS_PRIORITY, address, port)
  end

  if not object.last_ids[address..':'..port] then
    object.last_ids[address..':'..port] = {}
  end

  for i, v in ipairs(object.last_ids[address..':'..port]) do
    if v == unique_id then
      return false
    end
  end

  if #object.last_ids[address..':'..port] >= 10 then table.remove(object.last_ids[address..':'..port], 1) end
  table.insert(object.last_ids[address..':'..port], unique_id)

  if not object.clients[address..':'..port] then
    for i, v in ipairs(object.events) do
      if v[1] == 'onClientUpdate' then
        v[2](address, port, "connected")
      end
    end
  end
  object.clients[address..':'..port] = os.time()

  for i, v in ipairs(object.events) do
    if v[1] == 'onReceivePacket' then
      v[2](packet_id, bstream.new(clean_data), address, port)
    end
  end

  if packet_id == SNET_CONFIRM_PRIORITY then
    local conf_bs = bstream.new(clean_data)
    local conf_id = conf_bs:read(BS_UINT32)
    for i = #object.packets, 1, -1 do
      if object.packets[i].unique_id == conf_id then
        table.remove(object.packets, i)
        break
      end
    end
  end

  return true
end

local function send_packet(object, unique_id, packet_id, priority, bytes, address, port)
  local data = bstream.new(bytes)
  data.write_ptr = 1

  data:write(BS_UINT32, unique_id)
  data:write(BS_UINT32, packet_id)
  data:write(BS_UINT8, priority)

  return object.socket:sendto('\0' .. data.bytes .. '\0', address, port)
end

function server:send(packet_id, stream, priority, address, port)
  local unique_id = self.unique_id

  self.unique_id = self.unique_id + 1
  if self.unique_id >= 4294967295 then
    self.unique_id = 0
  end

  send_packet(self, unique_id, packet_id, priority, stream.bytes, address, port)

  if priority > 0 then
    table.insert(self.packets, {
      unique_id = unique_id, packet_id = packet_id,
      priority = priority, bytes = stream.bytes,
      address = address, port = port,
      times = 0, last_time = os.time()
    })
  end

  return true
end

local function resend_packets(object)
  for i = #object.packets, 1, -1 do
    local v = object.packets[i]
    if os.time() ~= v.last_time then
      v.last_time = os.time()
      v.times = v.times + 1

      send_packet(object, v.unique_id, v.packet_id,
      v.priority, v.bytes, v.address, v.port)

      if v.priority == SNET_SYSTEM_PRIORITY and not object.clients[v.address..':'..v.port] then table.remove(object.packets, i)
      elseif v.priority == SNET_HIGH_PRIORITY and v.times >= 20 then table.remove(object.packets, i)
      elseif v.priority == SNET_MEDIUM_PRIORITY and v.times >= 10 then table.remove(object.packets, i)
      elseif v.priority == SNET_LOW_PRIORITY and v.times >= 5 then table.remove(object.packets, i) end
    end
  end

  return true
end

function server:process()
  receive_packet(self)
  for k, v in pairs(self.clients) do
    if os.time() - v >= 60 then
      self.clients[k] = nil
      self.last_ids[k] = nil
      for i, vv in ipairs(self.events) do
        if vv[1] == 'onClientUpdate' then
          local address, port = k:match('^(%S+):(%d+)$')
          vv[2](address, port, "timeout")
        end
      end
    end
  end
  resend_packets(self)
end

return server