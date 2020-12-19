local functions = {}
functions.MAX_PLAYERS = config.players

functions.KEY_FIRE_ALT = 0x10 functions.KEY_ZOOM_IN = 0x20
functions.KEY_ZOOM_OUT = 0x80 functions.KEY_TARGET = 0x40
functions.KEY_LOOK_LEFT = 0x100 functions.KEY_LOOK_RIGHT = 0x200
functions.KEY_YES = 0x800 functions.KEY_NO = 0x400
functions.KEY_VIEW = 0x2000 functions.KEY_JUMP = 0x4000
functions.KEY_ENTER = 0x8000 functions.KEY_SPRINT = 0x10000
functions.KEY_FIRE = 0x20000 functions.KEY_CROUCH = 0x40000
functions.KEY_BACK = 0x80000 functions.KEY_WALK = 0x200000
functions.KEY_LEFT = 0x400000 functions.KEY_RIGHT = 0x800000
functions.KEY_UP = 0x1000000 functions.KEY_DOWN = 0x2000000

local function ctype(data)
  for i, v in ipairs(data) do
    if type(v[1]) ~= v[2] then
      return false
    end
  end; return true
end

local object_class = {}
function object_class:isAvailable()
  local pointer = objects.list[self.objectid]
  if not pointer or pointer == 0 then
    return false
  end; return true
end
function object_class:delete()
  if not self:isAvailable() then return false end
  return objects:delete(self.objectid)
end

local player_class = {}
function player_class:isConnected()
  local pointer = clients.list[self.playerid]
  if pointer == 0 then return false end
  return true
end
function player_class:sendMessage(color, text)
  if type(color) ~= "number" or type(text) ~= "string" then return false end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_UINT32, color)
  data:write(BS_UINT8, #text); data:write(BS_STRING, text)
  rpc.send(rpc["list"]["ID_CLIENT_MESSAGE"], data, address, port)
  return true
end
function player_class:getNickname()
  if not self:isConnected() then return false end
  return clients.list[self.playerid].nickname
end
function player_class:getPosition()
  if not self:isConnected() then return false end
  local poses = clients.list[self.playerid].pos
  return poses[1], poses[2], poses[3]
end
function player_class:getRotation()
  if not self:isConnected() then return false end
  local poses = clients.list[self.playerid].rot
  return poses[1], poses[2], poses[3]
end
function player_class:getQuaternion()
  if not self:isConnected() then return false end
  local poses = clients.list[self.playerid].quat
  return poses[1], poses[2], poses[3], poses[4]
end
function player_class:getVelocity()
  if not self:isConnected() then return false end
  local poses = clients.list[self.playerid].vec
  return poses[1], poses[2], poses[3]
end
function player_class:getState()
  if not self:isConnected() then return false end
  return clients.list[self.playerid].gamestate
end
function player_class:getAddress()
  if not self:isConnected() then return false end
  return clients.list[self.playerid].address
end
function player_class:setWeather(weather)
  if type(weather) ~= "number" then return false end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_UINT8, weather)
  rpc.send(rpc["list"]["ID_UPDAET_WEATHER"], data, address, port)
  return true
end
function player_class:setTime(hour)
  if type(hour) ~= "number" then return false end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_UINT8, hour)
  rpc.send(rpc["list"]["ID_UPDATE_TIME"], data, address, port)
  return true
end
function player_class:setInterior(interior)
  if type(interior) ~= "number" then return false end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_UINT16, interior)
  rpc.send(rpc["list"]["ID_UPDATE_INTERIOR"], data, address, port)
  clients.list[self.playerid].interior = interior
  return true
end
function player_class:setPosition(x, y, z)
  if type(x) ~= "number"
  or type(y) ~= "number"
  or type(z) ~= "number" then
    return false
  end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_FLOAT, x)
  data:write(BS_FLOAT, y); data:write(BS_FLOAT, z)
  rpc.send(rpc["list"]["ID_UPDATE_POSITION"], data, address, port)
  return true
end
function player_class:setAngle(angle)
  angle = angle or 0
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_FLOAT, angle)
  rpc.send(rpc["list"]["ID_UPDATE_ROTATION"], data, address, port)
  return true
end
function player_class:setWorld(world)
  if type(world) ~= "number" then return false end
  if not self:isConnected() then return false end
  clients.list[self.playerid].world = world
  return true
end
function player_class:setSkin(skin)
  if type(skin) ~= "number" then return false end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_UINT16, skin)
  rpc.send(rpc["list"]["ID_UPDATE_SKIN"], data, address, port)
  clients.list[self.playerid].skin = skin
  return true
end
function player_class:toggleSpectating(state)
  if type(state) ~= "boolean" then return false end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_BOOLEAN, state)
  rpc.send(rpc["list"]["ID_TOGGLE_SPECTATE"], data, address, port)
  clients.list[self.playerid].gamestate = state and 2 or 1
  return true
