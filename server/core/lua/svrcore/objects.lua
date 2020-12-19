local objects = {}
objects.list = {}

local function find_free()
  for i, v in ipairs(objects.list) do
    if v == 0 then
      return i
    end
  end; return #objects.list + 1
end

function objects:delete(objectid)
  if self.list[objectid] then
    self.list[objectid] = 0
    return true
  end; return false
end

function objects:new(modelid, oX, oY, oZ, rX, rY, rZ, distance)
  local objectid = find_free()
  self.list[objectid] = {
    modelid = modelid,
    pos = {oX, oY, oZ},
    rot = {rX, rY, rZ},
    stream_dist = distance,
    world = -1, interior = -1,
  }; return objectid
end

function objects.foreach(callback_func)
  for i, v in ipairs(objects.list) do
    if v ~= 0 then
      local res = callback_func(i, v)
      if res ~= nil then return res end
    end
  end
end

return objects