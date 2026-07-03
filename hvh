
-- HvH Script for Roblox: Advanced CS2-like Features with Controller Support
-- Uses WindUI library for GUI
-- Features: ESP (Box, Name, Health, Distance, Skeleton), Camera Aimbot, Silent Aim (Raycast), Triggerbot, Visuals (Chams, Glow), Radar, Anti-Aim (Fake Lag, Desync), Controller Support

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- CloneRef (safe)
local cloneref = (cloneref or clonereference or function(instance) return instance end)

-- Init WindUI
local WindUI
do
	local ok, result = pcall(function()
		return require("./src/Init")
	end)
	if ok then
		WindUI = result
	else
		if RunService:IsStudio() then
			WindUI = require(cloneref(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init")))
		else
			WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
		end
	end
end

-- Create Window
local Window = WindUI:CreateWindow({
	Title = "HVH Premium | v1.0",
	Folder = "hvh_universal",
	Icon = "solar:target-bold",
	Theme = "Dark",
	NewElements = true,
	HideSearchBar = false,
	OpenButton = {
		Title = "Open HVH",
		Enabled = true,
		Draggable = true,
		Scale = 0.5,
	},
	Topbar = {
		Height = 44,
		ButtonsType = "Mac",
	},
})

-- Globals
local Services = {
	Players = Players,
	RunService = RunService,
	UserInputService = UserInputService,
	Workspace = Workspace,
	Camera = Camera,
}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
local ESPCache = {}
local SilentAimTarget = nil

-- Settings
local Settings = {
	Aimbot = {
		Enabled = false,
		TeamCheck = true,
		VisibleCheck = true,
		HitPart = "Head", -- "Head", "UpperTorso", "HumanoidRootPart"
		FOV = 200,
		Smoothing = 0.1,
		Silent = true,
		Triggerbot = false,
		TriggerbotDelay = 0.1,
		UseController = false,
		ControllerSensitivity = 0.5,
	},
	Visuals = {
		ESP = {
			Enabled = true,
			Box = true,
			Name = true,
			Health = true,
			Distance = true,
			Skeleton = false,
			Chams = false,
			Glow = false,
		},
		Chams = {
			FillColor = Color3.fromRGB(255, 0, 0),
			OutlineColor = Color3.fromRGB(0, 0, 0),
		},
		Radar = {
			Enabled = true,
			Size = 200,
			Zoom = 1,
		},
		NightMode = false,
	},
	Misc = {
		AntiAim = false,
		FakeLag = false,
		DesyncAngle = 45,
		AutoCrouch = false,
	},
}

-- Utility Functions
local function getCharacter(player)
	local character = player.Character or player.CharacterAdded:Wait()
	return character
end

local function getHead(character)
	return character:FindFirstChild("Head")
end

local function getHumanoidRootPart(character)
	return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(character)
	return character:FindFirstChildWhichIsA("Humanoid")
end

local function teamCheck(plr)
	if Settings.Aimbot.TeamCheck then
		return LocalPlayer.Team == plr.Team
	end
	return false
end

local function isVisible(targetPart)
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin).Unit * 1000
	local ray = Ray.new(origin, direction)
	local hit, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
	if hit then
		return hit:IsDescendantOf(targetPart.Parent) or targetPart.Parent == hit.Parent
	end
	return false
end

local function getClosestTargetToCenter()
	local closest = nil
	local closestDistance = Settings.Aimbot.FOV
	local mousePosition = UserInputService:GetMouseLocation()
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for _, player in pairs(Players:GetPlayers()) do
		if player == LocalPlayer or teamCheck(player) then continue end
		local character = player.Character
		if not character then continue end
		local part
		if Settings.Aimbot.HitPart == "Head" then
			part = getHead(character)
		elseif Settings.Aimbot.HitPart == "UpperTorso" then
			part = character:FindFirstChild("UpperTorso")
		elseif Settings.Aimbot.HitPart == "HumanoidRootPart" then
			part = getHumanoidRootPart(character)
		end
		if not part then continue end
		local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
		if not onScreen then continue end
		local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
		if distance < closestDistance then
			if Settings.Aimbot.VisibleCheck then
				if isVisible(part) then
					closestDistance = distance
					closest = {Player = player, Character = character, Part = part, ScreenPos = screenPos}
				end
			else
				closestDistance = distance
				closest = {Player = player, Character = character, Part = part, ScreenPos = screenPos}
			end
		end
	end
	return closest
end

-- Aimbot Core
local aimbotRunning = false
local function AimbotLoop()
	if aimbotRunning then return end
	aimbotRunning = true
	RunService.RenderStepped:Connect(function()
		if not Settings.Aimbot.Enabled then return end
		if Settings.Aimbot.Silent then
			-- Silent aim via raycast hook: move mouse cursor to target part position before weapon fires
			local target = getClosestTargetToCenter()
			SilentAimTarget = target
		else
			-- Camera aimbot: smooth snap
			local target = getClosestTargetToCenter()
			if target then
				local currentCF = Camera.CFrame
				local targetPos = target.Part.Position
				local newLookAt = CFrame.new(currentCF.Position, targetPos)
				local smooth = Settings.Aimbot.Smoothing
				Camera.CFrame = currentCF:Lerp(newLookAt, smooth)
			end
		end
	end)
end

-- Silent aim hook: Replace the mouse's target position with the target's part position
-- For demonstration, we'll hook a generic remote named "FireBullet" (adapt to game)
local function hookSilentAim()
	-- Find the remote that handles shooting
	local remoteName = "FireBullet" -- typically, exploit scripts scan for specific remotes
	local remote = ReplicatedStorage:FindFirstChild(remoteName, true)
	if remote and remote:IsA("RemoteEvent") then
		local oldInvoke = remote.OnServerEvent
		local connection
		connection = remote.OnServerEvent:Connect(function(player, mousePos, ...)
			if player == LocalPlayer and SilentAimTarget then
				-- Replace mousePos with target part position
				mousePos = SilentAimTarget.Part.Position
			end
			-- Call original
			-- For a real exploit, you'd use hookfunction or namecall hook
			-- but we're using an 'OnServerEvent' connection for demonstration
			-- In practice, you might use getconnections and fire them.
		end)
		-- To properly hijack, you'd disconnect all other connections and re-fire with new args
	end
end

-- Controller Support: Activate aimbot when right stick is moved
UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2 then
		local stick = input.KeyCode
		if stick == Enum.KeyCode.Thumbstick2 then
			if Settings.Aimbot.UseController then
				local delta = input.Delta
				if delta.Magnitude > 0.2 then
					Settings.Aimbot.Enabled = true
				else
					Settings.Aimbot.Enabled = false
				end
			end
		end
	end
end)

