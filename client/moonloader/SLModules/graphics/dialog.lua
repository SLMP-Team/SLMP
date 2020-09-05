imgui.OnFrame(function() return not isGamePaused() and Graphics.wDialog[0] and not Graphics.tChatOpen end,
function(self)
  local scr = Game:getResolution()
  self.LockPlayer = true
  self.HideCursor = false
  imgui.SetNextWindowPos(imgui.ImVec2(scr[1]/2, scr[2]/2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
  imgui.SetNextWindowSizeConstraints(imgui.ImVec2(300, 0), imgui.ImVec2(scr[1] - 20, scr[2] - 20))
  imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
  imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 0.0)
  imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.1, 0.1, 0.1, 1))
  imgui.PushStyleColor(imgui.Col.Button, ImRGBA(171, 171, 171, 255))
  imgui.Begin('##Dialog'..Graphics.DialogSettings.tDialogTitle, Graphics.wDialog, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove + imgui.WindowFlags.AlwaysAutoResize)

  imgui.PushFont(IM_FONTS.CHAT_FONT)
  imgui.PushStyleColor(imgui.Col.ChildBg, imgui.ImVec4(0, 0, 0, 1))
  imgui.BeginChild('##titleBar', imgui.ImVec2(imgui.GetWindowWidth(), imgui.CalcTextSize(Graphics.DialogSettings.tDialogTitle).y + 10))
  imgui.SetCursorPos(imgui.ImVec2(5, imgui.GetWindowHeight() / 2 - imgui.CalcTextSize(Graphics.DialogSettings.tDialogTitle).y / 2))
  imgui.textRGB(Graphics.DialogSettings.tDialogTitle)
  imgui.EndChild()
  imgui.PopStyleColor()

  imgui.SetCursorPos(imgui.ImVec2(5, imgui.CalcTextSize(Graphics.DialogSettings.tDialogTitle).y + 20))
  imgui.BeginGroup()
  local selNum = -1
  for strs in Graphics.DialogSettings.tDialogText:gmatch('([^\n]+)') do
    if Graphics.DialogSettings.tDialogType == 2 then
      selNum = selNum + 1
      if imgui.Selectable(strs .. ' ', Graphics.DialogSettings.tDialogSelected == selNum) then
        Graphics.DialogSettings.tDialogSelected = selNum
      end
      if imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0) then
        Client:sendDialogResponse(Graphics.DialogSettings.tDialogID, 1, selNum, '')
        Graphics.wDialog[0] = false
      end
    else
      imgui.textRGB(strs)
      imgui.SameLine(0, 5)
      imgui.NewLine()
    end
  end
  imgui.EndGroup()

  imgui.Spacing(); imgui.Spacing()
  if Graphics.DialogSettings.tDialogType == 1 then
    imgui.SetCursorPosX(5)
    imgui.PushItemWidth(imgui.GetWindowWidth() - 10)
    if imgui.InputText('##dialogInput', Graphics.DialogSettings.tDialogInput, ffi.sizeof(Graphics.DialogSettings.tDialogInput) - 1, imgui.InputTextFlags.EnterReturnsTrue) then
      Client:sendDialogResponse(Graphics.DialogSettings.tDialogID, 1, -1, ffi.string(Graphics.DialogSettings.tDialogInput))
      Graphics.wDialog[0] = false
    end
    if Graphics.DialogSettings.tFocus then
      Graphics.DialogSettings.tFocus = nil
      imgui.SetKeyboardFocusHere(0)
    end
    imgui.PopItemWidth()
    imgui.Spacing()
  end
  imgui.SetCursorPosX(5)
  if Graphics.DialogSettings.tDialogButtons[2] ~= '' then
    imgui.PushStyleColor(imgui.Col.Button, ImRGBA(58, 212, 81, 255))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, ImRGBA(117, 225, 133, 255))
    if imgui.Button(Graphics.DialogSettings.tDialogButtons[1], imgui.ImVec2(imgui.GetWindowWidth() / 2 - 5
    - imgui.GetStyle().ItemSpacing.x / 2, imgui.CalcTextSize(Graphics.DialogSettings.tDialogButtons[1]).y + 5)) then
      Client:sendDialogResponse(Graphics.DialogSettings.tDialogID, 1, Graphics.DialogSettings.tDialogType == 2
      and Graphics.DialogSettings.tDialogSelected or -1, ffi.string(Graphics.DialogSettings.tDialogInput))
      Graphics.wDialog[0] = false
    end
    imgui.PopStyleColor(2)
    imgui.SameLine()
    imgui.PushStyleColor(imgui.Col.Button, ImRGBA(238, 104, 104, 255))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, ImRGBA(225, 117, 117, 255))
    if imgui.Button(Graphics.DialogSettings.tDialogButtons[2], imgui.ImVec2(imgui.GetWindowWidth() / 2 - 5
    - imgui.GetStyle().ItemSpacing.x / 2, imgui.CalcTextSize(Graphics.DialogSettings.tDialogButtons[2]).y + 5)) then
      Client:sendDialogResponse(Graphics.DialogSettings.tDialogID, 2, Graphics.DialogSettings.tDialogType == 2
      and Graphics.DialogSettings.tDialogSelected or -1, ffi.string(Graphics.DialogSettings.tDialogInput))
      Graphics.wDialog[0] = false
    end
    imgui.PopStyleColor(2)
  else
    if imgui.Button(Graphics.DialogSettings.tDialogButtons[1], imgui.ImVec2(imgui.GetWindowWidth() - 10,
    imgui.CalcTextSize(Graphics.DialogSettings.tDialogButtons[1]).y + 5)) then
      Client:sendDialogResponse(Graphics.DialogSettings.tDialogID, 1, Graphics.DialogSettings.tDialogType == 2
      and Graphics.DialogSettings.tDialogSelected or -1, ffi.string(Graphics.DialogSettings.tDialogInput))
      Graphics.wDialog[0] = false
    end
  end
  imgui.Spacing(); imgui.Spacing()

  imgui.PopFont()
  imgui.End()
  imgui.PopStyleVar(2)
  imgui.PopStyleColor(2)
end)