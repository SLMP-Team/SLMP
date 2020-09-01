Config =
{
  IP = '*',
  Port = 7777,
  Slots = 10,
  Gamemode = 'new',
  Chatlog = 0,
  Hostname = 'SL:MP Server',
  Language = 'English',
  Website = 'www.sl-mp.com',
  Stream = 300,
  OnFootRate = 40,
  InCarRate = 40,
  StreamRate = 1000,
  Rcon = '',
  Password = ''
}

function Config:load()
  local file = io.open('../server.cfg', 'r')
  if file then
    for lines in file:lines() do
      local name, option = lines:match('^(%S+)%s+(.+)$')
      if name and option then
        -- enjoy shit code, everything for you :3
        if name == 'bind' then Config.IP = option
        elseif name == 'port' then Config.Port = tonumber(option) or 0
        elseif name == 'maxplayers' then Config.Slots = tonumber(option) or 10
        elseif name == 'gamemode' then Config.Gamemode = option
        elseif name == 'chatlogging' then Config.Chatlog = tonumber(option) or 0
        elseif name == 'hostname' then Config.Hostname = option
        elseif name == 'language' then Config.Language = option
        elseif name == 'website' then Config.Website = option
        elseif name == 'stream_distance' then Config.Stream = tonumber(option) or 300
        elseif name == 'stream_rate' then Config.StreamRate = tonumber(option) or 1000
        elseif name == 'onfoot_rate' then Config.OnFootRate = tonumber(option) or 40
        elseif name == 'incar_rate' then Config.InCarRate = tonumber(option) or 40
        elseif name == 'rcon_password' then Config.Rcon = option
        elseif name == 'password' then Config.Password = option end
      end
    end
    file:close()
  end
end