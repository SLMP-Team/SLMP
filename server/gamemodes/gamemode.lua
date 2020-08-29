function onGamemodeInit()
  print('Gamemode loaded successfully!')
  createVehicle(400, -9.9193, 40.6951, 3.1096, 0, 0)
  local car = createVehicle(400, -9.9193, 40.6951, 3.1096, 0, 0)
  setVehicleVirtualWorld(car, 5)
  createVehicle(484, -258.6933, -352.0168, 1.8031, 0, 0)
  createVehicle(484, -242.0115, -367.5419, 1.3931, 0, 0)
  setTimer((60*1000), true, sendClientMessageToAll, 'Спасибо, что играете на нашем сервере!', 0xFFFF00FF)
  -- Таймеры временно не работают :з
end

local playerVehicles = {}

function onPlayerConnect(playerid)
  playerVehicles[playerid] = createVehicle(487, math.random(0, 50), math.random(0, 50), 2.0, 1, 1)
  sendClientMessage(playerid, '{FF0000}Добро {28B463FF}пожаловать {F4D03FFF}на сервер!', 0xFFFFFFFF)
  sendClientMessageToAll('{FF0000}' .. getPlayerName(playerid) .. ' {FFFFFF}залетел на наш сервер!', 0xFF0000FF)
end

function onPlayerSpawn(playerid)
  setPlayerSkin(playerid, math.random(14, 18))
  setPlayerPos(playerid, math.random(0, 50), math.random(0, 50), 2.0)
end

function onPlayerDisconnect(playerid, reason)
  if playerVehicles[playerid] then
    destroyVehicle(playerVehicles[playerid])
  end
  sendClientMessageToAll('{FF0000}' .. getPlayerName(playerid) .. ' принял Ислам и вышел с сервера!', 0xFF0000FF)
end

function onPlayerChat(playerid, message)
  sendClientMessageToAll('[' .. getPlayerName(playerid) .. ']: {919191}' .. message, 0xFFFFFFFF)
end

function onPlayerCommand(playerid, command)
  if command == 'help' then
    sendClientMessage(playerid, '{FFFFFF}Прости! Кажется, помощи нет, тебя обманули!', 0xFFFFFFFF)
    return true
  elseif command == 'kickme' then
    sendClientMessage(playerid, '{FFFFFF}Вы были кикнуты с сервера по вашему желанию!', 0xFFFFFFFF)
    kickPlayer(playerid)
    return true
  elseif command == 'freezeme' then
    sendClientMessage(playerid, 'Вы заморожены!', 0xFFFFFFFF)
    setPlayerControlable(playerid, false)
    return true
  elseif command == 'unfreezeme' then
    sendClientMessage(playerid, 'Вы разморожены!', 0xFFFFFFFF)
    setPlayerControlable(playerid, true)
    return true
  elseif command:match('^setvw%s(%d+)') then
    local vw = command:match('^setvw%s(%d+)')
    setPlayerVirtualWorld(playerid, vw)
    return true
  elseif command:match('^setint%s(%d+)') then
    local int = command:match('^setint%s(%d+)')
    setPlayerInterior(playerid, int)
    return true
  end
  sendClientMessage(playerid, '{FF0000}Неизвестная команда! {FFFFFF}Введите /help для помощи.', 0xFFFFFFFF)
end

function onIncomingPacket(bitStream, clientIP, clientPort)
  -- ПРИМЕР ИСПОЛЬЗОВАНИЯ (ПСЕВДО-АНТИЧИТ НА ТЕЛЕПОРТ)
  local packetID = SLNet.readInt16(bitStream)
  if packetID == S_PACKETS.ONFOOT_SYNC then
    SLNet.setReadPointerOffset(bitStream, 4)
    -- Переключаемся на 4-ое значение, список всех значений
    -- есть в WIKI на GitHub, там же есть все функции
    local pos =
    {
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream),
      SLNet.readFloat(bitStream)
    }
    local playerid = getIDbyAddress(clientIP, clientPort)
    if playerid ~= -1 then
      local x, y, z = getPlayerPos(playerid)
      local dist = getDistBetweenPoints(pos[1], pos[2], pos[3], x, y, z)
      if dist > 50 then
        sendClientMessage(playerid, 'Обнаружено использование чит-программ', 0xFF0000FF)
        kickPlayer(playerid)
        return false
      end
    end
  end
  return true -- если не отправить TRUE, PACKET не обработается сервером
  -- Если нужно игнорировать PACKET, можно использовать RETURN FALSE
  -- Наполнение BitStream можно изменять, это будет иметь эффект при обработке
end

function onIcomingRPC(bitStream, clientIP, clientPort)
  return true -- если не отправить TRUE, RPC не обработается сервером
  -- Если нужно игнорировать RPC, можно использовать RETURN FALSE
  -- Наполнение BitStream можно изменять, это будет иметь эффект при обработке
end
