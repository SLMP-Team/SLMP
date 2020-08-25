function sendClientMessage(playerid, message, color)
  if not color then color = 0xFFFFFFFF end
  if type(message) ~= 'string' then return false end
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      SPool.sendRPC(S_RPC.SEND_MESSAGE, {message = message, color = color}, SPool.sPlayers[i].bindedIP, SPool.sPlayers[i].bindedPort)
      return true
    end
  end
  return false
end
function sendClientMessageToAll(message, color)
  for i = 1, #SPool.sPlayers do
    sendClientMessage(SPool.sPlayers[i].playerid, message, color)
  end
  return true
end
function getPlayerName(playerid)
  for i = 1, #SPool.sPlayers do
    if SPool.sPlayers[i].playerid == playerid then
      return SPool.sPlayers[i].nickname
    end
  end
  return false
end