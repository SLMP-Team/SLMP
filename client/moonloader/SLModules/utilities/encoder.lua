-- Data to Bytes Encoder
-- Thanks for help to Akionka

Encoder = {}
function Encoder:UInt8ToInt8(data)
  if data > 0xFF then
    return data
  end
  return (data - bit.band(data, 128) * 2)
end
function Encoder:Int8ToUInt8(data)
  if data < -128 or data > 127 then
    return data
  end
  return bit.band(data, 0xFF)
end
function Encoder:UInt16ToInt16(data)
  if data > 0xFFFF then
    return data
  end
  return (data - bit.band(data, 32768) * 2)
end
function Encoder:Int16ToUInt16(data)
  if data < -32768 or data > 32767 then
    return data
  end
  return bit.band(data, 0xFFFF)
end
function Encoder:UInt32ToInt32(data)
  if data > 0xFFFFFFFF then
    return data
  end
  return (data - bit.band(data, 2147483648) * 2)
end
function Encoder:Int32ToUInt32(data)
  if data < -2147483648 or data > 2147483647 then
    return data
  end
  return bit.band(data, 0xFFFFFFFF)
end
function Encoder:UInt64ToInt64(data)
  if data > 0xFFFFFFFF then
    return data
  end
  return (data - bit.band(data, 9223372036854775808) * 2)
end
function Encoder:Int64ToUInt64(data)
  if data < -9223372036854775808 or data > 9223372036854775807 then
    return data
  end
  return bit.band(data, 0xFFFFFFFFFFFFFFFF)
end
function Encoder:encodeUInt8(data)
  data = (type(data) == 'number' and data or 0)
  if data > 0xFF or data < 0 then
    return ''
  end
  return string.char(bit.band(data, 0xFF))
end
function Encoder:decodeUInt8(data)
  data = (type(data) == 'string' and data or '')
  if #data == 0 or #data > 1 then
    return 0
  end
  return string.byte(data)
end
function Encoder:encodeUInt16(data)
  data = (type(data) == 'number' and data or 0)
  if data > 0xFFFF or data < 0 then
    return ''
  end
  return string.char(
    bit.band(bit.rshift(data, 8), 0xFF),
    bit.band(bit.rshift(data, 0), 0xFF)
  )
end
function Encoder:decodeUInt16(data)
  data = (type(data) == 'string' and data or '')
  if #data == 0 or #data > 2 then
    return 0
  end
  local b1, b2 = string.byte(data, 1, 2)
  return bit.bor(bit.lshift(b1, 8), b2)
end
function Encoder:encodeUInt32(data)
  data = (type(data) == 'number' and data or 0)
  if data > 0xFFFFFFFF or data < 0 then
    return ''
  end
  return string.char(
    bit.band(bit.rshift(data, 24), 0xFF),
    bit.band(bit.rshift(data, 16), 0xFF),
    bit.band(bit.rshift(data, 8), 0xFF),
    bit.band(bit.rshift(data, 0), 0xFF)
  )
end
function Encoder:decodeUInt32(data)
  data = (type(data) == 'string' and data or '')
  if #data == 0 or #data > 4 then
    return 0
  end
  local b1, b2, b3, b4 = string.byte(data, 1, 4)
  return bit.bor(bit.lshift(b1, 24), bit.lshift(b2, 16), bit.lshift(b3, 8), b4)
end
function Encoder:encodeUInt64(data)
  data = (type(data) == 'number' and data or 0)
  if data < 0 then
    return ''
  end
  return string.char(
    bit.band(bit.rshift(data, 56), 0xFF),
    bit.band(bit.rshift(data, 48), 0xFF),
    bit.band(bit.rshift(data, 40), 0xFF),
    bit.band(bit.rshift(data, 32), 0xFF),
    bit.band(bit.rshift(data, 24), 0xFF),
    bit.band(bit.rshift(data, 16), 0xFF),
    bit.band(bit.rshift(data, 8), 0xFF),
    bit.band(bit.rshift(data, 0), 0xFF)
  )
end
function Encoder:decodeUInt64(data)
  data = (type(data) == 'string' and data or '')
  if #data == 0 or #data > 8 then
    return 0
  end
  local b1, b2, b3, b4, b5, b6, b7, b8 = string.byte(data, 1, 8)
  return bit.bor(bit.lshift(b1, 56), bit.lshift(b2, 48), bit.lshift(b3, 40),
  bit.lshift(b4, 32), bit.lshift(b5, 24), bit.lshift(b6, 16), bit.lshift(b7, 8), b8)
end
function Encoder:encodeFloat(float)
  local function grabByte(v)
    return math.floor(v / 256), string.char(math.floor(v) % 256)
  end
  float = type(float) == 'number' and float or 0.0
  local sign = 0
  if float < 0 then
    sign = 1;
    float = -float
  end
  local mantissa, exponent = math.frexp(float)
  if float == 0 then
    mantissa = 0
    exponent = 0
  else
    mantissa = (mantissa * 2 - 1) * 8388608
    exponent = exponent + 126
  end
  local v, byte = ''
  float, byte = grabByte(mantissa); v = v..byte
  float, byte = grabByte(float); v = v..byte
  float, byte = grabByte(exponent * 128 + float); v = v..byte
  float, byte = grabByte(sign * 128 + float); v = v..byte
  return v
end
function Encoder:decodeFloat(bytes)
  bytes = type(bytes) == 'string' and bytes or ''
  if #bytes == 0 then
    return 0.0
  end
  local sign = 1
  local mantissa = string.byte(bytes, 3) % 128
  for i = 2, 1, -1 do
    mantissa = mantissa * 256 + string.byte(bytes, i)
  end
  if string.byte(bytes, 4) > 127 then
    sign = -1
  end
  local exponent = (string.byte(bytes, 4) % 128) * 2 + math.floor(string.byte(bytes, 3) / 128)
  if exponent == 0 then
    return 0
  end
  mantissa = (math.ldexp(mantissa, -23) + 1) * sign
  return math.ldexp(mantissa, exponent - 127)
end
function Encoder:encodeBool(data)
  data = type(data) == 'boolean' and data or false
  return self:encodeUInt8(data and 1 or 0)
end
function Encoder:decodeBool(data)
  data = type(data) == 'string' and data or ''
  if #data == 0 then
    return false
  end
  return Encoder:decodeUInt8(data) == 1
end