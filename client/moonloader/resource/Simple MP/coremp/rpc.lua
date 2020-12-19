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

function rpc.process(id, bs)
  --chat_pool:add(0xFFFFFFFF, "Incoming RPC: "..id)
  print("Incoming RPC: "..id)
  if id == list["ID_SERVER_JOIN"] then
    local pid = bs:read(BS_UINT16)
    local nickname = bs:read(BS_STRING, bs:read(BS_UINT8))
    players.list[pid] = {
      nickname = nickname,
      skin = 1, health = 100,
      armour = 0, skin = 0,
      score = 0, ping = 0
    }
    if nickname == client_data.name then
      localplayer_id = pid
    end
  elseif id == list["ID_SERVER_QUIT"] then
    local pid = bs:read(BS_UINT16)
    players.remove(pid)
  elseif id == list["ID_STREAMED_OUT"] then
    local pid = bs:read(BS_UINT16)
    if players.list[pid] == 0 then return end
    local ptr = players.list[pid]
    if camera.is_spectating and camera.player_spec == pid then camera:restore() end
    if doesCharExist(ptr.ped) then deleteChar(ptr.ped) end
  elseif id == list["ID_STREAMED_IN"] then
    local pid = bs:read(BS_UINT16)
    local skin = bs:read(BS_UINT16)
    local x, y, z = bs:read(BS_FLOAT),
    bs:read(BS_FLOAT), bs:read(BS_FLOAT)
    if players.list[pid] == 0 then return end
    local ptr = players.list[pid]
    if not doesCharExist(ptr.ped) then
      ptr.skin = skin; players.spawn(pid)
      setCharCoordinates(ptr.ped, x, y, z)
    end
  elseif id == list["ID_CLIENT_MESSAGE"] then
    local color = bs:read(BS_UINT32)
    local text = bs:read(BS_STRING, bs:read(BS_UINT8))
    chat_pool:add(color, text)
  elseif id == list["ID_UPDATE_TIME"] then
    world_data.time = bs:read(BS_UINT8)
  elseif id == list["ID_UPDAET_WEATHER"] then
    world_data.weather = bs:read(BS_UINT8)
  elseif id == list["ID_UPDATE_SKIN"] then
    set_skin(bs:read(BS_UINT16))
  elseif id == list["ID_UPDATE_INTERIOR"] then
    local intid = bs:read(BS_UINT16)
    setCharInterior(PLAYER_PED, intid)
    setInteriorVisible(intid)
  elseif id == list["ID_UPDATE_POSITION"] then
    local x, y, z = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
    setCharCoordinates(PLAYER_PED, x, y, z)
  elseif id == list["ID_TOGGLE_SPECTATE"] then
    camera:toggle(bs:read(BS_BOOLEAN))
  elseif id == list["ID_UPDATE_CAMERA_POS"] then
    local x, y, z = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
    camera:set_pos(x, y, z)
  elseif id == list["ID_UPDATE_CAMERA_ROT"] then
    local x, y, z = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
    camera:set_look_pos(x, y, z)
  elseif id == list["ID_SPECTATE_PLAYER"] then
    camera:attach_player(bs:read(BS_UINT16))
  elseif id == list["ID_UPDATE_SPAWN"] then
    world_data.spawn = {
      x = bs:read(BS_FLOAT),
      y = bs:read(BS_FLOAT),
      z = bs:read(BS_FLOAT)
    }
  elseif id == list["ID_SHOW_DIALOG"] then
    local did = bs:read(BS_UINT16)
    local title = bs:read(BS_STRING, bs:read(BS_UINT8)) or ""
    local text = strcomp.decompress(bs:read(BS_STRING, bs:read(BS_UINT16))) or ""
    local btn1 = bs:read(BS_STRING, bs:read(BS_UINT8)) or ""
    local btn2 = bs:read(BS_STRING, bs:read(BS_UINT8)) or ""
    local dtype = bs:read(BS_UINT8)
    dialog_pool.dialog_id = did; dialog_pool:show(title, text, btn1, btn2, dtype)
  elseif id == list["ID_RESTORE_CAMERA"] then camera:restore()
  elseif id == list["ID_UPDATE_CONTROL"] then
    local state = bs:read(BS_BOOLEAN)
    setPlayerControl(PLAYER_HANDLE, state)
  elseif id == list["ID_UPDATE_ROTATION"] then
    setCharHeading(PLAYER_PED, bs:read(BS_FLOAT))
  elseif id == list["ID_OBJECT_DELETE"] then
    objects:remove(bs:read(BS_UINT32))
  elseif id == list["ID_OBJECT_CREATE"] then
    local objectid, modelid = bs:read(BS_UINT32), bs:read(BS_UINT32)
    local x, y, z = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
    local rX, rY, rZ = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
    objects:new(objectid, modelid, x, y, z, rX, rY, rZ)
  end
end

function rpc.send(id, bs)
  if not bs then bs = bstream.new() end
  bs = bstream.new(bs.bytes) -- clone bstream
  bs.write_ptr = 1; bs:write(BS_BOOLEAN, true)
  client:send(id, bs, SNET_SYSTEM_PRIORITY)
end

return rpc