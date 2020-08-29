local scrX, scrY = getScreenResolution()
CGraphics =
{
  wClient = imgui.new.bool(true),
  tClientPopupText = 'Welcome to SL:MP Client, we`re hope you`ll enjoy playing!',
  ClientSettings =
  {
    tWallpaperPos = {-(scrX/2), scrX},
    tWallpaperTime = os.time() + 15,
    tWallpaperID = 1,
    tNickname = imgui.new.char[20](),
    tStatusBarPos = scrY,
    tSideBarPos = scrX,
    tAddress = imgui.new.char[128]()
  },
  wChat = imgui.new.bool(false),
  ChatSettings =
  {
    tChatLines = 10,
    tChatInput = imgui.new.char[144](),
    tRefocusNeed = false,
    tChatMessages = {},
    tChatFontSize = 14,
    tChatFontLoaded = true
  },
  wLockMove = imgui.new.bool(false)
}

IM_FONTS = {}
IM_WALLPAPER = {}
imgui.OnInitialize(function() 
  imgui.GetIO().IniFilename = nil
  for i = 1, 6 do
    local tmp = imgui.CreateTextureFromFile(mpFolder .. 'Resources\\Wallpapers\\wall'..i..'.jpg')
    if tmp then IM_WALLPAPER[#IM_WALLPAPER+1] = tmp end
  end
  CGraphics.ClientSettings.tWallpaperID = math.random(1, #IM_WALLPAPER)
  local config = imgui.ImFontConfig()
	config.MergeMode = true
	config.PixelSnapH = true
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	imgui.GetIO().Fonts:Clear()
  imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', scrX / 137, nil, glyph_ranges)
  IM_FONTS.TITLE_CLIENT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', scrX * 0.028, nil, glyph_ranges)
  IM_FONTS.SUBTITLE_CLIENT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', scrX * 0.015, nil, glyph_ranges)
  IM_FONTS.TITLE_ICON = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(FA.Solid, 28, nil, imgui.new.ImWchar[3](0xf000, 0xf83e, 0))
  IM_FONTS.INPUT_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', 18, nil, glyph_ranges)
  IM_FONTS.INFO_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', scrX / 96, nil, glyph_ranges)
  IM_FONTS.CHAT_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', CGraphics.ChatSettings.tChatFontSize, nil, glyph_ranges)
  imgui.InvalidateFontsTexture()  
end)

imgui.OnFrame(function() return not isGamePaused() and CGraphics.wLockMove[0] and not CGraphics.wClient[0] end,
function(self) 
  self.LockPlayer = true
  self.HideCursor = true
  imgui.Begin('##LockWindow', CGraphics.wLockMove, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoBackground)
  imgui.End()
end)

imgui.OnFrame(function() return not isGamePaused() and CGraphics.wChat[0] end,
function()
  if not CGraphics.ChatSettings.tChatFontLoaded then
    CGraphics.ChatSettings.tChatFontLoaded = true
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    IM_FONTS.CHAT_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', CGraphics.ChatSettings.tChatFontSize, nil, glyph_ranges)
    imgui.InvalidateFontsTexture() 
  end
end,
function(self)
  imgui.SetNextWindowPos(imgui.ImVec2(2, 10))
	imgui.SetNextWindowSize(imgui.ImVec2(CGame.cScreen.x / 1.8, (CGraphics.ChatSettings.tChatFontSize + 4) * CGraphics.ChatSettings.tChatLines + 50 + 2))
  imgui.PushStyleColor(imgui.Col.WindowBg, CGraphics.tChatOpen and imgui.ImVec4(0, 0, 0, 0.8) or imgui.ImVec4(0, 0, 0, 0))
  imgui.PushStyleColor(imgui.Col.Border, CGraphics.tChatOpen and imgui.ImVec4(1, 1, 1, 0.8) or imgui.ImVec4(0, 0, 0, 0))
  imgui.Begin('SLMP:Chat', CGraphics.wChat, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove)

  if CGraphics.tChatOpen then self.HideCursor = false
  else self.HideCursor = true end

  imgui.SetCursorPos(imgui.ImVec2(30, 15))
  imgui.BeginChild('##content', imgui.ImVec2(0, (CGraphics.ChatSettings.tChatFontSize + 4) * CGraphics.ChatSettings.tChatLines + 2), false, not CGraphics.tChatOpen and imgui.WindowFlags.NoScrollbar)
	local clipper = imgui.ImGuiListClipper(#CGraphics.ChatSettings.tChatMessages)
  imgui.PushFont(IM_FONTS.CHAT_FONT)
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
        CGraphics.TextColoredRGB(timetag .. CGraphics.ChatSettings.tChatMessages[i].text)
			end
		end
  end
  imgui.PopFont()
  if CGraphics.ChatSettings.tRefocusNeed == true then
    CGraphics.ChatSettings.tRefocusNeed = false
    imgui.SetScrollHereY()
  end
  imgui.EndChild()
  if CGraphics.tChatOpen then
    imgui.SetCursorPosX(30)
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(5, 5))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 5.0)
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(72 / 255, 72 / 255, 72 / 255, 1))
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(219 / 255, 219 / 255, 219 / 255, 1))
    if imgui.InputText("##inputtext", CGraphics.ChatSettings.tChatInput, ffi.sizeof(CGraphics.ChatSettings.tChatInput) - 1, imgui.InputTextFlags.EnterReturnsTrue) then
      CGraphics.tChatOpen = false
      if ffi.string(CGraphics.ChatSettings.tChatInput):len() > 0 then
        if ffi.string(CGraphics.ChatSettings.tChatInput):match('^/.+') then
          local str = ffi.string(CGraphics.ChatSettings.tChatInput):match('^/(.+)')
          if not CGraphics.commandsHook(str) then
            if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
              local bs = SLNet.createBitStream()
              SLNet.writeInt16(bs, S_RPC.SEND_COMMAND)
              SLNet.writeString(bs, u8:decode(str))
              SPool.sendRPC(bs)
              SLNet.deleteBitStream(bs)
            end
          end
        else
          if LPlayer.lpGameState == S_GAMESTATES.GS_CONNECTED then
            local bs = SLNet.createBitStream()
            SLNet.writeInt16(bs, S_RPC.SEND_MESSAGE)
            SLNet.writeString(bs, u8:decode(ffi.string(CGraphics.ChatSettings.tChatInput)))
            SPool.sendRPC(bs)
            SLNet.deleteBitStream(bs)
          end
        end
        ffi.copy(CGraphics.ChatSettings.tChatInput, '')
      end
    end
    imgui.SetKeyboardFocusHere()
    imgui.PopStyleVar(2)
    imgui.PopStyleColor(2)
  end

  imgui.End()
  imgui.PopStyleColor(2)
