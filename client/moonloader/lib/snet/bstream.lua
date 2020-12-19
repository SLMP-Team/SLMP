local bcoder = require("snet.utilities.bcoder")
local ffi = require("ffi")

local bstream = {}
local bstream_class = {}

bstream_class.bytes = ""
bstream_class.write_ptr = 1
bstream_class.read_ptr = 1

function bstream_class:write(v_type, v)
  if type(v_type) ~= 'string' then return false end

  local before = self.bytes:sub(1, self.write_ptr - 1)
  local after = self.bytes:sub(self.write_ptr, #self.bytes)

  if v_type == BS_STRING then self.bytes = before .. v .. after
  else self.bytes = before .. bcoder.encode(v_type, v) .. after end

  self.write_ptr = self.write_ptr + (v_type == BS_STRING and #v or ffi.sizeof(v_type))
  return true
end

function bstream_class:read(v_type, v_len)
  if type(v_type) ~= 'string' then return false end

  local result = 0
  if v_type == BS_STRING then result = self.bytes:sub(self.read_ptr, self.read_ptr + v_len - 1)
  else result = bcoder.decode(v_type, self.bytes:sub(self.read_ptr, self.read_ptr + ffi.sizeof(v_type) - 1)) end

  self.read_ptr = self.read_ptr + (v_type == BS_STRING and v_len or ffi.sizeof(v_type))
  return result
end

function bstream.new(bytes)
  local new_object = {}
  setmetatable(new_object, {
    __index = bstream_class,
    __tostring = function()
      return "SNET BStream"
    end
  })
  if type(bytes) == "string" then
    new_object.bytes = bytes
  elseif type(bytes) == "SNET BStream" then
    new_object.bytes = bytes.bytes
  end
  return new_object
end

return bstream