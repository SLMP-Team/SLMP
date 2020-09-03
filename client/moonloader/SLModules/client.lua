Client = {}
function Client:connect(name)
  if Player.GameState ~= GAMESTATE.DISCONNECTED then
    return
  end
  General.ConnectingTime = os.time()
  Player.GameState = GAMESTATE.CONNECTING
  name = type(name) == 'string' and name or ''
  --[[ip = type(ip) == 'string' and ip or ''
  port = type(port) == 'number' and port or 0
  udp:settimeout(0)
  udp:setpeername(ip, port)]]
  local bitStream = BitStream:new()
  bitStream:writeUInt8(name:len())
  bitStream:writeString(name)
  bitStream:writeInt32(sVolumeToken[0])
  bitStream:writeUInt16(General.Version)
  sendPacket(PACKET.CONNECTION_REQUEST, true, bitStream)
end
function Client:updatePingAndScore()
  if Player.GameState ~= GAMESTATE.CONNECTED then
    return
  end
  if os.time() - General.LastPingTime > 30 then
    Client:disconnect(false, 1)
    Game:addChatMessage('Connection to server lost', 0x939393FF)
    Game:addChatMessage('Use /disconnect to return to menu', 0x939393FF)
    return
  end
  local bitStream = BitStream:new()
  sendRPC(RPC.UPDATE_PING_AND_SCORE, false, bitStream)
end
function Client:sendSync()
  if Player.GameState ~= GAMESTATE.CONNECTED then
    return
  end
  if Player.PlayerState == PLAYERSTATE.ONFOOT then
    local bs = BitStream:new()
    bs:writeUInt8(getCharHealth(PLAYER_PED))
    bs:writeUInt8(getCharArmour(PLAYER_PED))
    local x, y, z = getCharCoordinates(PLAYER_PED)
    bs:writeFloat(x); bs:writeFloat(y); bs:writeFloat(z-1.0)
    x, y, z = getCharVelocity(PLAYER_PED)
    bs:writeFloat(x); bs:writeFloat(y); bs:writeFloat(z)
    x, y, z, w  = getCharQuaternion(PLAYER_PED)
    bs:writeFloat(x); bs:writeFloat(y); bs:writeFloat(z); bs:writeFloat(w)
    bs:writeFloat(getCharHeading(PLAYER_PED))
    sendPacket(PACKET.ONFOOT_SYNC, false, bs)
  end
end
function Client:disconnect(clearCache, reason)
  if clearCache then
    for i = 1, #Players do
      Players:remove(i)
    end
  end
  reason = type(reason) == 'number' and reason or 0
  local bs = BitStream:new()
  bs:writeUInt8(reason)
  sendPacket(PACKET.DISCONNECT_NOTIFICATION, true, bs)
  Player.GameState = GAMESTATE.DISCONNECTED
  udp:settimeout(0)
  udp:setpeername('localhost', 0)
end