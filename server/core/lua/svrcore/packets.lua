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

function packets.process(id, bs, address, port)
  local sendtime = bs:read(BS_UINT32)
  bs = bstream.new(bs.bytes:sub(5, #bs.bytes))
  if os.time() - sendtime > 5 then return end
  if id == list["ID_CONNECTION_REQUEST"] then
    if clients.find_free() == 0 then
      packets.send(list["ID_NO_FREE_INCOMING_CONNECTIONS"], nil, address, port)
      return
    end
    packets.send(list["ID_CONNECTION_REQUEST"], nil, address, port)
  elseif id == list["ID_ONFOOT_SYNC"] then sync.onfoot(bs, address, port)
  elseif id == list["ID_SPEC_SYNC"] then sync.spectating(bs, address, port)
  elseif id == list["ID_DISCONNECTION_NOTIFICATION"] then
    local client = clients.by_address(address, port)
    if client ~= 0 then
      console_log("[SERVER] Client disconnected: "..clients.list[client].nickname.." [" .. client .. "] (reason: quit)")
      inner_function("onPlayerDisconnect", true, true, client, 1) -- callback onPlayerDisconnect [PlayerID] [Reason]
      clients.remove(client)
      local data = bstream.new()
      data:write(BS_UINT16, client)
      data:write(BS_UINT8, 1) -- quit
      clients.foreach(function(index, value)
        for i = #value.stream.players, 1, -1 do
          if value.stream.players[i] == client then
            table.remove(value.stream.players, i)
            break
          end
        end
        rpc.send(rpc["list"]["ID_SERVER_QUIT"],
        data, value.address, value.port)
      end)
    end
  elseif id == list["ID_PING_SERVER_REQUEST"] then
    local client = clients.by_address(address, port)
    if client == 0 then return end
    local ptr = clients.list[client]
    if bs:read(BS_BOOLEAN) == false then
      ptr.last_ping = os.clock()
      packets.send(list["ID_PING_SERVER_REQUEST"], nil, ptr.address, ptr.port)
    else ptr.ping = math.floor((os.clock() - ptr.last_ping) * 1000) end
  elseif id == list["ID_UPDATE_SCORE_PING"] then
    local client = clients.by_address(address, port)
    if client == 0 then return end
    local ptr = clients.list[client]
    local data = bstream.new()
    local counter = 0
    for i, v in ipairs(clients.list) do
      if v ~= 0 then
        data:write(BS_UINT16, i)
        data:write(BS_UINT16, v.score)
        data:write(BS_UINT16, v.ping)
        counter = counter + 1
      end
    end
    data.write_ptr = 1; data:write(BS_UINT16, counter)
    packets.send(list["ID_UPDATE_SCORE_PING"], data, ptr.address, ptr.port)
  elseif id == list["ID_UPDATE_STREAM"] then sync.restream(bs, address, port) end
end

function packets.send(id, bs, address, port, priority)
  if not bs then bs = bstream.new() end
  if not priority then priority = SNET_BYPASS_PRIORITY end
  bs = bstream.new(bs.bytes) -- clone bstream
  bs.write_ptr = 1; bs:write(BS_BOOLEAN, false)
  bs:write(BS_UINT32, os.time()) -- send time
  server:send(id, bs, priority, address, port)
end

return packets