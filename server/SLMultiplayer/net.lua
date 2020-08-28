SLNet = 
{
  BitStreams = {}
}
SLNet.getFreeID = function()
  local result, bsID = true, 0
  while result do
    local wasID = false
    bsID = bsID + 1
    for i = 1, #SLNet.BitStreams do
      if SLNet.BitStreams[i].BitStreamID == bsID then
        wasID = true
        break
      end
    end
    if not wasID then
      result = false
    end
  end
  return bsID
end
SLNet.createBitStream = function()
  local bsID = SLNet.getFreeID()
  table.insert(SLNet.BitStreams, bsID, {
    BitStreamID = bsID,
    ReadPointer = 1,
    WritePointer = 1,
    BytesData = {}
  })
  return bsID
end
SLNet.getSlotByID = function(bitStream)
  for i = 1, #SLNet.BitStreams do
    if SLNet.BitStreams[i].BitStreamID == bitStream then
      return i
    end
  end
  return false
end
SLNet.resetReadPointer = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  SLNet.BitStreams[bitStream].ReadPointer = 1
end
SLNet.resetWritePointer = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  SLNet.BitStreams[bitStream].WritePointer = 1
end
SLNet.setWritePointerOffset = function(bitStream, offset)
  bitStream = SLNet.getSlotByID(bitStream)
  SLNet.BitStreams[bitStream].WritePointer = offset
end
SLNet.setReadPointerOffset = function(bitStream, offset)
  bitStream = SLNet.getSlotByID(bitStream)
  SLNet.BitStreams[bitStream].ReadPointer = offset
end
SLNet.deleteBitStream = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  for i = #SLNet.BitStreams, 1, -1 do
    if i == bitStream then
      table.remove(SLNet.BitStreams, i)
    end
  end
end
SLNet.importBytes = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  for i in data:gmatch('[^\\*]+') do
    local slot = #SLNet.BitStreams[bitStream].BytesData
    SLNet.BitStreams[bitStream].BytesData[slot+1] = i
  end
end
SLNet.exportBytes = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local data = ''
  for i, v in pairs(SLNet.BitStreams[bitStream].BytesData) do
    data = data .. v .. '\\*'
  end
  return data
end
SLNet.writeInt8 = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local uint8 = SLEncoder.Int8ToUint8(data)
  local bytes = SLEncoder.Uint8ToBytes(uint8)
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readInt8 = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return SLEncoder.Uint8ToInt8(SLEncoder.BytesToUint8(data))
end
SLNet.writeInt16 = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local uint16 = SLEncoder.Int16ToUint16(data)
  local bytes = SLEncoder.Uint16ToBytes(uint16)
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readInt16 = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return SLEncoder.Uint16ToInt16(SLEncoder.BytesToUint16(data))
end
SLNet.writeInt32 = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local uint32 = SLEncoder.Int32ToUint32(data)
  local bytes = SLEncoder.Uint32ToBytes(uint32)
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readInt32 = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return SLEncoder.Uint32ToInt32(SLEncoder.BytesToUint32(data))
end
SLNet.writeUInt8 = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local bytes = SLEncoder.Uint8ToBytes(data)
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readUInt8 = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return SLEncoder.BytesToUint8(data)
end
SLNet.writeUInt16 = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local bytes = SLEncoder.Uint16ToBytes(data)
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readUInt16 = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return SLEncoder.BytesToUint16(data)
end
SLNet.writeUInt32 = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local bytes = SLEncoder.Uint32ToBytes(data)
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readUInt32 = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return SLEncoder.BytesToUint32(data)
end
SLNet.writeFloat = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local bytes = SLEncoder.FloatToBytes(data)
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readFloat = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return SLEncoder.BytesToFloat(data)
end
SLNet.writeBool = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local bytes = SLEncoder.BoolToBytes(data)
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readBool = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return SLEncoder.BytesToBool(data)
end
SLNet.writeString = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local bytes = tostring(data):gsub('\1', '')
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readString = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return tostring(data)
end
SLNet.writeStringEncoded = function(bitStream, data, encodeLevel)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local bytes = tostring(data):gsub('\1', '')
  bytes = LEncoder:CompressDeflate(bytes, {level = encodeLevel})
  SLNet.BitStreams[bitStream].BytesData[wpoint] = tostring(bytes)
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readStringEncoded = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return tostring(LEncoder:DecompressDeflate(data))
end
SLNet.writeInteger = function(bitStream, data)
  bitStream = SLNet.getSlotByID(bitStream)
  local wpoint = SLNet.BitStreams[bitStream].WritePointer
  local bytes = tostring(tonumber(data))
  SLNet.BitStreams[bitStream].BytesData[wpoint] =  bytes
  SLNet.BitStreams[bitStream].WritePointer = wpoint + 1
end
SLNet.readInteger = function(bitStream)
  bitStream = SLNet.getSlotByID(bitStream)
  local rpoint = SLNet.BitStreams[bitStream].ReadPointer
  local data = SLNet.BitStreams[bitStream].BytesData[rpoint]
  SLNet.BitStreams[bitStream].ReadPointer = rpoint + 1
  return tonumber(data)
end