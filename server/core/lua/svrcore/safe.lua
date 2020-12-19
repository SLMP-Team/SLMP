local newCoroutine, newTable, newString, 
newMath, newIO, newOS = {}, {}, {}, {}, {}, {}
	
setmetatable(newCoroutine, {__index = coroutine})
setmetatable(newTable, {__index = table})
setmetatable(newString, {__index = string})
setmetatable(newMath, {__index = math})
setmetatable(newIO, {__index = io})
setmetatable(newOS, {__index = os})
	
local env = 
{
	assert = assert, error = error, ipairs = ipairs,
	next = next, pairs = pairs, pcall = pcall, print = print,
	select = select, tonumber = tonumber, tostring = tostring,
	type = type, unpack = unpack, _VERSION = _VERSION, xpcall = xpcall,
	coroutine = newCoroutine, table = newTable, string = newString, 
	math = newMath, io = newIO, os = newOS, require = require
}
	
return env