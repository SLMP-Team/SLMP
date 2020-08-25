LEncoder = require("LibDeflate")
json = require("dkjson")

socket = require("socket")
udp = socket.udp()

SInfo =
{
  sVersion = 'SL:MP 0.0.1-Alpha'
}

local doesFileExist = function(file_path)
  local tmp = io.open(file_path, 'r')
  if not tmp then return false end
  tmp:close()
  return true
end
local updateTable = function(default_table, fJson)
	for k, v in pairs(default_table) do
		if type(v) == 'table' then
			if fJson[k] == nil then fJson[k] = {} end
			fJson[k] = updateTable(default_table[k], fJson[k])
		else if fJson[k] == nil then fJson[k] = v end end
	end
	return fJson
end
json.load = function(json_file, default_table)
	if not default_table or type(default_table) ~= 'table' then default_table = {} end 
	if not json_file or not doesFileExist(json_file) then return false end
	local fHandle = io.open(json_file, 'r')
	if not fHandle then return false end
	local fText = fHandle:read('*all') 
	fHandle:close()
	if not fText then return false end
	local fRes, fJson = pcall(json.decode, fText)
	if not fRes or not fJson or type(fJson) ~= 'table' then return false end
	fJson = updateTable(default_table, fJson)
	return fJson
end
json.save = function(json_file, lua_table)
	if not json_file or not lua_table or type(lua_table) ~= 'table' then return false end
	if doesFileExist(json_file) then os.remove(json_file) end
	local fHandle = io.open(json_file, 'w+')
	if not fHandle then return false end
	fHandle:write(json.encode(lua_table))
	fHandle:close()
	return true
end

function getDistBetweenPoints(x1, y1, z1, x2, y2, z2)
  return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end