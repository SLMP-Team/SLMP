local rpc = {}

local list = {
  ID_CLIENT_JOIN = 1,
  ID_UPDATE_DATA = 2,
  ID_SERVER_JOIN = 3,
  ID_SERVER_QUIT = 4,
  ID_STREAMED_OUT = 5,
  ID_CLIENT_MESSAGE = 6,
  ID_CLIENT_COMMAND = 7,
  ID_UPDATE_TIME = 8,
  ID_UPDAET_WEATHER = 9,
  ID_UPDATE_POSITION = 10,
  ID_UPDATE_INTERIOR = 11,
  ID_UPDATE_SKIN = 12,
  ID_STREAMED_IN = 13,
  ID_TOGGLE_SPECTATE = 14,
  ID_SPECTATE_PLAYER = 15,
  ID_UPDATE_CAMERA_POS = 16,
  ID_UPDATE_CAMERA_ROT = 17,
  ID_UPDATE_SPAWN = 18,
  ID_SHOW_DIALOG = 19,
  ID_DIALOG_RESPONSE = 20,
  ID_RESTORE_CAMERA = 21,
  ID_UPDATE_CONTROL = 22,
  ID_UPDATE_ROTATION = 23,
  ID_OBJECT_CREATE = 24,
  ID_OBJECT_DELETE = 25,
}
rpc.list = list

local function call_client_join(bs, address, port)
  local nickname = bs:read(BS_STRING, bs:read(BS_UINT8))
  local authkey = bs:read(BS_STRING, bs:read(BS_UINT8))
  local clientver = bs:read(BS_STRING, bs:read(BS_UINT8))

  local free = clients.find_free()
  if free == 0 then
    packets.send(packets["list"]["ID_NO_FREE_INCOMING_CONNECTIONS"], nil, address, port)
    return -- all slots are in use and no free slots are available
  end

  local client = clients.by_address(address, port)
  if client ~= 0 then return end -- already connected (/==/)

  if clientver ~= "1.0.0" then
    local data = bstream.new(); data:write(BS_UINT8, 1)
    packets.send(packets["list"]["ID_CONNECTION_ATTEMPT_FAILED"], data, address, port)
    return -- client version is incorrect
  end

  local client = clients.by_nickname(nickname)
  if client ~= 0 or not nickname:match('^[A-Za-z0-9_%-%.]+$') or #nickname < 3 or #nickname > 25 then
    local data = bstream.new(); data:write(BS_UINT8, 2)
    packets.send(packets["list"]["ID_CONNECTION_ATTEMPT_FAILED"], data, address, port)
    return -- nickname with this nickname is already connected or nickname is bad
  end

  local data = bstream.new()
  data:write(BS_UINT8, #config.hostname)
  data:write(BS_STRING, config.hostname)
  packets.send(packets["list"]["ID_CONNECTION_REQUEST_ACCEPTED"], data, address, port, SNET_SYSTEM_PRIORITY)
  clients.list[free] = { -- add new client to clients list and send response to client
    nickname = nickname,
    ping = 0, score = 0,
    address = address,
    port = port, skin = 0,
    gamestate = 1, -- onfoot
    stream = {
      players = {},
      objects = {},
    },
    pos = {0, 0, 0},
    quat = {0, 0, 0, 0},
    vec = {0, 0, 0}, rot = 0,
    world = 0, interior = 0,
    last_ping = 0, last_sync = 0,
    health = 100, armour = 0,
    last_dialog = 0, keys = 0,
    vars = {},
  }

  local udata = bstream.new()
  udata:write(BS_UINT16, free)
  udata:write(BS_UINT8, #nickname)
  udata:write(BS_STRING, nickname)

  functions.getPlayerPointer(free):setTime(config.time)
  functions.getPlayerPointer(free):setWeather(config.weather)

  clients.foreach(function(index, value)
    local data = bstream.new()
    data:write(BS_UINT16, index)
    data:write(BS_UINT8, #value.nickname)
    data:write(BS_STRING, value.nickname)
    rpc.send(list["ID_SERVER_JOIN"], data, address, port)
    if index ~= free then
      rpc.send(list["ID_SERVER_JOIN"], udata, value.address, value.port)
    end
  end)

  console_log("[SERVER] New client connected: "..nickname.." [" .. free .. "] ("..address..":"..port..")")
  inner_function("onPlayerConnect", true, true, free) -- callback onPlayerConnect [PlayerID]
end

function rpc.process(id, bs, address, port)
  if id == list["ID_CLIENT_JOIN"] then
    call_client_join(bs, address, port)
  elseif id == list["ID_CLIENT_MESSAGE"] then
    local client = clients.by_address(address, port)
    if client ~= 0 then
      local text = bs:read(BS_STRING, bs:read(BS_UINT8))
      local result = inner_function("onPlayerText", true, true, client, text) -- callback onPlayerText [PlayerID] [Text]
      if not result then functions.sendMessage(0xFFFFFFFF, string.format("* %s[%s]: {F5F5F5}%s", functions.getPlayerPointer(client):getNickname(), client, text)) end
    end
  elseif id == list["ID_CLIENT_COMMAND"] then
    local client = clients.by_address(address, port)
    if client ~= 0 then
      local text = bs:read(BS_STRING, bs:read(BS_UINT8))
      local result = inner_function("onPlayerCommand", true, true, client, text) -- callback onPlayerCommand [PlayerID] [Text]
      if not result then functions.getPlayerPointer(client):sendMessage(0xC9C9C9FF, "* Unknown command, type /help to show commands list.") end
    end
  elseif id == list["ID_DIALOG_RESPONSE"] then
    local client = clients.by_address(address, port)
    if client == 0 then return end
    local id = bs:read(BS_UINT16)
    if clients.list[client].last_dialog ~= id then return end
    local btn = bs:read(BS_UINT8)
    local selected = bs:read(BS_UINT8)
    local inputtext = bs:read(BS_STRING, bs:read(BS_UINT8))
    inner_function("onDialogResponse", true, true, client, id, btn, selected, inputtext)
    -- callback onDialogRespose [PlayerID] [DialogID] [Button] [Selected] [Input]
  end
end

function rpc.send(id, bs, address, port)
  if not bs then bs = bstream.new() end
  bs = bstream.new(bs.bytes) -- clone bstream
  bs.write_ptr = 1; bs:write(BS_BOOLEAN, true)
  server:send(id, bs, SNET_SYSTEM_PRIORITY, address, port)
end

return rpc