end)

imgui.OnFrame(function() return CGraphics.wClient[0] and not isGamePaused() end,
function(self) 
  imgui.LockPlayer = true
  imgui.HideCursor = false
  imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.FirstUseEver, imgui.ImVec2(0.0, 0.0))
  imgui.SetNextWindowSize(imgui.ImVec2(CGame.cScreen.x, CGame.cScreen.y), imgui.Cond.Always)
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0.0)
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0.0)
  imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 1))
  imgui.Begin('SL-MP', CGraphics.wClient, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove)

  imgui.SetCursorPos(imgui.ImVec2(0, 0))
  local scPos = imgui.GetCursorScreenPos()
  local drawList = imgui.GetWindowDrawList()

  imgui.SetCursorPos(imgui.ImVec2(CGraphics.ClientSettings.tWallpaperPos[1], 0))
  imgui.Image(IM_WALLPAPER[CGraphics.ClientSettings.tWallpaperID], imgui.ImVec2(CGame.cScreen.x / 2, CGame.cScreen.y), imgui.ImVec2(0, 0), imgui.ImVec2(0.5, 1))
  imgui.SetCursorPos(imgui.ImVec2(CGraphics.ClientSettings.tWallpaperPos[2], 0))
  imgui.Image(IM_WALLPAPER[CGraphics.ClientSettings.tWallpaperID], imgui.ImVec2(CGame.cScreen.x / 2, CGame.cScreen.y), imgui.ImVec2(0.5, 0), imgui.ImVec2(1, 1))
  if CGraphics.ClientSettings.tWallpaperTime >= os.time() then
    if CGraphics.ClientSettings.tWallpaperPos[1] < 0 then
      CGraphics.ClientSettings.tWallpaperPos[1] = CGraphics.ClientSettings.tWallpaperPos[1] + (CGame.cScreen.x / 30)
    elseif CGraphics.ClientSettings.tWallpaperPos[1] > 0 then
      CGraphics.ClientSettings.tWallpaperPos[1] = 0
    end
    if CGraphics.ClientSettings.tWallpaperPos[2] > CGame.cScreen.x / 2 then
      CGraphics.ClientSettings.tWallpaperPos[2] = CGraphics.ClientSettings.tWallpaperPos[2] - (CGame.cScreen.x / 30)
    elseif CGraphics.ClientSettings.tWallpaperPos[2] < CGame.cScreen.x / 2 then
      CGraphics.ClientSettings.tWallpaperPos[2] = CGame.cScreen.x / 2
    end
  else
    if CGraphics.ClientSettings.tWallpaperPos[2] < scrX or CGraphics.ClientSettings.tWallpaperPos[1] > -(scrX/2) then
      CGraphics.ClientSettings.tWallpaperPos[1] = CGraphics.ClientSettings.tWallpaperPos[1] - (CGame.cScreen.x / 30)
      CGraphics.ClientSettings.tWallpaperPos[2] = CGraphics.ClientSettings.tWallpaperPos[2] + (CGame.cScreen.x / 30)
    else
      CGraphics.ClientSettings.tWallpaperPos[1] = -(scrX/2)
      CGraphics.ClientSettings.tWallpaperPos[2] = scrX
      local wasPicture = CGraphics.ClientSettings.tWallpaperID
      local findPicture = false
      while not findPicture do
        CGraphics.ClientSettings.tWallpaperID = math.random(1, #IM_WALLPAPER)
        findPicture = true
        if #IM_WALLPAPER > 1 and wasPicture == CGraphics.ClientSettings.tWallpaperID then
          findPicture = false
        end
      end
      CGraphics.ClientSettings.tWallpaperTime = os.time() + 15
    end
  end

  drawList:AddRectFilled(imgui.ImVec2(scPos.x, scPos.y), imgui.ImVec2(scPos.x + scrX / 4, scPos.y + scrY / 12), 0xAA17181A, 10.0, imgui.DrawCornerFlags.BotRight)

  imgui.SetCursorPos(imgui.ImVec2(scrX / 160, scrY / 60))
  imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(10, 10))
  imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 5.0)
  imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(72 / 255, 72 / 255, 72 / 255, 1))
  imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(219 / 255, 219 / 255, 219 / 255, 1))
  imgui.PushFont(IM_FONTS.SUBTITLE_CLIENT)
  imgui.PushItemWidth(scrX / 4 / 1.5)
  imgui.InputTextWithHint('##nickname', 'Player Name', CGraphics.ClientSettings.tNickname, ffi.sizeof(CGraphics.ClientSettings.tNickname) - 1)
  imgui.PopItemWidth()
  imgui.SameLine()
  imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(219 / 255, 219 / 255, 219 / 255, 1))
  if imgui.Button('CONNECT') then
    LPlayer.lpNickname = u8:decode(ffi.string(CGraphics.ClientSettings.tNickname))
    local ip, port = u8:decode(ffi.string(CGraphics.ClientSettings.tAddress)):match('^(%S+):(%d+)$')
    if ip and port and LPlayer.lpGameState == S_GAMESTATES.GS_DISCONNECTED then
      CConfig.playerName = LPlayer.lpNickname
      CConfig.address = u8:decode(ffi.string(CGraphics.ClientSettings.tAddress))
      CGraphics.tClientPopupText = 'Connecting to server...'
      SPool.setAddress(ip, port)
      SPool.connect()
    end
  end
  imgui.PopFont()
  imgui.PopStyleColor(3)
  imgui.PopStyleVar(2)

  imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(23 / 255, 24 / 255, 26 / 255, 1))
  imgui.SetCursorPos(imgui.ImVec2(0, CGraphics.ClientSettings.tStatusBarPos))
  if CGraphics.ClientSettings.tStatusBarPos > scrY - 20 then
    CGraphics.ClientSettings.tStatusBarPos = 
    CGraphics.ClientSettings.tStatusBarPos - 0.5
  end
  imgui.BeginChild('##statusbar', imgui.ImVec2(scrX, 20))
  imgui.SetCursorPos(imgui.ImVec2(10, imgui.GetWindowHeight() / 2 - imgui.GetTextLineHeight() / 2))
  imgui.Text(u8(CGraphics.tClientPopupText))
  imgui.EndChild()
  
  imgui.SetCursorPos(imgui.ImVec2(CGraphics.ClientSettings.tSideBarPos, 0))
  if CGraphics.ClientSettings.tSideBarPos > (scrX - scrX / 4) 
  and CGraphics.ClientSettings.tStatusBarPos <= scrY - 20 then
    CGraphics.ClientSettings.tSideBarPos =
    CGraphics.ClientSettings.tSideBarPos - 6
  end
  if CGraphics.ClientSettings.tSideBarPos < (scrX - scrX / 4) then
    CGraphics.ClientSettings.tSideBarPos = (scrX - scrX / 4)
  end
  imgui.BeginChild('##sidebar', imgui.ImVec2(scrX / 4, scrY))

  imgui.PushFont(IM_FONTS.TITLE_CLIENT)
  imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize('SIMPLE LUA').x / 2, scrY / 21.6))
  imgui.Text('SIMPLE LUA')
  imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize('MULTIPLAYER').x / 2)
  imgui.Text('MULTIPLAYER')
  imgui.PopFont()
  imgui.PushFont(IM_FONTS.SUBTITLE_CLIENT)
  imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize('Developed by SL Team').x / 2)
  imgui.Text('Developed by SL Team')

  imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 4, scrY / 4.6))
  imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(10, 10))
  imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 5.0)
  imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(72 / 255, 72 / 255, 72 / 255, 1))
  imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(219 / 255, 219 / 255, 219 / 255, 1))
  imgui.PushItemWidth(imgui.GetWindowWidth() - (imgui.GetWindowWidth() / 4) * 2)
  if imgui.InputTextWithHint('##address', 'Server Address', CGraphics.ClientSettings.tAddress, ffi.sizeof(CGraphics.ClientSettings.tAddress) - 1, imgui.InputTextFlags.EnterReturnsTrue) then
    local ip, port = u8:decode(ffi.string(CGraphics.ClientSettings.tAddress)):match('^(%S+):(%d+)$')
    if ip and port then
      udp:settimeout(0)
      udp:setpeername(ip, port)
      local bs = SLNet.createBitStream()
      SLNet.writeInt16(bs, S_PACKETS.SERVER_INFO)
      SPool.sendPacket(bs)
      SLNet.deleteBitStream(bs)
      ltServerAns = os.clock()
    end
  end
  imgui.PopItemWidth()
  imgui.PopStyleColor(2)
  imgui.PopStyleVar(2)
  imgui.PopFont()

  imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize('Don`t forget to change your nickname').x / 2)
  imgui.Text('Don`t forget to change your nickname')

  imgui.SetCursorPosY(scrY / 2.7)
  imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(29 / 255, 30 / 255, 32 / 255, 1))
  imgui.BeginChild('##serverinfo', imgui.ImVec2(imgui.GetWindowWidth(), scrY / 6))
  imgui.SetCursorPos(imgui.ImVec2(20, 18))
  imgui.BeginGroup()
  imgui.PushFont(IM_FONTS.INFO_FONT)
  imgui.Text(u8('Name: ' .. SPool.sName))
  imgui.Text(u8('Players: ' .. SPool.sPlayers[1] .. ' / ' .. SPool.sPlayers[2]))
  imgui.Text(u8('Ping: ' .. ('%d'):format(SPool.sPing) .. ' ms'))
  imgui.Text(u8('Language: ' .. SPool.sLanguage))
  imgui.Text(u8('Version: ' .. SPool.sVersion))
  imgui.Text(u8('Website: ' .. SPool.sWebsite))
  imgui.PopFont()
  imgui.EndGroup()
  imgui.EndChild()
  imgui.PopStyleColor(1)
  
  imgui.Spacing()
  imgui.PushFont(IM_FONTS.SUBTITLE_CLIENT)
  imgui.SetCursorPosX(10)
  imgui.Text('Players Online')
  imgui.PopFont()

  imgui.Spacing() imgui.Spacing()
  local curPos = imgui.GetCursorPos()
  imgui.BeginChild('##players', imgui.ImVec2(imgui.GetWindowWidth(), imgui.GetWindowHeight() - curPos.y))
  imgui.PushFont(IM_FONTS.INFO_FONT)
  imgui.SetCursorPosX(20)
  imgui.BeginGroup()
  for i = 1, #SPool.sPList do
    imgui.Text(u8(SPool.sPList[i][1]))
    imgui.SameLine(0, 80)
    imgui.Text(SPool.sPList[i][2]..' ms')
    imgui.Separator()
  end
  imgui.EndGroup()
  imgui.PopFont()
  imgui.EndChild()

  imgui.EndChild()
  imgui.PopStyleColor(1)

  imgui.End()
  imgui.PopStyleColor(1)
  imgui.PopStyleVar(3)
