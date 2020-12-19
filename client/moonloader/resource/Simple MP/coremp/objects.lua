local objects = {}
objects.list = {}

-- 0xFFFF is max objects number, fill values
for i = 1, 0xFFFF do objects.list[i] = 0 end

function objects:new(index, modelid, oX, oY, oZ, rX, rY, rZ)
  self:remove(index) -- delete object if exists
  self.list[index] = {
    modelid = modelid,
    pos = {oX, oY, oZ},
    rot = {rX, rY, rZ},
  }
  print(modelid, oX, oY, oZ)
  requestModel(modelid); loadAllModelsNow()
  self.list[index].handle = createObject(modelid, oX, oY, oZ)
  setObjectRotation(self.list[index].handle, rX, rY, rZ)
  markModelAsNoLongerNeeded(modelid); return true
end

function objects:remove(index)
  if self.list[index] and self.list[index] ~= 0 then
    if doesObjectExist(self.list[index].handle) then
      deleteObject(self.list[index].handle)
    end; self.list[index] = 0
  end; return false
end

function objects.foreach(callback_func)
  for i, v in ipairs(objects.list) do
    if v ~= 0 then
      local res = callback_func(i, v)
      if res ~= nil then return res end
    end
  end
end

addEventHandler("onScriptTerminate", function(script)
  if thisScript() == script then
    objects.foreach(function(i, v)
      objects:remove(i)
    end)
  end
end)

return objects