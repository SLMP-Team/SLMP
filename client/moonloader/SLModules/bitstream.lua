BitStream = {}
function BitStream:new()
  local bitStream =
  {
    WritePointer = 1,
    ReadPointer = 1,
    StreamData = ''
  }

  function bitStream:writeUInt8(data)
    local wpoint = self.WritePointer
    self.WritePointer = self.WritePointer + 1
    local forward = self.StreamData:sub(wpoint, #self.StreamData)
    self.StreamData = self.StreamData:sub(1, wpoint - 1)
    data = type(data) == 'number' and data or 0
    data = (data >= 0 and data <= 255) and data or 0
    data = Encoder:encodeUInt8(data)
    self.StreamData=self.StreamData..data..forward
  end
  function bitStream:readUInt8()
    local rpoint = self.ReadPointer
    self.ReadPointer = self.ReadPointer + 1
    local data = self.StreamData:sub(rpoint, rpoint)
    data = Encoder:decodeUInt8(data)
    if type(data) == 'number' then
      return data
    end
    return 0
  end
  function bitStream:writeInt8(data)
    data = type(data) == 'number' and data or 0
    data = (data >= -128 and data < 128) and data or 0
    self:writeUInt8(Encoder:Int8ToUInt8(data))
  end
  function bitStream:readInt8()
    local data = self:readUInt8()
    data = Encoder:UInt8ToInt8(data)
    return data
  end
  function bitStream:writeUInt16(data)
    local wpoint = self.WritePointer
    self.WritePointer = self.WritePointer + 2
    local forward = self.StreamData:sub(wpoint, #self.StreamData)
    self.StreamData = self.StreamData:sub(1, wpoint - 1)
    data = type(data) == 'number' and data or 0
    data = (data >= 0 and data <= 65535) and data or 0
    data = Encoder:encodeUInt16(data)
    self.StreamData=self.StreamData..data..forward
  end
  function bitStream:readUInt16()
    local rpoint = self.ReadPointer
    self.ReadPointer = self.ReadPointer + 2
    local data = self.StreamData:sub(rpoint, rpoint+1)
    data = Encoder:decodeUInt16(data)
    if type(data) == 'number' then
      return data
    end
    return 0
  end
  function bitStream:writeInt16(data)
    data = type(data) == 'number' and data or 0
    data = (data >= -32768 and data <= 32767) and data or 0
    self:writeUInt16(Encoder:Int16ToUInt16(data))
  end
  function bitStream:readInt16()
    local data = self:readUInt16()
    data = Encoder:UInt16ToInt16(data)
    return data
  end
  function bitStream:writeUInt32(data)
    local wpoint = self.WritePointer
    self.WritePointer = self.WritePointer + 4
    local forward = self.StreamData:sub(wpoint, #self.StreamData)
    self.StreamData = self.StreamData:sub(1, wpoint - 1)
    data = type(data) == 'number' and data or 0
    data = (data >= 0 and data <= 4294967295) and data or 0
    data = Encoder:encodeUInt32(data)
    self.StreamData=self.StreamData..data..forward
  end
  function bitStream:readUInt32()
    local rpoint = self.ReadPointer
    self.ReadPointer = self.ReadPointer + 4
    local data = self.StreamData:sub(rpoint, rpoint+3)
    data = Encoder:decodeUInt32(data)
    if type(data) == 'number' then
      return data
    end
    return 0
  end
  function bitStream:writeInt32(data)
    data = type(data) == 'number' and data or 0
    data = (data >= -2147483648 and data <= 2147483647) and data or 0
    self:writeUInt32(Encoder:Int32ToUInt32(data))
  end
  function bitStream:readInt32()
    local data = self:readUInt32()
    data = Encoder:UInt32ToInt32(data)
    return data
  end
  function bitStream:writeUInt64(data)
    local wpoint = self.WritePointer
    self.WritePointer = self.WritePointer + 8
    local forward = self.StreamData:sub(wpoint, #self.StreamData)
    self.StreamData = self.StreamData:sub(1, wpoint - 1)
    data = type(data) == 'number' and data or 0
    data = (data >= 0 and data <= 18446744073709551615) and data or 0
    data = Encoder:encodeUInt64(data)
    self.StreamData=self.StreamData..data..forward
  end
  function bitStream:readUInt64()
    local rpoint = self.ReadPointer
    self.ReadPointer = self.ReadPointer + 8
    local data = self.StreamData:sub(rpoint, rpoint+7)
    data = Encoder:decodeUInt64(data)
    if type(data) == 'number' then
      return data
    end
    return 0
  end
  function bitStream:writeInt64(data)
    data = type(data) == 'number' and data or 0
    data = (data >= -9223372036854775808 and data <= 9223372036854775807) and data or 0
    self:writeUInt64(Encoder:Int64ToUInt64(data))
  end
  function bitStream:readInt64()
    local data = self:readUInt64()
    data = Encoder:UInt64ToInt64(data)
    return data
  end
  function bitStream:writeFloat(data)
    local wpoint = self.WritePointer
    self.WritePointer = self.WritePointer + 4
    local forward = self.StreamData:sub(wpoint, #self.StreamData)
    self.StreamData = self.StreamData:sub(1, wpoint - 1)
    data = type(data) == 'number' and data or 0
    data = Encoder:encodeFloat(data)
    self.StreamData=self.StreamData..data..forward
  end
  function bitStream:readFloat()
    local rpoint = self.ReadPointer
    self.ReadPointer = self.ReadPointer + 4
    local data = self.StreamData:sub(rpoint, rpoint+3)
    data = Encoder:decodeFloat(data)
    if type(data) == 'number' then
      return data
    end
    return 0
  end
  function bitStream:writeBool(data)
    local wpoint = self.WritePointer
    self.WritePointer = self.WritePointer + 1
    local forward = self.StreamData:sub(wpoint, #self.StreamData)
    self.StreamData = self.StreamData:sub(1, wpoint - 1)
    data = type(data) == 'boolean' and data or false
    data = Encoder:encodeBool(data)
    self.StreamData=self.StreamData..data..forward
  end
  function bitStream:readBool()
    local rpoint = self.ReadPointer
    self.ReadPointer = self.ReadPointer + 1
    local data = self.StreamData:sub(rpoint, rpoint)
    data = Encoder:decodeBool(data)
    if type(data) == 'boolean' then
      return data
    end
    return false
  end
  function bitStream:writeString(data)
    local wpoint = self.WritePointer
    self.WritePointer = self.WritePointer + data:len()
    local forward = self.StreamData:sub(wpoint, #self.StreamData)
    self.StreamData = self.StreamData:sub(1, wpoint - 1)
    data = type(data) == 'string' and data or '0'
    self.StreamData=self.StreamData..data..forward
  end
  function bitStream:readString(len)
    local rpoint = self.ReadPointer
    self.ReadPointer = self.ReadPointer + len
    local data = self.StreamData:sub(rpoint, rpoint+len-1)
    if type(data) == 'string' then
      return data
    end
    return ' '
  end
  function bitStream:setWritePointer(data)
    data = type(data) == 'number' and data or 1
    data = data <= 0 and 1 or data
    self.WritePointer = data
  end
  function bitStream:setReadPointer(data)
    data = type(data) == 'number' and data or 1
    data = data <= 0 and 1 or data
    self.ReadPointer = data
  end
  function bitStream:getWritePointer()
    return self.WritePointer
  end
  function bitStream:getReadPointer()
    return self.ReadPointer
  end
  function bitStream:export()
    return self.StreamData
  end
  function bitStream:import(data)
    data = type(data) == 'string' and data or ''
    self.StreamData = self.StreamData .. data
  end
  function bitStream:clear()
    self.WritePointer = 1
    self.ReadPointer = 1
    self.StreamData = ''
  end
  return bitStream
end

Socket = {Handle=nil,Connection=false}
function Socket:isConnected()
  return self.Handle ~= nil
end
function Socket:init(host, port)
  host = type(host) == 'string' and host or ''
  port = (type(port) == 'string' or type(port) == 'number') and port or 0
  host = host:match('^%s*(.+)%s*$')
  port = tonumber(port)
  if Socket:isConnected() then
    self.Handle:close()
  end
  self.Handle = socket.udp()
  self.Handle:settimeout(0)
  self.Handle:setpeername(host, port)
  self.Connection = true
end
function Socket:close()
  if not Socket:isConnected() then
    return
  end
  self.Handle:close()
  self.Handle = nil
  self.Connection = false
end
function Socket:send(message)
  if not Socket:isConnected() then
    return
  end
  self.Handle:send(message)
end
function Socket:receive()
  if not Socket:isConnected() then
    return nil
  end
  return self.Handle:receive()
end