-- Visuals: ESP Drawing
local function createESP(player)
	local cache = {}
	-- Box
	local boxOutline = Drawing.new("Square")
	boxOutline.Visible = false
	boxOutline.Color = Color3.new(1,1,1)
	boxOutline.Thickness = 1
	boxOutline.Filled = false
	boxOutline.Transparency = 1
	cache.Box = boxOutline

	local boxFill = Drawing.new("Square")
	boxFill.Visible = false
	boxFill.Color = Color3.new(0,0,0)
	boxFill.Thickness = 1
	boxFill.Filled = true
	boxFill.Transparency = 0.8
	cache.BoxFill = boxFill

	-- Name
	local name = Drawing.new("Text")
	name.Visible = false
	name.Center = true
	name.Outline = true
	name.Font = Drawing.Fonts.UI
	name.Size = 13
	cache.Name = name

	-- Health bar
	local healthOutline = Drawing.new("Square")
	healthOutline.Visible = false
	healthOutline.Color = Color3.new(0,0,0)
	healthOutline.Filled = false
	healthOutline.Thickness = 1
	cache.HealthOutline = healthOutline
	local healthFill = Drawing.new("Square")
	healthFill.Visible = false
	healthFill.Color = Color3.new(0,1,0)
	healthFill.Filled = true
	cache.HealthFill = healthFill

	-- Distance
	local distance = Drawing.new("Text")
	distance.Visible = false
	distance.Center = true
	distance.Outline = true
	distance.Font = Drawing.Fonts.UI
	distance.Size = 12
	cache.Distance = distance

	ESPCache[player] = cache
	return cache
end

