local menu
local MenuName = isfile("bitchbot/menuname.txt") and readfile("bitchbot/menuname.txt") or nil
local loadstart = tick()

local function map(X, A, B, C, D)
	return (X - A) / (B - A) * (D - C) + C
end

do
	local notes = {}
	local function DrawingObject(t, col)
		local d = Drawing.new(t)

		d.Visible = true
		d.Transparency = 1
		d.Color = col

		return d
	end

	local function Rectangle(sizex, sizey, fill, col)
		local s = DrawingObject("Square", col)

		s.Filled = fill
		s.Thickness = 1
		s.Position = Vector2.new()
		s.Size = Vector2.new(sizex, sizey)

		return s
	end

	local function Text(text)
		local s = DrawingObject("Text", Color3.new(1, 1, 1))

		s.Text = text
		s.Size = 13
		s.Center = false
		s.Outline = true
		s.Position = Vector2.new()
		s.Font = 2

		return s
	end

	function CreateNotification(t, customcolor) -- TODO i want some kind of prioritized message to the notification list, like a warning or something. warnings have icons too maybe? idk??
		local gap = 25
		local width = 18

		local alpha = 255
		local time = 0
		local estep = 0
		local eestep = 0.02

		local insety = 0

		local Note = {

			enabled = true,

			targetPos = Vector2.new(50, 33),

			size = Vector2.new(200, width),

			drawings = {
				outline = Rectangle(202, width + 2, false, Color3.new(0, 0, 0)),
				fade = Rectangle(202, width + 2, false, Color3.new(0, 0, 0)),
			},

			Remove = function(self, d)
				if d.Position.x < d.Size.x then
					for k, drawing in pairs(self.drawings) do
						drawing:Remove()
						drawing = false
					end
					self.enabled = false
				end
			end,

			Update = function(self, num, listLength, dt)
				local pos = self.targetPos

				local indexOffset = (listLength - num) * gap
				if insety < indexOffset then
					insety -= (insety - indexOffset) * 0.2
				else
					insety = indexOffset
				end
				local size = self.size

				local tpos = Vector2.new(pos.x - size.x / time - map(alpha, 0, 255, size.x, 0), pos.y + insety)
				self.pos = tpos

				local locRect = {
					x = math.ceil(tpos.x),
					y = math.ceil(tpos.y),
					w = math.floor(size.x - map(255 - alpha, 0, 255, 0, 70)),
					h = size.y,
				}
				--pos.set(-size.x / fc - map(alpha, 0, 255, size.x, 0), pos.y)

				local fade = math.min(time * 12, alpha)
				fade = fade > 255 and 255 or fade < 0 and 0 or fade

				if self.enabled then
					local linenum = 1
					for i, drawing in pairs(self.drawings) do
						drawing.Transparency = fade / 255

						if type(i) == "number" then
							drawing.Position = Vector2.new(locRect.x + 1, locRect.y + i)
							drawing.Size = Vector2.new(locRect.w - 2, 1)
						elseif i == "text" then
							drawing.Position = tpos + Vector2.new(6, 2)
						elseif i == "outline" then
							drawing.Position = Vector2.new(locRect.x, locRect.y)
							drawing.Size = Vector2.new(locRect.w, locRect.h)
						elseif i == "fade" then
							drawing.Position = Vector2.new(locRect.x - 1, locRect.y - 1)
							drawing.Size = Vector2.new(locRect.w + 2, locRect.h + 2)
							local t = (200 - fade) / 255 / 3
							drawing.Transparency = t < 0.4 and 0.4 or t
						elseif i:find("line") then
							drawing.Position = Vector2.new(locRect.x + linenum, locRect.y + 1)
							if menu then
								local mencol = customcolor or (
										Color3.fromRGB(127, 72, 163)
									)
								local color = linenum == 1 and mencol or Color3.fromRGB(mencol.R * 255 - 40, mencol.G * 255 - 40, mencol.B * 255 - 40) -- super shit
								if drawing.Color ~= color then
									drawing.Color = color
								end
							end
							linenum += 1
						end
					end

					time += estep * dt * 128 -- TODO need to do the duration
					estep += eestep * dt * 64
				end
			end,

			Fade = function(self, num, len, dt)
				if self.pos.x > self.targetPos.x - 0.2 * len or self.fading then
					if not self.fading then
						estep = 0
					end
					self.fading = true
					alpha -= estep / 4 * len * dt * 50
					eestep += 0.01 * dt * 100
				end
				if alpha <= 0 then
					self:Remove(self.drawings[1])
				end
			end,
		}

		for i = 1, Note.size.y - 2 do
			local c = 0.28 - i / 80
			Note.drawings[i] = Rectangle(200, 1, true, Color3.new(c, c, c))
		end
		local color =  Color3.fromRGB(127, 72, 163)

		Note.drawings.text = Text(t)
		if Note.drawings.text.TextBounds.x + 7 > Note.size.x then -- expand the note size to fit if it's less than the default size
			Note.size = Vector2.new(Note.drawings.text.TextBounds.x + 7, Note.size.y)
		end
		Note.drawings.line = Rectangle(1, Note.size.y - 2, true, color)
		Note.drawings.line1 = Rectangle(1, Note.size.y - 2, true, color)

		notes[#notes + 1] = Note
	end

	renderStepped = game.RunService.RenderStepped:Connect(function(dt)
		Camera = workspace.CurrentCamera
		local smallest = math.huge
		for k = 1, #notes do
			local v = notes[k]
			if v and v.enabled then
				smallest = k < smallest and k or smallest
			else
				table.remove(notes, k)
			end
		end
		local length = #notes
		for k = 1, #notes do
			local note = notes[k]
			note:Update(k, length, dt)
			if k <= math.ceil(length / 10) or note.fading then
				note:Fade(k, length, dt)
			end
		end
	end)
	--ANCHOR how to create notification
	--CreateNotification("Loading...")
end

--!SECTION

local menuWidth, menuHeight = 500, 600
menu = { -- this is for menu stuffs n shi
	w = menuWidth,
	h = menuHeight,
	x = 0,
	y = 0,
	columns = {
		width = (menuWidth - 40) / 2,
		left = 17,
		right = (menuWidth - 20) / 2 + 13,
	},
	activetab = 1,
	open = true,
	fadestart = 0,
	fading = false,
	mousedown = false,
	postable = {},
	options = {},
	clrs = {
		norm = {},
		dark = {},
		togz = {},
	},
	mc = { 127, 72, 163 },
	watermark = {},
	connections = {},
	list = {},
	unloaded = false,
	copied_clr = nil,
	game = "uni",
	tabnames = {}, -- its used to change the tab num to the string (did it like this so its dynamic if u add or remove tabs or whatever :D)
	friends = {},
	priority = {},
	muted = {},
	spectating = false,
	stat_menu = false,
	load_time = 0,
	log_multi = nil,
	mgrouptabz = {},
	backspaceheld = false,
	backspacetime = -1,
	backspaceflags = 0,
	selectall = false,
	modkeys = {
		alt = {
			direction = nil,
		},
		shift = {
			direction = nil,
		},
	},
	modkeydown = function(self, key, direction)
		local keydata = self.modkeys[key]
		return keydata.direction and keydata.direction == direction or false
	end,
	keybinds = {},
	values = {}
}

local function round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function average(t)
	local sum = 0
	for _, v in pairs(t) do -- Get the sum of all numbers in t
		sum = sum + v
	end
	return sum / #t
end

local function clamp(a, lowerNum, higher) -- DONT REMOVE this clamp is better then roblox's because it doesnt error when its not lower or heigher
	if a > higher then
		return higher
	elseif a < lowerNum then
		return lowerNum
	else
		return a
	end
end

local function CreateThread(func, ...) -- improved... yay.
	local thread = coroutine.create(func)
	coroutine.resume(thread, ...)
	return thread
end

local function MultiThreadList(obj, ...)
	local n = #obj
	if n > 0 then
		for i = 1, n do
			local t = obj[i]
			if type(t) == "table" then
				local d = #t
				assert(d ~= 0, "table inserted was not an array or was empty")
				assert(d < 3, ("invalid number of arguments (%d)"):format(d))
				local thetype = type(t[1])
				assert(
					thetype == "function",
					("invalid argument #1: expected 'function', got '%s'"):format(tostring(thetype))
				)

				CreateThread(t[1], unpack(t[2]))
			else
				CreateThread(t, ...)
			end
		end
	else
		for i, v in pairs(obj) do
			CreateThread(v, ...)
		end
	end
end

local DeepRestoreTableFunctions, DeepCleanupTable

DeepRestoreTableFunctions = function(tbl)
	for k, v in next, tbl do
		if type(v) == "function" and is_synapse_function(v) then
			for k1, v1 in next, getupvalues(v) do
				if type(v1) == "function" and islclosure(v1) and not is_synapse_function(v1) then
					tbl[k] = v1
				end
			end
		end

		if type(v) == "table" then
			DeepRestoreTableFunctions(v)
		end
	end
end

DeepCleanupTable = function(tbl)
	local numTable = #tbl
	local isTableArray = numTable > 0
	if isTableArray then
		for i = 1, numTable do
			local entry = tbl[i]
			local entryType = type(entry)

			if entryType == "table" then
				DeepCleanupTable(tbl)
			end

			tbl[i] = nil
			entry = nil
			entryType = nil
		end
	else
		for k, v in next, tbl do
			if type(v) == "table" then
				DeepCleanupTable(tbl)
			end
		end

		tbl[k] = nil
	end

	numTable = nil
	isTableArray = nil
end

local event = {}

local allevent = {}

function event.new(eventname, eventtable, requirename) -- fyi you can put in a table of choice to make the table you want an "event" pretty cool its like doing & in c lol!
	if eventname then
		assert(
			allevent[eventname] == nil,
			("the event '%s' already exists in the event table"):format(eventname)
		)
	end
	local newevent = eventtable or {}
	local funcs = {}
	local disconnectlist = {}
	function newevent:fire(...)
		allevent[eventname].fire(...)
	end
	function newevent:connect(func)
		funcs[#funcs + 1] = func
		local disconnected = false
		local function disconnect()
			if not disconnected then
				disconnected = true
				disconnectlist[func] = true
			end
		end
		return disconnect
	end

	local function fire(...)
		local n = #funcs
		local j = 0
		for i = 1, n do
			local func = funcs[i]
			if disconnectlist[func] then
				disconnectlist[func] = nil
			else
				j = j + 1
				funcs[j] = func
			end
		end
		for i = j + 1, n do
			funcs[i] = nil
		end
		for i = 1, j do
			CreateThread(function(...)
				pcall(funcs[i], ...)
			end, ...)
		end
	end

	if eventname then
		allevent[eventname] = {
			event = newevent,
			fire = fire,
		}
	end

	return newevent, fire
end

local function FireEvent(eventname, ...)
	if allevent[eventname] then
		return allevent[eventname].fire(...)
	else
		--warn(("Event %s does not exist!"):format(eventname))
	end
end

local function GetEvent(eventname)
	return allevent[eventname]
end

local BBOT_IMAGES = {}
MultiThreadList({
	function()
		BBOT_IMAGES[1] = game:HttpGet("https://i.imgur.com/9NMuFcQ.png")
	end,
	function()
		BBOT_IMAGES[2] = game:HttpGet("https://i.imgur.com/jG3NjxN.png")
	end,
	function()
		BBOT_IMAGES[3] = game:HttpGet("https://i.imgur.com/2Ty4u2O.png")
	end,
	function()
		BBOT_IMAGES[4] = game:HttpGet("https://i.imgur.com/kNGuTlj.png")
	end,
	function()
		BBOT_IMAGES[5] = game:HttpGet("https://i.imgur.com/OZUR3EY.png")
	end,
	function()
		BBOT_IMAGES[6] = game:HttpGet("https://i.imgur.com/3HGuyVa.png")
	end,
})

-- MULTITHREAD DAT LOADING SO FAST!!!!
local loaded = {}
do
	local function Loopy_Image_Checky()
		for i = 1, 6 do
			local v = BBOT_IMAGES[i]
			if v == nil then
				return true
			elseif not loaded[i] then
				loaded[i] = true
			end
		end
		return false
	end
	while Loopy_Image_Checky() do
		wait(0)
	end
end

loadstart = tick()

-- nate i miss u D:
-- im back
local NETWORK = game:service("NetworkClient")
local NETWORK_SETTINGS = settings().Network
NETWORK:SetOutgoingKBPSLimit(0)

setfpscap(maxfps or 144)

if not isfolder("bitchbot") then
	makefolder("bitchbot")
	if not isfile("bitchbot/relations.bb") then
		writefile("bitchbot/relations.bb", "bb:{{friends:}{priority:}")
	end
else
	if not isfile("bitchbot/relations.bb") then
		writefile("bitchbot/relations.bb", "bb:{{friends:}{priority:}")
	end
	writefile("bitchbot/debuglog.bb", "")
end

if not isfolder("bitchbot/" .. menu.game) then
	makefolder("bitchbot/" .. menu.game)
end

local configs = {}

local function GetConfigs()
	local result = {}
	local directory = "bitchbot\\" .. menu.game
	for k, v in pairs(listfiles(directory)) do
		local clipped = v:sub(#directory + 2)
		if clipped:sub(#clipped - 2) == ".bb" then
			clipped = clipped:sub(0, #clipped - 3)
			result[k] = clipped
			configs[k] = v
		end
	end
	if #result <= 0 then
		writefile("bitchbot/" .. menu.game .. "/Default.bb", "")
	end
	return result
end

local Players = game:GetService("Players")
local stats = game:GetService("Stats")

local function UnpackRelations()
	local str = isfile("bitchbot/relations.bb") and readfile("bitchbot/relations.bb") or nil
	local final = {
		friends = {},
		priority = {},
	}
	if str then
		if str:find("bb:{{") then
			writefile("bitchbot/relations.bb", "friends:\npriority:")
			return
		end

		local friends, frend = str:find("friends:")
		local priority, priend = str:find("\npriority:")
		local friendslist = str:sub(frend + 1, priority - 1)
		local prioritylist = str:sub(priend + 1)
		for i in friendslist:gmatch("[^,]+") do
			if not table.find(final.friends, i) then
				table.insert(final.friends, i)
			end
		end
		for i in prioritylist:gmatch("[^,]+") do
			if not table.find(final.priority, i) then
				table.insert(final.priority, i)
			end
		end
	end
	if not menu then
		repeat
			game.RunService.Heartbeat:Wait()
		until menu
	end
	menu.friends = final.friends
	if not table.find(menu.friends, Players.LocalPlayer.Name) then
		table.insert(menu.friends, Players.LocalPlayer.Name)
	end
	menu.priority = final.priority
end

local function WriteRelations()
	local str = "friends:"

	for k, v in next, menu.friends do
		local playerobj
		local userid
		local pass, ret = pcall(function()
			playerobj = Players[v]
		end)

		if not pass then
			local newpass, newret = pcall(function()
				userid = v
			end)
		end

		if userid then
			str ..= tostring(userid) .. ","
		else
			str ..= tostring(playerobj.Name) .. ","
		end
	end

	str ..= "\npriority:"

	for k, v in next, menu.priority do
		local playerobj
		local userid
		local pass, ret = pcall(function()
			playerobj = Players[v]
		end)

		if not pass then
			local newpass, newret = pcall(function()
				userid = v
			end)
		end

		if userid then
			str ..= tostring(userid) .. ","
		else
			str ..= tostring(playerobj.Name) .. ","
		end
	end

	writefile("bitchbot/relations.bb", str)
end
CreateThread(function()
	if (not menu or not menu.GetVal) then
		repeat
			game.RunService.Heartbeat:Wait()
		until (menu and menu.GetVal)
	end
	wait(2)
	UnpackRelations()
	WriteRelations()
end)

local LOCAL_PLAYER = Players.LocalPlayer
local LOCAL_MOUSE = LOCAL_PLAYER:GetMouse()
local TEAMS = game:GetService("Teams")
local INPUT_SERVICE = game:GetService("UserInputService")
local GAME_SETTINGS = UserSettings():GetService("UserGameSettings")
local CACHED_VEC3 = Vector3.new()
local Camera = workspace.CurrentCamera
local SCREEN_SIZE = Camera.ViewportSize
local ButtonPressed = event.new("bb_buttonpressed")
local TogglePressed = event.new("bb_togglepressed")
local MouseMoved = event.new("bb_mousemoved")

menu.x = math.floor((SCREEN_SIZE.x / 2) - (menu.w / 2))
menu.y = math.floor((SCREEN_SIZE.y / 2) - (menu.h / 2))

local Lerp = function(delta, from, to) -- wtf why were these globals thats so exploitable!
	if (delta > 1) then
		return to
	end
	if (delta < 0) then
		return from
	end
	return from + (to - from) * delta
end

local ColorRange = function(value, ranges) -- ty tony for dis function u a homie
	if value <= ranges[1].start then
		return ranges[1].color
	end
	if value >= ranges[#ranges].start then
		return ranges[#ranges].color
	end

	local selected = #ranges
	for i = 1, #ranges - 1 do
		if value < ranges[i + 1].start then
			selected = i
			break
		end
	end
	local minColor = ranges[selected]
	local maxColor = ranges[selected + 1]
	local lerpValue = (value - minColor.start) / (maxColor.start - minColor.start)
	return Color3.new(
		Lerp(lerpValue, minColor.color.r, maxColor.color.r),
		Lerp(lerpValue, minColor.color.g, maxColor.color.g),
		Lerp(lerpValue, minColor.color.b, maxColor.color.b)
	)
end

local bVector2 = {}
do -- vector functions
	function bVector2:getRotate(Vec, Rads)
		local vec = Vec.Unit
		--x2 = cos β x1 − sin β y1
		--y2 = sin β x1 + cos β y1
		local sin = math.sin(Rads)
		local cos = math.cos(Rads)
		local x = (cos * vec.x) - (sin * vec.y)
		local y = (sin * vec.x) + (cos * vec.y)

		return Vector2.new(x, y).Unit * Vec.Magnitude
	end
end
local bColor = {}
do -- color functions
	function bColor:Mult(col, mult)
		return Color3.new(col.R * mult, col.G * mult, col.B * mult)
	end
	function bColor:Add(col, num)
		return Color3.new(col.R + num, col.G + num, col.B + num)
	end
end
local function string_cut(s1, num)
	return num == 0 and s1 or string.sub(s1, 1, num)
end

local textBoxLetters = {
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
}

local keyNames = {
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
	Zero = "0",
	LeftBracket = "[",
	RightBracket = "]",
	Semicolon = ";",
	BackSlash = "\\",
	Slash = "/",
	Minus = "-",
	Equals = "=",
	Return = "Enter",
	Backquote = "`",
	CapsLock = "Caps",
	LeftShift = "LShift",
	RightShift = "RShift",
	LeftControl = "LCtrl",
	RightControl = "RCtrl",
	LeftAlt = "LAlt",
	RightAlt = "RAlt",
	Backspace = "Back",
	Plus = "+",
	Multiply = "x",
	PageUp = "PgUp",
	PageDown = "PgDown",
	Delete = "Del",
	Insert = "Ins",
	NumLock = "NumL",
	Comma = ",",
	Period = ".",
}
local colemak = {
	E = "F",
	R = "P",
	T = "G",
	Y = "J",
	U = "L",
	I = "U",
	O = "Y",
	P = ";",
	S = "R",
	D = "S",
	F = "T",
	G = "D",
	J = "N",
	K = "E",
	L = "I",
	[";"] = "O",
	N = "K",
}

local keymodifiernames = {
	["`"] = "~",
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["-"] = "_",
	["="] = "+",
	["["] = "{",
	["]"] = "}",
	["\\"] = "|",
	[";"] = ":",
	["'"] = '"',
	[","] = "<",
	["."] = ".",
	["/"] = "?",
}

local function KeyEnumToName(key) -- did this all in a function cuz why not
	if key == nil then
		return "None"
	end
	local _key = tostring(key) .. "."
	local _key = _key:gsub("%.", ",")
	local keyname = nil
	local looptime = 0
	for w in _key:gmatch("(.-),") do
		looptime = looptime + 1
		if looptime == 3 then
			keyname = w
		end
	end
	if string.match(keyname, "Keypad") then
		keyname = string.gsub(keyname, "Keypad", "")
	end

	if keyname == "Unknown" or key.Value == 27 then
		return "None"
	end

	if keyNames[keyname] then
		keyname = keyNames[keyname]
	end
	if Nate then
		return colemak[keyname] or keyname
	else
		return keyname
	end
end

local invalidfilekeys = {
	["\\"] = true,
	["/"] = true,
	[":"] = true,
	["*"] = true,
	["?"] = true,
	['"'] = true,
	["<"] = true,
	[">"] = true,
	["|"] = true,
}

local function KeyModifierToName(key, filename)
	if keymodifiernames[key] ~= nil then
		if filename then
			if invalidfilekeys[keymodifiernames[key]] then
				return ""
			else
				return keymodifiernames[key]
			end
		else
			return keymodifiernames[key]
		end
	else
		return ""
	end
end

local allrender = {}

local RGB = Color3.fromRGB
local Draw = {}

do
	function Draw:UnRender()
		for k, v in pairs(allrender) do
			for k1, v1 in pairs(v) do
				--warn(k1, v1)
				-- ANCHOR WHAT THE FUCK IS GOING ON WITH THIS WHY IS THIS ERRORING BECAUSE OF NUMBER
				if v1 and type(v1) ~= "number" and v1.__OBJECT_EXISTS then
					v1:Remove()
				else
					--rconsolewarn(tostring(k),tostring(v),tostring(k1),tostring(v1)) -- idfk why but this shit doesn't print anything out. might as well have it commented out though -nata april 1 21
				end
			end
		end
	end

	function Draw:OutlinedRect(visible, pos_x, pos_y, width, height, clr, tablename)
		local temptable = Drawing.new("Square")
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = Vector2.new(width, height)
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Filled = false
		temptable.Thickness = 0
		temptable.Transparency = clr[4] / 255
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:FilledRect(visible, pos_x, pos_y, width, height, clr, tablename)
		local temptable = Drawing.new("Square")
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = Vector2.new(width, height)
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Filled = true
		temptable.Thickness = 0
		temptable.Transparency = clr[4] / 255
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:Line(visible, thickness, start_x, start_y, end_x, end_y, clr, tablename)
		temptable = Drawing.new("Line")
		temptable.Visible = visible
		temptable.Thickness = thickness
		temptable.From = Vector2.new(start_x, start_y)
		temptable.To = Vector2.new(end_x, end_y)
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Transparency = clr[4] / 255
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:Image(visible, imagedata, pos_x, pos_y, width, height, transparency, tablename)
		local temptable = Drawing.new("Image")
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = Vector2.new(width, height)
		temptable.Transparency = transparency
		temptable.Data = imagedata or placeholderImage
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:Text(text, font, visible, pos_x, pos_y, size, centered, clr, tablename)
		local temptable = Drawing.new("Text")
		temptable.Text = text
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = size
		temptable.Center = centered
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Transparency = clr[4] / 255
		temptable.Outline = false
		temptable.Font = font
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:OutlinedText(text, font, visible, pos_x, pos_y, size, centered, clr, clr2, tablename)
		local temptable = Drawing.new("Text")
		temptable.Text = text
		temptable.Visible = visible
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Size = size
		temptable.Center = centered
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Transparency = clr[4] / 255
		temptable.Outline = true
		temptable.OutlineColor = RGB(clr2[1], clr2[2], clr2[3])
		temptable.Font = font
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
		if tablename then
			table.insert(tablename, temptable)
		end
		return temptable
	end

	function Draw:Triangle(visible, filled, pa, pb, pc, clr, tablename)
		clr = clr or { 255, 255, 255, 1 }
		local temptable = Drawing.new("Triangle")
		temptable.Visible = visible
		temptable.Transparency = clr[4] or 1
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		temptable.Thickness = 4.1
		if pa and pb and pc then
			temptable.PointA = Vector2.new(pa[1], pa[2])
			temptable.PointB = Vector2.new(pb[1], pb[2])
			temptable.PointC = Vector2.new(pc[1], pc[2])
		end
		temptable.Filled = filled
		table.insert(tablename, temptable)
		if tablename and not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:Circle(visible, pos_x, pos_y, size, thickness, sides, clr, tablename)
		local temptable = Drawing.new("Circle")
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Visible = visible
		temptable.Radius = size
		temptable.Thickness = thickness
		temptable.NumSides = sides
		temptable.Transparency = clr[4]
		temptable.Filled = false
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	function Draw:FilledCircle(visible, pos_x, pos_y, size, thickness, sides, clr, tablename)
		local temptable = Drawing.new("Circle")
		temptable.Position = Vector2.new(pos_x, pos_y)
		temptable.Visible = visible
		temptable.Radius = size
		temptable.Thickness = thickness
		temptable.NumSides = sides
		temptable.Transparency = clr[4]
		temptable.Filled = true
		temptable.Color = RGB(clr[1], clr[2], clr[3])
		table.insert(tablename, temptable)
		if not table.find(allrender, tablename) then
			table.insert(allrender, tablename)
		end
	end

	--ANCHOR MENU ELEMENTS

	function Draw:MenuOutlinedRect(visible, pos_x, pos_y, width, height, clr, tablename)
		Draw:OutlinedRect(visible, pos_x + menu.x, pos_y + menu.y, width, height, clr, tablename)
		table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })

		if menu.log_multi ~= nil then
			table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
		end
	end

	function Draw:MenuFilledRect(visible, pos_x, pos_y, width, height, clr, tablename)
		Draw:FilledRect(visible, pos_x + menu.x, pos_y + menu.y, width, height, clr, tablename)
		table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })

		if menu.log_multi ~= nil then
			table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
		end
	end

	function Draw:MenuImage(visible, imagedata, pos_x, pos_y, width, height, transparency, tablename)
		Draw:Image(visible, imagedata, pos_x + menu.x, pos_y + menu.y, width, height, transparency, tablename)
		table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })

		if menu.log_multi ~= nil then
			table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
		end
	end

	function Draw:MenuBigText(text, visible, centered, pos_x, pos_y, tablename)
		local text = Draw:OutlinedText(
			text,
			2,
			visible,
			pos_x + menu.x,
			pos_y + menu.y,
			13,
			centered,
			{ 255, 255, 255, 255 },
			{ 0, 0, 0 },
			tablename
		)
		table.insert(menu.postable, { tablename[#tablename], pos_x, pos_y })

		if menu.log_multi ~= nil then
			table.insert(menu.mgrouptabz[menu.log_multi[1]][menu.log_multi[2]], tablename[#tablename])
		end

		return text
	end

	function Draw:CoolBox(name, x, y, width, height, tab)
		Draw:MenuOutlinedRect(true, x, y, width, height, { 0, 0, 0, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, width - 2, height - 2, { 20, 20, 20, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 2, y + 2, width - 3, 1, { 127, 72, 163, 255 }, tab)
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 3, width - 3, 1, { 87, 32, 123, 255 }, tab)
		table.insert(menu.clrs.dark, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 4, width - 3, 1, { 20, 20, 20, 255 }, tab)

		for i = 0, 7 do
			Draw:MenuFilledRect(true, x + 2, y + 5 + (i * 2), width - 4, 2, { 45, 45, 45, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(45, 45, 45) }, [2] = { start = 7, color = RGB(35, 35, 35) } }
			)
		end

		Draw:MenuBigText(name, true, false, x + 6, y + 5, tab)
	end

	function Draw:CoolMultiBox(names, x, y, width, height, tab)
		Draw:MenuOutlinedRect(true, x, y, width, height, { 0, 0, 0, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, width - 2, height - 2, { 20, 20, 20, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 2, y + 2, width - 3, 1, { 127, 72, 163, 255 }, tab)
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 3, width - 3, 1, { 87, 32, 123, 255 }, tab)
		table.insert(menu.clrs.dark, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 4, width - 3, 1, { 20, 20, 20, 255 }, tab)

		--{35, 35, 35, 255}

		Draw:MenuFilledRect(true, x + 2, y + 5, width - 4, 18, { 30, 30, 30, 255 }, tab)
		Draw:MenuFilledRect(true, x + 2, y + 21, width - 4, 2, { 20, 20, 20, 255 }, tab)

		local selected = {}
		for i = 0, 8 do
			Draw:MenuFilledRect(true, x + 2, y + 5 + (i * 2), width - 159, 2, { 45, 45, 45, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 8, color = RGB(35, 35, 35) } }
			)
			table.insert(selected, { postable = #menu.postable, drawn = tab[#tab] })
		end

		local length = 2
		local selected_pos = {}
		local click_pos = {}
		local nametext = {}
		for i, v in ipairs(names) do
			Draw:MenuBigText(v, true, false, x + 4 + length, y + 5, tab)
			if i == 1 then
				tab[#tab].Color = RGB(255, 255, 255)
			else
				tab[#tab].Color = RGB(170, 170, 170)
			end
			table.insert(nametext, tab[#tab])

			Draw:MenuFilledRect(true, x + length + tab[#tab].TextBounds.X + 8, y + 5, 2, 16, { 20, 20, 20, 255 }, tab)
			table.insert(selected_pos, { pos = x + length, length = tab[#tab - 1].TextBounds.X + 8 })
			table.insert(click_pos, {
				x = x + length,
				y = y + 5,
				width = tab[#tab - 1].TextBounds.X + 8,
				height = 18,
				name = v,
				num = i,
			})
			length += tab[#tab - 1].TextBounds.X + 10
		end

		local settab = 1
		for k, v in pairs(selected) do
			menu.postable[v.postable][2] = selected_pos[settab].pos
			v.drawn.Size = Vector2.new(selected_pos[settab].length, 2)
		end

		return { bar = selected, barpos = selected_pos, click_pos = click_pos, nametext = nametext }

		--Draw:MenuBigText(str, true, false, x + 6, y + 5, tab)
	end

	function Draw:Toggle(name, value, unsafe, x, y, tab)
		Draw:MenuOutlinedRect(true, x, y, 12, 12, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, 10, 10, { 0, 0, 0, 255 }, tab)

		local temptable = {}
		for i = 0, 3 do
			Draw:MenuFilledRect(true, x + 2, y + 2 + (i * 2), 8, 2, { 0, 0, 0, 255 }, tab)
			table.insert(temptable, tab[#tab])
			if value then
				tab[#tab].Color = ColorRange(i, {
					[1] = { start = 0, color = RGB(menu.mc[1], menu.mc[2], menu.mc[3]) },
					[2] = { start = 3, color = RGB(menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40) },
				})
			else
				tab[#tab].Color = ColorRange(i, {
					[1] = { start = 0, color = RGB(50, 50, 50) },
					[2] = { start = 3, color = RGB(30, 30, 30) },
				})
			end
		end

		Draw:MenuBigText(name, true, false, x + 16, y - 1, tab)
		if unsafe == true then
			tab[#tab].Color = RGB(90, 90, 90)
		end
		table.insert(temptable, tab[#tab])
		return temptable
	end

	function Draw:Keybind(key, x, y, tab)
		local temptable = {}
		Draw:MenuFilledRect(true, x, y, 44, 16, { 25, 25, 25, 255 }, tab)
		Draw:MenuBigText(KeyEnumToName(key), true, true, x + 22, y + 1, tab)
		table.insert(temptable, tab[#tab])
		Draw:MenuOutlinedRect(true, x, y, 44, 16, { 30, 30, 30, 255 }, tab)
		table.insert(temptable, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 1, y + 1, 42, 14, { 0, 0, 0, 255 }, tab)

		return temptable
	end

	function Draw:ColorPicker(color, x, y, tab)
		local temptable = {}

		Draw:MenuOutlinedRect(true, x, y, 28, 14, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, 26, 12, { 0, 0, 0, 255 }, tab)

		Draw:MenuFilledRect(true, x + 2, y + 2, 24, 10, { color[1], color[2], color[3], 255 }, tab)
		table.insert(temptable, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 2, y + 2, 24, 10, { color[1] - 40, color[2] - 40, color[3] - 40, 255 }, tab)
		table.insert(temptable, tab[#tab])
		Draw:MenuOutlinedRect(true, x + 3, y + 3, 22, 8, { color[1] - 40, color[2] - 40, color[3] - 40, 255 }, tab)
		table.insert(temptable, tab[#tab])

		return temptable
	end

	function Draw:Slider(name, stradd, value, minvalue, maxvalue, customvals, rounded, x, y, length, tab)
		Draw:MenuBigText(name, true, false, x, y - 3, tab)

		for i = 0, 3 do
			Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 3, color = RGB(30, 30, 30) } }
			)
		end

		local temptable = {}
		for i = 0, 3 do
			Draw:MenuFilledRect(
				true,
				x + 2,
				y + 14 + (i * 2),
				(length - 4) * ((value - minvalue) / (maxvalue - minvalue)),
				2,
				{ 0, 0, 0, 255 },
				tab
			)
			table.insert(temptable, tab[#tab])
			tab[#tab].Color = ColorRange(i, {
				[1] = { start = 0, color = RGB(menu.mc[1], menu.mc[2], menu.mc[3]) },
				[2] = { start = 3, color = RGB(menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40) },
			})
		end
		Draw:MenuOutlinedRect(true, x, y + 12, length, 12, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 10, { 0, 0, 0, 255 }, tab)

		local textstr = ""

		if stradd == nil then
			stradd = ""
		end

		local decplaces = rounded and string.rep("0", math.log(1 / rounded) / math.log(10)) or 1
		if rounded and value == math.floor(value * decplaces) then
			textstr = tostring(value) .. "." .. decplaces .. stradd
		else
			textstr = tostring(value) .. stradd
		end

		Draw:MenuBigText(customvals[value] or textstr, true, true, x + (length * 0.5), y + 11, tab)
		table.insert(temptable, tab[#tab])
		table.insert(temptable, stradd)
		return temptable
	end

	function Draw:Dropbox(name, value, values, x, y, length, tab)
		local temptable = {}
		Draw:MenuBigText(name, true, false, x, y - 3, tab)

		for i = 0, 7 do
			Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 7, color = RGB(35, 35, 35) } }
			)
		end

		Draw:MenuOutlinedRect(true, x, y + 12, length, 22, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 20, { 0, 0, 0, 255 }, tab)

		Draw:MenuBigText(tostring(values[value]), true, false, x + 6, y + 16, tab)
		table.insert(temptable, tab[#tab])

		Draw:MenuBigText("-", true, false, x - 17 + length, y + 16, tab)
		table.insert(temptable, tab[#tab])

		return temptable
	end

	function Draw:Combobox(name, values, x, y, length, tab)
		local temptable = {}
		Draw:MenuBigText(name, true, false, x, y - 3, tab)

		for i = 0, 7 do
			Draw:MenuFilledRect(true, x + 2, y + 14 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 7, color = RGB(35, 35, 35) } }
			)
		end

		Draw:MenuOutlinedRect(true, x, y + 12, length, 22, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 20, { 0, 0, 0, 255 }, tab)
		local textthing = ""
		for k, v in pairs(values) do
			if v[2] then
				if textthing == "" then
					textthing = v[1]
				else
					textthing ..= ", " .. v[1]
				end
			end
		end
		if string.len(textthing) > 25 then
			textthing = string_cut(textthing, 25)
		end
		textthing = textthing ~= "" and textthing or "None"
		Draw:MenuBigText(textthing, true, false, x + 6, y + 16, tab)
		table.insert(temptable, tab[#tab])

		Draw:MenuBigText("...", true, false, x - 27 + length, y + 16, tab)
		table.insert(temptable, tab[#tab])

		return temptable
	end

	function Draw:Button(name, x, y, length, tab)
		local temptable = {}

		for i = 0, 8 do
			Draw:MenuFilledRect(true, x + 2, y + 2 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 8, color = RGB(35, 35, 35) } }
			)
			table.insert(temptable, tab[#tab])
		end

		Draw:MenuOutlinedRect(true, x, y, length, 22, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, length - 2, 20, { 0, 0, 0, 255 }, tab)
		temptable.text = Draw:MenuBigText(name, true, true, x + math.floor(length * 0.5), y + 4, tab)

		return temptable
	end

	function Draw:List(name, x, y, length, maxamount, columns, tab)
		local temptable = { uparrow = {}, downarrow = {}, liststuff = { rows = {}, words = {} } }

		for i, v in ipairs(name) do
			Draw:MenuBigText(
				v,
				true,
				false,
				(math.floor(length / columns) * i) - math.floor(length / columns) + 30,
				y - 3,
				tab
			)
		end

		Draw:MenuOutlinedRect(true, x, y + 12, length, 22 * maxamount + 4, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 13, length - 2, 22 * maxamount + 2, { 0, 0, 0, 255 }, tab)

		Draw:MenuFilledRect(true, x + length - 7, y + 16, 1, 1, { menu.mc[1], menu.mc[2], menu.mc[3], 255 }, tab)
		table.insert(temptable.uparrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuFilledRect(true, x + length - 8, y + 17, 3, 1, { menu.mc[1], menu.mc[2], menu.mc[3], 255 }, tab)
		table.insert(temptable.uparrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuFilledRect(true, x + length - 9, y + 18, 5, 1, { menu.mc[1], menu.mc[2], menu.mc[3], 255 }, tab)
		table.insert(temptable.uparrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])

		Draw:MenuFilledRect(
			true,
			x + length - 7,
			y + 16 + (22 * maxamount + 4) - 9,
			1,
			1,
			{ menu.mc[1], menu.mc[2], menu.mc[3], 255 },
			tab
		)
		table.insert(temptable.downarrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuFilledRect(
			true,
			x + length - 8,
			y + 16 + (22 * maxamount + 4) - 10,
			3,
			1,
			{ menu.mc[1], menu.mc[2], menu.mc[3], 255 },
			tab
		)
		table.insert(temptable.downarrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])
		Draw:MenuFilledRect(
			true,
			x + length - 9,
			y + 16 + (22 * maxamount + 4) - 11,
			5,
			1,
			{ menu.mc[1], menu.mc[2], menu.mc[3], 255 },
			tab
		)
		table.insert(temptable.downarrow, tab[#tab])
		table.insert(menu.clrs.norm, tab[#tab])

		for i = 1, maxamount do
			temptable.liststuff.rows[i] = {}
			if i ~= maxamount then
				Draw:MenuOutlinedRect(true, x + 4, (y + 13) + (22 * i), length - 8, 2, { 20, 20, 20, 255 }, tab)
				table.insert(temptable.liststuff.rows[i], tab[#tab])
			end

			if columns ~= nil then
				for i1 = 1, columns - 1 do
					Draw:MenuOutlinedRect(
						true,
						x + math.floor(length / columns) * i1,
						(y + 13) + (22 * i) - 18,
						2,
						16,
						{ 20, 20, 20, 255 },
						tab
					)
					table.insert(temptable.liststuff.rows[i], tab[#tab])
				end
			end

			temptable.liststuff.words[i] = {}
			if columns ~= nil then
				for i1 = 1, columns do
					Draw:MenuBigText(
						"",
						true,
						false,
						(x + math.floor(length / columns) * i1) - math.floor(length / columns) + 5,
						(y + 13) + (22 * i) - 16,
						tab
					)
					table.insert(temptable.liststuff.words[i], tab[#tab])
				end
			else
				Draw:MenuBigText("", true, false, x + 5, (y + 13) + (22 * i) - 16, tab)
				table.insert(temptable.liststuff.words[i], tab[#tab])
			end
		end

		return temptable
	end

	function Draw:ImageWithText(size, image, text, x, y, tab)
		local temptable = {}
		Draw:MenuOutlinedRect(true, x, y, size + 4, size + 4, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, size + 2, size + 2, { 0, 0, 0, 255 }, tab)
		Draw:MenuFilledRect(true, x + 2, y + 2, size, size, { 40, 40, 40, 255 }, tab)

		Draw:MenuBigText(text, true, false, x + size + 8, y, tab)
		table.insert(temptable, tab[#tab])

		Draw:MenuImage(true, BBOT_IMAGES[5], x + 2, y + 2, size, size, 1, tab)
		table.insert(temptable, tab[#tab])

		return temptable
	end

	function Draw:TextBox(name, text, x, y, length, tab)
		for i = 0, 8 do
			Draw:MenuFilledRect(true, x + 2, y + 2 + (i * 2), length - 4, 2, { 0, 0, 0, 255 }, tab)
			tab[#tab].Color = ColorRange(
				i,
				{ [1] = { start = 0, color = RGB(50, 50, 50) }, [2] = { start = 8, color = RGB(35, 35, 35) } }
			)
		end

		Draw:MenuOutlinedRect(true, x, y, length, 22, { 30, 30, 30, 255 }, tab)
		Draw:MenuOutlinedRect(true, x + 1, y + 1, length - 2, 20, { 0, 0, 0, 255 }, tab)
		Draw:MenuBigText(text, true, false, x + 6, y + 4, tab)

		return tab[#tab]
	end
end

-- finish

local loadingthing = Draw:OutlinedText(
	"Loading...",
	2,
	true,
	math.floor(SCREEN_SIZE.x / 16),
	math.floor(SCREEN_SIZE.y / 16),
	13,
	true,
	{ 255, 50, 200, 255 },
	{ 0, 0, 0 }
)

menu.Initialize({
    {
        name = "Aimbot",
        content = {
            {
                name = "Main",
                autopos = "left",
                content = {
                    {
                        type = "toggle",
                        name = "Enable Aimbot",
                        value = false,
                        callback = function(bool) getgenv().AimbotEnabled = bool end
                    },
                    {
                        type = "toggle",
                        name = "Camera Aimbot (Viewport)",
                        value = false,
                        callback = function(bool) getgenv().CameraAim = bool end
                    },
                    {
                        type = "toggle",
                        name = "Silent Aim (Raycast)",
                        value = true,
                        callback = function(bool) getgenv().SilentAim = bool end
                    },
                    {
                        type = "toggle",
                        name = "Show FOV Circle",
                        value = true,
                        callback = function(bool) getgenv().ShowFOV = bool end
                    },
                    {
                        type = "toggle",
                        name = "Visibility Check",
                        value = true,
                        callback = function(bool) getgenv().VisCheck = bool end
                    },
                    {
                        type = "toggle",
                        name = "Team Check",
                        value = false,
                        callback = function(bool) getgenv().TeamCheck = bool end
                    },
                    {
                        type = "slider",
                        name = "FOV",
                        value = 200,
                        minvalue = 10,
                        maxvalue = 500,
                        stradd = "px",
                        callback = function(v) getgenv().AimbotFOV = v end
                    },
                    {
                        type = "slider",
                        name = "Smoothness",
                        value = 0.1,
                        minvalue = 0.1,
                        maxvalue = 1,
                        decimal = 0.1,
                        callback = function(v) getgenv().Smoothness = v end
                    },
                    {
                        type = "dropbox",
                        name = "Hit Part",
                        value = 1,
                        values = {"Head", "UpperTorso", "HumanoidRootPart"},
                        callback = function(v) getgenv().HitPart = v end
                    },
                    {
                        type = "dropbox",
                        name = "Aim Key",
                        value = 1,
                        values = {"Right Mouse", "Left Mouse", "E", "Q"},
                        callback = function(v)
                            if v == "Right Mouse" then getgenv().AimKey = Enum.UserInputType.MouseButton2
                            elseif v == "Left Mouse" then getgenv().AimKey = Enum.UserInputType.MouseButton1
                            else getgenv().AimKey = Enum.KeyCode[v] end
                        end
                    },
                }
            },
            {
                name = "Silent Aim Remote",
                autopos = "right",
                content = {
                    {
                        type = "input",
                        name = "Remote Name",
                        value = "FireBullet",
                        placeholder = "e.g. FireBullet",
                        callback = function(v)
                            getgenv().RemoteName = v
                            pcall(function() hookSilentAim(v) end)
                        end
                    },
                    {
                        type = "button",
                        name = "Auto-Detect Remote",
                        callback = function()
                            local names = {"FireBullet", "Shoot", "WeaponFire", "Fire", "RaycastHit"}
                            for _, n in ipairs(names) do
                                local ok = pcall(function() hookSilentAim(n) end)
                                if ok then
                                    CreateNotification("Hooked remote: " .. n)
                                    return
                                end
                            end
                            CreateNotification("No remote found.")
                        end
                    },
                }
            },
        }
    },
    {
        name = "Visuals",
        content = {
            {
                name = "ESP",
                autopos = "left",
                content = {
                    {
                        type = "toggle",
                        name = "Enable ESP",
                        value = false,
                        callback = function(bool) getgenv().ESPEnabled = bool end
                    },
                    {
                        type = "toggle",
                        name = "Box",
                        value = true,
                        callback = function(bool) getgenv().ESPBox = bool end
                    },
                    {
                        type = "toggle",
                        name = "Name",
                        value = true,
                        callback = function(bool) getgenv().ESPName = bool end
                    },
                    {
                        type = "toggle",
                        name = "Health Bar",
                        value = true,
                        callback = function(bool) getgenv().ESPHealth = bool end
                    },
                    {
                        type = "toggle",
                        name = "Distance",
                        value = true,
                        callback = function(bool) getgenv().ESPDistance = bool end
                    },
                    {
                        type = "toggle",
                        name = "Tracers",
                        value = true,
                        callback = function(bool) getgenv().ESPTracers = bool end
                    },
                    {
                        type = "toggle",
                        name = "Skeleton (R6/R15)",
                        value = false,
                        callback = function(bool) getgenv().ESPSkeleton = bool end
                    },
                }
            },
            {
                name = "World",
                autopos = "right",
                content = {
                    {
                        type = "toggle",
                        name = "Anti-Flash",
                        value = false,
                        callback = function(bool) getgenv().AntiFlash = bool end
                    },
                    {
                        type = "toggle",
                        name = "Anti-Smoke",
                        value = false,
                        callback = function(bool) getgenv().AntiSmoke = bool end
                    },
                }
            },
        }
    },
    {
        name = "Misc",
        content = {
            {
                name = "Triggerbot",
                autopos = "left",
                content = {
                    {
                        type = "toggle",
                        name = "Enable Triggerbot",
                        value = false,
                        callback = function(bool) getgenv().TriggerbotEnabled = bool end
                    },
                    {
                        type = "slider",
                        name = "Delay (ms)",
                        value = 0,
                        minvalue = 0,
                        maxvalue = 500,
                        stradd = "ms",
                        callback = function(v) getgenv().TriggerbotDelay = v end
                    },
                }
            },
            {
                name = "Hitbox",
                autopos = "right",
                content = {
                    {
                        type = "toggle",
                        name = "Enable Hitbox",
                        value = false,
                        callback = function(bool) getgenv().HitboxEnabled = bool end
                    },
                    {
                        type = "slider",
                        name = "Head Size",
                        value = 3,
                        minvalue = 1,
                        maxvalue = 3,
                        decimal = 0.1,
                        stradd = "Studs",
                        callback = function(v) getgenv().HitboxSize = v end
                    },
                }
            },
            {
                name = "Movement",
                autopos = "left",
                autofill = true,
                content = {
                    {
                        type = "toggle",
                        name = "Bunny Hop",
                        value = false,
                        callback = function(bool) getgenv().BhopEnabled = bool end
                    },
                }
            },
            {
                name = "Controller",
                autopos = "right",
                autofill = true,
                content = {
                    {
                        type = "toggle",
                        name = "Use Controller (Right Stick)",
                        value = false,
                        callback = function(bool) getgenv().ControllerEnabled = bool end
                    },
                    {
                        type = "slider",
                        name = "Sensitivity",
                        value = 0.5,
                        minvalue = 0.1,
                        maxvalue = 2,
                        decimal = 0.1,
                        callback = function(v) getgenv().ControllerSensitivity = v end
                    },
                }
            },
        }
    },
    {
        name = "Settings",
        content = {
            {
                name = "Cheat Settings",
                x = menu.columns.left,
                y = 66,
                width = menu.columns.width,
                height = 200,
                content = {
                    {
                        type = "toggle",
                        name = "Watermark",
                        value = true,
                        callback = function(bool)
                            for k, v in pairs(menu.watermark.rect) do v.Visible = bool end
                            menu.watermark.text[1].Visible = bool
                        end
                    },
                    {
                        type = "button",
                        name = "Unload Cheat",
                        doubleclick = true,
                        callback = function()
                            menu.fading = true
                            wait()
                            menu:unload()
                        end
                    },
                }
            },
        }
    },
})

-- =============================================
--  FEATURE CODE (Aimbot, ESP, etc.)
-- =============================================

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- Default settings
getgenv().AimbotEnabled = false
getgenv().CameraAim = false
getgenv().SilentAim = true
getgenv().ShowFOV = true
getgenv().AimbotFOV = 200
getgenv().Smoothness = 0.1
getgenv().HitPart = "Head"
getgenv().VisCheck = true
getgenv().TeamCheck = false
getgenv().AimKey = Enum.UserInputType.MouseButton2
getgenv().TriggerbotEnabled = false
getgenv().TriggerbotDelay = 0
getgenv().HitboxEnabled = false
getgenv().HitboxSize = 3
getgenv().BhopEnabled = false
getgenv().AntiFlash = false
getgenv().AntiSmoke = false
getgenv().ControllerEnabled = false
getgenv().ControllerSensitivity = 0.5
getgenv().ESPEnabled = false
getgenv().ESPBox = true
getgenv().ESPName = true
getgenv().ESPHealth = true
getgenv().ESPDistance = true
getgenv().ESPTracers = true
getgenv().ESPSkeleton = false
getgenv().RemoteName = "FireBullet"

-- Drawing for FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255,255,255)
FOVCircle.Thickness = 1

-- Silent aim target
local SilentAimTarget = nil
local isAiming = false

UIS.InputBegan:Connect(function(input)
    if input.UserInputType == getgenv().AimKey then isAiming = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == getgenv().AimKey then isAiming = false end
end)

local function teamCheck(plr)
    return getgenv().TeamCheck and plr.Team == LocalPlayer.Team
end
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin).Unit * 1000
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit and hit:IsDescendantOf(part.Parent)
end

local function getClosestEnemy()
    local closest = nil
    local closestDist = getgenv().AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or teamCheck(player) then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part
        if getgenv().HitPart == "Head" then part = char:FindFirstChild("Head")
        elseif getgenv().HitPart == "UpperTorso" then part = char:FindFirstChild("UpperTorso")
        else part = char:FindFirstChild("HumanoidRootPart") end
        if not part then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < closestDist then
            if getgenv().VisCheck and not isVisible(part) then continue end
            closestDist = dist
            closest = part
        end
    end
    return closest
end

function hookSilentAim(remoteName)
    local remote = nil
    local remotesFolder = RS:FindFirstChild("Remotes") or RS
    if remotesFolder then
        remote = remotesFolder:FindFirstChild(remoteName) or remotesFolder:FindFirstChild("FireBullet") or remotesFolder:FindFirstChild("Shoot")
    end
    if remote and remote:IsA("RemoteEvent") then
        local old = hookfunction(remote.FireServer, function(self, ...)
            local args = {...}
            if SilentAimTarget and getgenv().AimbotEnabled and getgenv().SilentAim then
                args[1] = SilentAimTarget.Position
            end
            return old(self, unpack(args))
        end)
        return true
    end
    return false
end

-- Start aimbot loops
RunService.RenderStepped:Connect(function()
    -- FOV circle
    if getgenv().AimbotEnabled and getgenv().ShowFOV then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Radius = getgenv().AimbotFOV
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if not getgenv().AimbotEnabled then
        SilentAimTarget = nil
        return
    end

    local target = getClosestEnemy()
    SilentAimTarget = target

    if getgenv().CameraAim and isAiming and target then
        local targetPos = Camera:WorldToViewportPoint(target.Position)
        local mousePos = UIS:GetMouseLocation()
        local smooth = getgenv().Smoothness * 5
        local moveX = (targetPos.X - mousePos.X) / smooth
        local moveY = (targetPos.Y - mousePos.Y) / smooth
        if mousemoverel then mousemoverel(moveX, moveY) end
    end
end)

-- Triggerbot
spawn(function()
    while task.wait(0.01) do
        if getgenv().TriggerbotEnabled then
            local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local ignore = {Camera}
            if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
            params.FilterDescendantsInstances = ignore
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            if result and result.Instance then
                local model = result.Instance:FindFirstAncestorOfClass("Model")
                if model then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local plr = Players:GetPlayerFromCharacter(model)
                        if plr and plr ~= LocalPlayer and not teamCheck(plr) then
                            if getgenv().TriggerbotDelay > 0 then task.wait(getgenv().TriggerbotDelay/1000) end
                            if mouse1click then mouse1click() end
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end
end)

-- Hitbox expander
local originalHeadSizes = {}
spawn(function()
    while task.wait(0.5) do
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or teamCheck(player) then continue end
            local char = player.Character
            if char then
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health > 0 then
                    if not originalHeadSizes[head] then originalHeadSizes[head] = head.Size end
                    if getgenv().HitboxEnabled then
                        head.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
                        head.CanCollide = false
                        head.Transparency = 0.5
                    else
                        if originalHeadSizes[head] then
                            head.Size = originalHeadSizes[head]
                            head.Transparency = 0
                        end
                    end
                end
            end
        end
    end
end)

-- Bunnyhop
RunService.RenderStepped:Connect(function()
    if getgenv().BhopEnabled and UIS:IsKeyDown(Enum.KeyCode.Space) then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                hum.Jump = true
            end
        end
    end
end)

-- Anti-Flash/Smoke
spawn(function()
    while task.wait(0.2) do
        if getgenv().AntiFlash then
            local gui = LocalPlayer.PlayerGui:FindFirstChild("FlashbangEffect")
            local effect = Lighting:FindFirstChild("FlashbangColorCorrection")
            if gui then gui:Destroy() end
            if effect then effect:Destroy() end
        end
    end
end)
spawn(function()
    while task.wait(0.5) do
        if getgenv().AntiSmoke then
            local debris = Workspace:FindFirstChild("Debris")
            if debris then
                for _, folder in pairs(debris:GetChildren()) do
                    if string.match(folder.Name, "Voxel") then folder:ClearAllChildren(); folder:Destroy() end
                end
            end
        end
    end
end)

-- Controller aim
UIS.InputChanged:Connect(function(input)
    if getgenv().ControllerEnabled and (input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2) then
        if input.KeyCode == Enum.KeyCode.Thumbstick2 then
            local delta = input.Delta
            local sens = getgenv().ControllerSensitivity * 5
            if mousemoverel then mousemoverel(math.floor(delta.X * sens), math.floor(delta.Y * -sens)) end
        end
    end
end)

-- Full ESP system (using Drawing library from the UI)
local espCache = {}
local function getBonePositions(char)
    local bones = {}
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local leftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
    local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    local leftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
    local rightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
    local function pos(part) return part and part.Position end
    if head and torso then
        bones.Head = pos(head)
        bones.Torso = pos(torso)
        bones.LeftArm = pos(leftArm) or bones.Torso
        bones.RightArm = pos(rightArm) or bones.Torso
        bones.LeftLeg = pos(leftLeg) or (bones.Torso - Vector3.new(0,2,0))
        bones.RightLeg = pos(rightLeg) or (bones.Torso - Vector3.new(0,2,0))
    end
    return bones
end

local function createESPobj()
    local esp = {
        boxOutline = Drawing.new("Square"), box = Drawing.new("Square"),
        name = Drawing.new("Text"), distance = Drawing.new("Text"),
        healthOutline = Drawing.new("Line"), healthBar = Drawing.new("Line"),
        tracer = Drawing.new("Line"),
        skeletonLines = {},
    }
    esp.boxOutline.Thickness = 3; esp.boxOutline.Filled = false; esp.boxOutline.Color = Color3.new(0,0,0)
    esp.box.Thickness = 1; esp.box.Filled = false; esp.box.Color = Color3.fromRGB(255,50,50)
    esp.name.Center = true; esp.name.Outline = true; esp.name.Color = Color3.new(1,1,1); esp.name.Size = 16
    esp.distance.Center = true; esp.distance.Outline = true; esp.distance.Color = Color3.new(0.8,0.8,0.8); esp.distance.Size = 13
    esp.healthOutline.Thickness = 3; esp.healthOutline.Color = Color3.new(0,0,0)
    esp.healthBar.Thickness = 1; esp.healthBar.Color = Color3.new(0,1,0)
    esp.tracer.Thickness = 1; esp.tracer.Color = Color3.fromRGB(255,255,255); esp.tracer.Visible = false
    return esp
end

RunService.RenderStepped:Connect(function()
    if not getgenv().ESPEnabled then
        for _, e in pairs(espCache) do
            e.boxOutline.Visible = false; e.box.Visible = false
            e.name.Visible = false; e.distance.Visible = false
            e.healthOutline.Visible = false; e.healthBar.Visible = false
            e.tracer.Visible = false
            for _, line in ipairs(e.skeletonLines) do line:Remove() end
            e.skeletonLines = {}
        end
        return
    end

    local aliveSet = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or teamCheck(player) then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if hum and hum.Health > 0 and root and head then
            aliveSet[player] = true
            if not espCache[player] then espCache[player] = createESPobj() end
            local esp = espCache[player]
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
            if onScreen then
                local boxH = math.abs(headPos.Y - legPos.Y)
                local boxW = boxH / 2
                local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)

                -- Box
                if getgenv().ESPBox then
                    esp.boxOutline.Size = Vector2.new(boxW, boxH); esp.boxOutline.Position = Vector2.new(rootPos.X - boxW/2, headPos.Y)
                    esp.boxOutline.Visible = true
                    esp.box.Size = esp.boxOutline.Size; esp.box.Position = esp.boxOutline.Position; esp.box.Visible = true
                else
                    esp.boxOutline.Visible = false; esp.box.Visible = false
                end

                -- Health bar
                if getgenv().ESPHealth then
                    local hpPct = hum.Health / hum.MaxHealth
                    local barX = rootPos.X - boxW/2 - 6
                    esp.healthOutline.From = Vector2.new(barX, headPos.Y - 1); esp.healthOutline.To = Vector2.new(barX, headPos.Y + boxH + 1)
                    esp.healthOutline.Visible = true
                    esp.healthBar.From = Vector2.new(barX, headPos.Y + boxH); esp.healthBar.To = Vector2.new(barX, headPos.Y + boxH - (boxH * hpPct))
                    esp.healthBar.Color = Color3.new(1 - hpPct, hpPct, 0); esp.healthBar.Visible = true
                else
                    esp.healthOutline.Visible = false; esp.healthBar.Visible = false
                end

                -- Name
                esp.name.Text = getgenv().ESPName and player.Name or ""
                esp.name.Position = Vector2.new(rootPos.X, headPos.Y - 20); esp.name.Visible = getgenv().ESPName

                -- Distance
                esp.distance.Text = getgenv().ESPDistance and ("[" .. dist .. "m]") or ""
                esp.distance.Position = Vector2.new(rootPos.X, headPos.Y + boxH + 2); esp.distance.Visible = getgenv().ESPDistance

                -- Tracers
                if getgenv().ESPTracers then
                    esp.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    esp.tracer.To = Vector2.new(rootPos.X, rootPos.Y); esp.tracer.Visible = true
                else
                    esp.tracer.Visible = false
                end

                -- Skeleton
                if getgenv().ESPSkeleton then
                    local bones = getBonePositions(char)
                    for _, line in ipairs(esp.skeletonLines) do line:Remove() end
                    esp.skeletonLines = {}
                    if bones then
                        local pairs = {
                            {"Head", "Torso"}, {"Torso", "LeftArm"}, {"Torso", "RightArm"},
                            {"Torso", "LeftLeg"}, {"Torso", "RightLeg"},
                        }
                        for _, pair in ipairs(pairs) do
                            local b1 = bones[pair[1]]; local b2 = bones[pair[2]]
                            if b1 and b2 then
                                local s1, o1 = Camera:WorldToViewportPoint(b1)
                                local s2, o2 = Camera:WorldToViewportPoint(b2)
                                if o1 and o2 then
                                    local line = Drawing.new("Line")
                                    line.From = Vector2.new(s1.X, s1.Y); line.To = Vector2.new(s2.X, s2.Y)
                                    line.Color = Color3.fromRGB(255,255,255); line.Thickness = 1; line.Visible = true
                                    table.insert(esp.skeletonLines, line)
                                end
                            end
                        end
                    end
                else
                    for _, line in ipairs(esp.skeletonLines) do line:Remove() end
                    esp.skeletonLines = {}
                end
            else
                -- Off screen, hide everything
                esp.boxOutline.Visible = false; esp.box.Visible = false
                esp.name.Visible = false; esp.distance.Visible = false
                esp.healthOutline.Visible = false; esp.healthBar.Visible = false
                esp.tracer.Visible = false
                for _, line in ipairs(esp.skeletonLines) do line.Visible = false end
            end
        end
    end
    -- Cleanup dead players
    for plr, esp in pairs(espCache) do
        if not aliveSet[plr] then
            for _, obj in pairs(esp) do if type(obj) == "table" and obj.Remove then obj:Remove() end end
            espCache[plr] = nil
        end
    end
end)

-- Final initialization
CreateNotification("Tulip.lua loaded! Enjoy.")

do
	local wm = menu.watermark
	wm.textString = " | " .. "user" .. " | " .. os.date("%b. %d, %Y")
	wm.pos = Vector2.new(50, 9)
	wm.text = {}
	local fulltext = menu.options["Settings"]["Cheat Settings"]["MenuName"][1] .. wm.textString
	wm.width = #fulltext * 7 + 10
	wm.height = 19
	wm.rect = {}

	Draw:FilledRect(
		false,
		wm.pos.x,
		wm.pos.y + 1,
		wm.width,
		2,
		{ menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40, 255 },
		wm.rect
	)
	Draw:FilledRect(false, wm.pos.x, wm.pos.y, wm.width, 2, { menu.mc[1], menu.mc[2], menu.mc[3], 255 }, wm.rect)
	Draw:FilledRect(false, wm.pos.x, wm.pos.y + 3, wm.width, wm.height - 5, { 50, 50, 50, 255 }, wm.rect)
	for i = 0, wm.height - 4 do
		Draw:FilledRect(
			false,
			wm.pos.x,
			wm.pos.y + 3 + i,
			wm.width,
			1,
			{ 50 - i * 1.7, 50 - i * 1.7, 50 - i * 1.7, 255 },
			wm.rect
		)
	end
	Draw:OutlinedRect(false, wm.pos.x, wm.pos.y, wm.width, wm.height, { 0, 0, 0, 255 }, wm.rect)
	Draw:OutlinedRect(false, wm.pos.x - 1, wm.pos.y - 1, wm.width + 2, wm.height + 2, { 0, 0, 0, 255 * 0.4 }, wm.rect)
	Draw:OutlinedText(
		fulltext,
		2,
		false,
		wm.pos.x + 5,
		wm.pos.y + 3,
		13,
		false,
		{ 255, 255, 255, 255 },
		{ 0, 0, 0, 255 },
		wm.text
	)
end

--ANCHOR watermak
for k, v in pairs(menu.watermark.rect) do
	v.Visible = true
end

menu.watermark.text[1].Visible = true

local textbox = menu.options["Settings"]["Configuration"]["ConfigName"]
local relconfigs = GetConfigs()
textbox[1] = relconfigs[menu.options["Settings"]["Configuration"]["Configs"][1]]
textbox[4].Text = textbox[1]

menu.load_time = math.floor((tick() - loadstart) * 1000)
CreateNotification(string.format("Done loading the " .. menu.game .. " cheat. (%d ms)", menu.load_time))
CreateNotification("Press DELETE to open and close the menu!")

loadingthing.Visible = false -- i do it this way because otherwise it would fuck up the Draw:UnRender function, it doesnt cause any lag sooooo
if not menu.open then
	menu.fading = true
	menu.fadestart = tick()
end

menu.Initialize = true -- let me freeeeee
-- not lettin u free asshole bitch
-- i meant the program memory, alan...............  fuckyouAlan_iHateYOU from v1
-- im changing all the var names that had typos by me back to what they were now because of this.... enjoy hieght....
-- wutw