General =
{
  Version = 1,
  VersionS = '0.0.1-RC8',
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

dofile(modules..'/patches.lua') -- lets include some patch methods
dofile(modules..'/game.lua') -- lets include game functions, who doesn`t like game functions?
dofile(modules..'/client.lua') -- some useful SL:MP methods and functions
dofile(modules..'/players.lua')
dofile(modules..'/graphics.lua')

local font_flag = require('moonloader').font_flag
AiralFont = renderCreateFont('Arial', 10, font_flag.SHADOW)