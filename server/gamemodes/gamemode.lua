require 'a_functions'

function onGamemodeInit()
  -- this function calls when gamemode loads
  print('Hello! It`s message from your gamemode!')
  return true
end

function onPlayerConnect(playerid)
  -- this functuin calls when player connects
  Players:setSkin(playerid, 46)
  Players:setPos(playerid, 50.0, 50.0, 3.0)
  Players:setAngle(playerid, 0.0)
  Players:setWorld(playerid, 0)
  Players:setInterior(playerid, 0)
  Players:sendMessageAll(Players:getName(playerid) .. '{FFFFFF} joined the game', Players:getColor(playerid))
	Players:showDialog(playerid, 1, 0, 'Добро пожаловать на сервер!', 'Надеемся, вам здесь понравится!', 'OK', '')
  return true
end

function onPlayerDisconnect(playerid, reason)
  -- this function calls when player disconnects
  Players:sendMessageAll(Players:getName(playerid) .. '{FFFFFF} left the game', Players:getColor(playerid))
  return true
end

function onPlayerChat(playerid, text)
  Players:setChatBubble(playerid, text, 5000, 0xFFFFFFFF, 50.0)
  return true -- set FALSE to prevent sending "chat-like" message
end

function onPlayerChatCommand(playerid, command)
  if command:find('help') then
    Players:sendMessage(playerid, 'Hello world!', 0xFFFFFFFF)
    return true
  end
  return false -- set TRUE to prevent "no command" message
end

function onPlayerUpdate(playerid)
  return true
end

function onDialogResponse(playerid, id, button, list, text)
  if id == 1 then
    Players:sendMessage(playerid, ':)', 0xFFFFFFFF)
  end
  return true
end