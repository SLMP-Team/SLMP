require("moonloader")
imgui = require("mimgui")
ffi = require("ffi")
memory = require("memory")
LEncoder = require("LibDeflate")
FA = require("FA5Pro")

encoding = require("encoding")
encoding.default = 'CP1251'
u8 = encoding.UTF8

socket = require("socket")
udp = socket.udp()

renderArial = renderCreateFont('Arial', 12)
renderVerdana = renderCreateFont('Verdana', 8)

ltSendOnFootSync = os.clock()

appdataFolder = getFolderPath(0x1C)
configFolder = appdataFolder..'\\SLTEAM\\SLMP'
if not doesDirectoryExist(configFolder) then
  createDirectory(appdataFolder..'\\SLTEAM')
  createDirectory(appdataFolder..'\\SLTEAM\\SLMP')
end

ffi.cdef[[
int __stdcall GetVolumeInformationA(
  const char* lpRootPathName,
  char* lpVolumeNameBuffer,
  uint32_t nVolumeNameSize,
  uint32_t* lpVolumeSerialNumber,
  uint32_t* lpMaximumComponentLength,
  uint32_t* lpFileSystemFlags,
  char* lpFileSystemNameBuffer,
  uint32_t nFileSystemNameSize
);
]]
sVolumeToken = ffi.new("unsigned long[1]", 0)
ffi.C.GetVolumeInformationA(nil, nil, 0, sVolumeToken, nil, nil, nil, 0)

S_GAMESTATES =
{
  GS_DISCONNECTED = 0,
  GS_CONNECTING = 1,
  GS_CONNECTED = 2
}

S_PLAYERSTATE =
{
  PS_ONFOOT = 0,
  PS_DRIVER = 1,
  PS_PASSANGER = 2
}

LPlayer =
{
  lpPlayerId = 0,
  lpNickname = 'PlayerName',
  lpHealth = 100.0,
  lpArmour = 0.0,
  lpFacingAngle = 0.0,
  lpPosition = {0.0, 0.0, 0.0},
  lpQuaternion = {0.0, 0.0, 0.0, 0.0},
  lpGameState = S_GAMESTATES.GS_DISCONNECTED,
  lpPlayerState = S_PLAYERSTATE.PS_ONFOOT,
  lpVehicleID = 0, lpVehicleSeat = 0
}

LPlayer.updateStats = function()
  LPlayer.lpHealth = getCharHealth(PLAYER_PED)
  LPlayer.lpArmour = getCharArmour(PLAYER_PED)
  LPlayer.lpFacingAngle = getCharHeading(PLAYER_PED)
  LPlayer.lpPosition[1], LPlayer.lpPosition[2], LPlayer.lpPosition[3] = getCharCoordinates(PLAYER_PED)
  LPlayer.lpQuaternion[1], LPlayer.lpQuaternion[2], LPlayer.lpQuaternion[3], LPlayer.lpQuaternion[4] = getCharQuaternion(PLAYER_PED)
end

GPool =
{
  GPlayers = {},
  GVehicles = {}
}

GPool.clearPool = function()
  for i = 1, #GPool.GPlayers do
    table.remove(GPool.GPlayers, i)
  end
  for i = 1, #GPool.GVehicles do
    table.remove(GPool.GVehicles, i)
  end
end

json = {}
function json.updateTable(default_table, fJson)
	for k, v in pairs(default_table) do
		if type(v) == 'table' then
			if fJson[k] == nil then fJson[k] = {} end
			fJson[k] = json.updateTable(default_table[k], fJson[k])
		else if fJson[k] == nil then fJson[k] = v end end
	end
	return fJson
end
json.load = function(json_file, default_table)
	if not default_table or type(default_table) ~= 'table' then default_table = {} end 
	if not json_file or not doesFileExist(json_file) then return false end
	local fHandle = io.open(json_file, 'r')
	if not fHandle then return false end
	local fText = fHandle:read('*all') 
	fHandle:close()
	if not fText then return false end
	local fRes, fJson = pcall(decodeJson, fText)
	if not fRes or not fJson or type(fJson) ~= 'table' then return false end
	fJson = json.updateTable(default_table, fJson)
	return fJson
end
json.save = function(json_file, lua_table)
	if not json_file or not lua_table or type(lua_table) ~= 'table' then return false end
	if doesFileExist(json_file) then os.remove(json_file) end
	local fHandle = io.open(json_file, 'w+')
	if not fHandle then return false end
	fHandle:write(encodeJson(lua_table))
	fHandle:close()
	return true
end

CConfig = 
{
  playerName = 'PlayerName',
  servers = {}
}

function checkPlayerState()
  if isCharInAnyCar(PLAYER_PED) then
    for i = 1, #GPool.GVehicles do
      local car = storeCarCharIsInNoSave(PLAYER_PED)
      if GPool.GVehicles[i].handle and GPool.GVehicles[i].handle == car then
        local carSeat = CGame.getVehicleSeat()
        if LPlayer.lpPlayerState == S_PLAYERSTATE.PS_ONFOOT then
          SPool.sendPacket(S_RPC.ENTER_VEHICLE, {
            vehicleid = GPool.GVehicles[i].vehicleid,
            seatID = tonumber(carSeat)
          })
        end
        if carSeat and carSeat == 0 then 
          LPlayer.lpPlayerState = S_PLAYERSTATE.PS_DRIVER
        else LPlayer.lpPlayerState = S_PLAYERSTATE.PS_PASSANGER end
        LPlayer.lpVehicleID = GPool.GVehicles[i].vehicleid
        LPlayer.lpVehicleSeat = tonumber(carSeat)
      end
    end
  else 
    if LPlayer.lpPlayerState == S_PLAYERSTATE.PS_DRIVER 
    or LPlayer.lpPlayerState == S_PLAYERSTATE.PS_PASSANGER then
      SPool.sendPacket(S_RPC.EXIT_VEHICLE, {
        vehicleid = LPlayer.lpVehicleID,
        seatID = LPlayer.lpVehicleSeat
      })
    end
    LPlayer.lpPlayerState = S_PLAYERSTATE.PS_ONFOOT 
  end
end