end
function player_class:setCameraPosition(x, y, z)
  if type(x) ~= "number"
  or type(y) ~= "number"
  or type(z) ~= "number" then
    return false
  end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_FLOAT, x)
  data:write(BS_FLOAT, y); data:write(BS_FLOAT, z)
  rpc.send(rpc["list"]["ID_UPDATE_CAMERA_POS"], data, address, port)
  return true
end
function player_class:setCameraLookAt(x, y, z)
  if type(x) ~= "number"
  or type(y) ~= "number"
  or type(z) ~= "number" then
    return false
  end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_FLOAT, x)
  data:write(BS_FLOAT, y); data:write(BS_FLOAT, z)
  rpc.send(rpc["list"]["ID_UPDATE_CAMERA_ROT"], data, address, port)
  return true
end
function player_class:spectatePlayer(playerid)
  if type(playerid) ~= "number" then return false end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_UINT16, playerid)
  if clients.list[playerid] == 0 then return false end
  pointer.pos = clients.list[playerid].pos -- magic
  update_stream(self.playerid) -- magic x2
  rpc.send(rpc["list"]["ID_SPECTATE_PLAYER"], data, address, port)
  return true
end
function player_class:setSpawn(x, y, z)
  if type(x) ~= "number"
  or type(y) ~= "number"
  or type(z) ~= "number" then
    return false
  end
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_FLOAT, x)
  data:write(BS_FLOAT, y); data:write(BS_FLOAT, z)
  rpc.send(rpc["list"]["ID_UPDATE_SPAWN"], data, address, port)
  return true
end
function player_class:showDialog(id, title, text, button1, button2, dtype)
  title = title or ""; text = text or ""; button1 = button1 or ""
  id = id or 0; button2 = button2 or ""; dtype = dtype or 0
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  pointer.last_dialog = id
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_UINT16, id)
  data:write(BS_UINT8, #title); data:write(BS_STRING, title)
  text = strcomp.compress(text)
  data:write(BS_UINT16, #text); data:write(BS_STRING, text)
  data:write(BS_UINT8, #button1); data:write(BS_STRING, button1)
  data:write(BS_UINT8, #button2); data:write(BS_STRING, button2)
  data:write(BS_UINT8, dtype)
  rpc.send(rpc["list"]["ID_SHOW_DIALOG"], data, address, port)
  return true
end
function player_class:toggleControllable(state)
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  local address, port = pointer.address, pointer.port
  local data = bstream.new(); data:write(BS_BOOLEAN, state)
  rpc.send(rpc["list"]["ID_UPDATE_CONTROL"], data, address, port)
  return true
end
function player_class:restoreCamera()
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  rpc.send(rpc["list"]["ID_RESTORE_CAMERA"], nil, pointer.address, pointer.port)
  return true
end
function player_class:setVar(key, value)
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  pointer.vars[key] = value
  return true
end
function player_class:getVar(key)
  if not self:isConnected() then return false end
  local pointer = clients.list[self.playerid]
  return pointer.vars[key] or nil
end

function functions.setWeather(weather)
  if type(weather) ~= "number" then return false end
  config.weather = weather
  for i, v in ipairs(clients.list) do
    local ptr = functions.getPlayerPointer(i)
    if ptr then ptr:setWeather(weather) end
  end; return true
end
function functions.setTime(hour)
  if type(hour) ~= "number" then return false end
  config.time = hour
  for i, v in ipairs(clients.list) do
    local ptr = functions.getPlayerPointer(i)
    if ptr then ptr:setTime(hour) end
  end; return true
end
function functions.sendMessage(color, message)
  for i, v in ipairs(clients.list) do
    local ptr = functions.getPlayerPointer(i)
    if ptr then ptr:sendMessage(color, message) end
  end; return true
end
function functions.getPlayerPointer(playerid)
  if clients.list[playerid] == 0 then
    return false -- player is not connected
  end
  local temp = {}
  setmetatable(temp, {
    __index = player_class,
    __tostring = function()
      return "Player Pointer"
    end
  })
  temp.playerid = playerid
  return temp
end
function functions.createObject(modelid, oX, oY, oZ, rX, rY, rZ, distance)
  local res = ctype({
    {modelid, "number"}, {oX, "number"}, {oY, "number"}, {oZ, "number"},
    {rX, "number"}, {rY, "number"}, {rZ, "number"}, {distance, "number"}
  }); if not res then return false end
  return objects:new(modelid, oX, oY, oZ, rX, rY, rZ, distance)
end
function functions.getObjectPointer(objectid)
  if not objects.list[objectid] or objects.list[objectid] == 0 then
    return false -- object does not exist
  end
  local temp = {}
  setmetatable(temp, {
    __index = object_class,
    __tostring = function()
      return "Object Pointer"
    end
  })
  temp.objectid = objectid
  return temp
end

return functions