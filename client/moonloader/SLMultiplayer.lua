script_properties('work-in-pause', 'forced-reloading-only')

mpFolder = getWorkingDirectory() .. '\\SLMultiplayer\\'
dofile(mpFolder .. "init.lua") -- SL:MP Header File
dofile(mpFolder .. "Utilities/encoder.lua") -- Network Base Module
dofile(mpFolder .. "net.lua") -- SL:MP Network Base File
dofile(mpFolder .. "graphics.lua") -- SL:MP GUI and HUD File
dofile(mpFolder .. "game.lua") -- SL:MP GTA:SA Patches & Fixes
dofile(mpFolder .. "network.lua") -- SL:MP Network File
dofile(mpFolder .. "packets.lua") -- SL:MP Packets Proccessing File
dofile(mpFolder .. "rpc.lua") -- SL:MP RPC Proccessing File

local gMenuPatch = true
if memory.getuint32(0xC8D4C0, false) < 9 then
  gMenuPatch = false
  memory.copy(0x866CCC, "slmp_load", ("slmp_load"):len())
  memory.fill(0x747483, 0x90, 6, true) -- bypass vids
  memory.setuint32(0xC8D4C0, 5, true) -- skip intros by changing game state
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
    playerName = 'Kalk0r',
    address = 'localhost:7777'
  }
end
json.save(configFolder .. '\\client.json', CConfig)
ffi.copy(CGraphics.ClientSettings.tNickname, u8(CConfig.playerName))
ffi.copy(CGraphics.ClientSettings.tAddress, u8(CConfig.address))

function main()
  print("SL:MP initialization proccess complited")

  setCharCoordinates(PLAYER_PED, 0.0, 0.0, 0.0)
  CGame.workInPause()
  displayCarNames(false)
  displayZoneNames(false)
  disableAllEntryExits(true)
  CGame.disableAllFuckingCity()
  CGame.disableBlurEffect()
  CGame.disableBlueFog()
  CGame.disableHazeEffect()
  CGame.disableParkedCars()
  CGame.disableReplays()
  CGame.disableWeaponPickups()
  CGame.disableInteriorPeds()
  CGame.disableCheats()
  CGame.disableMessagePrint()
  CGame.disableSpawnCars()
  CGame.disableWasted()
  CGame.disableCharacters()
  CGame.disableVehicles()
  CGame.disableCJWalkAnimation()
  CGame.disableIdleAnimation()

  setPlayerDisplayVitalStatsButton(PLAYER_HANDLE, false)

  GPool.clearPool()
  LPlayer.updateStats()

  lua_thread.create(gameLoop)
  lua_thread.create(networkLoop)
  lua_thread.create(function()
    while true do
      wait(5000)
      for i = #SLNet.BitStreams, 1, -1 do
        if os.time() >= SLNet.BitStreams[i].LifeTime then
          table.remove(SLNet.BitStreams, i)
        end
      end
    end
  end)
  lua_thread.create(CGame.hookPickupCollected)
  lua_thread.create(CGame.weaponSync)
end

