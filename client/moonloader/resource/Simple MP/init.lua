script_name("Simple Lua Multiplayer")
script_authors("Pavel Akulichev", "Vadim Vinogradov")
script_version("1.0.0"); script_version_number(1)
script_properties("work-in-pause", "forced-reloading-only")
script_description("GTA:SA Multiplayer based on MoonLoader")
script_moonloader(27); script_url("https://sl-mp.com")

WORKING_DIRECTORY = "moonloader\\resource\\Simple MP\\"
-- in WORKING_DIRECTORY we have to collect all SLMP core files and resources

package.path = package.path..";"..WORKING_DIRECTORY.."?.lua"
package.path = package.path..";"..WORKING_DIRECTORY.."?\\init.lua"
package.cpath = package.cpath..";"..WORKING_DIRECTORY.."?.dll"

ffi = require("ffi")
imgui = require("mimgui")
snetwork = require("snet")
socket = require("socket")
imgui = require("mimgui")
memory = require("memory")
strcomp = require("lualzw")
packets = require("coremp.packets")
rpc = require("coremp.rpc")
players = require("coremp.players")
objects = require("coremp.objects")
md5 = require("md5")
sync = require("coremp.sync")
camera = require("coremp.camera")

bstream = snetwork.bstream
sleep = socket.sleep
ImVec2, ImVec4, ToVec4, ToU32 = imgui.ImVec2, imgui.ImVec4,
imgui.ColorConvertU32ToFloat4, imgui.ColorConvertFloat4ToU32

ffi.cdef[[
  void *malloc(size_t size);
  void free(void *ptrmem);
  char *GetCommandLineA();
  void exit(int status);
  unsigned long GetActiveWindow(void);
  bool SetWindowTextA(unsigned long hwnd, const char *lpString);
]]

