-- LocalScript – Build Exploit Pack (Mobile Ready)
-- Chat commands available to all users.
-- Features: Destroy All, Nuke (spoof delete), Fling (resets after 2s), Touch Fling, Cage, Tornado Aura, Chat Commands

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Character reference (updates on respawn)
local character = nil
local function updateCharacter()
	character = player.Character
	if character then
		if not character:FindFirstChild("HumanoidRootPart") then
			character = nil
		end
	end
end
updateCharacter()
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	character:WaitForChild("HumanoidRootPart")
end)

-- Remote references
local replicatedStorage = game:GetService("ReplicatedStorage")
local events = replicatedStorage:WaitForChild("Events")
local placeRemote = events:WaitForChild("Place")           -- args: blockType, CFrame, Baseplate
local destroyRemote = events:WaitForChild("DestroyBlock")  -- args: partInstance

local baseplate = workspace:WaitForChild("Baseplate", 10) or workspace
local builtFolder = workspace:FindFirstChild("Built") or Instance.new("Folder", workspace)
builtFolder.Name = "Built"

-- Global fling state
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "BuildExploitGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 720)
frame.Position = UDim2.new(0, 20, 0, 80)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Parent = gui
Instance.new("UICorner", frame)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Build Exploit Pack"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = frame

-- ===== TARGET SELECTION =====
local dropButton = Instance.new("TextButton")
dropButton.Size = UDim2.new(1, -20, 0, 40)
dropButton.Position = UDim2.new(0, 10, 0, 40)
dropButton.Text = "Select Target ▼"
dropButton.Font = Enum.Font.SourceSansBold
dropButton.TextSize = 18
dropButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dropButton.BackgroundColor3 = Color3.fromRGB(120, 0, 180)
dropButton.Parent = frame
Instance.new("UICorner", dropButton)

local listFrame = Instance.new("Frame")
listFrame.Position = UDim2.new(0, 10, 0, 85)
listFrame.Size = UDim2.new(1, -20, 0, 150)
listFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
listFrame.Visible = false
listFrame.Parent = frame
Instance.new("UICorner", listFrame)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -10)
scroll.Position = UDim2.new(0, 5, 0, 5)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 8
scroll.BackgroundTransparency = 1
scroll.Parent = listFrame

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 8)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

local dropdownOpen = false
local selectedTargetPlayer = nil

-- ESP
local highlights = {}
local espConnection

local function clearESP()
	for obj, hl in pairs(highlights) do
		if hl then pcall(function() hl:Destroy() end) end
	end
	table.clear(highlights)
	if espConnection then espConnection:Disconnect() end
end

local function addESP(obj)
	if highlights[obj] then return end
	if obj:IsA("BasePart") or obj:IsA("Model") then
		local hl
		pcall(function()
			hl = Instance.new("Highlight")
			hl.FillColor = Color3.fromRGB(170, 0, 255)
			hl.OutlineColor = Color3.fromRGB(255, 255, 255)
			hl.FillTransparency = 0.4
			hl.OutlineTransparency = 0
			hl.Adornee = obj
			hl.Parent = obj
		end)
		if hl then highlights[obj] = hl end
	end
end

local function enableTargetESP(plr)
	clearESP()
	if not plr then return end
	local folder = builtFolder:FindFirstChild(plr.Name)
	if not folder then return end
	for _, obj in ipairs(folder:GetDescendants()) do
		addESP(obj)
	end
	espConnection = folder.DescendantAdded:Connect(function(obj)
		task.wait(0.05)
		addESP(obj)
	end)
end

