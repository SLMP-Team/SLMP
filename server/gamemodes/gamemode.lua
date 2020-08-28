function main()
  print('Gamemode loaded successfully!')
end

function onGamemodeInit()
  createVehicle(400, -9.9193, 40.6951, 3.1096, 0, 0)
  createVehicle(484, -258.6933, -352.0168, 1.8031, 0, 0)
  createVehicle(484, -242.0115, -367.5419, 1.3931, 0, 0)
end

local playerVehicles = {}

function onPlayerConnect(playerid)
  setPlayerPos(playerid, math.random(0, 50), math.random(0, 50), 2.0)
  local pX, pY, pZ = getPlayerPos(playerid)
  playerVehicles[playerid] = createVehicle(487, pX + 1.0, pY + 1.0, pZ + 1.5, 1, 1)
  setPlayerSkin(playerid, math.random(14, 18))
  sendClientMessage(playerid, '{FF0000}Добро {28B463FF}пожаловать {F4D03FFF}на сервер!', 0xFFFFFFFF)
  sendClientMessageToAll('{FF0000}' .. getPlayerName(playerid) .. ' {FFFFFF}залетел на наш сервер!', 0xFF0000FF)
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
  end
  if command == 'kickme' then
    sendClientMessage(playerid, '{FFFFFF}Вы были кикнуты с сервера по вашему желанию!', 0xFFFFFFFF)
    kickPlayer(playerid)
    return true
  end
  sendClientMessage(playerid, '{FF0000}Неизвестная команда! {FFFFFF}Введите /help для помощи.', 0xFFFFFFFF)
end