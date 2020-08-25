function main()
  print('Gamemode loaded successfully!')
end

function onPlayerConnect(playerid)
end

function onPlayerDisconnect(playerid, reason)
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