FS = WORKING_DIRECTORY.."fonts\\"

imgui.OnInitialize(function()
  imgui.GetIO().IniFilename = nil
  local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
  imgui.GetIO().Fonts:Clear()
  imgui.GetIO().Fonts:AddFontFromFileTTF(FS.."general.ttf", 18, nil, glyph_ranges)
  imgui.InvalidateFontsTexture()
end)

local function split(str, delim, plain)
  local tokens, pos, plain = {}, 1, not (plain == false)
  repeat
    local npos, epos = string.find(str, delim, pos, plain)
    table.insert(tokens, string.sub(str, pos, npos and npos - 1))
    pos = epos and epos + 1
  until not pos
  return tokens
end

function imgui.TextColoredEx(text, wrapped) -- by imring
  text = text:gsub('{(%x%x%x%x%x%x)}', '{%1FF}')
  local render_func = function(clr, text)
      if clr then imgui.PushStyleColor(imgui.Col.Text, clr) end
      imgui.TextUnformatted(text)
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

require("coremp.graphics.chat")
require("coremp.graphics.scoreboard")
require("coremp.graphics.dialog")