end)

CGraphics.addMessage = function(message, color)
  if type(message) ~= 'string' 
  or type(color) ~= 'number' then
    return false
  end
  table.insert(CGraphics.ChatSettings.tChatMessages, {text = message:sub(1, 128), color = color, time = os.time()})
  CGraphics.ChatSettings.tRefocusNeed = true
end
local function split(str, delim, plain)
  local tokens, pos, plain = {}, 1, not (plain == false)
  repeat
    local npos, epos = string.find(str, delim, pos, plain)
    table.insert(tokens, string.sub(str, pos, npos and npos - 1))
    pos = epos and epos + 1
  until not pos
  return tokens
end
CGraphics.TextColoredRGB = function(text, wrapped)
  text = text:gsub('{(%x%x%x%x%x%x)}', '{%1FF}')
  local render_func = function(clr, text)
      if clr then imgui.PushStyleColor(imgui.Col.Text, clr) end
      imgui.TextUnformatted(u8(text))
      if clr then imgui.PopStyleColor() end
  end

  local color = imgui.GetStyle().Colors[imgui.Col.Text]
  for _, w in ipairs(split(text, '\n')) do
      local start = 1
      local a, b = w:find('{........}', start)
      while a do
          local t = w:sub(start, a - 1)
          if #t > 0 then
              render_func(color, t)
              imgui.SameLine(nil, 0)
          end

          local clr = w:sub(a + 1, b - 1)
          if clr:upper() == 'STANDART' then 
            color = imgui.GetStyle().Colors[imgui.Col.Text]
          else
              clr = tonumber(clr, 16)
              if clr then
                  local r = bit.band(bit.rshift(clr, 24), 0xFF)
                  local g = bit.band(bit.rshift(clr, 16), 0xFF)
                  local b = bit.band(bit.rshift(clr, 8), 0xFF)
                  local a = bit.band(clr, 0xFF)
                  color = imgui.ImVec4(r / 255, g / 255, b / 255, a / 255)
              end
          end

          start = b + 1
          a, b = w:find('{........}', start)
      end
      imgui.NewLine()
      if #w > start-1 then
          imgui.SameLine(nil, 0)
          render_func(color, w:sub(start))
      end
  end
