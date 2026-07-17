local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayRemote = ReplicatedStorage:WaitForChild("ByteNetReliable")
local RespawnRemote = ReplicatedStorage:WaitForChild("ByteNetUnreliable")

local TARGET_USERNAME = "roblox_user_151932818"

local OFFSET_UP = 2
local OFFSET_FORWARD = 4
local PLAY_INTERVAL = 5
local RESPAWN_INTERVAL = 0.1

local DEATHS = 0
local RESPAWNS = 0
local START_TIME = os.clock()

local LocalPlayer = Players.LocalPlayer

local function getTargetHRP()
	local targetPlayer = Players:FindFirstChild(TARGET_USERNAME)
	if targetPlayer and targetPlayer.Character then
		return targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function getLocalHRP()
	local char = LocalPlayer.Character
	if not char then
		char = LocalPlayer.CharacterAdded:Wait()
	end
	return char:WaitForChild("HumanoidRootPart")
end

LocalPlayer.CharacterRemoving:Connect(function()
	DEATHS = DEATHS + 1
end)

-- Teleport loop (error‑protected so it never stops)
local function teleportLoop()
	while true do
		local success, err = pcall(function()
			local hrp = getLocalHRP()
			local targetHRP = getTargetHRP()
			if hrp and targetHRP then
				local forward = targetHRP.CFrame.LookVector
				local pos = targetHRP.Position + forward * OFFSET_FORWARD + Vector3.new(0, OFFSET_UP, 0)
				hrp.CFrame = CFrame.new(pos) * targetHRP.CFrame.Rotation
			end
		end)
		if not success then
			-- optional: print("Teleport error:", err)
		end
		RunService.Heartbeat:Wait()
	end
end

-- Play remote (every 5 seconds)
local function firePlayRemote()
	while true do
		pcall(function()
			PlayRemote:FireServer(buffer.fromstring("\027"))
		end)
		task.wait(PLAY_INTERVAL)
	end
end

-- Respawn remote (every 0.1 seconds, unconditional – old style, new buffer)
local function fireRespawnRemote()
	while true do
		pcall(function()
			RespawnRemote:FireServer(buffer.fromstring("\027"))
		end)
		RESPAWNS = RESPAWNS + 1
		task.wait(RESPAWN_INTERVAL)
	end
end

-- GUI (same as before)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportGUI"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 250)
Frame.Position = UDim2.new(0.8, -125, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Teleport Settings"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = Frame

local function makeLabel(text, y)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0, 120, 0, 20)
	lbl.Position = UDim2.new(0, 10, 0, y)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	lbl.Font = Enum.Font.SourceSans
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = Frame
	return lbl
end

local function makeTextBox(y, default)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 100, 0, 20)
	box.Position = UDim2.new(0, 140, 0, y)
	box.Text = tostring(default)
	box.TextColor3 = Color3.fromRGB(0, 0, 0)
	box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	box.Font = Enum.Font.SourceSans
	box.TextSize = 14
	box.Parent = Frame
	return box
end

makeLabel("Up Offset (studs):", 40)
local upOffsetBox = makeTextBox(40, OFFSET_UP)
makeLabel("Forward Offset (studs):", 65)
local forwardOffsetBox = makeTextBox(65, OFFSET_FORWARD)
makeLabel("Play Interval (s):", 90)
local playIntervalBox = makeTextBox(90, PLAY_INTERVAL)
makeLabel("Respawn Interval (s):", 115)
local respawnIntervalBox = makeTextBox(115, RESPAWN_INTERVAL)

upOffsetBox.FocusLost:Connect(function()
	local num = tonumber(upOffsetBox.Text)
	if num then OFFSET_UP = num end
end)
forwardOffsetBox.FocusLost:Connect(function()
	local num = tonumber(forwardOffsetBox.Text)
	if num then OFFSET_FORWARD = num end
end)
playIntervalBox.FocusLost:Connect(function()
	local num = tonumber(playIntervalBox.Text)
	if num and num > 0 then PLAY_INTERVAL = num end
end)
respawnIntervalBox.FocusLost:Connect(function()
	local num = tonumber(respawnIntervalBox.Text)
	if num and num > 0 then RESPAWN_INTERVAL = num end
end)

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -20, 0, 80)
statsLabel.Position = UDim2.new(0, 10, 0, 155)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "Deaths: 0 | Respawns: 0 | Active: 0s"
statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statsLabel.Font = Enum.Font.SourceSans
statsLabel.TextSize = 14
statsLabel.TextWrapped = true
statsLabel.Parent = Frame

task.spawn(function()
	while true do
		local active = math.floor(os.clock() - START_TIME)
		statsLabel.Text = string.format("Deaths: %d | Respawns: %d | Active: %ds", DEATHS, RESPAWNS, active)
		task.wait(1)
	end
end)

task.spawn(teleportLoop)
task.spawn(firePlayRemote)
task.spawn(fireRespawnRemote)