General =
{
  Version = 2,
  VersionS = '0.0.1-RC-X',
  Timer = os.time(),
  StreamUpdate = os.clock(),
  OnFootUpdate = os.clock()
}

dofile(modules..'/clients.lua') -- everything connected to players
Config:load() -- load configs from server.cfg file