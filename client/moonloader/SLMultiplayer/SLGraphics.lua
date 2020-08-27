CGraphics =
{
  wClient = imgui.new.bool(true),
  ClientInputs =
  {
    tNickname = imgui.new.char[24]('PlayerName'),
    tAddress = imgui.new.char[24]('127.0.0.1:7777')
  },
  tClientPopupText = 'Client is ready!',
  tClientSelectedServer = 0,
  wChat = imgui.new.bool(false),
  tChatOpen = false,
  ChatSettings =
  {
    tChatLines = 10,
    tMaxScroll = 0,
    tCurrentScroll = 0,
    tChatScrollbar = imgui.new.int(0),
    tChatMessages = {},
    tChatInput = imgui.new.char[144](),
    tRefocusNeed = false,
    tHistory = {},
    tHistoryLast = -1
  }
}

IM_FONTS = {}

imgui.OnInitialize(function() 
  imgui.GetIO().IniFilename = nil
	local config = imgui.ImFontConfig()
	config.MergeMode = true
	config.PixelSnapH = true
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	imgui.GetIO().Fonts:Clear()
  imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', 14, nil, glyph_ranges)
  IM_FONTS.TITLE_CLIENT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', 32, nil, glyph_ranges)
  IM_FONTS.SUBTITLE_CLIENT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', 26, nil, glyph_ranges)
  IM_FONTS.TITLE_ICON = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(FA.Solid, 28, nil, imgui.new.ImWchar[3](0xf000, 0xf83e, 0))
  IM_FONTS.INPUT_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', 18, nil, glyph_ranges)
  IM_FONTS.INFO_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', 20, nil, glyph_ranges)
  imgui.InvalidateFontsTexture()  
end)