function gameLoop()
  while true do
    wait(1)
    CGame.cScreen.x, CGame.cScreen.y = getScreenResolution()
    if CGraphics.wClient[0] and not isGamePaused() then
      renderDrawBox(0, 0, CGame.cScreen.x, CGame.cScreen.y, 0xFF000000)
    end
    CGame.disableCharacters()
    CGame.disableVehicles()
    renderFontDrawText(renderVerdana, CGame.cVersion, 5, CGame.cScreen.y - 16, 0x80FFFFFF)
    if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
      checkPlayerState()

      for i = 1, #GPool.GVehicles do
        CGame.setVehicleDamagable(GPool.GVehicles[i].handle, false)
        if isCharInAnyCar(PLAYER_PED) then
          if GPool.GVehicles[i].handle == storeCarCharIsInNoSave(PLAYER_PED) then
            if CGame.getVehicleSeat(PLAYER_PED) == 0 then
              CGame.setVehicleDamagable(GPool.GVehicles[i].handle, true)
            end
          end
        end
      end

      if LPlayer.lpPlayerState == S_PLAYERSTATE.PS_ONFOOT then
        if ltSendOnFootSync and os.clock() - ltSendOnFootSync >= 0.03 and not isGamePaused() then
          local x, y, z = getCharCoordinates(PLAYER_PED)
          if x ~= LPlayer.lpPosition[1] or y ~= LPlayer.lpPosition[2]
          or z ~= LPlayer.lpPosition[3] or os.clock() - ltSendOnFootSync >= 1.5 then
            LPlayer.updateStats()
            ltSendOnFootSync = os.clock()
            LPlayer.lpPosition = {x, y, z}
            local vecX, vecY, vecZ = getCharVelocity(PLAYER_PED)
            local bs = SLNet.createBitStream()
            SLNet.writeInt16(bs, S_PACKETS.ONFOOT_SYNC)
            SLNet.writeInt8(bs, LPlayer.lpHealth)
            SLNet.writeInt8(bs, LPlayer.lpArmour)
            SLNet.writeFloat(bs, x)
            SLNet.writeFloat(bs, y)
            SLNet.writeFloat(bs, z)
            SLNet.writeFloat(bs, LPlayer.lpQuaternion[1])
            SLNet.writeFloat(bs, LPlayer.lpQuaternion[2])
            SLNet.writeFloat(bs, LPlayer.lpQuaternion[3])
            SLNet.writeFloat(bs, LPlayer.lpQuaternion[4])
            SLNet.writeFloat(bs, vecX)
            SLNet.writeFloat(bs, vecY)
            SLNet.writeFloat(bs, vecZ)
            SLNet.writeFloat(bs, LPlayer.lpFacingAngle)
            SPool.sendPacket(bs)
            SLNet.deleteBitStream(bs)
          end
        end
      elseif LPlayer.lpPlayerState == S_PLAYERSTATE.PS_DRIVER or LPlayer.lpPlayerState == S_PLAYERSTATE.PS_PASSANGER then
        if ltSendOnFootSync and os.clock() - ltSendOnFootSync >= 0.03 and not isGamePaused() then
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
            if ((x ~= GPool.GVehicles[slot].position[1] or y ~= GPool.GVehicles[slot].position[2] or z ~= GPool.GVehicles[slot].position[3])
            and LPlayer.lpPlayerState == S_PLAYERSTATE.PS_DRIVER) or os.clock() - ltSendOnFootSync >= 1.5 then
              LPlayer.updateStats()
              ltSendOnFootSync = os.clock()
              GPool.GVehicles[slot].position = {x, y, z}
              if LPlayer.lpPlayerState == S_PLAYERSTATE.PS_DRIVER then
                local qX, qY, qZ, qW = getVehicleQuaternion(GPool.GVehicles[slot].handle)
                local facingAngle = getCarHeading(GPool.GVehicles[slot].handle)
                local vecX, vecY, vecZ = getCarSpeedVector(GPool.GVehicles[slot].handle)
                local vHealth = getCarHealth(GPool.GVehicles[slot].handle)
                local vRoll = getCarRoll(GPool.GVehicles[slot].handle)
                local vSpeed = getCarSpeed(GPool.GVehicles[slot].handle)
                local bs = SLNet.createBitStream()
                SLNet.writeInt16(bs, S_PACKETS.INCAR_SYNC)
                SLNet.writeInt16(bs, GPool.GVehicles[slot].vehicleid)
                SLNet.writeInt8(bs, LPlayer.lpVehicleSeat)
                SLNet.writeInt8(bs, LPlayer.lpHealth)
                SLNet.writeInt8(bs, LPlayer.lpArmour)
                SLNet.writeFloat(bs, x)
                SLNet.writeFloat(bs, y)
                SLNet.writeFloat(bs, z)
                SLNet.writeInt16(bs, vHealth)
                SLNet.writeFloat(bs, qX)
                SLNet.writeFloat(bs, qY)
                SLNet.writeFloat(bs, qZ)
                SLNet.writeFloat(bs, qW)
                SLNet.writeFloat(bs, vecX)
                SLNet.writeFloat(bs, vecY)
                SLNet.writeFloat(bs, vecZ)
                SLNet.writeFloat(bs, facingAngle)
                SLNet.writeFloat(bs, vRoll)
                SPool.sendPacket(bs)
                SLNet.deleteBitStream(bs)
              else
                local bs = SLNet.createBitStream()
                SLNet.writeInt16(bs, S_PACKETS.INCAR_SYNC)
                SLNet.writeInt16(bs, GPool.GVehicles[slot].vehicleid)
                SLNet.writeInt8(bs, LPlayer.lpVehicleSeat)
                SLNet.writeInt8(bs, LPlayer.lpHealth)
                SLNet.writeInt8(bs, LPlayer.lpArmour)
                SLNet.writeFloat(bs, x)
                SLNet.writeFloat(bs, y)
                SLNet.writeFloat(bs, z)
                SPool.sendPacket(bs)
                SLNet.deleteBitStream(bs)
              end
            end
          end
        end
      end
      if not isGamePaused() then
        renderNametags()
        if CGraphics.tVehicleData then
          renderVehicleData()
        end
      end
    end
  end
end

function renderVehicleData()
  local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
  for i = 1, #GPool.GVehicles do
    if GPool.GVehicles[i].handle and doesVehicleExist(GPool.GVehicles[i].handle) then
      if isCarOnScreen(GPool.GVehicles[i].handle) then
        local cX, cY, cZ = getCarCoordinates(GPool.GVehicles[i].handle)
        local dist = getDistanceBetweenCoords3d(cX, cY, cZ, pX, pY, pZ)
        if dist <= 50.0 then
          local camX, camY, camZ = getActiveCameraCoordinates()
          local wposX, wposY = convert3DCoordsToScreen(cX, cY, cZ + 0.4 + (dist * 0.05))
          local result, colPoint = processLineOfSight(camX, camY, camZ, cX, cY, cZ, true, false, false, true, false, false, false, true)
          if result then
            renderFontDrawText(renderVerdana, 'VehicleID: ' .. GPool.GVehicles[i].vehicleid ..
            '\nVHealth: ' .. getCarHealth(GPool.GVehicles[i].handle), wposX, wposY, 0xFFFFFFFF)
          end
        end
      end
    end
  end
