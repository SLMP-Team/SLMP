Players = {}
function Players:new(playerid, name)
  table.insert(self, {
    id = playerid,
    name = name,
    score = 0,
    ping = 65535,
    skin = 0,
    handle = nil,
    armour = 0,
    color = 0xFFFFFF50,
    chatBubble =
    {
      text = '',
      color = 0,
      dist = 0,
      time = 0
    }
  })
end
function Players:getSlotByID(playerid)
  for i = 1, #self do
    if self[i].id == playerid then
      return i
    end
  end
  return -1
end
function Players:remove(slot)
  if self:isSpawned(slot) then
    self:unspawn(slot)
  end
  table.remove(self, slot)
end
function Players:isSpawned(slot)
  if self[slot] and doesCharExist(self[slot].handle) then
    return true
  end
  return false
end
function Players:unspawn(slot)
  if self:isSpawned(slot) then
    deleteChar(self[slot].handle)
  end
end
function Players:spawn(slot)
  if self:isSpawned(slot) then
    self:unspawn(slot)
  end
  local specialSkin = false
  if Game.SpecialSkins[self[slot].skin] then
    specialSkin = true
    loadSpecialCharacter(Game.SpecialSkins[self[slot].skin], 1)
  else
    requestModel(self[slot].skin)
    loadAllModelsNow()
  end
  local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
  self[slot].handle = createChar(24, specialSkin and 290 or self[slot].skin, pX + 10.0, pY + 10.0, pZ)
  if specialSkin then
    unloadSpecialCharacter(1)
  else
    markModelAsNoLongerNeeded(self[slot].skin)
  end
  local dec = loadCharDecisionMaker(65543)
  setCharDecisionMaker(self[slot].handle, dec)
  setCharProofs(self[slot].handle, true, true, true, true, true)
  setCharDropsWeaponsWhenDead(self[slot].handle, false)
  setCharStayInSamePlace(self[slot].handle, true)
  setCharCantBeDraggedOut(self[slot].handle, true)
  setCharDrownsInWater(self[slot].handle, false)
end