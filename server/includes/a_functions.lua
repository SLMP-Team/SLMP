Players = {}
function Players:isConnected(playerid)
  local slot = Clients:getSlotByID(playerid)
  return slot == -1 and false or true
end
function Players:getName(playerid)
  local slot = Clients:getSlotByID(playerid)
  if slot == -1 then return ' ' end
  return Clients[slot].name
end
function Players:getIP(playerid)
  local slot = Clients:getSlotByID(playerid)
  if slot == -1 then return '0.0.0.0' end
  return Clients[slot].ip
end
function Players:setSkin(playerid, skinid)
  if skinid < 0 or skinid > 312 then
    return
  end
  local slot = Clients:getSlotByID(playerid)
  if slot ~= -1 then
    Clients:setSkin(slot, skinid)
  end
end
function Players:getSkin(playerid)
  local slot = Clients:getSlotByID(playerid)
  if slot == -1 then return -1 end
  return Clients[slot].skin
end
function Players:setPos(playerid, x, y, z)
  local slot = Clients:getSlotByID(playerid)
  if slot ~= -1 then
    Clients:setPos(slot, x, y, z)
  end
end
function Players:getPos(playerid)
  local slot = Clients:getSlotByID(playerid)
  if slot == -1 then return -1, -1, -1 end
  return Clients[slot].pos[1], Clients[slot].pos[2], Clients[slot].pos[3]
end
function Players:setAngle(playerid, angle)
  local slot = Clients:getSlotByID(playerid)
  if slot ~= -1 then
    Clients:setAngle(slot, angle)
  end
end
function Players:getAngle(playerid)
  local slot = Clients:getSlotByID(playerid)
  if slot == -1 then return -1 end
  return Clients[slot].ang
end
function Players:setWorld(playerid, world)
  local slot = Clients:getSlotByID(playerid)
  if slot ~= -1 then
    Clients[slot].world = world
  end
end
function Players:getWorld(playerid)
  local slot = Clients:getSlotByID(playerid)
  if slot == -1 then return -1 end
  return Clients[slot].world
end
function Players:setInterior(playerid, interior)
  if interior < 0 or interior > 0xFFFF then
    return
  end
  local slot = Clients:getSlotByID(playerid)
  if slot ~= -1 then
    Clients:setInterior(slot, interior)
  end
end
function Players:getInterior(playerid)
  local slot = Clients:getSlotByID(playerid)
  if slot == -1 then return -1 end
  return Clients[slot].interior
end
function Players:setColor(playerid, color)
  if color < 0x0 or color > 0xFFFFFFFF then
    return
  end
  local slot = Clients:getSlotByID(playerid)
  if slot ~= -1 then
    Clients[slot].color = color
  end
end
function Players:getColor(playerid)
  local slot = Clients:getSlotByID(playerid)
  if slot == -1 then return -1 end
  return Clients[slot].color
end
function Players:sendMessage(playerid, text, color)
  local slot = Clients:getSlotByID(playerid)
  if slot ~= -1 then
    Clients:sendMessage(slot, text, color)
  end
end
function Players:sendMessageAll(text, color)
  Clients:sendMessageAll(text, color)
end