local function get_argument(argname)
  local args_str = ffi.string(ffi.C.GetCommandLineA())
  args_str = args_str:sub(11, #args_str)
  local value = args_str:match("-"..argname.."=\"(.-)\"")
  return value
end

client_data = {
  host = get_argument("h"),
  port = get_argument("p"),
  name = get_argument("n")
}

if not client_data.name or not client_data.port
or not client_data.host then return thisScript():unload() end
ffi.C.SetWindowTextA(ffi.C.GetActiveWindow(), "Simple MP")

require("coremp.patches").prepare()
require("coremp.graphics")

special_skins={[3]='ANDRE',[4]='BBTHIN',[5]='BB',[298]='CAT',[292]='CESAR',[190]='COPGRL3',[299]='CLAUDE',[194]='CROGRL3',[268]='DWAYNE',
[6]='EMMET',[272]='FORELLI',[195]='GANGRL3',[191]='GUNGRL3',[267]='HERN',[8]='JANITOR',[42]='JETHRO',[296]='JIZZY',[65]='KENDL',[2]='MACCER',
[297]='MADDOGG',[192]='MECGRL3',[193]='NURGRL2',[293]='OGLOC',[291]='PAUL',[266]='PULASKI',[290]='ROSE',[271]='RYDER',[86]='RYDER3',[119]='SINDACO',
[269]='SMOKE',[149]='SMOKEV',[208]='SUZIE',[270]='SWEET',[273]='TBONE',[265]='TENPEN',[295]='TORINO',[1]='TRUTH',[294]='WUZIMU',[289]='ZERO',
[300]='LAPDNA',[301]='SFPDNA',[302]='LVPDNA',[303]='LAPDPC',[304]='LAPDPD',[305]='LVPDPC',[306]='WFYCLPD',[307]='VBFYCPD',[308]='WFYCLEM',
[309]='WFYCLLV',[310]='CSHERNA',[311]='DSHERNA',[312]='COPGRL1'}

function set_skin(skin)
  local is_special = false
  if special_skins[skin] then
    is_special = true; loadSpecialCharacter(special_skins[skin], 1)
  else requestModel(skin) loadAllModelsNow() end
  setPlayerModel(PLAYER_HANDLE, is_special and 290 or skin)
  if is_special then unloadSpecialCharacter(1)
  else markModelAsNoLongerNeeded(skin) end
end

world_data = {
  time = 12,
  weather = 1,
  spawn = {
    x = 0.0,
    y = 0.0,
    z = 5.0
  },
}

client = snetwork.client(tostring(client_data.host), tonumber(client_data.port))
client:add_event_handler("onReceivePacket",
function(id, bs)
  if id == SNET_CONFIRM_PRIORITY then return end
  if id == SNET_BLOCK_PACKET then
    if last_connection ~= 0 then
      last_connection = 0
      chat_pool:add(0xC9C9C9FF, "You are banned on the server.")
    end
    return
  end
  local is_rpc = bs:read(BS_BOOLEAN)
  bs = bstream.new(bs.bytes:sub(2, #bs.bytes))
  if is_rpc then rpc.process(id, bs)
  else packets.process(id, bs) end
end)

servername = "SL:MP Server"
localplayer_id = 0
last_connection = 0
server_was_full = false
is_connected = false
function connect_to_server(next)
  last_connection = os.time()
  if next then
    local data = bstream.new()
    data:write(BS_UINT8, #client_data.name)
    data:write(BS_STRING, client_data.name)
    local authkey = md5.sum(WORKING_DIRECTORY):sub(0, 254)
    data:write(BS_UINT8, #authkey)
    data:write(BS_STRING, authkey)
    data:write(BS_UINT8, #thisScript().version)
    data:write(BS_STRING, thisScript().version)
    rpc.send(rpc["list"]["ID_CLIENT_JOIN"], data)
    return
  end
  chat_pool:add(0xC9C9C9FF, "Connecting to "..client_data.host..":"..client_data.port.."...")
  packets.send(packets["list"]["ID_CONNECTION_REQUEST"], nil)
end

local last_sync = 0
local last_sync_pos = {0.0, 0.0, 0.0, 0.0}
local last_keys = 0
local function send_sync()
  local x, y, z = getCharCoordinates(PLAYER_PED)
  local r = getCharHeading(PLAYER_PED)
  last_sync_pos = {x, y, z, r}
  last_sync = os.clock()
  if camera.is_spectating then sync.spectating()
  elseif not isCharInAnyCar(PLAYER_PED) then sync.onfoot()
  elseif isCharInAnyCar(PLAYER_PED) then sync.incar() end
end

local ping_pack = 0
function main()
  require("coremp.patches").apply()
  require("coremp.patches").antipause()
  chat_pool:add(0xC9C9C9FF, "Simple MP 1.0.0 started and initialized.")
  chat_pool:add(0xC9C9C9FF, "Authors: Pavel Akulichev & Vadim Vinogradov.")
  wait(1000); connect_to_server()
  lua_thread.create(function()
    -- delete not-slmp vehicles
    while true do wait(0)
      local vehs = getAllVehicles()
      for i, v in ipairs(vehs) do
        if doesVehicleExist(v) then
          deleteCar(v)
        end
      end
    end
  end)
  lua_thread.create(function()
    while true do wait(0)
      client:process()
    end
  end)
  while true do wait(0)
    if is_connected and store_keys() ~= last_keys then
      last_keys = store_keys(); send_sync()
      last_sync = os.clock()
    end
    if scoreboard.enable or chat_pool.mode_num == 0 then
      displayRadar(false) displayHud(false)
    else displayRadar(true) displayHud(true) end
    forceWeatherNow(world_data.weather)
    setTimeOfDay(world_data.time, 0)
    players.nametags()
    if camera.is_spectating then
      local cam_x, cam_y, cam_z = getActiveCameraCoordinates()
      setCharCoordinates(PLAYER_PED, cam_x, cam_y, cam_z)
      setCharVisible(PLAYER_PED, false)
    end
    if last_connection ~= 0 and os.time() - last_connection > 5 then
      if server_was_full then server_was_full = false
        chat_pool:add(0xC9C9C9FF, "Server is full, retrying...")
      else chat_pool:add(0xC9C9C9FF, "Server didn't respond, retrying...") end
      connect_to_server()
    end
    if not isPauseMenuActive() and is_connected and os.clock() - last_sync >= 0.03 then
      local lX, lY, lZ, lR = last_sync_pos[1], last_sync_pos[2], last_sync_pos[3], last_sync_pos[4]
      local x, y, z = getCharCoordinates(PLAYER_PED); local r = getCharHeading(PLAYER_PED)
      local dist = getDistanceBetweenCoords3d(x, y, z, lX, lY, lZ)
      local rot = math.abs(lR - r)
      if os.clock() - last_sync >= 0.5 then send_sync()
      elseif dist ~= 0 or rot ~= 0 then send_sync() end
    end
    if is_connected and os.time() - ping_pack > 10 then
      local data = bstream.new(); data:write(BS_BOOLEAN, false)
      ping_pack = os.time(); packets.send(packets["list"]["ID_PING_SERVER_REQUEST"], data)
      if not isPauseMenuActive() then
        packets.send(packets["list"]["ID_UPDATE_SCORE_PING"], nil)
        packets.send(packets["list"]["ID_UPDATE_STREAM"], nil)
      end
    end
  end
end

addEventHandler("onQuitGame", function()
  if thisScript() == script and is_connected then
    packets.send(packets["list"]["ID_DISCONNECTION_NOTIFICATION"], nil)
  end
end)

addEventHandler("onScriptTerminate", function(script)
  if thisScript() == script and is_connected then
    packets.send(packets["list"]["ID_DISCONNECTION_NOTIFICATION"], nil)
  end
end)