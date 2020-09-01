-- GTA: SAN ANDERS MULTIPLAYER BASED ON LUA
-- SIMPLE LUA MULTIPLAYER IS AN OPENSOURCE PROJECT
-- WE ASK YOU TO SUPPORT OUR WORK ON GITHUB

-- Developers: Pakulichev & Seven.ExE
-- Special Thanks: Akionka, imring, FYP,
-- SL Team members and other guys, who
-- participated in SL:MP development

script_properties('work-in-pause')
require 'moonloader' -- SL:MP based on MoonLoader by FYP

imgui = require 'mimgui' -- imgui the best
bit = require 'bit' -- client uses Bit to encode data
socket = require 'socket' -- client uses LuaSocket
udp = socket.udp() -- client uses UDP method to send data
memory = require 'memory' -- some memory focuses, okay?
ffi = require 'ffi' -- one more focus
FA = require 'FA5Pro' -- just icons

encoding = require 'encoding'
encoding.default = 'UTF8'
cp1251 = encoding.CP1251

gMenuPatch = true
if memory.getuint32(0xC8D4C0, false) < 9 then
  -- if game isn`t loaded now we will make some patches
  gMenuPatch = false -- notify client that game is not loaded
  pcall(memory.copy, 0x866CCC, memory.strptr("slmp_load"..string.char(0x0)), 10)
  pcall(memory.fill, 0x747483, 0x90, 6, true) -- bypass vids
  pcall(memory.setuint32, 0xC8D4C0, 5, true) -- skip intros by changing game state
  pcall(memory.write, 0x5B8E6A, 134217728, 4, true) -- multipling streaming value
end

modules = getWorkingDirectory() .. '/SLModules' -- some server modules located there
dofile(modules..'/utilities/encoder.lua') -- data to bytes encoder by Akionka
dofile(modules..'/utilities/snippets.lua') -- useful snippets and functions
dofile(modules..'/bitstream.lua') -- method to work with data using encoder
dofile(modules..'/defines.lua') -- just defines, nothing interesting
dofile(modules..'/networking.lua') -- sending and receiving data from server
dofile(modules..'/initialization.lua') -- some operations to get client ready

udp:settimeout(0) -- client will not disconnect server with timeout
udp:setpeername('localhost', 0) -- set local IP and unknown PORT

function main() -- moonloader script header function
  print('SL:MP Initialization Finished')

  displayZoneNames(false)
  disableAllEntryExits(true)
  Patches.improveAllLimites() -- peds, vehicles, etc.
  Patches.applyPatches()
  Patches.workInPause()
  setPlayerDisplayVitalStatsButton(PLAYER_HANDLE, false)
  setCharCoordinates(PLAYER_PED, 1.0, 1.0, 3.0)

  lua_thread.create(NetworkLoop)
  lua_thread.create(RenderLoop)
  while true do
    wait(0)
  end
end

function onD3DPresent()
  if memory.getuint32(0xC8D4C0, true) == 7 and not gMenuPatch then
    -- if game is not loaded, lets skip all videos
    gMenuPatch = true -- notify client that everything done
    memory.setuint8(0xBA6831, 1, true) -- game state = 1
    memory.setuint32(0xC8D4C0, 8, true) -- game state = 8
    memory.setuint8(0xBA67A4, 0, true) -- disable a menu
    memory.setuint8(0xBA677B, 0, true) -- start game
  end
end

function onScriptTerminate(script, quitGame)
  if script == thisScript() then
    Client:disconnect(true)
    udp:close()
  end
end

function onWindowMessage(msg, wparam, lparam)
  if msg == 0x100 then
    if Graphics.wChat[0] then
      if wparam == 0x75 then
        Graphics.tChatOpen = not Graphics.tChatOpen
      elseif wparam == 0x1B and Graphics.tChatOpen then
        Graphics.tChatOpen = false
      elseif wparam == 0x54 and not Graphics.tChatOpen then
        Graphics.tChatOpen = true
      end
    end
    --[[if not CGraphics.tChatOpen and wparam == 0x47 then
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
    end]]
  end
end