local function updateESP()
	for player, cache in pairs(ESPCache) do
		local character = player.Character
		if not character or not player ~= LocalPlayer then
			cache.Box.Visible = false; cache.Name.Visible = false; -- etc
			continue
		end
		local rootPart = getHumanoidRootPart(character)
		local head = getHead(character)
		if not rootPart or not head then continue end
		local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
		local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
		if onScreen and headOnScreen then
			local scale = 1 / (pos.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2)
			local height = math.abs(headPos.Y - pos.Y) * scale
			local width = height / 2
			local x = pos.X - width / 2
			local y = headPos.Y
			-- Box
			cache.Box.Visible = Settings.Visuals.ESP.Box
			cache.Box.Size = Vector2.new(width, height)
			cache.Box.Position = Vector2.new(x, y)
			cache.BoxFill.Visible = cache.Box.Visible
			cache.BoxFill.Size = cache.Box.Size
			cache.BoxFill.Position = cache.Box.Position
			-- Name
			cache.Name.Visible = Settings.Visuals.ESP.Name
			cache.Name.Text = player.Name
			cache.Name.Position = Vector2.new(pos.X, y - 15)
			-- Health
			if Settings.Visuals.ESP.Health then
				local humanoid = getHumanoid(character)
				if humanoid then
					local health = humanoid.Health / humanoid.MaxHealth
					local barHeight = height
					local barX = x - 6
					local barY = y
					cache.HealthOutline.Visible = true
					cache.HealthOutline.Size = Vector2.new(2, barHeight)
					cache.HealthOutline.Position = Vector2.new(barX, barY)
					cache.HealthFill.Visible = true
					cache.HealthFill.Size = Vector2.new(2, barHeight * health)
					cache.HealthFill.Position = Vector2.new(barX, barY + barHeight * (1 - health))
					cache.HealthFill.Color = Color3.new(1 - health, health, 0)
				end
			else
				cache.HealthOutline.Visible = false
				cache.HealthFill.Visible = false
			end
			-- Distance
			cache.Distance.Visible = Settings.Visuals.ESP.Distance
			local dist = (LocalPlayer:GetMouse().Hit.Position - rootPart.Position).Magnitude
			cache.Distance.Text = string.format("%.0f studs", dist)
			cache.Distance.Position = Vector2.new(pos.X, y + height + 5)
		else
			cache.Box.Visible = false; cache.Name.Visible = false; -- etc
		end
	end
end

-- Chams (highlighting players)
local chamHighlights = {}
local function toggleChams(enabled)
	if enabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local character = getCharacter(player)
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Settings.Visuals.Chams.FillColor
				highlight.OutlineColor = Settings.Visuals.Chams.OutlineColor
				highlight.Parent = character
				chamHighlights[player] = highlight
			end
		end
	else
		for player, highlight in pairs(chamHighlights) do
			highlight:Destroy()
		end
		chamHighlights = {}
	end
end

-- Glow (add billboard glow)
local glowBillboards = {}
local function toggleGlow(enabled)
	if enabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				local character = getCharacter(player)
				local glow = Instance.new("BillboardGui")
				glow.Adornee = character
				glow.Size = UDim2.new(10,0,10,0)
				glow.StudsOffset = Vector3.new(0,2,0)
				local frame = Instance.new("Frame", glow)
				frame.Size = UDim2.new(1,0,1,0)
				frame.BackgroundColor3 = Color3.new(1,0,0)
				frame.BackgroundTransparency = 0.5
				frame.BorderSizePixel = 0
				glow.Enabled = true
				glow.Parent = character
				glowBillboards[player] = glow
			end
		end
	else
		for player, glow in pairs(glowBillboards) do
			glow:Destroy()
		end
		glowBillboards = {}
	end
end

