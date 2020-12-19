local patches = {}
local is_patched = true

local function set_main_script(directory, name)
  memory.setuint32(0x468EB5 + 1, tonumber(ffi.cast('uintptr_t', directory)), true)
  memory.setuint32(0x468EC4 + 1, tonumber(ffi.cast('uintptr_t', name)), true)
end

local function set_load_screen(directory, name)
  memory.setuint32(0x5900B6 + 1, tonumber(ffi.cast('uintptr_t', directory)), true)
  memory.setuint32(0x5900CC + 1, tonumber(ffi.cast('uintptr_t', name)), true)
end

function patches.apply() -- GTA:SA in-game patches
  memory.fill(0x575B0E, 0x90, 5, true) -- Disable Blue Fog
  memory.write(0x72C1B7, 0xEB, 1, true) -- Disable Haze Effect
  -- Disable Singleplayer Cheat Codes
  memory.write(0x4384D0, 0x9090, 2, true)
  memory.write(0x4384D2, 0x90, 1, true)
  memory.write(0x4384D3, 0xE9, 1, true)
  memory.write(0x4384D4, 0xCD, 4, true)
  -- Disable Wanted Level by Game
  memory.write(0x58DB5F, 0xBD, 1, true)
  memory.fill(0x58DB60, 0x00, 4, true)
  memory.fill(0x58DB64, 0x90, 4, true)
  memory.fill(0x748063, 0x90, 5, true) -- Disable Pause Game
  memory.write(0x47C477, 0xEB, 1, true) -- Disable Camera Movement
  memory.fill(0x704E8A, 0x90, 5, true) -- Disable Motion Blue
  memory.fill(0x609A4E, 0x90, 6, true) -- Lock Player Animation
  memory.write(0x86D1EC, 0x0, 1, true) -- Disable Idle Animation
  memory.fill(0x53C090, 0x90, 5, true) -- Disable Replays
  memory.fill(0x440833, 0x90, 8, true) -- Disable Interior Peds
  memory.fill(0x53C159, 0x90, 5, true) -- Disable Plants Objects
  memory.fill(0x5B47B0, 0xC3, 1, true) -- Disable Weapon Pickups
  memory.write(0x588BE0, 0xC3, 1, true) -- Disable Printing Messages
  memory.fill(0x58FBE9, 0x90, 5, true) -- Disable Vehicles Names
  memory.fill(0x56E5AD, 0x90, 5, true) -- Disable Wasted Message
  setPedDensityMultiplier(0.0) -- Disable Peds on the street
  setCarDensityMultiplier(0.0) -- Disable Cars on the street
  displayZoneNames(false) -- Disable Zone Names
  disableAllEntryExits(true) -- Disable SA Enteries
  setPlayerDisplayVitalStatsButton(PLAYER_HANDLE, false) -- Disable Stats Button
  setMaxWantedLevel(0) -- Disable Wanted Level
  setOnlyCreateGangMembers(true) -- Disable Gang Wars
  setCreateRandomGangMembers(false) -- Disable Gang Members
  enableBurglaryHouses(false) -- Disable Houses
  setFreeResprays(true) -- Disable Paid Resprays
  switchRandomTrains(false) -- Disable Trains
  setCreateRandomCops(false) -- Disable Police
  switchEmergencyServices(false) -- Disable EMS
  switchAmbientPlanes(false) -- Disable Planes
  memory.write(0x9690A0, 0, 4, true) -- Disable Car Generator #1
  -- Disable Car Generator #2
  memory.fill(0x53C1C1, 0x90, 5, true)
  memory.fill(0x434272, 0x90, 5, true)
  --memory.fill(0x561AF0, 0x90, 7, true) -- antipause
end

function patches.antipause()
  memory.setuint8(7634870, 1)
  memory.setuint8(7635034, 1)
  memory.fill(7623723, 144, 8)
  memory.fill(5499528, 144, 6)
end

function patches.prepare() -- GTA:SA pre-game patches
  if memory.getuint32(0xC8D4C0, false) < 9 then
    is_patched = false
    memory.copy(0x866CCC, memory.strptr("slmp_load"..string.char(0x0)), 10)
    memory.fill(0x747483, 0x90, 6, true)
    memory.setuint32(0xC8D4C0, 5, true)
    memory.write(0x5B8E6A, 134217728, 4, true)
    local dir_full_path = WORKING_DIRECTORY.."data\0"
    local dir = ffi.C.malloc(#dir_full_path)
    ffi.copy(dir, dir_full_path)
    local name_sc = ffi.C.malloc(11)
    ffi.copy(name_sc, "script.scm\0")
    local name_ls = ffi.C.malloc(15)
    ffi.copy(name_ls, "loadscreen.txd\0")
    set_main_script(dir, name_sc)
    set_load_screen(dir, name_ls)
    addEventHandler("onD3DPresent", function()
      if memory.getuint32(0xC8D4C0, true) == 7 and not is_patched then
        is_patched = true
        memory.setuint8(0xBA6831, 1, true)
        memory.setuint32(0xC8D4C0, 8, true)
        memory.setuint8(0xBA67A4, 0, true)
        memory.setuint8(0xBA677B, 0, true)
      end
    end)
  end
end

return patches