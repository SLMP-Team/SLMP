function Packet_Connection_Success(bitStream)
  local bs = BitStream:new()
  local playerid = bitStream:readUInt16()
  Server.OnFootRate = bitStream:readUInt16()
  Player.ID = playerid
  General.LastPingTime = os.time()
  bs:writeUInt16(playerid)
  sendPacket(PACKET.CONNECTION_REQUEST_SUCCESS, true, bs)
  Player.GameState = GAMESTATE.CONNECTED
  Graphics.wClient[0] = false
  Graphics.wChat[0] = true
  Graphics.tClientPopupText = 'Connected to server!'
  Game:addChatMessage('Conntected to ' .. Config.serverAddress .. '!', 0xCFCFCFFF)
  setCharProofs(PLAYER_PED, false, false, false, false, false)
  setPlayerControl(PLAYER_HANDLE, true)
  setCharVisible(PLAYER_PED, true)
  local x, y, z = getCharCoordinates(PLAYER_PED)
  setFixedCameraPosition(x, y, z, 0.0, 0.0, 0.0)
  restoreCamera()
  setCameraBehindPlayer()
  displayHud(true); displayRadar(true)
end

function Packet_Connection_Fail(bitStream)
  Player.GameState = GAMESTATE.DISCONNECTED
  Graphics.tClientPopupText = 'Unknown Connection Error, please try connect later.'
  local error = bitStream:readUInt8()
  if error == 1 then Graphics.tClientPopupText = 'The server is full, please try connect later.'
  elseif error == 2 then Graphics.tClientPopupText = 'Incorrect nickname, you allowed to use only a-z, A-Z and 0-9 symbols.'
  elseif error == 3 then Graphics.tClientPopupText = 'Incorrect client version, please check server`s version.'
  elseif error == 4 then Graphics.tClientPopupText = 'User nickname already taken by someone, try to change your nickname.' end
  Game:addChatMessage(Graphics.tClientPopupText, 0x8AFF80FF)
  Game:addChatMessage('Change invalid data and try to connect again.', 0x8AFF80FF)
end

function Packet_Update_Stream(bitStream)
  local who = bitStream:readUInt8()
  if who == 1 then
    local playerid = bitStream:readUInt16()
    local streamed = bitStream:readBool()
    local slot = Players:getSlotByID(playerid)
    if slot ~= -1 then
      if not streamed then
        Players:unspawn(slot)
      else
        local skin = bitStream:readUInt16()
        local health = bitStream:readUInt8()
        Players[slot].armour = bitStream:readUInt8()
        local pos = {}
        for i = 1, 3 do
          pos[i] = bitStream:readFloat()
        end
        local vel = {}
        for i = 1, 3 do
          vel[i] = bitStream:readFloat()
        end
        local quat = {}
        for i = 1, 4 do
          quat[i] = bitStream:readFloat()
        end
        local ang = bitStream:readFloat()
        Players[slot].skin = skin
        Players:spawn(slot)
        setCharHealth(Players[slot].handle, health)
        setCharCoordinates(Players[slot].handle, pos[1], pos[2], pos[3])
        setCharVelocity(Players[slot].handle, vel[1], vel[2], vel[3])
        setCharQuaternion(Players[slot].handle, quat[1], quat[2], quat[3], quat[4])
        setCharHeading(Players[slot].handle, ang)
      end
    end
  end
end

function Packet_OnFoot_Sync(bitStream)
  local playerid = bitStream:readUInt16()
  local slot = Players:getSlotByID(playerid)
  if slot ~= -1 and Players:isSpawned(slot) then
    local health = bitStream:readUInt8()
    Players[slot].armour = bitStream:readUInt8()
    local skin = bitStream:readUInt16()
    if skin ~= Players[slot].skin then
      Players:spawn(slot)
    end
    setCharHealth(Players[slot].handle, health)
    local pos = {}
    for i = 1, 3 do
      pos[i] = bitStream:readFloat()
    end
    setCharCoordinates(Players[slot].handle, pos[1], pos[2], pos[3])
    local vel = {}
    for i = 1, 3 do
      vel[i] = bitStream:readFloat()
    end
    setCharVelocity(Players[slot].handle, vel[1], vel[2], vel[3])
    local quat = {}
    for i = 1, 4 do
      quat[i] = bitStream:readFloat()
    end
    setCharQuaternion(Players[slot].handle, quat[1], quat[2], quat[3], quat[4])
    local ang = bitStream:readFloat()
    setCharHeading(Players[slot].handle, ang)
  end
end

function Packet_Ping_Server(bitStream)
  ClientData.sPing = math.floor((os.clock() - ClientData.sRequestTime) * 1000)
  ClientData.sPlayers[1] = bitStream:readUInt16()
  ClientData.sPlayers[2] = bitStream:readUInt16()
  local len = bitStream:readUInt16()
  ClientData.sName = bitStream:readString(len)
  len = bitStream:readUInt8()
  ClientData.sVersion = bitStream:readString(len)
  len = bitStream:readUInt8()
  ClientData.sLanguage = bitStream:readString(len)
  len = bitStream:readUInt8()
  ClientData.sWebsite = bitStream:readString(len)
  ClientData.sPlayerPool = {}
  for i = 1, ClientData.sPlayers[1] do
    len = bitStream:readUInt8()
    ClientData.sPlayerPool[i] = bitStream:readString(len)
  end
end