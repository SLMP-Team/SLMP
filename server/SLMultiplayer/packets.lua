function Packet_Connect(bitStream, pAddress, pPort)
  local pData = {}
  pData.nickname = SLNet.readString(bitStream)
  pData.token = SLNet.readUInt32(bitStream)
  pData.version = SLNet.readString(bitStream)

  local bs = SLNet.createBitStream()

  print(string.format('[PLAYER] %s:%s trying to connect to server', pAddress, pPort))
  if type(pData.nickname) ~= 'string' or type(pData.version) ~= 'string' or type(pData.token) ~= 'number'then
    SLNet.writeInt16(bs, S_PACKETS.CONNECTION_FAIL)
    SLNet.writeInt8(bs, 1)
    SPool.sendPacket(bs, pAddress, pPort)
    SLNet.deleteBitStream(bs)
    return false
  elseif pData.nickname:len() < 1 or pData.nickname:len() > 24 then
    SLNet.writeInt16(bs, S_PACKETS.CONNECTION_FAIL)
    SLNet.writeInt8(bs, 2)
    SPool.sendPacket(bs, pAddress, pPort)
    SLNet.deleteBitStream(bs)
    return false
  elseif not pData.nickname:match('^[a-zA-Z0-9]+$') then
    SLNet.writeInt16(bs, S_PACKETS.CONNECTION_FAIL)
    SLNet.writeInt8(bs, 3)
    SPool.sendPacket(bs, pAddress, pPort)
    SLNet.deleteBitStream(bs)
    return false
  elseif #SPool.sPlayers >= SConfig.maxSlots then
    SLNet.writeInt16(bs, S_PACKETS.CONNECTION_FAIL)
    SLNet.writeInt8(bs, 4)
    SPool.sendPacket(bs, pAddress, pPort)
    SLNet.deleteBitStream(bs)
    return false
  elseif pData.version ~= SInfo.sVersion then
    SLNet.writeInt16(bs, S_PACKETS.CONNECTION_FAIL)
    SLNet.writeInt8(bs, 5)
    SPool.sendPacket(bs, pAddress, pPort)
    SLNet.deleteBitStream(bs)
    return false
  end
  for i = 1, #SPool.sPlayers do
    if pData.nickname:lower() == SPool.sPlayers[i].nickname:lower() then
      SLNet.writeInt16(bs, S_PACKETS.CONNECTION_FAIL)
      SLNet.writeInt8(bs, 6)
      SPool.sendPacket(bs, pAddress, pPort)
      SLNet.deleteBitStream(bs)
      return false
    end
  end
  local playerid = SPool.findFreePlayerId()
  SLNet.writeInt16(bs, S_PACKETS.CONNECTION_SUCCESS)
  SLNet.writeInt16(bs, playerid)
  SPool.sendPacket(bs, pAddress, pPort)
  SLNet.deleteBitStream(bs)
  local slot = #SPool.sPlayers + 1
  SPool.sPlayers[slot] =
  {
    playerid = playerid,
    nickname = pData.nickname,
    token = pData.token,
    bindedIP = pAddress or '',
    bindedPort = pPort or 0,
    ping = 999, 
    ltPingUpdate = os.time(),
    ltPingBackMS = os.clock(),
    ltPingServer = os.time(),
    position = {0.0, 0.0, 0.0},
    quaternion = {0.0, 0.0, 0.0, 0.0},
    velocity = {0.0, 0.0, 0.0},
    facingAngle = 0.0,
    health = 100.0,
    armour = 0.0,
    skin = 0,
    stream = 
    {
      players = {}, 
      vehicles = {}
    },
    playerState = S_PLAYERSTATE.PS_ONFOOT,
    vehicleID = 0, vehicleSeatID = 0
  }
  bs = {}
  bs[1] = SLNet.createBitStream()
  bs[2] = SLNet.createBitStream()
  SLNet.writeInt16(bs[1], S_RPC.PLAYER_JOIN)
  SLNet.writeInt16(bs[2], S_RPC.PLAYER_JOIN)
  SLNet.writeInt16(bs[2], playerid)
  SLNet.writeString(bs[2], pData.nickname)
  
  for i = 1, #SPool.sPlayers do
    SLNet.setWritePointerOffset(bs[1], 2)
    SLNet.writeInt16(bs[1], SPool.sPlayers[i].playerid)
    SLNet.writeString(bs[1], SPool.sPlayers[i].nickname)
    SPool.sendRPC(bs[1], pAddress, pPort)
    if SPool.sPlayers[i].bindedIP ~= pAddress 
    or SPool.sPlayers[i].bindedPort ~= pPort then
      SPool.sendRPC(bs[2], SPool.sPlayers[i].bindedIP, 
      SPool.sPlayers[i].bindedPort)
    end
  end
  SLNet.deleteBitStream(bs[1])
  SLNet.deleteBitStream(bs[2])

  bs = SLNet.createBitStream()
  SLNet.writeInt16(bs, S_RPC.CREATE_VEHICLE)
  for i = 1, #SPool.sVehicles do
    SLNet.setWritePointerOffset(bs, 2)
    SLNet.writeInt16(bs, SPool.sVehicles[i].vehicleid)
    SLNet.writeInt16(bs, SPool.sVehicles[i].model)
    SLNet.writeInt16(bs, SPool.sVehicles[i].colors[1])
    SLNet.writeInt16(bs, SPool.sVehicles[i].colors[2])
    SPool.sendRPC(bs, pAddress, pPort)
  end
  SLNet.deleteBitStream(bs)
  print(string.format('[PLAYER] %s [%s:%s:%s] connected to server', pData.nickname, pAddress, pPort, playerid))
  pcall(onPlayerConnect, playerid)
  return true
