dialog_pool = {
  enable = false,
  font_load = false,
  font_handle = {nil, nil},
  font_size = {16, 20},
  dialog_type = 1, selected = 0,
  inputtext = imgui.new.char[256](),
  fade_color = 0, dialog_title = "",
  dialog_text = "", dialog_id = 0,
  dialog_buttons = {"", ""},
  refocus_field = false,
}

function send_dialog_button(btn)
  dialog_pool.enable = false
  local data = bstream.new() -- ID_DIALOG_RESPONSE
  data:write(BS_UINT16, dialog_pool.dialog_id)
  data:write(BS_UINT8, btn) -- left or right (1 & 2)
  data:write(BS_UINT8, dialog_pool.selected)
  local output = ffi.string(dialog_pool.inputtext)
  data:write(BS_UINT8, #output)
  data:write(BS_STRING, output)
  rpc.send(rpc["list"]["ID_DIALOG_RESPONSE"], data)
end

function dialog_pool:show(title, text, btn1, btn2, dtype)
  if #title < 1 then self.enable = false else
    self.selected = 0 ffi.copy(self.inputtext, "")
    self.dialog_title = title self.dialog_text = text
    self.dialog_buttons = {btn1, btn2}
    self.dialog_type = dtype
    self.fade_color = 0.01 self.enable = true
    self.refocus_field = true
  end
end

local size_x, size_y = 500, 500

imgui.OnFrame(function() return not isPauseMenuActive() and dialog_pool.fade_color > 0 end,
function()
  if not dialog_pool.font_load then
    dialog_pool.font_load = true
    dialog_pool.font_handle[1] = imgui.GetIO().Fonts:AddFontFromFileTTF(FS.."general.ttf",
    dialog_pool.font_size[1], nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    dialog_pool.font_handle[2] = imgui.GetIO().Fonts:AddFontFromFileTTF(FS.."general.ttf",
    dialog_pool.font_size[2], nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    imgui.InvalidateFontsTexture()
  end
end,
function(self)
  self.HideCursor = not dialog_pool.enable
  self.LockPlayer = dialog_pool.enable

  if dialog_pool.enable and dialog_pool.fade_color < 1 then dialog_pool.fade_color = dialog_pool.fade_color + 0.01
  elseif not dialog_pool.enable and dialog_pool.fade_color > 0.0 then dialog_pool.fade_color = dialog_pool.fade_color - 0.01 end

  local scr_x, scr_y = getScreenResolution()

  local max_width, max_height = 0, 0

  if dialog_pool.fade_color > 0.0 then
    imgui.PushFont(dialog_pool.font_handle[1])

    imgui.SetNextWindowPos(imgui.ImVec2(scr_x / 2, scr_y / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(size_x, size_y), imgui.Cond.Always)

    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(12 / 255, 12 / 255, 12 / 255, dialog_pool.fade_color))
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, dialog_pool.fade_color))
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(52 / 255, 50 / 255, 70 / 255, dialog_pool.fade_color))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(52 / 255, 50 / 255, 70 / 255, dialog_pool.fade_color))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(52 / 255, 30 / 255, 70 / 255, dialog_pool.fade_color))
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(52 / 255, 50 / 255, 70 / 255, dialog_pool.fade_color))
    imgui.PushStyleColor(imgui.Col.FrameBgHovered, imgui.ImVec4(52 / 255, 30 / 255, 70 / 255, dialog_pool.fade_color))
    imgui.PushStyleColor(imgui.Col.FrameBgActive, imgui.ImVec4(52 / 255, 50 / 255, 70 / 255, dialog_pool.fade_color))
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 5.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0.0)
    imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, dialog_pool.fade_color)

    imgui.Begin("SL:MP Dialog", nil, imgui.WindowFlags.NoDecoration + imgui.WindowFlags.NoMove)
    local wps = imgui.GetCursorScreenPos()

    imgui.GetWindowDrawList():AddRectFilled(imgui.ImVec2(wps.x, wps.y), imgui.ImVec2(wps.x +
    imgui.GetWindowWidth(), wps.y + 50), ToU32(imgui.ImVec4(52 / 255, 50 / 255, 70 / 255, dialog_pool.fade_color)))

    imgui.PushFont(dialog_pool.font_handle[2])
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() / 2 - imgui.CalcTextSize(dialog_pool.dialog_title).x / 2, 14))
    imgui.Text(dialog_pool.dialog_title)
    imgui.PopFont()

    imgui.SetCursorPos(imgui.ImVec2(15, 65))
    imgui.BeginGroup()
    for line in dialog_pool.dialog_text:gmatch("[^\n\r]+") do
      local tsize = imgui.CalcTextSize(line)
      if tsize.x > max_width then max_width = tsize.x end
      max_height = max_height + imgui.GetTextLineHeightWithSpacing()
      imgui.TextColoredEx(line, false)
    end
    imgui.EndGroup()

    if dialog_pool.dialog_type == 1
    or dialog_pool.dialog_type == 2 then
      imgui.SetCursorPos(imgui.ImVec2(10, 70 + max_height + 20))
      max_height = max_height + imgui.GetTextLineHeightWithSpacing() + 10
      imgui.PushItemWidth(imgui.GetWindowWidth() - 20)
      imgui.InputText("##dialoginput", dialog_pool.inputtext, ffi.sizeof(dialog_pool.inputtext),
      (dialog_pool.dialog_type == 2 and imgui.InputTextFlags.Password or 0))
      imgui.PopItemWidth()
      if dialog_pool.refocus_field then
        dialog_pool.refocus_field = false
        imgui.SetKeyboardFocusHere()
      end
    end

    imgui.SetCursorPos(imgui.ImVec2(10, 70 + max_height + 20))

    local btn_size = imgui.GetWindowWidth() / 2 - 15
    if #dialog_pool.dialog_buttons[2] < 1 then
      btn_size = imgui.GetWindowWidth() - 20
    end

    if imgui.Button(dialog_pool.dialog_buttons[1], imgui.ImVec2(btn_size, 25)) then
      send_dialog_button(1)
    end
    if #dialog_pool.dialog_buttons[2] > 0 then
      imgui.SameLine()
      if imgui.Button(dialog_pool.dialog_buttons[2], imgui.ImVec2(btn_size, 25)) then
        send_dialog_button(2)
      end
    end

    size_x = max_width + 30
    size_y = max_height + 130

    imgui.End()

    imgui.PopStyleColor(8)
    imgui.PopStyleVar(4)

    imgui.PopFont()

  end
end)

addEventHandler("onWindowMessage",
function(msg, wparam)
  if msg == 0x100 and dialog_pool.enable then
    if wparam == 0x0D then
      send_dialog_button(1)
      consumeWindowMessage(true, false)
    elseif wparam == 0x1B then
      send_dialog_button(2)
      consumeWindowMessage(true, false)
    end
  end
end)