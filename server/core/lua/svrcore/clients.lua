local clients = {}
clients.list = {}

function clients.by_address(address, port)
  local res = clients.foreach(function(index, value)
    if value.address == address and
    tonumber(value.port) == tonumber(port) then
      return index
    end
  end); return res or 0
end

function clients.by_nickname(nickname)
  local res = clients.foreach(function(index, value)
    if value.nickname:lower() == nickname:lower() then
      return index
    end
  end); return res or 0
end

function clients.find_free()
  for i, v in ipairs(clients.list) do
    if v == 0 then
      return i
    end
  end; return 0
end

function clients.remove(index)
  clients.list[index] = 0
  -- we can't use table.remove
  -- because it will move indexes
end

function clients.foreach(callback_func)
  for i, v in ipairs(clients.list) do
    if v ~= 0 then
      local res = callback_func(i, v)
      if res ~= nil then return res end
    end
  end
end

function clients.is_streamed(who, for_whom)
  for i, v in ipairs(clients.list[for_whom].stream.players) do
    if v == who then return true end
  end; return false
end

function clients.is_streamed_object(objectid, for_whom)
  for i, v in ipairs(clients.list[for_whom].stream.objects) do
    if v == objectid then return true end
  end; return false
end

return clients