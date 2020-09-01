Patches = {}
-- InGame PATCHES
Patches.disableBlueFog = function()
  memory.fill(0x575B0E, 0x90, 5, true)
end
Patches.disableFuckingCamera = function()
  memory.write(0x47C477, 0xEB, 1, true)
end
Patches.disableCheats = function()
  memory.write(0x4384D0, 0x9090, 2)
  memory.write(0x4384D2, 0x90, 1)
  memory.write(0x4384D3, 0xE9, 1)
  memory.write(0x4384D4, 0xCD, 4)
end
Patches.removeMotionBlur = function()
  memory.fill(0x704E8A, 0x90, 5, true)
end
Patches.disableHazeEffect = function()
  memory.write(0x72C1B7, 0xEB, 1, true)
end
Patches.lockPlayerAnimation = function()
  memory.fill(0x609A4E, 0x90, 6, true)
end
Patches.addPedsPool = function()
  memory.write(0x550FF2, 0xD2, 1, true)
  memory.write(0x551283, 0xD2, 1, true)
  memory.write(0x551140, 0x05, 1, true)
  memory.write(0x551178, 0x01, 1, true)
  memory.write(0x54F3A2, 0x10, 1, true)
end
Patches.addVehicleStruct = function()
  memory.write(0x5B8FDE, 0x6A, 1, true)
  memory.write(0x5B8FDE, 0x00, 1, true)
  memory.write(0x5B8FE0, 0x68, 1, true)
  memory.write(0x5B8FE1, 127, 1, true)
  memory.write(0x5B8FE2, 0x00, 1, true)
  memory.write(0x5B8FE3, 0x00, 1, true)
  memory.write(0x5B8FE4, 0x00, 1, true)
end
Patches.addBuildingsPool = function()
  memory.write(0x551060, 0x42, 1, true)
end
Patches.improveAllLimites = function()
  Patches.addPedsPool()
  Patches.addVehicleStruct()
  Patches.addBuildingsPool()
end
Patches.noVehicleNames = function()
  memory.fill(0x58FBE9, 0x90, 5, true)
end
Patches.noIdleAnimation = function()
  memory.write(0x86D1EC, 0x0, 1, true)
end
Patches.noReplays = function()
  memory.fill(0x53C090, 0x90, 5, true)
end
Patches.noInteriorPeds = function()
  memory.fill(0x440833, 0x90, 8, true)
end
Patches.disablePlants = function()
  memory.fill(0x53C159, 0x90, 5, true)
end
Patches.disableWeaponPickups = function()
  memory.fill(0x5B47B0, 0xC3, 1, true)
end
Patches.noPrintMessage = function()
  memory.write(0x588BE0, 0xC3, 1, true)
end
Patches.applyPatches = function()
  Patches.disableHazeEffect()
  Patches.disableCheats()
  Patches.disableFuckingCamera()
  Patches.disableBlueFog()
  memory.write(0x71162C, 80, 1, true)
  memory.write(0x4090A0, 0xC3, 1, true)
  memory.write(0x60D64D, 0x84, 2, true)
  memory.write(0x9690A0, 0x0, 4, true)
  memory.write(0x58DB5F, 0xBD, 1, true)
  memory.fill(0x58DB60, 0x00, 4, true)
  memory.fill(0x58DB64, 0x90, 4, true)
  memory.fill(0x53C06A, 0x90, 5, true)
  memory.fill(0x53EA08, 0x90, 10, true)
  --memory.fill(0x561AF0, 0x90, 7, true) Do Not Activate!
  memory.fill(0x441482, 0x90, 5, true)
  --memory.fill(0x434272, 0x90, 5, true) !!
  memory.fill(0x542485, 0x90, 11, true)
  memory.fill(0x609A4E, 0x90, 6, true)
  memory.fill(0x53C1C1, 0x90, 5, true)
  Patches.noVehicleNames()
  Patches.noIdleAnimation()
  Patches.noReplays()
  Patches.noInteriorPeds()
  Patches.disablePlants()
  Patches.disableWeaponPickups()
  Patches.removeMotionBlur()
  Patches.lockPlayerAnimation()
  Patches.noPrintMessage()
  setPedDensityMultiplier(0.0)
  setCarDensityMultiplier(0.0)
end
Patches.workInPause = function()
  memory.setuint8(7634870, 1)
  memory.setuint8(7635034, 1)
  memory.fill(7623723, 144, 8)
  memory.fill(5499528, 144, 6)
  memory.fill(0x748063, 0x90, 5, true)
end