imgui.OnFrame(function() return not isGamePaused() and CGraphics.wChat[0] end,
function(self)
  imgui.SetNextWindowPos(imgui.ImVec2(2, 10))
	imgui.SetNextWindowSize(imgui.ImVec2(1020, imgui.GetTextLineHeightWithSpacing() * CGraphics.ChatSettings.tChatLines + 50 + 2))
  imgui.PushStyleColor(imgui.Col.WindowBg, CGraphics.tChatOpen and imgui.ImVec4(0, 0, 0, 0.8) or imgui.ImVec4(0, 0, 0, 0))
  imgui.PushStyleColor(imgui.Col.Border, CGraphics.tChatOpen and imgui.ImVec4(1, 1, 1, 0.8) or imgui.ImVec4(0, 0, 0, 0))
  imgui.Begin('IMChat', CGraphics.wChat, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove)

  if CGraphics.tChatOpen then self.HideCursor = false
  else self.HideCursor = true end

  imgui.SetCursorPos(imgui.ImVec2(30, 15))
  imgui.BeginChild('##content', imgui.ImVec2(0, imgui.GetTextLineHeightWithSpacing() * CGraphics.ChatSettings.tChatLines + 2), false, not CGraphics.tChatOpen and imgui.WindowFlags.NoScrollbar)
	local clipper = imgui.ImGuiListClipper(#CGraphics.ChatSettings.tChatMessages)
	while clipper:Step() do
		for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
      if CGraphics.ChatSettings.tChatMessages[i] ~= nil then
        local timetag = ('{%6X}'):format(CGraphics.ChatSettings.tChatMessages[i].color) .. '[' .. os.date('%H:%M:%S', CGraphics.ChatSettings.tChatMessages[i].time) .. '] '
        local tpos = imgui.GetCursorPos()
        
        imgui.SetCursorPos(imgui.ImVec2(tpos.x + 1, tpos.y))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), u8(timetag .. CGraphics.ChatSettings.tChatMessages[i].text):gsub('{......}', ''):gsub('{........}', ''))
        imgui.SetCursorPos(imgui.ImVec2(tpos.x - 1, tpos.y))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), u8(timetag .. CGraphics.ChatSettings.tChatMessages[i].text):gsub('{......}', ''):gsub('{........}', ''))
        imgui.SetCursorPos(imgui.ImVec2(tpos.x, tpos.y + 1))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), u8(timetag .. CGraphics.ChatSettings.tChatMessages[i].text):gsub('{......}', ''):gsub('{........}', ''))
        imgui.SetCursorPos(imgui.ImVec2(tpos.x, tpos.y - 1))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), u8(timetag .. CGraphics.ChatSettings.tChatMessages[i].text):gsub('{......}', ''):gsub('{........}', ''))
        
        imgui.SetCursorPos(imgui.ImVec2(tpos.x, tpos.y))
        CGraphics.TextColoredRGB(u8(timetag .. CGraphics.ChatSettings.tChatMessages[i].text))
			end
		end
  end
  if CGraphics.ChatSettings.tRefocusNeed == true then
    CGraphics.ChatSettings.tRefocusNeed = false
    imgui.SetScrollHereY()
  end
  imgui.EndChild()
  if CGraphics.tChatOpen then
    imgui.SetCursorPosX(30)
    if imgui.InputText("##inputtext", CGraphics.ChatSettings.tChatInput, ffi.sizeof(CGraphics.ChatSettings.tChatInput) - 1, imgui.InputTextFlags.EnterReturnsTrue) then
      --CGraphics.addMessage(u8:decode(ffi.string(CGraphics.ChatSettings.tChatInput)), 0xFFFFFFFF)
      if ffi.string(CGraphics.ChatSettings.tChatInput):len() > 0 then
        CGraphics.addChatHistory(ffi.string(CGraphics.ChatSettings.tChatInput))
        if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
          if ffi.string(CGraphics.ChatSettings.tChatInput):match('^/.+') then
            local str = ffi.string(CGraphics.ChatSettings.tChatInput):match('^/(.+)')
            if not CGraphics.commandsHook(str) then
              SPool.sendRPC(S_RPC.SEND_COMMAND, {command = u8:decode(str)})
            end
          else
            SPool.sendRPC(S_RPC.SEND_MESSAGE, {message = u8:decode(ffi.string(CGraphics.ChatSettings.tChatInput))})
          end
          ffi.copy(CGraphics.ChatSettings.tChatInput, '')
          CGraphics.tChatOpen = false
        end
      end
    end
    imgui.SetKeyboardFocusHere()
    if imgui.IsKeyPressed(0x26) then
      if CGraphics.ChatSettings.tHistoryLast < 1 then
        CGraphics.ChatSettings.tHistoryLast = #CGraphics.ChatSettings.tHistory
      end
      if CGraphics.ChatSettings.tHistoryLast < 1 then return end
      if CGraphics.ChatSettings.tHistory[CGraphics.ChatSettings.tHistoryLast] then
        imgui.InputText('##tmp', imgui.new.char[1](), 1)
        imgui.SetKeyboardFocusHere()
        ffi.copy(CGraphics.ChatSettings.tChatInput, CGraphics.ChatSettings.tHistory[CGraphics.ChatSettings.tHistoryLast])
        CGraphics.ChatSettings.tHistoryLast = CGraphics.ChatSettings.tHistoryLast - 1
        if CGraphics.ChatSettings.tHistoryLast < 1 then
          CGraphics.ChatSettings.tHistoryLast = #CGraphics.ChatSettings.tHistory
        end
      end
    end
  end

  imgui.End()
  imgui.PopStyleColor(2)
end)

