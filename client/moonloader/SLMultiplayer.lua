script_properties('work-in-pause')

mpFolder = getWorkingDirectory() .. '\\SLMultiplayer'
dofile(mpFolder .. "\\SLMultiplayer.lua") -- SL:MP Header File
dofile(mpFolder .. "\\SLGraphics.lua") -- SL:MP GUI and HUD File
dofile(mpFolder .. "\\SLGame.lua") -- SL:MP GTA:SA Patches & Fixes
dofile(mpFolder .. "\\SLNetwork.lua") -- SL:MP Network File
dofile(mpFolder .. "\\SLPackets.lua") -- SL:MP Packets Proccessing File
dofile(mpFolder .. "\\SLRPC.lua") -- SL:MP RPC Proccessing File

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
  CGame.disableParkedCars()

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
    checkPlayerState() -- checking player state

    if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
      -- UNOCCUPIED SYNC
      local pX, pY, pZ = isCharInAnyCar(PLAYER_PED) and getCarCoordinates(storeCarCharIsInNoSave(PLAYER_PED)) or getCharCoordinates(PLAYER_PED)
      if os.clock() - ltSendUnoccupied >= 1.0 then
        ltSendUnoccupied = os.clock()
        for i = 1, #GPool.GVehicles do
          if GPool.GVehicles[i].handle and doesVehicleExist(GPool.GVehicles[i].handle) and (not isCharInAnyCar(PLAYER_PED) or (storeCarCharIsInNoSave(PLAYER_PED) ~= GPool.GVehicles[i].handle)) then
            local cX, cY, cZ = getCarCoordinates(GPool.GVehicles[i].handle)
            local dist = getDistanceBetweenCoords3d(px, pY, pZ, cX, cY, cZ)
            if dist <= 60.0 then
              dist = getDistanceBetweenCoords3d(cX, cY, cZ, GPool.GVehicles[i].position[1], GPool.GVehicles[i].position[2], GPool.GVehicles[i].position[3])
              if dist >= 1.0 then
                local anyDriverInCar = false
                for ii = 1, #GPool.GPlayers do
                  if GPool.GPlayers[ii].handle and doesCharExist(GPool.GPlayers[ii].handle) then
                    if isCharInAnyCar(GPool.GPlayers[ii].handle) and storeCarCharIsInNoSave(GPool.GPlayers[ii].handle) == GPool.GVehicles[i].handle then
                      if CGame.getVehicleSeat(GPool.GPlayers[ii].handle) == 0 then
                        anyDriverInCar = true
                        break
                      end
                    end
                  end
                end
                if not anyDriverInCar then
                  local qX, qY, qZ, qW = getVehicleQuaternion(GPool.GVehicles[i].handle)
                  GPool.GVehicles[i].position = {cX, cY, cZ}
                  SPool.sendPacket(S_PACKETS.UNOCCUPIED_SYNC, {
                    vehicleid = GPool.GVehicles[i].vehicleid,
                    position = {cX, cY, cZ},
                    facingAngle = getCarHeading(GPool.GVehicles[i].handle),
                    quaternion = {qX, qY, qZ, qW},
                    roll = getCarRoll(GPool.GVehicles[i].handle)
                  })
                end
              end
            end
          end
        end
      end
      -- UNOCCUPIED SYNC

      if LPlayer.lpPlayerState == S_PLAYERSTATE.PS_ONFOOT then

        -- Send OnFoot Sync
        if ltSendOnFootSync and os.clock() - ltSendOnFootSync >= 0.05 and not isGamePaused() then
          local x, y, z = getCharCoordinates(PLAYER_PED)
          if x ~= LPlayer.lpPosition[1] or y ~= LPlayer.lpPosition[2] or z ~= LPlayer.lpPosition[3] or os.clock() - ltSendOnFootSync >= 1.5 then
            ltSendOnFootSync = os.clock()
            LPlayer.updateStats()
            LPlayer.lpPosition = {x, y, z}
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
        -- Send OnFoot Sync

      elseif LPlayer.lpPlayerState == S_PLAYERSTATE.PS_DRIVER or LPlayer.lpPlayerState == S_PLAYERSTATE.PS_PASSANGER then

        -- Send InCar Sync
        if ltSendOnFootSync and os.clock() - ltSendOnFootSync >= 0.1 and not isGamePaused() then
          local car, slot = storeCarCharIsInNoSave(PLAYER_PED), 0
          for i = 1, #GPool.GVehicles do
            if GPool.GVehicles[i].handle and GPool.GVehicles[i].handle == car then
              slot = i
              break
            end
          end
          if slot ~= 0 then
            car = GPool.GVehicles[slot]
            local x, y, z = getCarCoordinates(GPool.GVehicles[slot].handle)
            if x ~= GPool.GVehicles[slot].position[1] or y ~= GPool.GVehicles[slot].position[2] or z ~= GPool.GVehicles[slot].position[3] or os.clock() - ltSendOnFootSync >= 1.5 then
              ltSendOnFootSync = os.clock()
              GPool.GVehicles[slot].position = {x, y, z}
              if LPlayer.lpPlayerState == S_PLAYERSTATE.PS_DRIVER then
                local qX, qY, qZ, qW = getVehicleQuaternion(GPool.GVehicles[slot].handle)
                local facingAngle = getCarHeading(GPool.GVehicles[slot].handle)
                local vecX, vecY, vecZ = getCarSpeedVector(GPool.GVehicles[slot].handle)
                local vHealth = getCarHealth(GPool.GVehicles[slot].handle)
                local vRoll = getCarRoll(GPool.GVehicles[slot].handle)
                local vSpeed = getCarSpeed(GPool.GVehicles[slot].handle)
                SPool.sendPacket(S_PACKETS.INCAR_SYNC, {
                  position = {x, y, z},
                  quaternion = {qX, qY, qZ, qW},
                  facingAngle = facingAngle,
                  velocity = {vecX, vecY, vecZ},
                  speed = vSpeed,
                  vehicleid = LPlayer.lpVehicleID,
                  seatID = LPlayer.lpVehicleSeat,
                  health = vHealth, roll = vRoll
                })
              else 
                SPool.sendPacket(S_PACKETS.INCAR_SYNC, {
                  position = {x, y, z}, 
                  vehicleid = LPlayer.lpVehicleID,
                  seatID = LPlayer.lpVehicleSeat
                }) 
              end
            end
          end
        end
        -- SendInCar Sync

      end
    end
    

    -- NameTags for Players
    local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
    for i = 1, #GPool.GPlayers do
      if GPool.GPlayers[i].handle and doesCharExist(GPool.GPlayers[i].handle) then
        if isCharOnScreen(GPool.GPlayers[i].handle) then
          local rpX, rpY, rpZ = CGame.getBodyPartCoordinates(8, GPool.GPlayers[i].handle)
          local dist = getDistanceBetweenCoords3d(rpX, rpY, rpZ, pX, pY, pZ)
          if dist <= SPool.sNametag then
            local camX, camY, camZ = getActiveCameraCoordinates()
            local wposX, wposY = convert3DCoordsToScreen(rpX, rpY, rpZ + 0.4 + (dist * 0.05))
            local result, colPoint = processLineOfSight(camX, camY, camZ, rpX, rpY, rpZ, true, false, false, true, false, false, false, true)
            if not result then
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
  -- NameTags for Players

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
      for i = #GPool.GVehicles, 1, -1 do
        if GPool.GVehicles[i].handle and doesVehicleExist(GPool.GVehicles[i].handle) then
          deleteCar(GPool.GVehicles[i].handle)
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