local function refreshPlayerList()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -10, 0, 40)
			btn.Text = plr.Name
			btn.Font = Enum.Font.SourceSansBold
			btn.TextSize = 18
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			btn.Parent = scroll
			Instance.new("UICorner", btn)
			btn.MouseButton1Click:Connect(function()
				selectedTargetPlayer = plr
				dropButton.Text = plr.Name .. " ▼"
				listFrame.Visible = false
				dropdownOpen = false
				frame.Size = UDim2.new(0, 320, 0, 720)
				enableTargetESP(plr)
			end)
		end
	end
	local clearBtn = Instance.new("TextButton")
	clearBtn.Size = UDim2.new(1, -10, 0, 40)
	clearBtn.Text = "None (Self)"
	clearBtn.Font = Enum.Font.SourceSansBold
	clearBtn.TextSize = 18
	clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	clearBtn.Parent = scroll
	Instance.new("UICorner", clearBtn)
	clearBtn.MouseButton1Click:Connect(function()
		selectedTargetPlayer = nil
		dropButton.Text = "Select Target ▼"
		listFrame.Visible = false
		dropdownOpen = false
		frame.Size = UDim2.new(0, 320, 0, 720)
		clearESP()
	end)
end

dropButton.MouseButton1Click:Connect(function()
	dropdownOpen = not dropdownOpen
	listFrame.Visible = dropdownOpen
	if dropdownOpen then
		refreshPlayerList()
		frame.Size = UDim2.new(0, 320, 0, 870)
	else
		frame.Size = UDim2.new(0, 320, 0, 720)
	end
end)

-- ===== DESTROY ALL (global) =====
local destroyButton = Instance.new("TextButton")
destroyButton.Size = UDim2.new(1, -20, 0, 40)
destroyButton.Position = UDim2.new(0, 10, 0, 240)
destroyButton.Text = "🗑️ DESTROY ALL"
destroyButton.Font = Enum.Font.SourceSansBold
destroyButton.TextSize = 20
destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
destroyButton.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
destroyButton.Parent = frame
Instance.new("UICorner", destroyButton)

local destroying = false
local function destroyAllParts()
	if destroying then return end
	destroying = true
	destroyButton.Text = "⏳ DESTROYING..."
	destroyButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)

	local targets = {}
	for _, v in ipairs(builtFolder:GetDescendants()) do
		if v:IsA("BasePart") then table.insert(targets, v) end
	end

	if #targets == 0 then
		destroyButton.Text = "❌ NO TARGETS"
		task.wait(2)
		destroying = false
		destroyButton.Text = "🗑️ DESTROY ALL"
		destroyButton.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
		return
	end

	local destroyed, failed = 0, 0
	for _, part in ipairs(targets) do
		task.spawn(function()
			local success = pcall(function()
				destroyRemote:InvokeServer(part)
			end)
			if success then destroyed = destroyed + 1 else failed = failed + 1 end
		end)
	end
	task.wait(0.5)

	destroying = false
	destroyButton.Text = "✅ " .. destroyed .. " | ❌ " .. failed
	destroyButton.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
	task.wait(3)
	destroyButton.Text = "🗑️ DESTROY ALL"
	destroyButton.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
end
destroyButton.MouseButton1Click:Connect(destroyAllParts)

-- ===== NUKE (spoof delete) =====
local nukeToggle = Instance.new("TextButton")
nukeToggle.Size = UDim2.new(1, -20, 0, 40)
nukeToggle.Position = UDim2.new(0, 10, 0, 285)
nukeToggle.Text = "NUKE: OFF"
nukeToggle.Font = Enum.Font.SourceSansBold
nukeToggle.TextSize = 18
nukeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
nukeToggle.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
nukeToggle.Parent = frame
Instance.new("UICorner", nukeToggle)

local nukeRunning = false
local nukeThread
local nukeTarget = nil  -- nil = all parts, player object = only that player's parts
local SPOOF_RADIUS = 20

local function nukeLoop()
	while nukeRunning do
		local source = builtFolder
		-- Determine target folder if nukeTarget is set
		if nukeTarget and nukeTarget:FindFirstChild("Built") then
			local folder = builtFolder:FindFirstChild(nukeTarget.Name)
			if folder then
				source = folder
			else
				source = builtFolder
			end
		end

		-- Find one part to start
		local part = nil
		for _, v in ipairs(source:GetDescendants()) do
			if v:IsA("BasePart") and v.Parent then
				part = v
				break
			end
		end

		if not part then
			task.wait(0.1)
			continue
		end

		-- Teleport to part
		if character and character.PrimaryPart then
			pcall(function() character:PivotTo(part.CFrame) end)
		end

		local pos = part.Position
		-- Delete all parts within radius from source
		local toDelete = {}
		for _, v in ipairs(source:GetDescendants()) do
			if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= SPOOF_RADIUS then
				table.insert(toDelete, v)
			end
		end

		for _, d in ipairs(toDelete) do
			task.spawn(function()
				pcall(function() destroyRemote:InvokeServer(d) end)
			end)
		end

		task.wait(0.05)  -- prevent freeze
	end
