-- GTA: SAN ANDERS MULTIPLAYER BASED ON LUA
-- SIMPLE LUA MULTIPLAYER IS AN OPENSOURCE PROJECT
-- WE ASK YOU TO SUPPORT OUR WORK ON GITHUB

-- Developers: Pakulichev & Seven.ExE
-- Special Thanks: Akionka, imring, FYP,
-- SL Team members and other guys, who
-- participated in SL:MP development

bit = require 'bit' -- server uses Bit to encode data
socket = require 'socket' -- server uses LuaSocket
udp = socket.udp() -- server uses UDP method to send data

package.path = package.path .. ';../includes/?.lua;../includes/?.luac'
package.cpath = package.cpath .. ';../includes/?.dll'

--local oldPrint = print
--print = function(text) oldPrint('\t'..text) end

modules = '../modules' -- some server modules located there
dofile(modules..'/utilities/encoder.lua') -- data to bytes encoder by Akionka
dofile(modules..'/utilities/snippets.lua') -- useful snippets and functions
dofile(modules..'/bitstream.lua') -- method to work with data using encoder
dofile(modules..'/networking.lua') -- sending and receiving data from client
dofile(modules..'/config.lua') -- just config for server
dofile(modules..'/defines.lua') -- different stuff defined here
dofile(modules..'/initialization.lua') -- some operations to get server ready

udp:settimeout(0) -- server will not disconnect clients with timeout
Config.IP = type(Config.IP) and Config.IP or '*'
Config.Port = type(Config.Port) and Config.Port or 7777
udp:setsockname(Config.IP, Config.Port) -- set server`s IP and PORT

print(' ')
print('SL:MP Dedicated Server')
print('-----------------------------------')
print('v. '..General.VersionS..' | (c) SL-Team 2020')
print(' ')
print('SL:MP Developers: Pakulichev & SeVeN.ExE')
print('Special Thanks to FYP, imring, Akionka,')
print('SL-Team members and other SL:MP Testers')
print(' ')
print('Listening to port ' .. Config.Port .. ', max players is ' .. Config.Slots)
print(' ')

if Config.Rcon == '' or Config.Rcon == 'changeme' then
  print('Error! Change RCON password to launch server!')
  return
end

print('Loading gamemode file with name ' .. Config.Gamemode .. '...')

local modes =
{
  '../gamemodes/' .. Config.Gamemode .. '.lua',
  '../gamemodes/' .. Config.Gamemode .. '.luac'
}
local modLoaded = false
for i = 1, #modes do
  local file = io.open(modes[i], 'r')
  if file then
    file:close()
    print('\t[+] Gamemode was loaded successfully!')
    print(' ')
    dofile(modes[i])
    modLoaded = true
    break
  end
end
if not modLoaded then
  print('Error! Change gamemode filename to correct!')
  return
end

pcall(onGamemodeInit) -- call main gamemode function
MainLoop() -- load server`s main loop