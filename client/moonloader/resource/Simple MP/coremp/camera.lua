local camera = {}
camera.is_spectating = false
camera.player_spec = 0

function camera:set_pos(cam_x, cam_y, cam_z)
  setFixedCameraPosition(cam_x, cam_y, cam_z, 0.0, 0.0, 0.0)
end

function camera:set_look_pos(cam_x, cam_y, cam_z)
  pointCameraAtPoint(cam_x, cam_y, cam_z, 2)
end

function camera:attach_player(playerid)
  if not camera.is_spectating then return end
  if players.list[playerid] == 0 then return end
  if not doesCharExist(players.list[playerid].ped) then return end
  camera.player_spec = playerid
  attachCameraToChar(players.list[playerid].ped, 5.0, 5.0, 5.0, 0.0, 0.0, 0.0, 0.0, 2)
end

function camera:restore()
  if not camera.is_spectating then
    restoreCamera()
    setCameraBehindPlayer()
    return
  end
  camera:toggle(false)
  camera:toggle(true)
end

function camera:toggle(state)
  if state then
    camera.is_spectating = true
    setCharProofs(PLAYER_PED, true, true, true, true, true)
    self:set_pos(0.0, 0.0, 5.0)
    self:set_look_pos(15.0, 15.0, 5.0)
    setCharVisible(PLAYER_PED, false)
    setPlayerControl(PLAYER_HANDLE, false)
    freezeCharPosition(PLAYER_PED, true)
  elseif not state then
    camera.is_spectating = false
    setCharVisible(PLAYER_PED, true)
    setPlayerControl(PLAYER_HANDLE, true)
    setCharProofs(PLAYER_PED, false, false, false, false, false)
    freezeCharPosition(PLAYER_PED, false)
    setCharCoordinates(PLAYER_PED, world_data.spawn.x,
    world_data.spawn.y, world_data.spawn.z)
    setCameraBehindPlayer() restoreCamera()
  end
end

return camera