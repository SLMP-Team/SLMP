local players = {}
players.list = {}

local nametag_font = renderCreateFont("Trebuchet", 10, 8)

local get_bone_pos = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
function get_body_part(id, handle)
  local vec = ffi.new("float[3]")
  get_bone_pos(ffi.cast("void*", getCharPointer(handle)), vec, id, true)
  return vec[0], vec[1], vec[2]
end

-- 65535 is max players number, fill values
for i = 1, 65535 do players.list[i] = 0 end

function players.remove(index)
  if players.list[index] ~= 0 then
    if camera.is_spectating and camera.player_spec == index then camera:restore() end
    if doesCharExist(players.list[index].ped) then
      deleteChar(players.list[index].ped)
    end
  end; players.list[index] = 0
end

function players.foreach(callback_func)
  for i, v in ipairs(players.list) do
    if v ~= 0 then
      local res = callback_func(i, v)
      if res ~= nil then return res end
    end
  end
end

function players.spawn(index)
  if index == localplayer_id then return end
  if players.list[index] == 0 then return end

  local ptr = players.list[index]
  if camera.is_spectating and camera.player_spec == index then camera:restore() end
  if doesCharExist(ptr.ped) then deleteChar(ptr.ped) end

  local skin = ptr.skin

  local is_special = false
  if special_skins[skin] then
    is_special = true
  end

  if is_special then loadSpecialCharacter(special_skins[skin], 1)
  else requestModel(skin); loadAllModelsNow() end
  ptr.ped = createChar(21, is_special and 290 or skin, 0, 0, 0)

  setCharDecisionMaker(ptr.ped, 65545)
  setCharProofs(ptr.ped, true, true, true, true, true)
  setCharDropsWeaponsWhenDead(ptr.ped, false)
  setCharStayInSamePlace(ptr.ped, true)
  setCharCantBeDraggedOut(ptr.ped, true)
  setCharDrownsInWater(ptr.ped, false)
  setCharHealth(ptr.ped, 1000)

  if is_special then unloadSpecialCharacter(1)
  else markModelAsNoLongerNeeded(skin) end
end

function players.nametags()
  local px, py, pz = getCharCoordinates(PLAYER_PED)
  for i, v in ipairs(players.list) do
    if v ~= 0 and doesCharExist(v.ped) and isCharOnScreen(v.ped)
    and not isPauseMenuActive() then
      local rpX, rpY, rpZ = get_body_part(8, v.ped)
      local dist = getDistanceBetweenCoords3d(rpX, rpY, rpZ, px, py, pz)
      local camX, camY, camZ = getActiveCameraCoordinates()
      local wposX, wposY = convert3DCoordsToScreen(rpX, rpY, rpZ + 0.4 + (dist * 0.05))
      local result, colPoint = processLineOfSight(camX, camY, camZ, rpX, rpY, rpZ, true, false, false, true, false, false, false, true)
      if not result then
        if dist <= 20 then
          local health, armour = v.health, v.armour
          renderFontDrawText(nametag_font, v.nickname .. " (" .. i .. ")", wposX - renderGetFontDrawTextLength(nametag_font, v.nickname .. " (" .. i .. ")") / 2, wposY, 0xFFFFFFFF)
          renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(nametag_font) + 4, 100 / 2, 6, 0xFF000000, 1, 0xFF000000)
          renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(nametag_font) + 4, health / 2, 6, 0xFFFF0000, 1, 0x00000000)
          if armour > 0 then
            renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(nametag_font) + 12, 100 / 2, 6, 0xFF000000, 1, 0xFF000000)
            renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(nametag_font) + 12, armour / 2, 6, 0xFFFFFFFF, 1, 0x00000000)
          end
        end
      end
    end
  end
end

addEventHandler("onScriptTerminate", function(script)
  if thisScript() == script then
    players.foreach(function(i, v)
      if v ~= 0 and doesCharExist(v.ped) then
        if camera.is_spectating and camera.player_spec == i then camera:restore() end
        deleteChar(v.ped); v.ped = nil
      end
    end)
  end
end)

return players