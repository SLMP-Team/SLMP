function onGamemodeInit()
	print("New Gamemode Started!")
	setTime(0); setWeather(19)
end

function onPlayerConnect(playerid)
	local pointer = getPlayerPointer(playerid)
	pointer:sendMessage(0x6FDB6BFF, "Добро пожаловать на сервер, "..pointer:getNickname())

	local count = 0
	local x, y, z = pointer:getPosition()
	for i = 1, MAX_PLAYERS do
		local ptr = getPlayerPointer(i)
		if i ~= playerid and ptr then
			local px, py, pz = ptr:getPosition()
			local dist = math.sqrt((px - x)^2 + (py - y)^2 + (pz - z)^2)
			if dist <= 300.0 then count = count + 1 end
		end
	end

	pointer:sendMessage(0x6FDB6BFF, "Рядом с вами в данный момент "..count.." игрок(-ов)")
	pointer:sendMessage(0x6FDB6BFF, "Для получения подсказок по игре используйте {FFFFFF}/help")
	pointer:setSpawn(math.random(0, 10), math.random(0, 10), math.random(5, 8))
	pointer:setPosition(math.random(0, 10), math.random(0, 10), math.random(5, 8))
	pointer:setSkin(math.random(50, 80))

	sendMessage(0x00FF00FF, "* Игрок "..getPlayerPointer(playerid):getNickname().." зашел на сервер :)")
end

function onPlayerDisconnect(playerid, reason)
	sendMessage(0xFF0000FF, "* Игрок "..getPlayerPointer(playerid):getNickname().." покинул сервер :(")
end

function onPlayerText(playerid, message)

end

function onPlayerCommand(playerid, command)
	local ptr = getPlayerPointer(playerid)
	if command == "/help" then
		ptr:sendMessage(0xCFCFCFFF, "Список доступных команд на сервере:")
		ptr:sendMessage(0xCFCFCFFF, "/setweather /settime /sp /back(spoff)")
	elseif command:match("^/setweather%s*") then
		local id = command:match("^/setweather%s*(%d+)")
		if not id then ptr:sendMessage(0xCFCFCFFF, "/setweather [ID погоды]")
		else setWeather(tonumber(id)) sendMessage(0xFF0000FF, "Внимание! {FFFFFF}На сервере изменена погода на ID "..id) end
	elseif command:match("^/settime%s*") then
		local id = command:match("^/settime%s*(%d+)")
		if not id then ptr:sendMessage(0xCFCFCFFF, "/settime [нужный час]")
		else setTime(tonumber(id)) sendMessage(0xFF0000FF, "Внимание! {FFFFFF}На сервере изменено время на "..id) end
	elseif command:match("^/sp%s*") then
		local id = command:match("^/sp%s*(%d+)")
		if not id then ptr:sendMessage(0xCFCFCFFF, "/settime [ID игрока]")
		else
			sendMessage(0xFFFFFFFF, "Игрок "..ptr:getNickname().." начал следить за "..id.." ID")
			ptr:toggleSpectating(true); ptr:spectatePlayer(tonumber(id))
		end
	elseif command:match("^/back") then ptr:toggleSpectating(false)
	elseif command:match("^/showdlg")  then
		ptr:showDialog(1, "Новый тестовый диалог", "Текст тестового диалога\nОго перенос текста, что-то новенькое", "Кнопка 1", "Кнопка 2", 2)
	else ptr:sendMessage(0xFFFFFFFF, "Упс, кажется такой команды не существует.") end
	return true
end

function onPlayerUpdate(playerid)

end

function onPlayerStreamIn(playerid, forplayerid)

end

function onPlayerStreamOut(playerid, forplayerid)

end

function onDialogResponse(playerid, dialogid, button, listitem, inputtext)
	local ptr = getPlayerPointer(playerid)
	ptr:sendMessage(0xFFFFFFFF, "Получен ответ на диалог "..dialogid..": "..inputtext)
end

function onPlayerKeyStateChange(playerid, oldkeys, newkeys)

end