end

nukeToggle.MouseButton1Click:Connect(function()
	nukeRunning = not nukeRunning
	if nukeRunning then
		nukeToggle.Text = "NUKE: ON"
		nukeToggle.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
		nukeTarget = nil  -- GUI nuke always global
		nukeThread = task.spawn(nukeLoop)
	else
		nukeToggle.Text = "NUKE: OFF"
		nukeToggle.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
		if nukeThread then task.cancel(nukeThread) end
	end
end)

-- ===== FLING (target toggle) =====
local flingToggle = Instance.new("TextButton")
flingToggle.Size = UDim2.new(1, -20, 0, 40)
flingToggle.Position = UDim2.new(0, 10, 0, 330)
flingToggle.Text = "FLING TARGET: OFF"
flingToggle.Font = Enum.Font.SourceSansBold
flingToggle.TextSize = 18
flingToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
flingToggle.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
flingToggle.Parent = frame
Instance.new("UICorner", flingToggle)

local flingRunning = false
local flingThread

local function SkidFling(TargetPlayer)
	local Character = character
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Humanoid and Humanoid.RootPart
	local TCharacter = TargetPlayer.Character
	if not TCharacter then return end

	local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
	local TRootPart = THumanoid and THumanoid.RootPart
	local THead = TCharacter:FindFirstChild("Head")
	local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
	local Handle = Accessory and Accessory:FindFirstChild("Handle")

	if Character and Humanoid and RootPart then
		if RootPart.Velocity.Magnitude < 50 then
			getgenv().OldPos = RootPart.CFrame
		end

		if THumanoid and THumanoid.Sit then return end

		if THead then
			workspace.CurrentCamera.CameraSubject = THead
		elseif Handle then
			workspace.CurrentCamera.CameraSubject = Handle
		elseif THumanoid and TRootPart then
			workspace.CurrentCamera.CameraSubject = THumanoid
		end

		if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end

		local function FPos(BasePart, Pos, Ang)
			RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
			Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
			RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
			RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
		end

		local function SFBasePart(BasePart)
			local TimeToWait = 2
			local Time = tick()
			local Angle = 0
			local THumanoidLocal = THumanoid
			repeat
				if RootPart and THumanoidLocal then
					if BasePart.Velocity.Magnitude < 50 then
						Angle = Angle + 100
						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoidLocal.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoidLocal.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoidLocal.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoidLocal.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoidLocal.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoidLocal.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
					else
						FPos(BasePart, CFrame.new(0, 1.5, THumanoidLocal.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, -THumanoidLocal.WalkSpeed), CFrame.Angles(0, 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, THumanoidLocal.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						task.wait()
					end
				end
			until Time + TimeToWait < tick() or not flingRunning
		end

		workspace.FallenPartsDestroyHeight = 0/0

		local BV = Instance.new("BodyVelocity")
		BV.Parent = RootPart
		BV.Velocity = Vector3.new(0, 0, 0)
		BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

		if TRootPart then
			SFBasePart(TRootPart)
		elseif THead then
			SFBasePart(THead)
		elseif Handle then
			SFBasePart(Handle)
		end

		BV:Destroy()
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		workspace.CurrentCamera.CameraSubject = Humanoid

		if getgenv().OldPos then
			repeat
				RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
				Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
				Humanoid:ChangeState("GettingUp")
				for _, part in pairs(Character:GetChildren()) do
					if part:IsA("BasePart") then
						part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
					end
				end
				task.wait()
			until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25 or not flingRunning
			workspace.FallenPartsDestroyHeight = getgenv().FPDH
		end
	end
end

local function flingLoop()
	while flingRunning do
		if not selectedTargetPlayer then task.wait(1) continue end
		local target = selectedTargetPlayer
		if not target or not target.Parent then
			selectedTargetPlayer = nil
			task.wait(1)
			continue
		end
		SkidFling(target)
		task.wait(0.5)
	end
end

flingToggle.MouseButton1Click:Connect(function()
	flingRunning = not flingRunning
	if flingRunning then
		flingToggle.Text = "FLING TARGET: ON"
		flingToggle.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
		flingThread = task.spawn(flingLoop)
	else
		flingToggle.Text = "FLING TARGET: OFF"
		flingToggle.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
		if flingThread then task.cancel(flingThread) end
	end
end)

-- ===== TOUCH FLING =====
local touchFlingToggle = Instance.new("TextButton")
touchFlingToggle.Size = UDim2.new(1, -20, 0, 40)
touchFlingToggle.Position = UDim2.new(0, 10, 0, 375)
touchFlingToggle.Text = "TOUCH FLING: OFF"
touchFlingToggle.Font = Enum.Font.SourceSansBold
touchFlingToggle.TextSize = 18
touchFlingToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
touchFlingToggle.BackgroundColor3 = Color3.fromRGB(255, 80, 0)
touchFlingToggle.Parent = frame
Instance.new("UICorner", touchFlingToggle)

local touchFlingRunning = false
local touchConnections = {}

local function startTouchFling()
	if touchFlingRunning then return end
	touchFlingRunning = true
	local function connectTouch()
		if not character then return end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				local con = part.Touched:Connect(function(hit)
					if not touchFlingRunning then return end
					local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
					if hitPlayer and hitPlayer ~= player then
						task.spawn(function() SkidFling(hitPlayer) end)
					end
				end)
				table.insert(touchConnections, con)
			end
		end
	end
	connectTouch()
	player.CharacterAdded:Connect(function(newChar)
		for _, con in ipairs(touchConnections) do
			con:Disconnect()
		end
		touchConnections = {}
		character = newChar
		connectTouch()
	end)
end

local function stopTouchFling()
	touchFlingRunning = false
	for _, con in ipairs(touchConnections) do
		con:Disconnect()
	end
	touchConnections = {}
end

touchFlingToggle.MouseButton1Click:Connect(function()
	touchFlingRunning = not touchFlingRunning
	if touchFlingRunning then
		touchFlingToggle.Text = "TOUCH FLING: ON"
		touchFlingToggle.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
		startTouchFling()
	else
		touchFlingToggle.Text = "TOUCH FLING: OFF"
		touchFlingToggle.BackgroundColor3 = Color3.fromRGB(255, 80, 0)
		stopTouchFling()
	end
end)

-- ===== CAGE =====
local cageToggle = Instance.new("TextButton")
cageToggle.Size = UDim2.new(1, -20, 0, 40)
cageToggle.Position = UDim2.new(0, 10, 0, 420)
cageToggle.Text = "CAGE: OFF"
cageToggle.Font = Enum.Font.SourceSansBold
cageToggle.TextSize = 18
cageToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
cageToggle.BackgroundColor3 = Color3.fromRGB(200, 0, 200)
cageToggle.Parent = frame
Instance.new("UICorner", cageToggle)

local cageRunning = false
local cageThread
local cageBlockType = "Oak Planks"

local offsets = {}
for x = -1, 1 do
	for y = -1, 1 do
		for z = -1, 1 do
			if x == 0 and y == 0 and z == 0 then continue end
			table.insert(offsets, Vector3.new(x*4, y*4, z*4))
		end
	end
end

local function cageLoop()
	while cageRunning do
		local target = selectedTargetPlayer
		if not target or not target.Character or not target.Character.PrimaryPart then
			task.wait(1)
			continue
		end
		local targetRoot = target.Character.PrimaryPart
		if character and character.PrimaryPart then
			pcall(function()
				character:PivotTo(targetRoot.CFrame + Vector3.new(0, 2, 0))
			end)
		end
		local bp = workspace:FindFirstChild("Baseplate") or workspace
		for _, offset in ipairs(offsets) do
			if not cageRunning then break end
			local pos = targetRoot.Position + offset
			pcall(function()
				placeRemote:InvokeServer(cageBlockType, CFrame.new(pos), bp)
			end)
			task.wait(0.02)
		end
		task.wait(0.5)
	end
end

cageToggle.MouseButton1Click:Connect(function()
	cageRunning = not cageRunning
	if cageRunning then
		cageToggle.Text = "CAGE: ON"
		cageToggle.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
		cageThread = task.spawn(cageLoop)
	else
		cageToggle.Text = "CAGE: OFF"
		cageToggle.BackgroundColor3 = Color3.fromRGB(200, 0, 200)
		if cageThread then task.cancel(cageThread) end
	end
end)

-- ===== DESTROY AURA (tornado orbit) =====
local auraToggle = Instance.new("TextButton")
auraToggle.Size = UDim2.new(1, -20, 0, 40)
auraToggle.Position = UDim2.new(0, 10, 0, 465)
auraToggle.Text = "DESTROY AURA: OFF"
auraToggle.Font = Enum.Font.SourceSansBold
auraToggle.TextSize = 18
auraToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
auraToggle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
auraToggle.Parent = frame
Instance.new("UICorner", auraToggle)

local auraSpeedLabel = Instance.new("TextLabel")
auraSpeedLabel.Size = UDim2.new(0.4, -5, 0, 20)
auraSpeedLabel.Position = UDim2.new(0, 10, 0, 510)
auraSpeedLabel.BackgroundTransparency = 1
auraSpeedLabel.Text = "Speed:"
auraSpeedLabel.Font = Enum.Font.SourceSans
auraSpeedLabel.TextSize = 14
auraSpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
auraSpeedLabel.Parent = frame

local auraSpeedInput = Instance.new("TextBox")
auraSpeedInput.Size = UDim2.new(0.6, -5, 0, 30)
auraSpeedInput.Position = UDim2.new(0.4, 5, 0, 505)
auraSpeedInput.Text = "0.3"
auraSpeedInput.PlaceholderText = "Orbit speed"
auraSpeedInput.Font = Enum.Font.SourceSansBold
auraSpeedInput.TextSize = 14
auraSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
auraSpeedInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
auraSpeedInput.Parent = frame
Instance.new("UICorner", auraSpeedInput)

local auraRadiusLabel = Instance.new("TextLabel")
auraRadiusLabel.Size = UDim2.new(0.4, -5, 0, 20)
auraRadiusLabel.Position = UDim2.new(0, 10, 0, 540)
auraRadiusLabel.BackgroundTransparency = 1
auraRadiusLabel.Text = "Clear Dist:"
auraRadiusLabel.Font = Enum.Font.SourceSans
auraRadiusLabel.TextSize = 14
auraRadiusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
auraRadiusLabel.Parent = frame

local auraRadiusInput = Instance.new("TextBox")
auraRadiusInput.Size = UDim2.new(0.6, -5, 0, 30)
auraRadiusInput.Position = UDim2.new(0.4, 5, 0, 535)
auraRadiusInput.Text = "20"
auraRadiusInput.PlaceholderText = "Clear radius"
auraRadiusInput.Font = Enum.Font.SourceSansBold
auraRadiusInput.TextSize = 14
auraRadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
auraRadiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
auraRadiusInput.Parent = frame
Instance.new("UICorner", auraRadiusInput)

local auraOrbitRadiusLabel = Instance.new("TextLabel")
auraOrbitRadiusLabel.Size = UDim2.new(0.4, -5, 0, 20)
auraOrbitRadiusLabel.Position = UDim2.new(0, 10, 0, 570)
auraOrbitRadiusLabel.BackgroundTransparency = 1
auraOrbitRadiusLabel.Text = "Orbit Dist:"
auraOrbitRadiusLabel.Font = Enum.Font.SourceSans
auraOrbitRadiusLabel.TextSize = 14
auraOrbitRadiusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
auraOrbitRadiusLabel.Parent = frame

local auraOrbitRadiusInput = Instance.new("TextBox")
auraOrbitRadiusInput.Size = UDim2.new(0.6, -5, 0, 30)
auraOrbitRadiusInput.Position = UDim2.new(0.4, 5, 0, 565)
auraOrbitRadiusInput.Text = "20"
auraOrbitRadiusInput.PlaceholderText = "Orbit distance"
auraOrbitRadiusInput.Font = Enum.Font.SourceSansBold
auraOrbitRadiusInput.TextSize = 14
auraOrbitRadiusInput.TextColor3 = Color3.fromRGB(255, 255, 255)
auraOrbitRadiusInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
auraOrbitRadiusInput.Parent = frame
Instance.new("UICorner", auraOrbitRadiusInput)

local auraRunning = false
local auraThread
local auraAngle = 0

local function auraLoop()
	while auraRunning do
		local target = selectedTargetPlayer
		local source = builtFolder
		if target and target.Character and target.Character.PrimaryPart then
			local targetPos = target.Character.PrimaryPart.Position
			local orbitRadius = tonumber(auraOrbitRadiusInput.Text) or 20
			local clearanceRadius = tonumber(auraRadiusInput.Text) or 20
			local speed = tonumber(auraSpeedInput.Text) or 0.3
			if speed < 0.01 then speed = 0.01 end

			-- Tornado-like orbit
			local vertOffset = math.sin(auraAngle * 2) * 10
			local radiusMod = math.sin(auraAngle * 0.5) * 5
			local dynamicRadius = orbitRadius + radiusMod
			local offset = Vector3.new(math.cos(auraAngle) * dynamicRadius, 2 + vertOffset, math.sin(auraAngle) * dynamicRadius)
			local myPos = targetPos + offset

			if character and character.PrimaryPart then
				pcall(function()
					character:PivotTo(CFrame.new(myPos))
				end)
			end

			task.spawn(function()
				for _, v in ipairs(source:GetDescendants()) do
					if v:IsA("BasePart") and v.Parent and (v.Position - myPos).Magnitude <= clearanceRadius then
						pcall(function() destroyRemote:InvokeServer(v) end)
					end
				end
			end)
			auraAngle = auraAngle + speed
		else
			if character and character.PrimaryPart then
				local pos = character.PrimaryPart.Position
				local clearanceRadius = tonumber(auraRadiusInput.Text) or 20
				task.spawn(function()
					for _, v in ipairs(source:GetDescendants()) do
						if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= clearanceRadius then
							pcall(function() destroyRemote:InvokeServer(v) end)
						end
					end
				end)
			end
		end
		task.wait()
	end
end

auraToggle.MouseButton1Click:Connect(function()
	auraRunning = not auraRunning
	if auraRunning then
		auraToggle.Text = "DESTROY AURA: ON"
		auraToggle.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
		auraAngle = 0
		auraThread = task.spawn(auraLoop)
	else
		auraToggle.Text = "DESTROY AURA: OFF"
		auraToggle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
		if auraThread then task.cancel(auraThread) end
	end
end)

-- ===== UI DRAG (MOBILE) =====
local dragging, dragStart, startPos

frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

frame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

-- ===== CHAT COMMANDS (available to all users) =====
local function findPlayer(name)
	name = name:lower()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower():find(name, 1, true) then
			return plr
		end
	end
	return nil
end

local function stopAll()
	if nukeRunning then
		nukeRunning = false
		nukeToggle.Text = "NUKE: OFF"
		nukeToggle.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
		if nukeThread then task.cancel(nukeThread) end
	end
	if flingRunning then
		flingRunning = false
		flingToggle.Text = "FLING TARGET: OFF"
		flingToggle.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
		if flingThread then task.cancel(flingThread) end
	end
	if cageRunning then
		cageRunning = false
		cageToggle.Text = "CAGE: OFF"
		cageToggle.BackgroundColor3 = Color3.fromRGB(200, 0, 200)
		if cageThread then task.cancel(cageThread) end
	end
	if auraRunning then
		auraRunning = false
		auraToggle.Text = "DESTROY AURA: OFF"
		auraToggle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
		if auraThread then task.cancel(auraThread) end
	end
	if touchFlingRunning then
		stopTouchFling()
		touchFlingToggle.Text = "TOUCH FLING: OFF"
		touchFlingToggle.BackgroundColor3 = Color3.fromRGB(255, 80, 0)
	end
end

player.Chatted:Connect(function(message)
	local cmd = message:lower()
	local args = cmd:split(" ")
	local command = args[1]
	table.remove(args, 1)
	local arg = table.concat(args, " ")

	if command == "!orbit" then
		if arg == "" or arg == "me" then
			selectedTargetPlayer = nil
			dropButton.Text = "Select Target ▼"
			clearESP()
		else
			local target = findPlayer(arg)
			if target then
				selectedTargetPlayer = target
				dropButton.Text = target.Name .. " ▼"
				enableTargetESP(target)
			end
		end
		if not auraRunning then
			auraToggle.Text = "DESTROY AURA: ON"
			auraToggle.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
			auraRunning = true
			auraAngle = 0
			auraThread = task.spawn(auraLoop)
		end

	elseif command == "!fling" then
		if arg == "" then return end
		local target = findPlayer(arg)
		if target then
			selectedTargetPlayer = target
			dropButton.Text = target.Name .. " ▼"
			enableTargetESP(target)
			flingRunning = true
			flingToggle.Text = "FLING TARGET: ON"
			flingToggle.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
			task.spawn(function()
				SkidFling(target)
				task.wait(2)
				if flingRunning then
					flingRunning = false
					flingToggle.Text = "FLING TARGET: OFF"
					flingToggle.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
				end
			end)
		end

	elseif command == "!nuke" then
		if arg == "" then
			nukeTarget = nil
		else
			local target = findPlayer(arg)
			if target then
				nukeTarget = target
			else
				nukeTarget = nil
			end
		end
		if not nukeRunning then
			nukeToggle.Text = "NUKE: ON"
			nukeToggle.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
			nukeRunning = true
			nukeThread = task.spawn(nukeLoop)
		end

	elseif command == "!stop" then
		stopAll()

	elseif command == "!cage" then
		if arg == "" then return end
		local target = findPlayer(arg)
		if target then
			selectedTargetPlayer = target
			dropButton.Text = target.Name .. " ▼"
			enableTargetESP(target)
			if not cageRunning then
				cageToggle.Text = "CAGE: ON"
				cageToggle.BackgroundColor3 = Color3.fromRGB(20, 220, 20)
				cageRunning = true
				cageThread = task.spawn(cageLoop)
			end
		end

	elseif command == "!bring" then
		if arg == "" then return end
		local target = findPlayer(arg)
		if target and target.Character and target.Character.PrimaryPart then
			if character and character.PrimaryPart then
				pcall(function()
					character:PivotTo(target.Character.PrimaryPart.CFrame + Vector3.new(0,2,0))
				end)
			end
		end

	elseif command == "!dance" then
		if character and character:FindFirstChildOfClass("Humanoid") then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local animId = "rbxassetid://507766388"
			local anim = humanoid:LoadAnimation(Instance.new("Animation", humanoid))
			anim.AnimationId = animId
			anim:Play()
		end

	elseif command == "!spin" then
		local speed = tonumber(arg) or 50
		if character and character.PrimaryPart then
			local bodyGyro = Instance.new("BodyAngularVelocity")
			bodyGyro.Parent = character.PrimaryPart
			bodyGyro.AngularVelocity = Vector3.new(0, speed, 0)
			bodyGyro.MaxTorque = Vector3.new(0, 9e6, 0)
			task.delay(5, function() bodyGyro:Destroy() end)
		end

	elseif command == "!jump" then
		if character and character:FindFirstChildOfClass("Humanoid") then
			character:FindFirstChildOfClass("Humanoid").Jump = true
		end
	end
end)

-- Keyboard shortcuts
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.K then
		destroyAllParts()
	end
end)

print("Build Exploit Pack – Chat commands available for everyone")