imgui.OnFrame(function() return not isGamePaused() and CGraphics.wClient[0] end,
function(self)  
  self.LockPlayer = true
  self.HideCursor = false
  imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.FirstUseEver, imgui.ImVec2(0, 0))
  imgui.SetNextWindowSize(imgui.ImVec2(CGame.cScreen.x, CGame.cScreen.y), imgui.Cond.FirstUseEver)
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0.0)
  imgui.Begin('##SLClient', CGraphics.wClient, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove)

  local drawList = imgui.GetWindowDrawList()
  local sPos = imgui.GetCursorScreenPos()

  -- Client Menu on Top
  imgui.SetCursorPos(imgui.ImVec2(0, 0))
  imgui.PushStyleColorU32(imgui.Col.ChildBg, 0xFF666666)
  imgui.BeginChild('##TopMenu', imgui.ImVec2(imgui.GetWindowWidth(), 60))

  imgui.PushStyleColorU32(imgui.Col.FrameBg, 0xFF9E9E9E)
  imgui.PushStyleColorU32(imgui.Col.Button, 0xFF9E9E9E)
  imgui.SetCursorPos(imgui.ImVec2(10, 5))
  imgui.BeginGroup()
  imgui.PushFont(IM_FONTS.TITLE_CLIENT)
  imgui.Text('SL:MP')
  imgui.PopFont()
  imgui.SetCursorPosY(35)
  imgui.Text('0.0.1-Alpha')
  imgui.EndGroup()  
  imgui.SameLine(0, 100)
  imgui.SetCursorPosY(5)
  imgui.BeginGroup()
  imgui.Text('PLAYER NAME')
  imgui.PushItemWidth(100.0)
  imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(3, 7))
  imgui.PushFont(IM_FONTS.INPUT_FONT)
  imgui.InputText('##PlayerName', CGraphics.ClientInputs.tNickname, ffi.sizeof(CGraphics.ClientInputs.tNickname)-1)
  imgui.PopFont()
  imgui.PopStyleVar()
  imgui.PopItemWidth()
  imgui.EndGroup()
  imgui.SameLine()
  imgui.PushFont(IM_FONTS.TITLE_ICON)
  if imgui.Button('\xef\x81\x8b', imgui.ImVec2(50, 50)) then
    if CGraphics.tClientSelectedServer < 1 then
      CGraphics.tClientPopupText = "Select server to play!"
    else
      if LPlayer.lpGameState == S_GAMESTATES.GS_DISCONNECTED then
        clUpdatingInfo = false
        local selServ = CGraphics.tClientSelectedServer
        LPlayer.lpNickname = u8:decode(ffi.string(CGraphics.ClientInputs.tNickname))
        CConfig.playerName = LPlayer.lpNickname
        CGraphics.tClientPopupText = "Connecting to server..."
        SPool.setAddress(tostring(CConfig.servers[selServ].ip), tonumber(CConfig.servers[selServ].port))
        SPool.connect()
      end
    end
  end
  imgui.SameLine()
  if imgui.Button('\xef\x81\xa7', imgui.ImVec2(50, 50)) then
    local ip, port = ffi.string(CGraphics.ClientInputs.tAddress):match('^(%S+):(%d+)$')
    if ip and port then
      local listed = false
      for i = 1, #CConfig.servers do
        if ip == CConfig.servers[i].ip and port == CConfig.servers[i].port then
          CGraphics.tClientPopupText = "Server is already in your list!"
          listed = true
          break
        end
      end
      if not listed then
      local slot = #CConfig.servers + 1
        CConfig.servers[slot] =
        {
          ip = ip,
          port = port,
          players = 0,
          maxPlayers = 0,
          language = '',
          gamemode = '',
          version = '',
          ping = 999,
          website = '',
          playersPool = {}
        }
        CGraphics.tClientPopupText = "Server added to your list!"
      end
    else
      CGraphics.tClientPopupText = "Invalid Server Address!"
    end
  end
  imgui.SameLine()
  if imgui.Button('\xef\x81\xa8', imgui.ImVec2(50, 50)) then
    for i = #CConfig.servers, 1, -1 do
      if i == CGraphics.tClientSelectedServer then
        table.remove(CConfig.servers, i)
        CGraphics.tClientSelectedServer = 0
        CGraphics.tClientPopupText = "Server removed from list!"
        break
      end
    end
  end
  imgui.SameLine()
  imgui.Button('\xef\x82\x85', imgui.ImVec2(50, 50))
  imgui.SameLine()
  imgui.Button('\xef\x80\xa1', imgui.ImVec2(50, 50))
  imgui.PopFont()
  imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - CGame.cScreen.x / 6 + 5, 5))
  imgui.BeginGroup()
  imgui.Text('SERVER ADDRESS (IP:PORT)')
  imgui.SetCursorPosY(23)
  imgui.PushItemWidth(CGame.cScreen.x / 6 - 10)
  imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(3, 7))
  imgui.PushFont(IM_FONTS.INPUT_FONT)
  imgui.InputText('##ServerAddress', CGraphics.ClientInputs.tAddress, ffi.sizeof(CGraphics.ClientInputs.tAddress)-1)
  imgui.PopFont()
  imgui.PopStyleVar()
  imgui.PopItemWidth()
  imgui.EndGroup()
  imgui.PopStyleColor(2)

  imgui.EndChild()
  imgui.PopStyleColor()
  -- Client Menu on Top

  -- Client Center Menu
  imgui.SetCursorPos(imgui.ImVec2(0, 60))
  imgui.PushStyleColorU32(imgui.Col.ChildBg, 0xFF9E9E9E)
  imgui.BeginChild('##MainField', imgui.ImVec2(imgui.GetWindowWidth() - CGame.cScreen.x / 6, imgui.GetWindowHeight() - 80))

  imgui.PushStyleColorU32(imgui.Col.Text, 0xFF000000)
  imgui.SetCursorPos(imgui.ImVec2(20, 20))
  imgui.BeginGroup()
  for i = 1, #CConfig.servers do
    imgui.PushStyleColorU32(imgui.Col.ChildBg, CGraphics.tClientSelectedServer == i and 0xFFF1F1F1 or 0xFFFFFFFF)
    imgui.BeginChild('##ServerInList' .. i, imgui.ImVec2(imgui.GetWindowWidth() - 40, 60))
    
    imgui.SetCursorPos(imgui.ImVec2(10, 5))
    imgui.BeginGroup()
    imgui.PushFont(IM_FONTS.SUBTITLE_CLIENT)
    imgui.Text(u8(tostring(CConfig.servers[i].name or 'Click to Load Server Info')))
    imgui.PopFont()
    imgui.Text(tostring('Server Address: ' .. CConfig.servers[i].ip .. ':' .. CConfig.servers[i].port))
    imgui.EndGroup()
    
    imgui.EndChild()
    if imgui.IsItemHovered() and imgui.IsItemClicked(0) then
      if CGraphics.tClientSelectedServer == i then
        CGraphics.tClientSelectedServer = 0
        clUpdatingInfo = false
      else
        CGraphics.tClientSelectedServer = i
        LPlayer.lpGameState = S_GAMESTATES.GS_CONNECTING
        udp:settimeout(0)
        udp:setpeername(CConfig.servers[i].ip, CConfig.servers[i].port)
        lua_thread.create(UDP_Receiver)
        clUpdatingMS = os.clock()
        SPool.sendPacket(S_PACKETS.SERVER_INFO, {token = sVolumeToken[0]})
        clUpdatingInfo = true
      end
    end
    imgui.PopStyleColor()
    imgui.Spacing()
  end
  imgui.EndGroup()
  imgui.PopStyleColor()

  imgui.EndChild()
  imgui.PopStyleColor()
  -- Client Center Menu

  -- Client Status Bar
  imgui.SetCursorPos(imgui.ImVec2(0, imgui.GetWindowHeight() - 20))
  imgui.PushStyleColorU32(imgui.Col.ChildBg, 0xFFFFFFFF)
  imgui.BeginChild('##StatusBar', imgui.ImVec2(imgui.GetWindowWidth() - CGame.cScreen.x / 6, 20))
  
  imgui.SetCursorPos(imgui.ImVec2(5, imgui.GetWindowHeight() / 2 - imgui.CalcTextSize(u8(CGraphics.tClientPopupText)).y / 2))
  imgui.TextColored(imgui.ImVec4(0.3, 0.3, 0.3, 1), u8(CGraphics.tClientPopupText))
  
  imgui.EndChild()
  imgui.PopStyleColor()
  -- Client Status Bar

  -- Client Server Info Panel
  imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - CGame.cScreen.x / 6 , 60))
  imgui.PushStyleColorU32(imgui.Col.ChildBg, 0xFF666666)
  imgui.BeginChild('##SideBar', imgui.ImVec2(CGame.cScreen.x / 6, CGame.cScreen.y / 5))

  imgui.SetCursorPos(imgui.ImVec2(5, 14))
  imgui.BeginGroup()
  imgui.PushFont(IM_FONTS.INFO_FONT)
  local selServ = CGraphics.tClientSelectedServer
  imgui.Text(u8('Address: ' .. tostring(selServ > 0 and (CConfig.servers[selServ].ip .. ':' .. CConfig.servers[selServ].port))))
  imgui.Text(u8('Players: ' .. tostring(selServ > 0 and (CConfig.servers[selServ].players .. ' / ' .. CConfig.servers[selServ].maxPlayers))))
  imgui.Text(u8('Ping: ' .. tostring(selServ > 0 and math.floor(CConfig.servers[selServ].ping) .. ' ms')))
  imgui.Text(u8('Language: ' .. tostring(selServ > 0 and CConfig.servers[selServ].language)))
  imgui.Text(u8('Version: ' .. tostring(selServ > 0 and CConfig.servers[selServ].version)))
  imgui.Text(u8('Website: ' .. tostring(selServ > 0 and CConfig.servers[selServ].website)))
  imgui.PopFont()
  imgui.EndGroup()

  imgui.EndChild()
  imgui.PopStyleColor()
  -- Client Server Info Panel

  -- Client Server Players
  imgui.PushStyleColorU32(imgui.Col.ChildBg, 0xFF444444)
  imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - CGame.cScreen.x / 6 , 60 + CGame.cScreen.y / 5))
  imgui.BeginChild('##SideBar2', imgui.ImVec2(CGame.cScreen.x / 6, imgui.GetWindowHeight() - 60 + CGame.cScreen.y / 5))

  imgui.SetCursorPos(imgui.ImVec2(10, 10))
  imgui.PushFont(IM_FONTS.SUBTITLE_CLIENT)
  imgui.Text('PLAYERS ONLINE')
  imgui.PopFont()

  imgui.EndChild()
  imgui.PopStyleColor()
  -- Client Server Players

  -- DrawList Drawing
  drawList:AddLine(imgui.ImVec2(sPos.x + imgui.GetWindowWidth() - CGame.cScreen.x / 6 , sPos.y + 60.5), imgui.ImVec2(sPos.x + imgui.GetWindowWidth(), sPos.y + 60.5), 0xFF9E9E9E, 2.0)
  -- DrawList Drawing

  imgui.End()
  imgui.PopStyleVar(2)
