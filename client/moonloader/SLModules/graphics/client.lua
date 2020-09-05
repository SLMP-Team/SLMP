imgui.OnFrame(function() return not isGamePaused() and Graphics.wClient[0] end,
function(self)
  local scr = Game:getResolution()
  imgui.LockPlayer = true
  imgui.HideCursor = false
  imgui.SetNextWindowPos(imgui.ImVec2(0, 0), imgui.Cond.FirstUseEver, imgui.ImVec2(0.0, 0.0))
  imgui.SetNextWindowSize(imgui.ImVec2(scr[1], scr[2]), imgui.Cond.Always)
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0.0)
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0.0)
  imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0, 0, 0, 1))
  imgui.Begin('SL-MP', Graphics.wClient, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove)

  imgui.SetCursorPos(imgui.ImVec2(0, 0))
  local scPos = imgui.GetCursorScreenPos()
  local drawList = imgui.GetWindowDrawList()

  imgui.SetCursorPos(imgui.ImVec2(Graphics.ClientSettings.tWallpaperPos[1], 0))
  imgui.Image(IM_WALLPAPER[Graphics.ClientSettings.tWallpaperID], imgui.ImVec2(scr[1] / 2, scr[2]), imgui.ImVec2(0, 0), imgui.ImVec2(0.5, 1))
  imgui.SetCursorPos(imgui.ImVec2(Graphics.ClientSettings.tWallpaperPos[2], 0))
  imgui.Image(IM_WALLPAPER[Graphics.ClientSettings.tWallpaperID], imgui.ImVec2(scr[1] / 2, scr[2]), imgui.ImVec2(0.5, 0), imgui.ImVec2(1, 1))
  if Graphics.ClientSettings.tWallpaperTime >= os.time() then
    if Graphics.ClientSettings.tWallpaperPos[1] < 0 then
      Graphics.ClientSettings.tWallpaperPos[1] = Graphics.ClientSettings.tWallpaperPos[1] + (scr[1] / 30)
    elseif Graphics.ClientSettings.tWallpaperPos[1] > 0 then
      Graphics.ClientSettings.tWallpaperPos[1] = 0
    end
    if Graphics.ClientSettings.tWallpaperPos[2] > scr[1] / 2 then
      Graphics.ClientSettings.tWallpaperPos[2] = Graphics.ClientSettings.tWallpaperPos[2] - (scr[1] / 30)
    elseif Graphics.ClientSettings.tWallpaperPos[2] < scr[1] / 2 then
      Graphics.ClientSettings.tWallpaperPos[2] = scr[1] / 2
    end
  else
    if Graphics.ClientSettings.tWallpaperPos[2] < scr[1] or Graphics.ClientSettings.tWallpaperPos[1] > -(scr[1]/2) then
      Graphics.ClientSettings.tWallpaperPos[1] = Graphics.ClientSettings.tWallpaperPos[1] - (scr[1] / 30)
      Graphics.ClientSettings.tWallpaperPos[2] = Graphics.ClientSettings.tWallpaperPos[2] + (scr[1] / 30)
    else
      Graphics.ClientSettings.tWallpaperPos[1] = -(scr[1]/2)
      Graphics.ClientSettings.tWallpaperPos[2] = scr[1]
      local wasPicture = Graphics.ClientSettings.tWallpaperID
      local findPicture = false
      while not findPicture do
        Graphics.ClientSettings.tWallpaperID = math.random(1, #IM_WALLPAPER)
        findPicture = true
        if #IM_WALLPAPER > 1 and wasPicture == Graphics.ClientSettings.tWallpaperID then
          findPicture = false
        end
      end
      Graphics.ClientSettings.tWallpaperTime = os.time() + 15
    end
  end

  --drawList:AddRectFilled(imgui.ImVec2(scr[1], scr[2]), imgui.ImVec2(scr[1] + scr[1] / 4, scr[2] + scr[2] / 12), 0xAA17181A, 10.0, imgui.DrawCornerFlags.BotRight)

  imgui.SetCursorPos(imgui.ImVec2(scr[1] / 160, scr[2] / 60))
  imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(10, 10))
  imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 5.0)
  imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(72 / 255, 72 / 255, 72 / 255, 1))
  imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(219 / 255, 219 / 255, 219 / 255, 1))
  imgui.PushFont(IM_FONTS.SUBTITLE_CLIENT)
  imgui.PushItemWidth(scr[1] / 4 / 1.5)
  imgui.InputTextWithHint('##nickname', 'Player Name', Graphics.ClientSettings.tNickname, ffi.sizeof(Graphics.ClientSettings.tNickname) - 1)
  imgui.PopItemWidth()
  imgui.SameLine()
  imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(219 / 255, 219 / 255, 219 / 255, 1))
  if imgui.Button('CONNECT') then
    local ip, port = ffi.string(Graphics.ClientSettings.tAddress):match('^(%S+):(%d+)$')
    if ip and port and Player.GameState == GAMESTATE.DISCONNECTED then
      udp:settimeout(0)
      udp:setpeername(ip, tonumber(port))
      local bs = BitStream:new()
      sendPacket(PACKET.PING_SERVER, false, bs)
      Graphics.tClientPopupText = 'Connecting to server...'
      Client:connect(ffi.string(Graphics.ClientSettings.tNickname), ip, tonumber(port))
      Config.playerName = ffi.string(Graphics.ClientSettings.tNickname)
      Config.serverAddress = ffi.string(Graphics.ClientSettings.tAddress)
    end
  end
  imgui.PopFont()
  imgui.PopStyleColor(3)
  imgui.PopStyleVar(2)

  imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(23 / 255, 24 / 255, 26 / 255, 1))
  imgui.SetCursorPos(imgui.ImVec2(0, Graphics.ClientSettings.tStatusBarPos))
  if Graphics.ClientSettings.tStatusBarPos > scr[2] - 20 then
    Graphics.ClientSettings.tStatusBarPos =
    Graphics.ClientSettings.tStatusBarPos - 0.5
  end
  imgui.BeginChild('##statusbar', imgui.ImVec2(scr[1], 20))
  imgui.SetCursorPos(imgui.ImVec2(10, imgui.GetWindowHeight() / 2 - imgui.GetTextLineHeight() / 2))
  imgui.Text(Graphics.tClientPopupText)
  imgui.EndChild()

  imgui.SetCursorPos(imgui.ImVec2(Graphics.ClientSettings.tSideBarPos, 0))
  if Graphics.ClientSettings.tSideBarPos > (scr[1] - scr[1] / 4)
  and Graphics.ClientSettings.tStatusBarPos <= scr[2] - 20 then
    Graphics.ClientSettings.tSideBarPos =
    Graphics.ClientSettings.tSideBarPos - 6
  end
  if Graphics.ClientSettings.tSideBarPos < (scr[1] - scr[1] / 4) then
    Graphics.ClientSettings.tSideBarPos = (scr[1] - scr[1] / 4)
  end
  imgui.BeginChild('##sidebar', imgui.ImVec2(scr[1] / 4, scr[2]))

  imgui.PushFont(IM_FONTS.TITLE_CLIENT)
  imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize('SIMPLE LUA').x / 2, scr[2] / 21.6))
  imgui.Text('SIMPLE LUA')
  imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize('MULTIPLAYER').x / 2)
  imgui.Text('MULTIPLAYER')
  imgui.PopFont()
  imgui.PushFont(IM_FONTS.SUBTITLE_CLIENT)
  imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize('Developed by SL Team').x / 2)
  imgui.Text('Developed by SL Team')

  imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 4, scr[2] / 4.6))
  imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(10, 10))
  imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 5.0)
  imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(72 / 255, 72 / 255, 72 / 255, 1))
  imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(219 / 255, 219 / 255, 219 / 255, 1))
  imgui.PushItemWidth(imgui.GetWindowWidth() - (imgui.GetWindowWidth() / 4) * 2)
  if imgui.InputTextWithHint('##address', 'Server Address', Graphics.ClientSettings.tAddress, ffi.sizeof(Graphics.ClientSettings.tAddress) - 1, imgui.InputTextFlags.EnterReturnsTrue) then
    local ip, port = ffi.string(Graphics.ClientSettings.tAddress):match('^(%S+):(%d+)$')
    if ip and port then
      ClientData.sName = 'Pending...'
      ClientData.sRequestTime = os.clock()
      udp:settimeout(0)
      udp:setpeername(ip, port)
      local bs = BitStream:new()
      sendPacket(PACKET.PING_SERVER, false, bs)
    end
  end
  imgui.PopItemWidth()
  imgui.PopStyleColor(2)
  imgui.PopStyleVar(2)
  imgui.PopFont()

  imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize('Don`t forget to change your nickname').x / 2)
  imgui.Text('Don`t forget to change your nickname')

  imgui.SetCursorPosY(scr[2] / 2.7)
  imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(29 / 255, 30 / 255, 32 / 255, 1))
  imgui.BeginChild('##serverinfo', imgui.ImVec2(imgui.GetWindowWidth(), scr[2] / 6))
  imgui.SetCursorPos(imgui.ImVec2(20, 18))
  imgui.BeginGroup()
  imgui.PushFont(IM_FONTS.INFO_FONT)
  imgui.Text('Name: ' .. ClientData.sName)
  imgui.Text('Players: ' .. ClientData.sPlayers[1] .. ' / ' .. ClientData.sPlayers[2])
  imgui.Text('Ping: ' .. ('%d'):format(ClientData.sPing) .. ' ms')
  imgui.Text('Language: ' .. ClientData.sLanguage)
  imgui.Text('Version: ' .. ClientData.sVersion)
  imgui.Text('Website: ' .. ClientData.sWebsite)
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
  for i = 1, #ClientData.sPlayerPool do
    imgui.Text(ClientData.sPlayerPool[i])
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