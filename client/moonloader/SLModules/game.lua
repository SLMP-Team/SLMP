Game = {}
Game.SpecialSkins={[3]='ANDRE',[4]='BBTHIN',[5]='BB',[298]='CAT',[292]='CESAR',[190]='COPGRL3',[299]='CLAUDE',[194]='CROGRL3',[268]='DWAYNE',
[6]='EMMET',[272]='FORELLI',[195]='GANGRL3',[191]='GUNGRL3',[267]='HERN',[8]='JANITOR',[42]='JETHRO',[296]='JIZZY',[65]='KENDL',[2]='MACCER',
[297]='MADDOGG',[192]='MECGRL3',[193]='NURGRL2',[293]='OGLOC',[291]='PAUL',[266]='PULASKI',[290]='ROSE',[271]='RYDER',[86]='RYDER3',[119]='SINDACO',
[269]='SMOKE',[149]='SMOKEV',[208]='SUZIE',[270]='SWEET',[273]='TBONE',[265]='TENPEN',[295]='TORINO',[1]='TRUTH',[294]='WUZIMU',[289]='ZERO',
[300]='LAPDNA',[301]='SFPDNA',[302]='LVPDNA',[303]='LAPDPC',[304]='LAPDPD',[305]='LVPDPC',[306]='WFYCLPD',[307]='VBFYCPD',[308]='WFYCLEM',
[309]='WFYCLLV',[310]='CSHERNA',[311]='DSHERNA',[312]='COPGRL1'}

function Game:getResolution()
  local x, y = getScreenResolution()
  return {x, y}
end

function RenderLoop()
  while true do
    wait(0)
    local scr = Game:getResolution()
    renderFontDrawText(AiralFont, 'SL:MP ' .. General.VersionS, 10,
    scr[2] - renderGetFontDrawHeight(AiralFont) - 5, 0x50FFFFFF)
    -- Render NameTags for Players
    local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
    for i = 1, #Players do
      if Players:isSpawned(i) and isCharOnScreen(Players[i].handle) and not isGamePaused() then
        local rpX, rpY, rpZ = Game:getBodyPartCoordinates(8, Players[i].handle)
        local dist = getDistanceBetweenCoords3d(rpX, rpY, rpZ, pX, pY, pZ)
        local camX, camY, camZ = getActiveCameraCoordinates()
        local wposX, wposY = convert3DCoordsToScreen(rpX, rpY, rpZ + 0.4 + (dist * 0.05))
        local result, colPoint = processLineOfSight(camX, camY, camZ, rpX, rpY, rpZ, true, false, false, true, false, false, false, true)
        if not result then
          if Players[i].chatBubble.time >= os.clock() and dist <= Players[i].chatBubble.dist then
            renderFontDrawText(AiralFont, u8:decode(Players[i].chatBubble.text), wposX - renderGetFontDrawTextLength(AiralFont, u8:decode(Players[i].chatBubble.text)) / 2, wposY - 16, Players[i].chatBubble.color)
          end
          if dist <= 20 then
            local health = getCharHealth(Players[i].handle)
            local a, r, g, b = explodeArgb(Players[i].color)
            local color = joinArgb(255, a, r, g)

            renderFontDrawText(AiralFont, Players[i].name .. " (" .. Players[i].id .. ")", wposX - renderGetFontDrawTextLength(AiralFont, Players[i].name .. " (" .. Players[i].id .. ")") / 2, wposY, color)
            renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(AiralFont) + 4, 100 / 2, 6, 0xFF000000, 1, 0xFF000000)
            renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(AiralFont) + 4, health / 2, 6, 0xFFFF0000, 1, 0x00000000)
            if Players[i].armour > 0 then
              renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(AiralFont) + 12, 100 / 2, 6, 0xFF000000, 1, 0xFF000000)
              renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(AiralFont) + 12, Players[i].armour / 2, 6, 0xFFFFFFFF, 1, 0x00000000)
            end
          end
        end
      end
    end
    -- Render NameTags for Players
  end
end

Game.getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
function Game:getBodyPartCoordinates(id, handle)
  local pedptr = getCharPointer(handle)
  local vec = ffi.new("float[3]")
  Game.getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
  return vec[0], vec[1], vec[2]
end

function Game:setPlayerSkin(skin)
  local specialSkin = false
  if Game.SpecialSkins[skin] then
    specialSkin = true
    loadSpecialCharacter(Game.SpecialSkins[skin], 1)
  else
    requestModel(skin)
    loadAllModelsNow()
  end
  setPlayerModel(PLAYER_HANDLE, specialSkin and 290 or skin)
  if specialSkin then
    unloadSpecialCharacter(1)
  else
    markModelAsNoLongerNeeded(skin)
  end
end

function Game:proccessCommand(command)
  if command:match('^pagesize') then
    local num = command:match('^pagesize%s+(%d+)')
    if not num then
      Game:addChatMessage('/pagesize [1-20]', 0xF5F5F5FF)
      return true
    end
    num = tonumber(num)
    if num < 1 or num > 20 then
      Game:addChatMessage('/pagesize [1-20]', 0xF5F5F5FF)
      return true
    end
    Graphics.ChatSettings.tChatLines = num
    return true
  elseif command:match('^fontsize') then
    local num = command:match('^fontsize%s+(%d+)')
    if not num then
      Game:addChatMessage('/fontsize [1-5]', 0xF5F5F5FF)
      return true
    end
    num = tonumber(num)
    if num < 1 or num > 5 then
      Game:addChatMessage('/fontsize [1-5]', 0xF5F5F5FF)
      return true
    end
    Graphics.ChatSettings.tChatFontSize = num
    Graphics.ChatSettings.tChatFontLoaded = false
    return true
  elseif command == 'disconnect' then
    Client:disconnect(true)
    Graphics.wChat[0] = false
    Graphics.ChatSettings.tChatMessages = {}
    Graphics.wClient[0] = true
    setCharCoordinates(PLAYER_PED, 0.0, 0.0, 3.0)
  elseif command == 'q' or command == 'quit' then
    os.execute('TASKKILL /IM gta_sa.exe')
    os.execute('TASKKILL /IM gtasa.exe')
    return true
  end
  return false
end
function Game:addChatMessage(text, color)
  text = type(text) == 'string' and text or ''
  color = type(color) == 'number' and color or 0xFFFFFFFF
  table.insert(Graphics.ChatSettings.tChatMessages, {
    text = text:sub(1, 128),
    color = color,
    time = os.time()
  })
  Graphics.ChatSettings.tRefocusNeed = true
end