end)

CGraphics.addMessage = function(message, color)
  if type(message) ~= 'string' or type(color) ~= 'number' then
    return false
  end
  if #CGraphics.ChatSettings.tChatMessages >= 100 then
    for i = #CGraphics.ChatSettings.tChatMessages, 1, -1 do
      if i == 1 then
        table.remove(CGraphics.ChatSettings.tChatMessages, i)
      end
    end
  end
  table.insert(CGraphics.ChatSettings.tChatMessages, {text = message, color = color, time = os.time()})
  CGraphics.ChatSettings.tRefocusNeed = true
end
CGraphics.addChatHistory = function(text)
  if #CGraphics.ChatSettings.tHistory > 10 then
    for i = #CGraphics.ChatSettings.tHistory, 1, -1 do
      if i == 1 then
        table.remove(CGraphics.ChatSettings.tHistory, i)
      end
    end
  end
  table.insert(CGraphics.ChatSettings.tHistory, text)
  CGraphics.ChatSettings.tHistoryLast = #CGraphics.ChatSettings.tHistory
end
CGraphics.TextColoredRGB = function(text)
  local style = imgui.GetStyle()
  local colors = style.Colors
  local ImVec4 = imgui.ImVec4

  local explode_argb = function(argb)
      local a = bit.band(bit.rshift(argb, 24), 0xFF)
      local r = bit.band(bit.rshift(argb, 16), 0xFF)
      local g = bit.band(bit.rshift(argb, 8), 0xFF)
      local b = bit.band(argb, 0xFF)
      return a, r, g, b
  end

  local getcolor = function(color)
      if color:sub(1, 6):upper() == 'SSSSSS' then
          local r, g, b = colors[1].x, colors[1].y, colors[1].z
          local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
          return ImVec4(r, g, b, a / 255)
      end
      local color = type(color) == 'string' and tonumber(color, 16) or color
      if type(color) ~= 'number' then return end
      local r, g, b, a = explode_argb(color)
      return imgui.ImVec4(r, g, b, a)
  end

  local render_text = function(text_)
      for w in text_:gmatch('[^\r\n]+') do
          local text, colors_, m = {}, {}, 1
          w = w:gsub('{(......)}', '{%1FF}')
          while w:find('{........}') do
              local n, k = w:find('{........}')
              local color = getcolor(w:sub(n + 1, k - 1))
              if color then
                  text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                  colors_[#colors_ + 1] = color
                  m = n
              end
              w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
          end
          if text[0] then
              for i = 0, #text do
                  imgui.TextColored(colors_[i] or colors[1], text[i])
                  imgui.SameLine(nil, 0)
              end
              imgui.NewLine()
          else imgui.Text(w) end
      end
  end

  render_text(text)
end

function CGraphics.commandsHook(command)
  if command == 'save' then
    local file = io.open('savedPosition.txt', 'w+')
    if file then
      local x, y, z = getCharCoordinates(PLAYER_PED)
      file:write(tostring(x .. ', ' .. y .. ', ' .. z))
      file:close()
    end
    CGraphics.addMessage('Position saved!', 0xFFFFFFFF)
    return true
  end
  return false
end