end
function CGraphics.commandsHook(command)
  if command:match('^pagesize') then
    local num = command:match('^pagesize%s+(%d+)')
    if not num then
      CGraphics.addMessage('/pagesize [1-20]', 0xF5F5F5FF)
      return true
    end
    num = tonumber(num)
    if num < 1 or num > 20 then
      CGraphics.addMessage('/pagesize [1-20]', 0xF5F5F5FF)
      return true
    end
    CGraphics.ChatSettings.tChatLines = num
    return true
  elseif command:match('^fontsize') then
    local num = command:match('^fontsize%s+(%d+)')
    if not num then
      CGraphics.addMessage('/fontsize [10-30]', 0xF5F5F5FF)
      return true
    end
    num = tonumber(num)
    if num < 10 or num > 30 then
      CGraphics.addMessage('/fontsize [10-30]', 0xF5F5F5FF)
      return true
    end
    CGraphics.ChatSettings.tChatFontSize = num
    CGraphics.ChatSettings.tChatFontLoaded = false
    return true
  elseif command == 'save' then
    local file = io.open('savedPosition.txt', 'w+')
    if file then
      local x, y, z = getCharCoordinates(PLAYER_PED)
      file:write(tostring(x .. ', ' .. y .. ', ' .. z))
      file:close()
    end
    CGraphics.addMessage('Position saved!', 0xFFFFFFFF)
    return true
  elseif command == 'disconnect' then
    removeAllServerStuff()
    SPool.disconnect(0)
    CGraphics.wClient[0] = true
    CGraphics.wChat[0] = false
    LPlayer.lpGameState = S_GAMESTATES.GS_DISCONNECTED
  elseif command == 'q' or command == 'quit' then
    os.execute('TASKKILL /IM gta_sa.exe')
    os.execute('TASKKILL /IM gtasa.exe')
    return true
  end
  return false
end