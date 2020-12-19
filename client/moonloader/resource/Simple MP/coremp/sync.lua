local sync = {}

local function key_to_bit(key)
  local def = 0x1
  for i = 1, key do
    def = def * 2
  end
  return def
end

function store_keys()
  local keys = 0
  for i = 2, 21 do
    local res = getPadState(PLAYER_HANDLE, i)
    local to_bit = key_to_bit(i)
    if res and res ~= 0 then
      keys = bit.bor(keys, to_bit)
    end
  end
  if getPadState(PLAYER_HANDLE, 0) == -128 then
    keys = bit.bor(keys, key_to_bit(22))
  elseif getPadState(PLAYER_HANDLE, 0) == 128 then
    keys = bit.bor(keys, key_to_bit(23))
  end
  if getPadState(PLAYER_HANDLE, 1) == -128 then
    keys = bit.bor(keys, key_to_bit(24))
  elseif getPadState(PLAYER_HANDLE, 1) == 128 then
    keys = bit.bor(keys, key_to_bit(25))
  end
  return keys
end

function sync.spectating()
  local keys = store_keys()
  local x, y, z = getActiveCameraCoordinates()
  local bs = bstream.new()
  bs:write(BS_UINT32, keys)
  bs:write(BS_FLOAT, x)
  bs:write(BS_FLOAT, y)
  bs:write(BS_FLOAT, z)
  packets.send(packets["list"]["ID_SPEC_SYNC"], bs)
end

function sync.onfoot()
  local x, y, z = getCharCoordinates(PLAYER_PED)
  local qx, qy, qz, qw = getCharQuaternion(PLAYER_PED)
  local vx, vy, vz = getCharVelocity(PLAYER_PED)
  local rot = getCharHeading(PLAYER_PED)
  local lrKey = getPadState(PLAYER_HANDLE, 0)
  local udKey = getPadState(PLAYER_HANDLE, 1)
  local keys = store_keys()
  local ch = getCharHealth(PLAYER_PED)
  local am = getCharArmour(PLAYER_PED)
  local bs = bstream.new()
  bs:write(BS_INT16, lrKey)
  bs:write(BS_INT16, udKey)
  bs:write(BS_UINT32, keys)
  bs:write(BS_FLOAT, x); bs:write(BS_FLOAT, y); bs:write(BS_FLOAT, z)
  bs:write(BS_FLOAT, qx); bs:write(BS_FLOAT, qy); bs:write(BS_FLOAT, qz);
  bs:write(BS_FLOAT, qw); bs:write(BS_UINT8, ch); bs:write(BS_UINT8, am)
  bs:write(BS_BOOLEAN, isCharDucking(PLAYER_PED))
  bs:write(BS_BOOLEAN, isKeyDown(0xA4)) -- walking
  bs:write(BS_UINT8, getCurrentCharWeapon(PLAYER_PED))
  bs:write(BS_UINT8, 0) -- Special Action (TO-DO)
  bs:write(BS_FLOAT, vx); bs:write(BS_FLOAT, vy); bs:write(BS_FLOAT, vy)
  bs:write(BS_FLOAT, rot)

  packets.send(packets["list"]["ID_ONFOOT_SYNC"], bs)
end

function sync.onfoot_in(bs)
  local playerid = bs:read(BS_UINT16)
  local skin = bs:read(BS_UINT16)
  local lrKey = bs:read(BS_INT16)
  local udKey = bs:read(BS_INT16)
  local keys = bs:read(BS_UINT32)
  local x, y, z = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
  local qx, qy, qz, qw = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
  local health, armour = bs:read(BS_UINT8), bs:read(BS_UINT8)
  local is_duck, is_walk = bs:read(BS_BOOLEAN), bs:read(BS_BOOLEAN)
  local weap_id, action_id = bs:read(BS_UINT8), bs:read(BS_UINT8)
  local vx, vy, vz = bs:read(BS_FLOAT), bs:read(BS_FLOAT), bs:read(BS_FLOAT)
  local rot = bs:read(BS_FLOAT)

  if players.list[playerid] == 0 then return end
  local ptr = players.list[playerid]

  ptr.health = health
  ptr.armour = armour

  if not ptr.ped or not doesCharExist(ptr.ped) then return end

  if isCharDucking(ptr.ped) ~= is_duck then
    taskToggleDuck(ptr.ped, is_duck)
  end

  if (udKey ~= 0 or lrKey ~= 0) and is_walk then
    taskPlayAnimNonInterruptable(ptr.ped, "WALK_CIVI",
    "PED", 4.1, false, true, true, false, 100)
  elseif (udKey ~= 0 or lrKey ~= 0) and not is_walk then
    taskPlayAnimNonInterruptable(ptr.ped, "RUN_CIVI",
    "PED", 4.1, false, true, true, false, 100)
  end

  setCharCoordinates(ptr.ped, x, y, z - 1.1)
  setCharQuaternion(ptr.ped, qx, qy, qz, qw)
  setCharHeading(ptr.ped, rot)
  setCharVelocity(ptr.ped, vx, vy, vz)
  setCharHealth(ptr.ped, 1000.0)

  if getCurrentCharWeapon(ptr.ped) ~= weap_id then
    setCurrentCharWeapon(ptr.ped, weap_id)
  end

end

function sync.incar()
  -- TO-DO InCar Sync
end

return sync