chat_pool = {
  input = imgui.new.char[145](),
  is_input = false, fade_color = 0,
  mode_num = 2, lines_num = 15,
  messages = {}, is_new = false,
  font = nil, is_font_load = false,
  font_size = 18
}

function chat_pool:add(color, text)
  if #self.messages > 100 then
    table.remove(self.messages, 1)
  end
  table.insert(self.messages, {
    color = color, text = text,
    time = os.time()
  })
  self.is_new = true
end

function chat_pool:process(text)
  if text:match("^/lines") then
    local lines = text:match("^/lines%s+(%d+)")
    if not lines then
      self:add(0xFFEEEEEE, "* Usage: /lines [2 to 20]")
    else
      lines = tonumber(lines)
      if lines < 2 or lines > 20 then
        self:add(0xFFEEEEEE, "* Error: 2 to 20 lines available!")
      else
        self.lines_num = lines
        self:add(0xFFEEEEEE, "* Success: lines number is "..lines)
      end
    end
    return false
  elseif text:match("^/font") then
    local size = text:match("^/font%s+(%d+)")
    if not size then
      self:add(0xFFEEEEEE, "* Usage: /font [10 to 30]")
    else
      size = tonumber(size)
      if size < 10 or size > 30 then
        self:add(0xFFEEEEEE, "* Error: font size 10 to 30 available!")
      else
        self.font_size = size
        self.is_font_load = false
        self:add(0xFFEEEEEE, "* Success: font size is "..size)
      end
    end
    return false
  elseif text:match("^/quit%s*$") or text:match("^/q%s*$") then
    packets.send(packets["list"]["ID_DISCONNECTION_NOTIFICATION"], nil)
    ffi.C.exit(0) -- quit game
    return false
  elseif text == "/getpos" then
    local x, y, z = getCharCoordinates(PLAYER_PED)
    chat_pool:add(0xCFCFCFFF, ("Current Position: %.4f, %.4f, %.4f"):format(x, y, z))
    return false
  end
  return true
end

imgui.OnFrame(function() return not isPauseMenuActive() and chat_pool.mode_num > 0 and not scoreboard.enable end,
function()
  if not chat_pool.is_font_load then
    chat_pool.is_font_load = true
    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    chat_pool.font = imgui.GetIO().Fonts:AddFontFromFileTTF(FS.."chat_font.ttf", chat_pool.font_size, nil, glyph_ranges)
    imgui.InvalidateFontsTexture()
  end
end,
function(self)
  local sx, sy = getScreenResolution()

  self.HideCursor = not chat_pool.is_input

  if chat_pool.is_input and chat_pool.fade_color < 0.6 then chat_pool.fade_color = chat_pool.fade_color + 0.01
  elseif not chat_pool.is_input and chat_pool.fade_color > 0.0 then chat_pool.fade_color = chat_pool.fade_color - 0.01 end

  imgui.PushFont(chat_pool.font)

  imgui.SetNextWindowPos(imgui.ImVec2(10, 10), imgui.Cond.Always, imgui.ImVec2(0.0, 0.0))
  imgui.SetNextWindowSize(imgui.ImVec2(sx / 1.5, imgui.GetTextLineHeightWithSpacing() * (chat_pool.lines_num + 1) + 25), imgui.Cond.Always)

  imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0.0)
  imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(20 / 255, 20 / 255, 20 / 255,  chat_pool.fade_color))
  imgui.Begin("SL:MP Chat", nil, imgui.WindowFlags.NoDecoration + (chat_pool.is_input and 0 or imgui.WindowFlags.NoScrollWithMouse))

  imgui.BeginChild("messages", imgui.ImVec2(imgui.GetWindowWidth() - 15, imgui.GetTextLineHeightWithSpacing() * chat_pool.lines_num), false, (not chat_pool.is_input and imgui.WindowFlags.NoScrollbar or 0) + (chat_pool.is_input and 0 or imgui.WindowFlags.NoScrollWithMouse))
  local clipper = imgui.ImGuiListClipper(#chat_pool.messages)
  while clipper:Step() do
    for i = clipper.DisplayStart + 1, clipper.DisplayEnd do
      local color = ("{%08x}"):format(chat_pool.messages[i].color)
      local text = color.."["..os.date("%H:%M:%S", chat_pool.messages[i].time).."] "..chat_pool.messages[i].text
      local shadow_text = text:gsub("{......}", ""):gsub("{........}", ""):gsub("%%", "%%%%")
      local tpos = imgui.GetCursorPos()

      if chat_pool.mode_num == 2 then
        imgui.SetCursorPos(imgui.ImVec2(tpos.x + 1, tpos.y))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), shadow_text)
        imgui.SetCursorPos(imgui.ImVec2(tpos.x - 1, tpos.y))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), shadow_text)
        imgui.SetCursorPos(imgui.ImVec2(tpos.x, tpos.y + 1))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), shadow_text)
        imgui.SetCursorPos(imgui.ImVec2(tpos.x, tpos.y - 1))
        imgui.TextColored(imgui.ImVec4(0, 0, 0, 1), shadow_text)
      end

      imgui.SetCursorPos(imgui.ImVec2(tpos.x, tpos.y))
      imgui.TextColoredEx(text, false)
    end
  end
  if chat_pool.is_new and not chat_pool.is_input then
    chat_pool.is_new = false
    imgui.SetScrollHereY()
  end
  imgui.EndChild()

  if chat_pool.is_input then
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 5.0)
    imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(10 / 255, 10 / 255, 10 / 255, chat_pool.fade_color))
    imgui.PushItemWidth(imgui.GetWindowWidth() - 15)

    if imgui.InputTextWithHint("##Input", "Type your message...", chat_pool.input,
    ffi.sizeof(chat_pool.input), imgui.InputTextFlags.EnterReturnsTrue) then
      local output = ffi.string(chat_pool.input)
      if output:sub(1, 1) == "/" then
        if chat_pool:process(output) then
          local chat_data = bstream.new()
          chat_data:write(BS_UINT8, #output)
          chat_data:write(BS_STRING, output)
          rpc.send(rpc["list"]["ID_CLIENT_COMMAND"], chat_data)
        end
      elseif #output > 0 then
        local chat_data = bstream.new()
        chat_data:write(BS_UINT8, #output)
        chat_data:write(BS_STRING, output)
        rpc.send(rpc["list"]["ID_CLIENT_MESSAGE"], chat_data)
      end
      ffi.copy(chat_pool.input, "")
      chat_pool.is_input = false
    end
    imgui.SetKeyboardFocusHere()

    imgui.PopItemWidth()
    imgui.PopStyleColor()
    imgui.PopStyleVar()
  end

  imgui.End()
  imgui.PopStyleColor()
  imgui.PopStyleVar()

  imgui.PopFont()
end)

addEventHandler("onWindowMessage", function(msg, wparam)
  if msg == 0x100 then
    if wparam == 0x75 then
      chat_pool.is_input =
      not chat_pool.is_input
    elseif wparam == 0x76 then
      chat_pool.mode_num = chat_pool.mode_num + 1
      if chat_pool.mode_num > 2 then
        chat_pool.mode_num = 0
      end
    end
  end
end)