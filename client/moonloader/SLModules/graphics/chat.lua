imgui.OnFrame(function() return not isGamePaused() and Graphics.wChat[0] end,
function()
  local fontSize = Game:getResolution()[1] / 200 + (5 * Graphics.ChatSettings.tChatFontSize)
  if not Graphics.ChatSettings.tChatFontLoaded then
    Graphics.ChatSettings.tChatFontLoaded = true
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    IM_FONTS.CHAT_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', fontSize, nil, glyph_ranges)
    imgui.InvalidateFontsTexture()
  end
end,
function(self)
  local scr = Game:getResolution()
  local fontSize = scr[1] / 200 + (5 * Graphics.ChatSettings.tChatFontSize)
  imgui.SetNextWindowPos(imgui.ImVec2(2, 10))
	imgui.SetNextWindowSize(imgui.ImVec2(scr[1] / 1.3, (fontSize + imgui.GetStyle().ItemSpacing.y - 1) * Graphics.ChatSettings.tChatLines + 50 + 2))
  imgui.PushStyleColor(imgui.Col.WindowBg, Graphics.tChatOpen and imgui.ImVec4(0, 0, 0, 0.8) or imgui.ImVec4(0, 0, 0, 0))
  imgui.PushStyleColor(imgui.Col.Border, Graphics.tChatOpen and imgui.ImVec4(1, 1, 1, 0.8) or imgui.ImVec4(0, 0, 0, 0))
  imgui.Begin('SLMP:Chat', Graphics.wChat, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove)

  if Graphics.tChatOpen then self.HideCursor = false
  else self.HideCursor = true end

  imgui.SetCursorPos(imgui.ImVec2(30, 15))
  imgui.BeginChild('##content', imgui.ImVec2(0, (fontSize + imgui.GetStyle().ItemSpacing.y - 1) * Graphics.ChatSettings.tChatLines + 2), false, not Graphics.tChatOpen and imgui.WindowFlags.NoScrollbar)
	local clipper = imgui.ImGuiListClipper(#Graphics.ChatSettings.tChatMessages)
  imgui.PushFont(IM_FONTS.CHAT_FONT)
  while clipper:Step() do
		for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
      if Graphics.ChatSettings.tChatMessages[i] ~= nil then
        local a, r, g, b = explodeArgb(Graphics.ChatSettings.tChatMessages[i].color)
        local argb = joinArgb(a, r, g, 0xFF)
        local timetag = '{'..('%6X'):format(argb):sub(9, 17) .. '}[' .. os.date('%H:%M:%S', Graphics.ChatSettings.tChatMessages[i].time) .. '] '
        local tpos = imgui.GetCursorPos()

        local shadowText = (timetag .. Graphics.ChatSettings.tChatMessages[i].text):gsub('{......}', ''):gsub('{........}', '')
        imgui.SetCursorPos(imgui.ImVec2(tpos.x + 1, tpos.y))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), shadowText)
        imgui.SetCursorPos(imgui.ImVec2(tpos.x - 1, tpos.y))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), shadowText)
        imgui.SetCursorPos(imgui.ImVec2(tpos.x, tpos.y + 1))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), shadowText)
        imgui.SetCursorPos(imgui.ImVec2(tpos.x, tpos.y - 1))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), shadowText)

        imgui.SetCursorPos(imgui.ImVec2(tpos.x, tpos.y))
        imgui.textRGB(timetag .. Graphics.ChatSettings.tChatMessages[i].text:gsub('%%%%', '%%'))
			end
		end
  end
  imgui.PopFont()
  if Graphics.ChatSettings.tRefocusNeed == true then
    Graphics.ChatSettings.tRefocusNeed = false
    imgui.SetScrollHereY()
  end
  imgui.EndChild()
  if Graphics.tChatOpen then
    imgui.SetCursorPosX(30)
    imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(5, 5))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 5.0)
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(72 / 255, 72 / 255, 72 / 255, 1))
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(219 / 255, 219 / 255, 219 / 255, 1))
    if imgui.InputText("##inputtext", Graphics.ChatSettings.tChatInput, ffi.sizeof(Graphics.ChatSettings.tChatInput) - 1, imgui.InputTextFlags.EnterReturnsTrue) then
      Graphics.tChatOpen = false
      if ffi.string(Graphics.ChatSettings.tChatInput):len() > 0 then
        if ffi.string(Graphics.ChatSettings.tChatInput):match('^/.+') then
          local str = ffi.string(Graphics.ChatSettings.tChatInput):match('^/(.+)')
          if not Game:proccessCommand(str) then
            if Player.GameState == GAMESTATE.CONNECTED then
              local bs = BitStream:new()
              bs:writeUInt8(str:len())
              bs:writeString(str)
              sendRPC(RPC.SEND_COMMAND, true, bs)
            end
          end
        else
          if Player.GameState == GAMESTATE.CONNECTED then
            local str = ffi.string(Graphics.ChatSettings.tChatInput)
            local bs = BitStream:new()
            bs:writeUInt8(str:len())
            bs:writeString(str)
            sendRPC(RPC.SEND_MESSAGE, true, bs)
          end
        end
        ffi.copy(Graphics.ChatSettings.tChatInput, '')
      end
    end
    imgui.SetKeyboardFocusHere()
    imgui.PopStyleVar(2)
    imgui.PopStyleColor(2)
  end

  imgui.End()
  imgui.PopStyleColor(2)
end)