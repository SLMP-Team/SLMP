function main()
  print('Gamemode loaded successfully!')
end

function onGamemodeInit()
  createVehicle(400, -9.9193, 40.6951, 3.1096, 0, 0)
end

local playerVehicles = {}

function onPlayerConnect(playerid)
  local pX, pY, pZ = getPlayerPos(playerid)
  playerVehicles[playerid] = createVehicle(411, pX + 1.0, pY + 1.0, pZ + 1.5, 1, 1)
end

function onPlayerDisconnect(playerid, reason)
  if playerVehicles[playerid] then
    destroyVehicle(playerVehicles[playerid])
  end
end

function onPlayerChat(playerid, message)
  sendClientMessageToAll('[' .. getPlayerName(playerid) .. ']: {919191}' .. message, 0xFFFFFFFF)
end

function onPlayerCommand(playerid, command)
  if command == 'help' then
    sendClientMessage(playerid, '{FFFFFF}Прости! Кажется, помощи нет, тебя обманули!', 0xFFFFFFFF)
    return true
  end
  sendClientMessage(playerid, '{FF0000}Неизвестная команда! {FFFFFF}Введите /help для помощи.', 0xFFFFFFFF)
end