end

function renderNametags()
  local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
  for i = 1, #GPool.GPlayers do
    if GPool.GPlayers[i].playerid ~= LPlayer.lpPlayerId and GPool.GPlayers[i].handle and doesCharExist(GPool.GPlayers[i].handle) then
      if isCharOnScreen(GPool.GPlayers[i].handle) then
        local rpX, rpY, rpZ = CGame.getBodyPartCoordinates(8, GPool.GPlayers[i].handle)
        local dist = getDistanceBetweenCoords3d(rpX, rpY, rpZ, pX, pY, pZ)
        local camX, camY, camZ = getActiveCameraCoordinates()
        local wposX, wposY = convert3DCoordsToScreen(rpX, rpY, rpZ + 0.4 + (dist * 0.05))
        local result, colPoint = processLineOfSight(camX, camY, camZ, rpX, rpY, rpZ, true, false, false, true, false, false, false, true)
        if not result then
          if GPool.GPlayers[i].chatBubble.time > os.clock()
          and dist <= GPool.GPlayers[i].chatBubble.distance then
            renderFontDrawText(renderVerdana, GPool.GPlayers[i].chatBubble.text, wposX - renderGetFontDrawTextLength(renderVerdana, GPool.GPlayers[i].chatBubble.text) / 2, wposY - 12, GPool.GPlayers[i].chatBubble.color)
          end
          if dist <= SPool.sNametag then
            renderFontDrawText(renderVerdana, GPool.GPlayers[i].nickname .. " (" .. GPool.GPlayers[i].playerid .. ")", wposX - renderGetFontDrawTextLength(renderVerdana, GPool.GPlayers[i].nickname .. " (" .. GPool.GPlayers[i].playerid .. ")") / 2, wposY, 0xFFFFFFFF)
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
end

function onWindowMessage(msg, wparam, lparam)
  if msg == 0x100 then
    if CGraphics.wChat[0] then
      if wparam == 0x75 then
        CGraphics.tChatOpen = not CGraphics.tChatOpen
      elseif wparam == 0x1B and CGraphics.tChatOpen then
        CGraphics.tChatOpen = false
      elseif wparam == 0x54 and not CGraphics.tChatOpen then
        CGraphics.tChatOpen = true
      end
    end
    if not CGraphics.tChatOpen and wparam == 0x47 then
      local data = {-1, -1}
      local pX, pY, pZ = getCharCoordinates(PLAYER_PED)
      for i = 1, #GPool.GVehicles do
        if GPool.GVehicles[i].handle and doesVehicleExist(GPool.GVehicles[i].handle) then
          local cX, cY, cZ = getCarCoordinates(GPool.GVehicles[i].handle)
          local dist = getDistanceBetweenCoords3d(cX, cY, cZ, pX, pY, pZ)
          if dist <= 20.0 then
            if data[1] == -1 or dist < data[2] then
              data[2] = dist
              data[1] = GPool.GVehicles[i].handle
            end
          end
        end
      end
      if data[1] ~= -1 then
        taskEnterCarAsPassenger(PLAYER_PED, data[1], 5000, -1)
      end
    end
  end
end

function onScriptTerminate(script, quitGame)
  if script == thisScript() then
    json.save(configFolder .. '\\client.json', CConfig)
    if LPlayer.lpGameState ~= S_GAMESTATES.GS_DISCONNECTED then
      local bs = SLNet.createBitStream()
      SLNet.writeInt16(bs, S_PACKETS.DISCONNECT)
      SLNet.writeInt8(bs, 0)
      SPool.sendPacket(bs)
      SLNet.deleteBitStream(bs)
      removeAllServerStuff()
    end
  end
end

function removeAllServerStuff()
  for i = #GPool.GPlayers, 1, -1 do
    if GPool.GPlayers[i].handle and doesCharExist(GPool.GPlayers[i].handle) then
      deleteChar(GPool.GPlayers[i].handle)
    end
    table.remove(GPool.GPlayers, i)
  end
  for i = #GPool.GVehicles, 1, -1 do
    if GPool.GVehicles[i].handle and doesVehicleExist(GPool.GVehicles[i].handle) then
      deleteCar(GPool.GVehicles[i].handle)
    end
    table.remove(GPool.GVehicles, i)
  end
  for i = #GPool.GPickups, 1, -1 do
    if GPool.GPickups[i].handle and doesPickupExist(GPool.GPickups[i].handle) then
      removePickup(GPool.GPickups[i].handle)
    end
    table.remove(GPool.GPickups, i)
  end
end