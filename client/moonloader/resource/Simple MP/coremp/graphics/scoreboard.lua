scoreboard = {
  enable = false,
  fade_color = 0,
  font_size = {
    18,
    14
  },
  font_handle = {
    nil,
    nil
  },
  font_load = false,
  selected = 0
}

imgui.OnFrame(function() return not isPauseMenuActive() and scoreboard.fade_color > 0.0 end,
function()
  if not scoreboard.font_load then
    scoreboard.font_load = true
    scoreboard.font_handle[1] = imgui.GetIO().Fonts:AddFontFromFileTTF(FS.."general.ttf", scoreboard.font_size[1], nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    scoreboard.font_handle[2] = imgui.GetIO().Fonts:AddFontFromFileTTF(FS.."general.ttf", scoreboard.font_size[2], nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.InvalidateFontsTexture()
  end
end,
function(self)
  self.HideCursor = not scoreboard.enable
  --self.LockPlayer = scoreboard.enable

  if scoreboard.enable and scoreboard.fade_color < 0.95 then scoreboard.fade_color = scoreboard.fade_color + 0.01
  elseif not scoreboard.enable and scoreboard.fade_color > 0.0 then scoreboard.fade_color = scoreboard.fade_color - 0.01 end

  local scr_x, scr_y = getScreenResolution()
  local size_x, size_y = scr_x / 2, scr_y / 1.5
  local pos_x, pos_y = scr_x / 2 - size_x / 2, scr_y / 2 - size_y / 2

  if scoreboard.fade_color > 0.0 then
    imgui.PushFont(scoreboard.font_handle[1])

    imgui.SetNextWindowPos(imgui.ImVec2(pos_x, pos_y), imgui.Cond.Always, imgui.ImVec2(0.0, 0.0))
    imgui.SetNextWindowSize(imgui.ImVec2(size_x, size_y), imgui.Cond.Always)

    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(12 / 255, 12 / 255, 12 / 255, scoreboard.fade_color))
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, scoreboard.fade_color))
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 15.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0.0)
    imgui.Begin('SL:MP Players', nil, imgui.WindowFlags.NoDecoration)

    imgui.SetCursorPos(imgui.ImVec2(20, 20))
    imgui.Text(tostring(servername))

    local counter = 0
    for i, v in ipairs(players.list) do
      if v ~= 0 then counter = counter + 1 end
    end

    local pl_text = 'Players: '..counter
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() -  imgui.CalcTextSize(pl_text).x - 20, 20))
    imgui.Text(pl_text)

    imgui.PushFont(scoreboard.font_handle[2])
    local ping_pos = imgui.CalcTextSize('PING').x

    imgui.SetCursorPos(imgui.ImVec2(20, 60))
    imgui.TextColored(imgui.ImVec4(128 / 255, 24 / 255, 226 / 255, scoreboard.fade_color), 'ID')
    imgui.SetCursorPos(imgui.ImVec2(100, 60))
    imgui.TextColored(imgui.ImVec4(128 / 255, 24 / 255, 226 / 255, scoreboard.fade_color), 'NICKNAME')
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 2, 60))
    imgui.TextColored(imgui.ImVec4(128 / 255, 24 / 255, 226 / 255, scoreboard.fade_color), 'SCORE')
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - 40 - ping_pos, 60))
    imgui.TextColored(imgui.ImVec4(128 / 255, 24 / 255, 226 / 255, scoreboard.fade_color), 'PING')

    imgui.PopFont()

    imgui.SetCursorPos(imgui.ImVec2(20, 90))
    imgui.Text(tostring(localplayer_id))
    imgui.SetCursorPos(imgui.ImVec2(100, 90))
    imgui.Text(client_data.name)
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 2, 90))
    imgui.Text(tostring(players.list[localplayer_id] and players.list[localplayer_id].score or 0))
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - 40 - ping_pos, 90))
    imgui.Text(tostring(players.list[localplayer_id] and players.list[localplayer_id].ping or 0))

    imgui.SetCursorPos(imgui.ImVec2(20, 120))
    imgui.BeginChild('##SepZone', imgui.ImVec2(imgui.GetWindowWidth() - 60, 10))
    imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(128 / 255, 24 / 255, 226 / 255, scoreboard.fade_color))
    imgui.Separator()
    imgui.PopStyleColor()
    imgui.EndChild()

    local start_list = 130
    local list_size = imgui.GetWindowHeight() - 155

    imgui.SetCursorPos(imgui.ImVec2(0, start_list))
    imgui.PushStyleVarFloat(imgui.StyleVar.ScrollbarSize, 2.0)
    imgui.PushStyleColor(imgui.Col.ScrollbarGrab, imgui.ImVec4(128 / 255, 24 / 255, 226 / 255, scoreboard.fade_color))
    imgui.PushStyleColor(imgui.Col.ScrollbarGrabHovered, imgui.ImVec4(128 / 255, 24 / 255, 226 / 255, scoreboard.fade_color))
    imgui.PushStyleColor(imgui.Col.ScrollbarGrabActive, imgui.ImVec4(128 / 255, 24 / 255, 226 / 255, scoreboard.fade_color))
    imgui.BeginChild('##AllPlayers', imgui.ImVec2(imgui.GetWindowWidth() - 20, list_size))
    imgui.PushStyleColor(imgui.Col.Header, imgui.ImVec4(128 / 255, 24 / 255, 226 / 255, scoreboard.fade_color - 0.8))
    imgui.PushStyleColor(imgui.Col.HeaderHovered, imgui.ImVec4(108 / 255, 24 / 255, 226 / 255, scoreboard.fade_color - 0.8))
    imgui.PushStyleColor(imgui.Col.HeaderActive, imgui.ImVec4(108 / 255, 24 / 255, 226 / 255, scoreboard.fade_color - 0.8))

    local spacer = 0
    for i, v in ipairs(players.list) do
      if v ~= 0 and i ~= localplayer_id then
        spacer = spacer + 1
        imgui.SetCursorPos(imgui.ImVec2(15, (spacer - 1) * 25))
        if imgui.Selectable('##SelectSlot'..i, scoreboard.selected == i,
        imgui.SelectableFlags.SpanAllColumns) then scoreboard.selected = i end
        imgui.SetCursorPos(imgui.ImVec2(20, (spacer - 1) * 25))
        imgui.Text(tostring(i))
        imgui.SetCursorPos(imgui.ImVec2(100, (spacer - 1) * 25))
        imgui.Text(v.nickname)
        imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 2 + 10, (spacer - 1) * 25))
        imgui.Text(tostring(v.score))
        imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - 40 - ping_pos + 20, (spacer - 1) * 25))
        imgui.Text(tostring(v.ping >= 1000 and 999 or v.ping))
      end
    end

    imgui.PopStyleColor(3)
    imgui.EndChild()
    imgui.PopStyleVar()
    imgui.PopStyleColor(3)

    imgui.End()
    imgui.PopStyleVar(3)
    imgui.PopStyleColor(2)

    imgui.PopFont()
  end
end)

addEventHandler("onWindowMessage",
function(msg, wparam)
  if msg == 0x100 then
    if wparam == 0x09 then
      scoreboard.enable = not scoreboard.enable
      if scoreboard.enable then
        scoreboard.fade_color = 0.01
      end
    end
  end
end)