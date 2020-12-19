local client = {}
local bstream = require("snet.bstream")

client.address = "127.0.0.1"
client.port = 13322
client.status = SNET_DISCONNECTED
client.unique_id = 0
client.last_ids = {}
client.events = {}
client.packets = {}

function client:add_event_handler(event, callback)
  table.insert(self.events, {event, callback})
end

local function get_packet(object)
  local data = object.socket:receive()
  if data then
    if data:sub(1, 1):byte() ~= 0x0 then return false end
    data = data:sub(2, #data)
    return data
  end
  return false
end

local function receive_packet(object)
  local data = get_packet(object)
  if not data then return false end

  local clean_data = data:sub(10, #data)
  data = bstream.new(data)
  local unique_id = data:read(BS_UINT32)
  local packet_id = data:read(BS_UINT32)
  local priority = data:read(BS_UINT8)

	if priority > 0 then
    local new_bs = bstream.new()
    new_bs:write(BS_UINT32, unique_id)
    object:send(SNET_CONFIRM_PRIORITY, new_bs, SNET_BYPASS_PRIORITY)
  end

  for i, v in ipairs(object.last_ids) do
    if v == unique_id then
      return false
    end
  end

  if #object.last_ids >= 10 then table.remove(object.last_ids, 1) end
  table.insert(object.last_ids, unique_id)

  object.status = SNET_CONNECTED

  for i, v in ipairs(object.events) do
    if v[1] == 'onReceivePacket' then
      v[2](packet_id, bstream.new(clean_data))
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

local function send_packet(object, unique_id, packet_id, priority, bytes)
  local data = bstream.new(bytes)
  data.write_ptr = 1

  data:write(BS_UINT32, unique_id)
  data:write(BS_UINT32, packet_id)
  data:write(BS_UINT8, priority)

  return object.socket:send('\0' .. data.bytes .. '\0')
end

function client:send(packet_id, stream, priority)
  local unique_id = self.unique_id

  self.unique_id = self.unique_id + 1
  if self.unique_id >= 4294967295 then
    self.unique_id = 0
  end

  send_packet(self, unique_id, packet_id, priority, stream.bytes)

  if priority > 0 then
    table.insert(self.packets, {
      unique_id = unique_id, packet_id = packet_id,
      priority = priority, bytes = stream.bytes,
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

      send_packet(object, v.unique_id, v.packet_id, v.priority, v.bytes)

      if v.priority == SNET_SYSTEM_PRIORITY and object.status ~= SNET_CONNECTED then table.remove(object.packets, i)
      elseif v.priority == SNET_HIGH_PRIORITY and v.times >= 20 then table.remove(object.packets, i)
      elseif v.priority == SNET_MEDIUM_PRIORITY and v.times >= 10 then table.remove(object.packets, i)
      elseif v.priority == SNET_LOW_PRIORITY and v.times >= 5 then table.remove(object.packets, i) end
    end
  end

  return true
end

function client:process()
  receive_packet(self)
  resend_packets(self)
end

return client