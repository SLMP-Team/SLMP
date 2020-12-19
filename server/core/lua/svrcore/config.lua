local config = {}

local default = {
  address = {"*", "string"},
  port = {7777, "number"},
  players = {1, "number"},
  hostname = {"SL:MP Server", "string"},
  gamemode = {"gamemode", "string"},
  scripts = {"", "string"},
  weather = {1, "number"},
  time = {12, "number"},
}

local function check(t)
  if t.players <= 0 or t.players > 65535 then t.players = 65535
  elseif t.port < 0 then t.port = 0 end
  return t
end

function config.init()
  local file = io.open(WORKING_DIRECTORY.."server.cfg", "r")
  local result = {}
  for k, v in pairs(default) do result[k] = v[1] end
  if file then
    for line in file:lines() do
      local key, value = line:match("^(%S+)%s*(.+)")
      if key and value then
        for k, v in pairs(default) do
          if k == key then
            if v[2] == "number" then
              result[k] = tonumber(value) or v[1]
            elseif v[2] == "string" then
              result[k] = tostring(value) or v[1]
            end
          end
        end
      end
    end
    file:close()
  end
  return check(result)
end

return config