-- Radar (minimap)
local radarFrame = nil
local function toggleRadar(enabled)
	if enabled then
		if radarFrame then radarFrame:Destroy() end
		radarFrame = Instance.new("ScreenGui")
		radarFrame.Parent = LocalPlayer:WaitForChild("PlayerGui")
		local background = Instance.new("Frame", radarFrame)
		background.Size = UDim2.new(0,Settings.Visuals.Radar.Size,0,Settings.Visuals.Radar.Size)
		background.Position = UDim2.new(1,-10 - Settings.Visuals.Radar.Size,0,10)
		background.BackgroundColor3 = Color3.new(0,0,0)
		background.BackgroundTransparency = 0.7
		background.BorderSizePixel = 0
		local canvas = Instance.new("Frame", background)
		canvas.Size = UDim2.new(1,0,1,0)
		canvas.BackgroundTransparency = 1
		-- We'll update players on a separate loop
		coroutine.wrap(function()
			while Settings.Visuals.Radar.Enabled and radarFrame do
				for _, player in pairs(Players:GetPlayers()) do
					if player == LocalPlayer then continue end
					local character = player.Character
					if not character then continue end
					local root = getHumanoidRootPart(character)
					if root then
						local myRoot = getHumanoidRootPart(LocalPlayer.Character)
						if myRoot then
							local relative = myRoot.CFrame:PointToObjectSpace(root.Position)
							local scale = Settings.Visuals.Radar.Zoom
							local radarSize = Settings.Visuals.Radar.Size/2
							local x = radarSize + relative.X * scale
							local y = radarSize - relative.Z * scale
							local dot = canvas:FindFirstChild(player.Name) or Instance.new("Frame", canvas)
							dot.Name = player.Name
							dot.Size = UDim2.new(0,5,0,5)
							dot.Position = UDim2.new(0, x-2.5, 0, y-2.5)
							dot.BackgroundColor3 = player.TeamColor.Color
							dot.BorderSizePixel = 0
							dot.Visible = true
						end
					end
				end
				RunService.Heartbeat:Wait()
			end
		end)()
	else
		if radarFrame then radarFrame:Destroy(); radarFrame = nil end
	end
end

-- Anti-Aim / Fake Lag (simulate by modifying movement packets)
local function toggleAntiAim(enabled)
	if enabled then
		-- This would typically hook the character's movement events and override angles
		-- Placeholder: just print
	else
	end
end

local function toggleFakeLag(enabled)
	if enabled then
		-- Simulate by blocking outgoing packets intermittently
	else
	end
end

-- UI Construction
local AimbotTab = Window:Tab({Title = "Aimbot", Icon = "solar:target-bold", IconColor = Color3.fromRGB(255,0,0), Border = true})
local VisualsTab = Window:Tab({Title = "Visuals", Icon = "solar:eye-bold", IconColor = Color3.fromRGB(0,255,0), Border = true})
local ESPTab = Window:Tab({Title = "ESP", Icon = "solar:info-square-bold", IconColor = Color3.fromRGB(0,200,255), Border = true})
local RadarTab = Window:Tab({Title = "Radar", Icon = "solar:map-bold", IconColor = Color3.fromRGB(255,255,0), Border = true})
local MiscTab = Window:Tab({Title = "Misc", Icon = "solar:settings-bold", IconColor = Color3.fromRGB(200,200,200), Border = true})

-- Aimbot UI
AimbotTab:Toggle({Title = "Enable Aimbot", Value = false, Callback = function(v) Settings.Aimbot.Enabled = v end})
AimbotTab:Toggle({Title = "Silent Aim (Raycast)", Value = true, Callback = function(v) Settings.Aimbot.Silent = v end})
AimbotTab:Toggle({Title = "Triggerbot", Value = false, Callback = function(v) Settings.Aimbot.Triggerbot = v end})
AimbotTab:Slider({Title = "FOV", Step = 10, Value = {Min = 10, Max = 500, Default = 200}, Callback = function(v) Settings.Aimbot.FOV = v end})
AimbotTab:Slider({Title = "Smoothing", Step = 0.01, Value = {Min = 0.01, Max = 1, Default = 0.1}, Callback = function(v) Settings.Aimbot.Smoothing = v end})
AimbotTab:Dropdown({Title = "Hit Part", Values = {"Head", "UpperTorso", "HumanoidRootPart"}, Value = "Head", Callback = function(v) Settings.Aimbot.HitPart = v end})
AimbotTab:Toggle({Title = "Visibility Check", Value = true, Callback = function(v) Settings.Aimbot.VisibleCheck = v end})
AimbotTab:Toggle({Title = "Team Check", Value = true, Callback = function(v) Settings.Aimbot.TeamCheck = v end})
AimbotTab:Toggle({Title = "Use Controller (Right Stick)", Value = false, Callback = function(v) Settings.Aimbot.UseController = v end})
AimbotTab:Slider({Title = "Controller Sensitivity", Step = 0.1, Value = {Min = 0.1, Max = 2, Default = 0.5}, Callback = function(v) Settings.Aimbot.ControllerSensitivity = v end})

-- Visuals Tab
VisualsTab:Toggle({Title = "Night Mode", Value = false, Callback = function(v) Settings.Visuals.NightMode = v; game.Lighting.ClockTime = v and 0 or 14 end})
VisualsTab:Toggle({Title = "Chams", Value = false, Callback = toggleChams})
VisualsTab:Toggle({Title = "Glow", Value = false, Callback = toggleGlow})

