require 'a_functions'

function onGamemodeInit()
  -- this function calls when gamemode loads
  print('Hello! It`s message from your gamemode!')
  return true
end

function onPlayerConnect(playerid)
  -- this functuin calls when player connects
  Players:setSkin(playerid, math.random(1, 299))
  Players:setPos(playerid, math.random(-10, 10), math.random(-10, 10), 3.0)
  Players:setAngle(playerid, math.random(0, 365))
  Players:setWorld(playerid, 0)
  Players:setInterior(playerid, 0)
  Players:sendMessageAll(Players:getName(playerid) .. '{FFFFFF} joined the game', Players:getColor(playerid))
  return true
end

function onPlayerDisconnect(playerid, reason)
  -- this function calls when player disconnects
  Players:sendMessageAll(Players:getName(playerid) .. '{FFFFFF} left the game', Players:getColor(playerid))
  return true
end

function onPlayerChat(playerid, text)
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