end

function Packet_OnFoot(bitStream, pAddress, pPort)
  local connected, clientID = SPool.getClient(pAddress, pPort)
  if not connected then return false end
  
  if SPool.sPlayers[clientID].playerState ~= S_PLAYERSTATE.PS_ONFOOT then
    return false
  end

  local pData = {}
  pData.health = SLNet.readInt8(bitStream)
  pData.armour = SLNet.readInt8(bitStream)
  pData.position =
  {
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream)
  }
  pData.quaternion =
  {
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream)
  }
  pData.velocity =
  {
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream)
  }
  pData.facingAngle = SLNet.readFloat(bitStream)

  SPool.sPlayers[clientID].position = pData.position
  SPool.sPlayers[clientID].quaternion = pData.quaternion
  SPool.sPlayers[clientID].velocity = pData.velocity
  SPool.sPlayers[clientID].health = pData.health
  SPool.sPlayers[clientID].armour = pData.armour
  SPool.sPlayers[clientID].facingAngle = pData.facingAngle

  for i = 1, #SPool.sVehicles do
    local dist = getDistBetweenPoints(pData.position[1], pData.position[2], pData.position[3],
    SPool.sVehicles[i].position[1], SPool.sVehicles[i].position[2], SPool.sVehicles[i].position[3])
    local wereStreamed = false
    for ii = 1, #SPool.sVehicles[i].streamedFor do
      if SPool.sVehicles[i].streamedFor[ii] == SPool.sPlayers[clientID].playerid then
        wereStreamed = true
        break
      end
    end

    local bs = SLNet.createBitStream()
    SLNet.writeInt16(bs, S_PACKETS.VEHICLES_SYNC)
    if dist > SConfig.streamDistance and wereStreamed then
      SLNet.writeInt16(bs, SPool.sVehicles[i].vehicleid)
      SLNet.writeBool(bs, false)
      SPool.sendPacket(bs, pAddress, pPort)
      for ii = #SPool.sVehicles[i].streamedFor, 1, -1 do
        if SPool.sVehicles[i].streamedFor[ii] == SPool.sPlayers[clientID].playerid then
          table.remove(SPool.sVehicles[i].streamedFor, ii)
        end
      end
    elseif dist <= SConfig.streamDistance and not wereStreamed then
      SLNet.writeInt16(bs, SPool.sVehicles[i].vehicleid)
      SLNet.writeBool(bs, true)
      SLNet.writeFloat(bs, SPool.sVehicles[i].position[1])
      SLNet.writeFloat(bs, SPool.sVehicles[i].position[2])
      SLNet.writeFloat(bs, SPool.sVehicles[i].position[3])
      SLNet.writeFloat(bs, SPool.sVehicles[i].quaternion[1])
      SLNet.writeFloat(bs, SPool.sVehicles[i].quaternion[2])
      SLNet.writeFloat(bs, SPool.sVehicles[i].quaternion[3])
      SLNet.writeFloat(bs, SPool.sVehicles[i].quaternion[4])
      SLNet.writeFloat(bs, SPool.sVehicles[i].facingAngle)
      SLNet.writeFloat(bs, SPool.sVehicles[i].roll)
      SLNet.writeInt16(bs, SPool.sVehicles[i].health)
      SPool.sendPacket(bs, pAddress, pPort)
      table.insert(SPool.sVehicles[i].streamedFor, SPool.sPlayers[clientID].playerid)
    end
    SLNet.deleteBitStream(bs)
  end

  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[clientID].playerid ~= SPool.sPlayers[i].playerid then
      local dist = getDistBetweenPoints(pData.position[1], pData.position[2], pData.position[3],
      SPool.sPlayers[i].position[1], SPool.sPlayers[i].position[2], SPool.sPlayers[i].position[3])
      if dist > SConfig.streamDistance then
        local wereStreamed = false
        for ii = #SPool.sPlayers[i].stream.players, 1, -1 do
          if SPool.sPlayers[i].stream.players[ii] == SPool.sPlayers[clientID].playerid then
            wereStreamed = true
            table.remove(SPool.sPlayers[i].stream.players, ii)
            break
          end
        end
        if wereStreamed then
          local bs = SLNet.createBitStream()
          SLNet.writeInt16(bs, S_PACKETS.ONFOOT_SYNC)
          SLNet.writeInt16(bs, SPool.sPlayers[clientID].playerid)
          SLNet.writeBool(bs, false)
          SPool.sendPacket(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
          SLNet.deleteBitStream(bs)
        end
      else
        local bs = SLNet.createBitStream()
        SLNet.writeInt16(bs, S_PACKETS.ONFOOT_SYNC)
        SLNet.writeInt16(bs, SPool.sPlayers[clientID].playerid)
        SLNet.writeBool(bs, true)
        SLNet.writeInt8(bs, pData.health)
        SLNet.writeInt8(bs, pData.armour)
        SLNet.writeInt16(bs, SPool.sPlayers[clientID].skin)
        SLNet.writeFloat(bs, pData.position[1])
        SLNet.writeFloat(bs, pData.position[2])
        SLNet.writeFloat(bs, pData.position[3])
        SLNet.writeFloat(bs, pData.quaternion[1])
        SLNet.writeFloat(bs, pData.quaternion[2])
        SLNet.writeFloat(bs, pData.quaternion[3])
        SLNet.writeFloat(bs, pData.quaternion[4])
        SLNet.writeFloat(bs, pData.velocity[1])
        SLNet.writeFloat(bs, pData.velocity[2])
        SLNet.writeFloat(bs, pData.velocity[3])
        SLNet.writeFloat(bs, pData.facingAngle)
        SPool.sendPacket(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
        SLNet.deleteBitStream(bs)
        local wereStreamed = false
        for ii = #SPool.sPlayers[i].stream.players, 1, -1 do
          if SPool.sPlayers[i].stream.players[ii] == SPool.sPlayers[clientID].playerid then
            wereStreamed = true
            break
          end
        end
        if not wereStreamed then
          table.insert(SPool.sPlayers[i].stream.players, SPool.sPlayers[clientID].playerid)
        end
      end
    end
  end
  return true
end

function Packet_UnoccupiedSync(bitStream, pAddress, pPort)
  local connected, clientID = SPool.getClient(pAddress, pPort)
  if not connected then return false end

  local pData = {}
  pData.vehicleid = SLNet.readInt16(bitStream)
  pData.position = 
  {
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream)
  }
  pData.quaternion = 
  {
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream)
  }
  pData.facingAngle = SLNet.readFloat(bitStream)
  pData.roll = SLNet.readFloat(bitStream)

  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].vehicleID == pData.vehicleid and SPool.sPlayers[i].vehicleSeatID == 0 then
      return false
    end
  end

  local car = -1
  for i = 1, #SPool.sVehicles do
    if SPool.sVehicles[i].vehicleid == pData.vehicleid then
      car = i
      break
    end
  end
  if car == -1 then return false end
  if SPool.sVehicles[car].position == pData.position then
    return false 
  end
  SPool.sVehicles[car].position = pData.position

  for i = 1, #SPool.sPlayers do
    if i ~= clientID then
      local dist = getDistBetweenPoints(pData.position[1], pData.position[2], pData.position[3],
      SPool.sPlayers[i].position[1], SPool.sPlayers[i].position[2], SPool.sPlayers[i].position[3])
      if dist <= SConfig.streamDistance then
        local bs = SLNet.createBitStream()
        SLNet.writeInt16(bs, S_PACKETS.UNOCCUPIED_SYNC)
        SLNet.writeInt16(bs, pData.vehicleid)
        SLNet.writeFloat(bs, pData.position[1])
        SLNet.writeFloat(bs, pData.position[2])
        SLNet.writeFloat(bs, pData.position[3])
        SLNet.writeFloat(bs, pData.quaternion[1])
        SLNet.writeFloat(bs, pData.quaternion[2])
        SLNet.writeFloat(bs, pData.quaternion[3])
        SLNet.writeFloat(bs, pData.quaternion[4])
        SLNet.writeFloat(bs, pData.facingAngle)
        SLNet.writeFloat(bs, pData.roll)
        SPool.sendPacket(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
        SLNet.deleteBitStream(bs)
      end
    end
  end

  return true
end

function Packet_InCar(bitStream, pAddress, pPort)
  local connected, clientID = SPool.getClient(pAddress, pPort)
  if not connected then return false end

  if SPool.sPlayers[clientID].playerState == S_PLAYERSTATE.PS_ONFOOT then
    return false
  end

  local pData = {}
  pData.vehicleid = SLNet.readInt16(bitStream)
  pData.seatID = SLNet.readInt8(bitStream)
  pData.pHealth = SLNet.readInt8(bitStream)
  pData.armour = SLNet.readInt8(bitStream)
  pData.position = 
  {
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream),
    SLNet.readFloat(bitStream)
  }
  if pData.seatID < 1 then
    pData.health = SLNet.readInt16(bitStream)
    pData.quaternion = 
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
    pData.velocity = 
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
    pData.facingAngle = SLNet.readFloat(bitStream)
    pData.roll = SLNet.readFloat(bitStream)
  end

  local car = -1
  for i = 1, #SPool.sVehicles do
    if SPool.sVehicles[i].vehicleid == pData.vehicleid then
      car = i
      break
    end
  end
  if car == -1 then return false end

  SPool.sPlayers[clientID].position = pData.position
  SPool.sPlayers[clientID].health = pData.pHealth
  SPool.sPlayers[clientID].armour = pData.armour
  SPool.sVehicles[car].position = pData.position
  SPool.sVehicles[car].quaternion = pData.quaternion
  SPool.sVehicles[car].roll = pData.roll
  SPool.sVehicles[car].facingAngle = pData.facingAngle
  SPool.sVehicles[car].health = pData.health

  for i = 1, #SPool.sVehicles do
    local dist = getDistBetweenPoints(pData.position[1], pData.position[2], pData.position[3],
    SPool.sVehicles[i].position[1], SPool.sVehicles[i].position[2], SPool.sVehicles[i].position[3])
    local wereStreamed = false
    for ii = 1, #SPool.sVehicles[i].streamedFor do
      if SPool.sVehicles[i].streamedFor[ii] == SPool.sPlayers[clientID].playerid then
        wereStreamed = true
        break
      end
    end

    local bs = SLNet.createBitStream()
    SLNet.writeInt16(bs, S_PACKETS.VEHICLES_SYNC)
    if dist > SConfig.streamDistance and wereStreamed then
      SLNet.writeInt16(bs, SPool.sVehicles[i].vehicleid)
      SLNet.writeBool(bs, false)
      SPool.sendPacket(bs, pAddress, pPort)
      for ii = #SPool.sVehicles[i].streamedFor, 1, -1 do
        if SPool.sVehicles[i].streamedFor[ii] == SPool.sPlayers[clientID].playerid then
          table.remove(SPool.sVehicles[i].streamedFor, ii)
        end
      end
    elseif dist <= SConfig.streamDistance and not wereStreamed then
      SLNet.writeInt16(bs, SPool.sVehicles[i].vehicleid)
      SLNet.writeBool(bs, true)
      SLNet.writeFloat(bs, SPool.sVehicles[i].position[1])
      SLNet.writeFloat(bs, SPool.sVehicles[i].position[2])
      SLNet.writeFloat(bs, SPool.sVehicles[i].position[3])
      SLNet.writeFloat(bs, SPool.sVehicles[i].quaternion[1])
      SLNet.writeFloat(bs, SPool.sVehicles[i].quaternion[2])
      SLNet.writeFloat(bs, SPool.sVehicles[i].quaternion[3])
      SLNet.writeFloat(bs, SPool.sVehicles[i].quaternion[4])
      SLNet.writeFloat(bs, SPool.sVehicles[i].facingAngle)
      SLNet.writeFloat(bs, SPool.sVehicles[i].roll)
      SLNet.writeInt16(bs, SPool.sVehicles[i].health)
      SPool.sendPacket(bs, pAddress, pPort)
      table.insert(SPool.sVehicles[i].streamedFor, SPool.sPlayers[clientID].playerid)
    end
    SLNet.deleteBitStream(bs)
  end

  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[clientID].playerid ~= SPool.sPlayers[i].playerid then

      local dist = getDistBetweenPoints(pData.position[1], pData.position[2], pData.position[3],
      SPool.sPlayers[i].position[1], SPool.sPlayers[i].position[2], SPool.sPlayers[i].position[3])
      if dist > SConfig.streamDistance then
        local wereStreamed = false
        for ii = #SPool.sPlayers[i].stream.players, 1, -1 do
          if SPool.sPlayers[i].stream.players[ii] == SPool.sPlayers[clientID].playerid then
            wereStreamed = true
            table.remove(SPool.sPlayers[i].stream.players, ii)
            break
          end
        end
        if wereStreamed then
          local bs = SLNet.createBitStream()
          SLNet.writeInt16(bs, S_PACKETS.INCAR_SYNC)
          SLNet.writeInt16(bs, SPool.sPlayers[clientID].playerid)
          SLNet.writeBool(bs, false)
          SPool.sendPacket(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
          SLNet.deleteBitStream(bs)
        end
      else
        local bs = SLNet.createBitStream()
        SLNet.writeInt16(bs, S_PACKETS.INCAR_SYNC)
        SLNet.writeInt16(bs, SPool.sPlayers[clientID].playerid)
        SLNet.writeBool(bs, true)
        SLNet.writeInt8(bs, pData.pHealth)
        SLNet.writeInt8(bs, pData.armour)
        SLNet.writeInt16(bs, SPool.sPlayers[clientID].skin)
        SLNet.writeInt16(bs, pData.vehicleid)
        SLNet.writeInt8(bs, pData.seatID)
        SLNet.writeInt16(bs, pData.health)
        SLNet.writeFloat(bs, pData.position[1])
        SLNet.writeFloat(bs, pData.position[2])
        SLNet.writeFloat(bs, pData.position[3])
        SLNet.writeFloat(bs, pData.quaternion[1])
        SLNet.writeFloat(bs, pData.quaternion[2])
        SLNet.writeFloat(bs, pData.quaternion[3])
        SLNet.writeFloat(bs, pData.quaternion[4])
        SLNet.writeFloat(bs, pData.velocity[1])
        SLNet.writeFloat(bs, pData.velocity[2])
        SLNet.writeFloat(bs, pData.velocity[3])
        SLNet.writeFloat(bs, pData.facingAngle)
        SLNet.writeFloat(bs, pData.roll)
        SPool.sendPacket(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
        SLNet.deleteBitStream(bs)
        local wereStreamed = false
        for ii = #SPool.sPlayers[i].stream.players, 1, -1 do
          if SPool.sPlayers[i].stream.players[ii] == SPool.sPlayers[clientID].playerid then
            wereStreamed = true
            break
          end
        end
        if not wereStreamed then
          table.insert(SPool.sPlayers[i].stream.players, SPool.sPlayers[clientID].playerid)
        end
      end

    end
  end

  return true
end

function Packet_Disconnect(bitStream, pAddress, pPort)
  local connected, clientID = SPool.getClient(pAddress, pPort)
  if not connected then return false end

  local pData = {}
  pData.reason = SLNet.readInt8(bitStream)

  print(string.format('[PLAYER] %s [%s:%s:%s] disconnected from server', SPool.sPlayers[clientID].nickname, SPool.sPlayers[clientID].bindedIP, SPool.sPlayers[clientID].bindedPort, pData.reason))
  for i = 1, #SPool.sPlayers do
    local bs = SLNet.createBitStream()
    SLNet.writeInt16(bs, S_RPC.PLAYER_LEAVE)
    SLNet.writeInt16(bs, SPool.sPlayers[clientID].playerid)
    SPool.sendRPC(bs, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
    SLNet.deleteBitStream(bs)
  end
  pcall(onPlayerDisconnect, SPool.sPlayers[clientID].playerid, pData.reason)
  for i = 1, #SPool.sVehicles do
    for ii = #SPool.sVehicles[i].streamedFor, 1, -1 do
      if SPool.sVehicles[i].streamedFor[ii] == SPool.sPlayers[clientID].playerid then
        table.remove(SPool.sVehicles[i].streamedFor, ii)
        break
      end
    end
  end
  for i = #SPool.sPlayers, 1, -1 do
    if i == clientID then
      table.remove(SPool.sPlayers, clientID)
    end
  end
  return true
end