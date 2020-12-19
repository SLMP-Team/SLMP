local packets = {}

local list = {
  ID_PING_SERVER_REQUEST = 0,
  ID_CONNECTION_REQUEST = 1,
  ID_CONNECTION_REQUEST_ACCEPTED = 2,
  ID_CONNECTION_ATTEMPT_FAILED = 3,
  ID_NO_FREE_INCOMING_CONNECTIONS = 4,
  ID_DISCONNECTION_NOTIFICATION = 5,
  ID_CONNECTION_LOST = 6,
  ID_ONFOOT_SYNC = 7,
  ID_UPDATE_SCORE_PING = 8,
  ID_UPDATE_STREAM = 9,
  ID_SPEC_SYNC = 10,
}
packets.list = list

function packets.process(id, bs)
  --chat_pool:add(0xFFFFFFFF, "Incoming Packet: "..id)
  print("Incoming Packet: "..id)
  local sendtime = bs:read(BS_UINT32)
  bs = bstream.new(bs.bytes:sub(5, #bs.bytes))
  if os.time() - sendtime > 5 then return end
  if last_connection ~= 0 then
    if id == list["ID_CONNECTION_REQUEST"] then
      chat_pool:add(0xC9C9C9FF, "Connected. Joining the game...")
      connect_to_server(true)
    elseif id == list["ID_CONNECTION_ATTEMPT_FAILED"] then
      last_connection = 0
      local reason = bs:read(BS_UINT8)
      if reason == 1 then
        chat_pool:add(0x7CC46EFF, "CONNECTION REJECTED: Incorrect Client Version.")
      elseif reason == 2 then
        chat_pool:add(0x7CC46EFF, "CONNECTION REJECTED: Unacceptable Nickname.")
        chat_pool:add(0x7CC46EFF, "Length of nickname: from 3 to 25 symbols")
        chat_pool:add(0x7CC46EFF, "Allowed symbols: a-z, A-Z, 0-9 and _")
        chat_pool:add(0x7CC46EFF, "Use /quit to exit or press ESC and select Quit Game")
      else
        chat_pool:add(0x7CC46EFF, "CONNECTION REJECTED: Unknown Reason.")
      end
    elseif id == list["ID_CONNECTION_REQUEST_ACCEPTED"] then
      last_connection = 0; is_connected = true
      local hostname = bs:read(BS_STRING, bs:read(BS_UINT8)); servername = hostname
      chat_pool:add(0xC9C9C9FF, "Connected to {7CC46E}"..hostname..".")
      packets.send(packets["list"]["ID_PING_SERVER_REQUEST"], nil)
      packets.send(packets["list"]["ID_UPDATE_SCORE_PING"], nil)
      packets.send(packets["list"]["ID_UPDATE_STREAM"], nil)
    elseif id == list["ID_NO_FREE_INCOMING_CONNECTIONS"] then
      server_was_full = true
    end
  end
  if id == list["ID_ONFOOT_SYNC"] then sync.onfoot_in(bs)
  elseif id == list["ID_PING_SERVER_REQUEST"] then
    local data = bstream.new(); data:write(BS_BOOLEAN, true)
    packets.send(packets["list"]["ID_PING_SERVER_REQUEST"], data)
  elseif id == list["ID_UPDATE_SCORE_PING"] then
    local counter = bs:read(BS_UINT16)
    for i = 1, counter do
      local pid = bs:read(BS_UINT16)
      local score = bs:read(BS_UINT16)
      local ping = bs:read(BS_UINT16)
      if players.list[pid] then
        players.list[pid].score = score
        players.list[pid].ping = ping
      end
    end
  end
end

function packets.send(id, bs, priority)
  if not bs then bs = bstream.new() end
  if not priority then priority = SNET_BYPASS_PRIORITY end
  bs = bstream.new(bs.bytes) -- clone bstream
  bs.write_ptr = 1; bs:write(BS_BOOLEAN, false)
  bs:write(BS_UINT32, os.time()) -- send time
  client:send(id, bs, priority)
end

return packets