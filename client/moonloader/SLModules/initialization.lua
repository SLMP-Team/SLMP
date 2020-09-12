General =
{
  Version = 2,
  VersionS = '0.0.1-RC-X',
  Timer = os.time(),
  SendSyncTime = os.clock(),
  LastPingTime = os.time(),
  ConnectingTime = os.time()
}

Server =
{
  IP = 'localhost',
  Port = 0,
  OnFootRate = 40
}

Player =
{
  ID = -1,
  GameState = GAMESTATE.DISCONNECTED,
  PlayerState = PLAYERSTATE.ONFOOT
}

ClientData =
{
  sName = '',
  sPlayers = {0, 0},
  sPing = 0,
  sLanguage = '',
  sVersion = '',
  sWebsite = '',
  sRequestTime = 0,
  sPlayerPool = {}
}

appdataFolder = getFolderPath(0x1C)
configFolder = appdataFolder..'\\SL-TEAM\\SL-MP'
if not doesDirectoryExist(configFolder) then
  createDirectory(configFolder)
end
Config =
{
  playerName = '',
  serverAddress = ''
}
local file = io.open(configFolder..'\\conf.json', 'r')
if file then
  local text = file:read('*a')
  local res, data = pcall(decodeJson, text)
  if res and type(data) == 'table' then
    Config.playerName = data.playerName
    Config.serverAddress = data.serverAddress
  end
  file:close()
end

require('patches') -- lets include some patch methods
require('game') -- lets include game functions, who doesn`t like game functions?
require('client') -- some useful SL:MP methods and functions
require('players')
require('graphics')

ffi.cdef[[
	typedef struct {
		const char* state;
		const char* details;
		int64_t startTimestamp;
		int64_t endTimestamp;
		const char* largeImageKey;
		const char* largeImageText;
		const char* smallImageKey;
		const char* smallImageText;
		const char* partyId;
		int partySize;
		int partyMax;
		const char* matchSecret;
		const char* joinSecret;
		const char* spectateSecret;
		int8_t instance;
	} DiscordRichPresence;

	void Discord_Initialize(const char* applicationId,
        int handlers,
        int autoRegister,
        const char* optionalSteamId);

	void Discord_UpdatePresence(const DiscordRichPresence* presence);

	typedef struct {
		int type;
		int state;
		int ammoInClip;
		int totalAmmo;
		char field_10[0x0C];
	} CWeapon;

	typedef struct {
		char field_0[0x544];
		float maxHealth;
		char field_548[0x58];
		CWeapon weapons[13];
	} CPed;
]]
DiscordRPC = ffi.load('moonloader/lib/discord-rpc.dll')
dRPC = ffi.new("DiscordRichPresence")
require('discord') -- Discord Rich Presense

ffi.copy(Graphics.ClientSettings.tNickname, Config.playerName)
ffi.copy(Graphics.ClientSettings.tAddress, Config.serverAddress)

local font_flag = require('moonloader').font_flag
AiralFont = renderCreateFont('Arial', 10, font_flag.SHADOW)