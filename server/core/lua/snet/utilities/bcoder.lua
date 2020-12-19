local ffi = require("ffi")
local bcoder = {}

-- Types Definition
BS_INT8 = "int8_t"
BS_INT16 = "int16_t"
BS_INT32 = "int32_t"
BS_UINT8 = "uint8_t"
BS_UINT16 = "uint16_t"
BS_UINT32 = "uint32_t"
BS_FLOAT = "float"
BS_BOOLEAN = "bool"
BS_STRING = "string"

local function set_value(v_type, v)
  local ptr = ffi.new(v_type .. "[1]", v)
  return ffi.string(ffi.cast("const char *", ptr), ffi.sizeof(v_type))
end

function bcoder.encode(v_type, v)
  if type(v_type) ~= "string" then return "\0" end
  return set_value(v_type, v)
end

local function get_value(v_type, v)
  local v_size = ffi.sizeof(v_type)
  local ptr = ffi.new("char[?]", v_size, v:byte(1, v_size))
  return ffi.cast(v_type .. "*", ptr)[0]
end

function bcoder.decode(v_type, v)
  if type(v_type) ~= "string" then return false end
  if not v then return ffi.cast(v_type .. "*", 0)[0] end
  return get_value(v_type, v)
end

return bcoder