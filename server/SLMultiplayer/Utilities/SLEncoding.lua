local encoding = {}

function encoding.Uint8ToBytes(uint8)
  if type(uint8) ~= 'number' then
    return false
  end
  if uint8 > 0xFF or uint8 < 0 then
    return false
  end

  return string.char(bit.band(uint8, 0xFF))
end

function encoding.BytesToUint8(bytes)
  if type(bytes) ~= 'string' then
    return false
  end
  if #bytes == 0 or #bytes > 1 then
    return false
  end

  return string.byte(bytes)
end

function encoding.Uint16ToBytes(uint16)
  if type(uint16) ~= 'number' then
    return false
  end
  if uint16 > 0xFFFF or uint16 < 0 then
    return false
  end

  return string.char(
    bit.band(bit.rshift(uint16, 8), 0xFF),
    bit.band(bit.rshift(uint16, 0), 0xFF)
  )
end

function encoding.BytesToUint16(bytes)
  if type(bytes) ~= 'string' then
    return false
  end
  if #bytes == 0 or #bytes > 3 then
    return false
  end

  local b1, b2 = string.byte(bytes, 1, 2)
  return bit.bor(bit.lshift(b1, 8), b2)
end

function encoding.Uint32ToBytes(uint32)
  if type(uint32) ~= 'number' then
    return false
  end
  if uint32 > 0xFFFFFFFF then
    return false
  end

  return string.char(
    bit.band(bit.rshift(uint32, 24), 0xFF),
    bit.band(bit.rshift(uint32, 16), 0xFF),
    bit.band(bit.rshift(uint32, 8), 0xFF),
    bit.band(bit.rshift(uint32, 0), 0xFF)
  )

end

function encoding.BytesToUint32(bytes)
  if type(bytes) ~= 'string' then
    return false
  end
  if #bytes == 0 or #bytes > 5 then
    return false
  end

  local b1, b2, b3, b4 = string.byte(bytes, 1, 4)
  return bit.bor(bit.lshift(b1, 24), bit.lshift(b2, 16), bit.lshift(b3, 8), b4)

end

return encoding