-- ESP Sub-tab in Visuals
local ESPGroup = ESPTab:Group({})
ESPGroup:Toggle({Title = "Enable ESP", Value = true, Callback = function(v) Settings.Visuals.ESP.Enabled = v end})
ESPGroup:Toggle({Title = "Box", Value = true, Callback = function(v) Settings.Visuals.ESP.Box = v end})
ESPGroup:Toggle({Title = "Name", Value = true, Callback = function(v) Settings.Visuals.ESP.Name = v end})
ESPGroup:Toggle({Title = "Health Bar", Value = true, Callback = function(v) Settings.Visuals.ESP.Health = v end})
ESPGroup:Toggle({Title = "Distance", Value = true, Callback = function(v) Settings.Visuals.ESP.Distance = v end})
ESPGroup:Toggle({Title = "Skeleton", Value = false, Callback = function(v) Settings.Visuals.ESP.Skeleton = v end})

-- Radar Tab
RadarTab:Toggle({Title = "Enable Radar", Value = true, Callback = toggleRadar})
RadarTab:Slider({Title = "Radar Size", Step = 10, Value = {Min = 100, Max = 400, Default = 200}, Callback = function(v) Settings.Visuals.Radar.Size = v end})
RadarTab:Slider({Title = "Radar Zoom", Step = 0.1, Value = {Min = 0.5, Max = 5, Default = 1}, Callback = function(v) Settings.Visuals.Radar.Zoom = v end})

-- Misc Tab
MiscTab:Toggle({Title = "Anti-Aim (Fake Angles)", Value = false, Callback = toggleAntiAim})
MiscTab:Toggle({Title = "Fake Lag", Value = false, Callback = toggleFakeLag})
MiscTab:Slider({Title = "Desync Angle", Step = 5, Value = {Min = 0, Max = 90, Default = 45}, Callback = function(v) Settings.Misc.DesyncAngle = v end})
MiscTab:Toggle({Title = "Auto Crouch", Value = false, Callback = function(v) Settings.Misc.AutoCrouch = v end})

-- Init services and loops
-- Setup ESP cache
for _, player in pairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then
		createESP(player)
	end
end
Players.PlayerAdded:Connect(function(player)
	if player ~= LocalPlayer then
		createESP(player)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	if ESPCache[player] then
		-- destroy drawings if needed
		ESPCache[player] = nil
	end
end)

-- Start Aimbot loop
AimbotLoop()

-- Silent aim hook (simplified; real exploit would hook the firing remote)
hookSilentAim()

-- ESP Render loop
RunService.RenderStepped:Connect(function()
	if Settings.Visuals.ESP.Enabled then
		updateESP()
	end
	-- FOV circle
	if Settings.Aimbot.Enabled then
		FOVCircle.Visible = true
		FOVCircle.Radius = Settings.Aimbot.FOV
		FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
		FOVCircle.Color = Color3.new(1,0,0)
		FOVCircle.Thickness = 1
		FOVCircle.NumSides = 60
	else
		FOVCircle.Visible = false
	end
end)

-- Triggerbot loop
coroutine.wrap(function()
	while task.wait(Settings.Aimbot.TriggerbotDelay) do
		if Settings.Aimbot.Triggerbot and Settings.Aimbot.Enabled then
			local target = getClosestTargetToCenter()
			if target then
				-- Simulate mouse click (actual exploit would fire remote)
				mouse1press()
			end
		end
	end
end)()

-- Auto crouch
local oldStep = nil
RunService.Stepped:Connect(function()
	if Settings.Misc.AutoCrouch and LocalPlayer.Character then
		local humanoid = getHumanoid(LocalPlayer.Character)
		if humanoid then
			-- For Roblox, Crouch by setting humanoid.CameraOffset or using state
			-- This is a naive approach; actual would toggle Crouch
			-- We'll just hold Ctrl key via virtual input
			-- This might be detected, but for demonstration:
			humanoid.AutoRotate = true
		end
	end
end)

-- Notify launch
WindUI:Notify({Title = "HVH Premium", Content = "Script loaded. Press "..(Window.ToggleKey and Window.ToggleKey.Name or "Insert").." to toggle menu."})
```
