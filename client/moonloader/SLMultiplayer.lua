script_properties('work-in-pause')

mpFolder = getWorkingDirectory() .. '\\SLMultiplayer'
dofile(mpFolder .. "\\SLMultiplayer.lua") -- SL:MP Header File
dofile(mpFolder .. "\\SLGraphics.lua") -- SL:MP GUI and HUD File
dofile(mpFolder .. "\\SLGame.lua") -- SL:MP GTA:SA Patches & Fixes
dofile(mpFolder .. "\\SLNetwork.lua") -- SL:MP Network File
dofile(mpFolder .. "\\SLPackets.lua") -- SL:MP Packets Proccessing File

local gMenuPatch = true
if memory.getuint8(0xC8D4C0, false) ~= 9 then
  gMenuPatch = false
  memory.fill(0x747483, 0x90, 6, true) -- bypass vids
  memory.setuint32(0xC8D4C0, 5, true) -- skip intros by changing game state
  memory.fill(0x745B83, 0x90, 71, true) -- fix resolution (?)
end

function onD3DPresent()
  if memory.getuint32(0xC8D4C0, true) == 7 and not gMenuPatch then
    gMenuPatch = true
    memory.setuint8(0xBA6831, 1, true) -- game started = 1
    memory.setuint32(0xC8D4C0, 8, true) -- game state = 8
    memory.setuint8(0xBA67A4, 0, true) -- disable a menu
    memory.setuint8(0xBA677B, 0, true) -- not start a game (???)
  end
end

CConfig = json.load(configFolder .. '\\client.json', CConfig)
if type(CConfig) ~= 'table' then
  CConfig = 
  {
    playerName = 'PlayerName',
    servers = {}
  }
end
for i = 1, #CConfig.servers do
  CConfig.servers[i].ping = 999
end
json.save(configFolder .. '\\client.json', CConfig)
ffi.copy(CGraphics.ClientInputs.tNickname, u8(CConfig.playerName))

function main()
  print("SL:MP initialization proccess complited")
  
  CGame.disableVehicleName()
  CGame.disableReplays()
  CGame.disableWasted()
  CGame.disableCharacters()
  CGame.disableBlurEffect()
  CGame.disableCheats()
  CGame.disableWanted()
  CGame.disableSpawnCars()
  CGame.disableInteriorPeds()
  CGame.disableMessagePrint()
  CGame.disableWeaponPickups()
  displayZoneNames(false)
  setPlayerDisplayVitalStatsButton(PLAYER_HANDLE, false)
  disableAllEntryExits(true)
  pcall(CGame.disableAllFuckingCity)
  CGame.workInPause()
  memory.write(0x72C1B7, 0xEB, 1, true) -- anti HazeEffect

  GPool.clearPool()
  LPlayer.updateStats()

  lua_thread.create(gameLoop)
end

function gameLoop()
  repeat wait(0) until CGame.getGamestate() == 9
  setCharCoordinates(PLAYER_PED, 0.0, 0.0, 5.0)
  while true do
    wait(0)
    CGame.disableCharacters()
    pcall(memory.setfloat, 0x8A5B20, 0.0, true) -- disable vehicles
    renderFontDrawText(renderVerdana, CGame.cVersion, 5, CGame.cScreen.y - 16, 0x80FFFFFF)

    -- Send OnFoot Sync
    if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
      if ltSendOnFootSync and os.clock() - ltSendOnFootSync >= 0.05 and not isGamePaused() then
        local x, y, z = getCharCoordinates(PLAYER_PED)
        if x ~= LPlayer.lpPosition[1] or y ~= LPlayer.lpPosition[2] or z ~= LPlayer.lpPosition[3] or os.clock() - ltSendOnFootSync >= 0.5 then
          ltSendOnFootSync = os.clock()
          LPlayer.updateStats()
          local vecX, vecY, vecZ = getCharVelocity(PLAYER_PED)
          SPool.sendPacket(S_PACKETS.ONFOOT_SYNC, {
            position = LPlayer.lpPosition,
            quaternion = LPlayer.lpQuaternion,
            facingAngle = LPlayer.lpFacingAngle,
            velocity = {vecX, vecY, vecZ},
            health = LPlayer.lpHealth,
            armour = LPlayer.lpArmour,
            keys = {
              leftRight = getPadState(PLAYER_HANDLE, 0), forwardBackward = getPadState(PLAYER_HANDLE, 1),
              jump = getPadState(PLAYER_HANDLE, 14), sprint = getPadState(PLAYER_HANDLE, 16),
              crouch = getPadState(PLAYER_HANDLE, 18), walk = getPadState(PLAYER_HANDLE, 22)
            }
          })
        end
      end
    end
    -- Send OnFoot Sync

    local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
    for i = 1, #GPool.GPlayers do
      if GPool.GPlayers[i].handle and doesCharExist(GPool.GPlayers[i].handle) then
        if isCharOnScreen(GPool.GPlayers[i].handle) then
          local wposX, wposY = convert3DCoordsToScreen(GPool.GPlayers[i].position[1], GPool.GPlayers[i].position[2], GPool.GPlayers[i].position[3] + 2.2)
          renderFontDrawText(renderVerdana, GPool.GPlayers[i].nickname .. " (" .. i .. ")", wposX - renderGetFontDrawTextLength(renderVerdana, GPool.GPlayers[i].nickname .. " (" .. GPool.GPlayers[i].playerid .. ")") / 2, wposY, 0xFFFFFFFF)                 
          renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(renderVerdana) + 4, 100 / 2, 6, 0xFF000000, 1, 0xFF000000)
          renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(renderVerdana) + 4, GPool.GPlayers[i].health / 2, 6, 0xFFFF0000, 1, 0x00000000)
          if GPool.GPlayers[i].armour > 0 then
            renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(renderVerdana) + 12, 100 / 2, 6, 0xFF000000, 1, 0xFF000000)
            renderDrawBoxWithBorder(wposX - 24, wposY + renderGetFontDrawHeight(renderVerdana) + 12, GPool.GPlayers[i].armour / 2, 6, 0xFFFFFFFF, 1, 0x00000000)
          end
        end
      end
    end
  
  end
end

function onQuitGame()
  onScriptTerminate(thisScript(), 1)
end

function onExitScript(quitGame)
  onScriptTerminate(thisScript(), quitGame and 1 or 0)
end

function onScriptTerminate(script, quitGame)
  if script == thisScript() then
    json.save(configFolder .. '\\client.json', CConfig)
    if LPlayer.lpGameState ~= S_GAMESTATES.GS_DISCONNECTED then
      SPool.sendPacket(S_PACKETS.DISCONNECT, {reason = 0})
      for i = #GPool.GPlayers, 1, -1 do
        if GPool.GPlayers[i].handle and doesCharExist(GPool.GPlayers[i].handle) then
          deleteChar(GPool.GPlayers[i].handle)
        end
      end
    end
  end
end

function onWindowMessage(msg, wparam, lparam)
  if msg == 0x100 then
    if wparam == 0x75 and LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
      CGraphics.tChatOpen = not CGraphics.tChatOpen
    end
  end
end