Graphics =
{
  wClient = imgui.new.bool(true),
  tClientPopupText = 'Welcome to SL:MP Client, we`re hope you`ll enjoy playing!',
  ClientSettings =
  {
    tWallpaperPos = {-(Game:getResolution()[1]/2), Game:getResolution()[1]},
    tWallpaperTime = os.time() + 15,
    tWallpaperID = 1,
    tNickname = imgui.new.char[20](),
    tStatusBarPos = Game:getResolution()[2],
    tSideBarPos = Game:getResolution()[1],
    tAddress = imgui.new.char[128]()
  },
  wChat = imgui.new.bool(false),
  ChatSettings =
  {
    tChatLines = 10,
    tChatInput = imgui.new.char[144](),
    tRefocusNeed = false,
    tChatMessages = {},
    tChatFontSize = 1,
    tChatFontLoaded = true
  },
  wDialog = imgui.new.bool(false),
  DialogSettings =
  {
    tDialogID = 0,
    tDialogTitle = '',
    tDialogText = '',
    tDialogType = 0,
    tDialogButtons = {'OK', 'Close'},
    tDialogInput = imgui.new.char[144](),
    tDialogSelected = -1
  }
}

IM_FONTS = {}
IM_WALLPAPER = {}
imgui.OnInitialize(function()
  local scr = Game:getResolution()
  imgui.GetIO().IniFilename = nil
  for i = 1, 6 do
    local tmp = imgui.CreateTextureFromFile(modules .. '/resources/wallpapers/wall'..i..'.jpg')
    if tmp then IM_WALLPAPER[#IM_WALLPAPER+1] = tmp end
  end
  Graphics.ClientSettings.tWallpaperID = math.random(1, #IM_WALLPAPER)
  local config = imgui.ImFontConfig()
	config.MergeMode = true
	config.PixelSnapH = true
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
	imgui.GetIO().Fonts:Clear()
  imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', scr[1] / 137, nil, glyph_ranges)
  IM_FONTS.TITLE_CLIENT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', scr[1] * 0.028, nil, glyph_ranges)
  IM_FONTS.SUBTITLE_CLIENT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', scr[1] * 0.015, nil, glyph_ranges)
  IM_FONTS.TITLE_ICON = imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(FA.Solid, 28, nil, imgui.new.ImWchar[3](0xf000, 0xf83e, 0))
  IM_FONTS.INPUT_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', 18, nil, glyph_ranges)
  IM_FONTS.INFO_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', scr[1] / 96, nil, glyph_ranges)
  IM_FONTS.CHAT_FONT = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebuc.ttf', scr[1] / 200 + (5 * Graphics.ChatSettings.tChatFontSize), nil, glyph_ranges)
  imgui.InvalidateFontsTexture()
end)

dofile(modules..'/graphics/chat.lua')
dofile(modules..'/graphics/client.lua')
dofile(modules..'/graphics/dialog.lua')