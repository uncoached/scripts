-- Build Exploit Pack – Final Working (Classic GUI, All Features)
-- Place blocks with no rotation, rounded coordinates, extensive logging.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

-- Character
local character
local function onChar(c)
	character = c
	c:WaitForChild("HumanoidRootPart")
end
if player.Character then onChar(player.Character) end
player.CharacterAdded:Connect(onChar)

-- Remotes (with existence checks)
local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
if not events then
	game.StarterGui:SetCore("SendNotification",{Title="Error",Text="Events folder not found."})
	return
end
local placeRemote = events:FindFirstChild("Place")
local destroyRemote = events:FindFirstChild("DestroyBlock")
if not placeRemote then
	game.StarterGui:SetCore("SendNotification",{Title="Error",Text="Place remote missing."})
	return
end
if not destroyRemote then
	game.StarterGui:SetCore("SendNotification",{Title="Error",Text="DestroyBlock remote missing."})
	return
end
local baseplate = workspace:FindFirstChild("Baseplate")
if not baseplate then
	game.StarterGui:SetCore("SendNotification",{Title="Error",Text="Baseplate missing."})
	return
end
local builtFolder = workspace:FindFirstChild("Built") or Instance.new("Folder", workspace)
builtFolder.Name = "Built"

-- Global fling state
_G.FlingOldPos = nil
_G.FPDH = workspace.FallenPartsDestroyHeight

-- Thread tracking
local threads = {}
local function stop(name)
	if threads[name] then
		task.cancel(threads[name])
		threads[name] = nil
	end
end
local function start(name, fn)
	stop(name)
	threads[name] = task.spawn(fn)
end

-- ====================== Utility Functions ======================
local function placeBlock(blockType, pos)
	local roundedPos = Vector3.new(math.round(pos.X), math.round(pos.Y), math.round(pos.Z))
	local cf = CFrame.new(roundedPos) -- identity rotation
	local ok, err = pcall(function()
		placeRemote:InvokeServer(blockType, cf, baseplate)
	end)
	if ok then
		print("✅ Placed " .. blockType .. " at " .. tostring(roundedPos))
		return true
	else
		warn("❌ Place failed: " .. tostring(err))
		return false
	end
end

local function destroyAllParts(folder)
	local count = 0
	for _, v in ipairs(folder:GetDescendants()) do
		if v:IsA("BasePart") then
			count += 1
			task.spawn(function()
				local ok, err = pcall(function() destroyRemote:InvokeServer(v) end)
				if not ok then warn("❌ Destroy failed: " .. tostring(err)) end
			end)
		end
	end
	print("💥 Destroying " .. count .. " parts")
end

-- Nuke All: teleports to each part, deletes all within radius
local function nukeAllLoop()
	local radius = 20
	while threads["nukeAll"] do
		local parts = {}
		for _, v in ipairs(builtFolder:GetDescendants()) do
			if v:IsA("BasePart") and v.Parent then table.insert(parts, v) end
		end
		for _, part in ipairs(parts) do
			if not threads["nukeAll"] then break end
			if part and part.Parent then
				if character and character.PrimaryPart then
					pcall(function() character:PivotTo(part.CFrame) end)
				end
				local pos = part.Position
				local toDelete = {}
				for _, v in ipairs(builtFolder:GetDescendants()) do
					if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= radius then
						table.insert(toDelete, v)
					end
				end
				for _, d in ipairs(toDelete) do
					task.spawn(function() pcall(function() destroyRemote:InvokeServer(d) end) end)
				end
				task.wait(0.05)
			end
		end
		task.wait(0.3)
	end
end

-- Cage a player (teleport + place)
local function cagePlayer(target)
	if not target or not target.Character or not target.Character.PrimaryPart then return end
	local root = target.Character.PrimaryPart
	if character and character.PrimaryPart then
		pcall(function() character:PivotTo(root.CFrame + Vector3.new(0,2,0)) end)
	end
	local center = root.Position
	for x = -2,2 do for y = -2,2 do for z = -2,2 do
		if x==0 and y==0 and z==0 then continue end
		placeBlock("Glass", center + Vector3.new(x*4,y*4,z*4))
	end end end
end

-- Fling function (unchanged)
local function fling(target)
	local char = character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = hum and hum.RootPart
	local tChar = target.Character
	if not tChar or not hum or not root then return end
	local tHum = tChar:FindFirstChildOfClass("Humanoid")
	local tRoot = tHum and tHum.RootPart
	local tHead = tChar:FindFirstChild("Head")
	local acc = tChar:FindFirstChildOfClass("Accessory")
	local handle = acc and acc:FindFirstChild("Handle")
	if root.Velocity.Magnitude < 50 then _G.FlingOldPos = root.CFrame end
	if tHum and tHum.Sit then return end
	if tHead then workspace.CurrentCamera.CameraSubject = tHead
	elseif handle then workspace.CurrentCamera.CameraSubject = handle
	elseif tHum and tRoot then workspace.CurrentCamera.CameraSubject = tHum end
	if not tChar:FindFirstChildWhichIsA("BasePart") then return end

	local function FPos(bp, pos, ang)
		root.CFrame = CFrame.new(bp.Position) * pos * ang
		char:SetPrimaryPartCFrame(CFrame.new(bp.Position) * pos * ang)
		root.Velocity = Vector3.new(9e7, 9e7*10, 9e7)
		root.RotVelocity = Vector3.new(9e8,9e8,9e8)
	end

	local function SF(bp)
		local t0 = tick(); local ang = 0
		repeat
			if root and tHum then
				if bp.Velocity.Magnitude < 50 then
					ang += 100
					FPos(bp, CFrame.new(0,1.5,0)+tHum.MoveDirection*bp.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(ang),0,0))
					task.wait()
					FPos(bp, CFrame.new(0,-1.5,0)+tHum.MoveDirection*bp.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(ang),0,0))
					task.wait()
					FPos(bp, CFrame.new(0,1.5,0)+tHum.MoveDirection*bp.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(ang),0,0))
					task.wait()
					FPos(bp, CFrame.new(0,-1.5,0)+tHum.MoveDirection*bp.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(ang),0,0))
					task.wait()
					FPos(bp, CFrame.new(0,1.5,0)+tHum.MoveDirection, CFrame.Angles(math.rad(ang),0,0))
					task.wait()
					FPos(bp, CFrame.new(0,-1.5,0)+tHum.MoveDirection, CFrame.Angles(math.rad(ang),0,0))
					task.wait()
				else
					FPos(bp, CFrame.new(0,1.5,tHum.WalkSpeed), CFrame.Angles(math.rad(90),0,0))
					task.wait()
					FPos(bp, CFrame.new(0,-1.5,-tHum.WalkSpeed), CFrame.Angles(0,0,0))
					task.wait()
					FPos(bp, CFrame.new(0,1.5,tHum.WalkSpeed), CFrame.Angles(math.rad(90),0,0))
					task.wait()
					FPos(bp, CFrame.new(0,-1.5,0), CFrame.Angles(math.rad(90),0,0))
					task.wait()
					FPos(bp, CFrame.new(0,-1.5,0), CFrame.Angles(0,0,0))
					task.wait()
					FPos(bp, CFrame.new(0,-1.5,0), CFrame.Angles(math.rad(90),0,0))
					task.wait()
					FPos(bp, CFrame.new(0,-1.5,0), CFrame.Angles(0,0,0))
					task.wait()
				end
			end
		until tick()-t0 > 2 or not (threads["flingAll"] or threads["flingTarget"])
	end

	workspace.FallenPartsDestroyHeight = 0/0
	local bv = Instance.new("BodyVelocity"); bv.Parent = root; bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.new(9e9,9e9,9e9)
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	if tRoot then SF(tRoot) elseif tHead then SF(tHead) elseif handle then SF(handle) end
	bv:Destroy(); hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	workspace.CurrentCamera.CameraSubject = hum
	if _G.FlingOldPos then
		repeat
			root.CFrame = _G.FlingOldPos * CFrame.new(0,.5,0)
			char:SetPrimaryPartCFrame(_G.FlingOldPos * CFrame.new(0,.5,0))
			hum:ChangeState("GettingUp")
			for _, p in pairs(char:GetChildren()) do if p:IsA("BasePart") then p.Velocity, p.RotVelocity = Vector3.new(), Vector3.new() end end
			task.wait()
		until (root.Position - _G.FlingOldPos.p).Magnitude < 25 or not (threads["flingAll"] or threads["flingTarget"])
		workspace.FallenPartsDestroyHeight = _G.FPDH
	end
end

-- ====================== GUI (Classic Style) ======================
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "BuildExploitGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 620)
frame.Position = UDim2.new(0, 20, 0, 80)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-20,0,30)
title.Position = UDim2.new(0,10,0,5)
title.BackgroundTransparency = 1
title.Text = "Build Exploit Pack"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.TextColor3 = Color3.new(1,1,1)

-- Target selection dropdown
local targetDropdownButton = Instance.new("TextButton", frame)
targetDropdownButton.Size = UDim2.new(1,-20,0,35)
targetDropdownButton.Position = UDim2.new(0,10,0,40)
targetDropdownButton.Text = "Select Target ▼"
targetDropdownButton.BackgroundColor3 = Color3.fromRGB(120,0,180)
targetDropdownButton.TextColor3 = Color3.new(1,1,1)
targetDropdownButton.Font = Enum.Font.SourceSansBold
targetDropdownButton.TextSize = 16
Instance.new("UICorner", targetDropdownButton)

local targetListFrame = Instance.new("Frame", frame)
targetListFrame.Size = UDim2.new(1,-20,0,150)
targetListFrame.Position = UDim2.new(0,10,0,80)
targetListFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
targetListFrame.Visible = false
Instance.new("UICorner", targetListFrame)
local targetScroll = Instance.new("ScrollingFrame", targetListFrame)
targetScroll.Size = UDim2.new(1,-10,1,-10)
targetScroll.Position = UDim2.new(0,5,0,5)
targetScroll.CanvasSize = UDim2.new(0,0,0,0)
targetScroll.ScrollBarThickness = 6
targetScroll.BackgroundTransparency = 1
local targetLayout = Instance.new("UIListLayout", targetScroll)
targetLayout.Padding = UDim.new(0,4)
targetLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	targetScroll.CanvasSize = UDim2.new(0,0,0,targetLayout.AbsoluteContentSize.Y+10)
end)

local selectedTarget = nil

local function refreshTargetDropdown()
	for _, b in ipairs(targetScroll:GetChildren()) do if b:IsA("TextButton") then b:Destroy() end end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local btn = Instance.new("TextButton", targetScroll)
			btn.Size = UDim2.new(1,-10,0,30)
			btn.Text = p.Name
			btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
			btn.TextColor3 = Color3.new(1,1,1)
			btn.Font = Enum.Font.SourceSansBold
			btn.TextSize = 14
			Instance.new("UICorner", btn)
			btn.MouseButton1Click:Connect(function()
				selectedTarget = p
				targetDropdownButton.Text = p.Name .. " ▼"
				targetListFrame.Visible = false
			end)
		end
	end
	local noneBtn = Instance.new("TextButton", targetScroll)
	noneBtn.Size = UDim2.new(1,-10,0,30)
	noneBtn.Text = "None (Global)"
	noneBtn.BackgroundColor3 = Color3.fromRGB(90,90,90)
	noneBtn.TextColor3 = Color3.new(1,1,1)
	noneBtn.Font = Enum.Font.SourceSansBold
	noneBtn.TextSize = 14
	Instance.new("UICorner", noneBtn)
	noneBtn.MouseButton1Click:Connect(function()
		selectedTarget = nil
		targetDropdownButton.Text = "Select Target ▼"
		targetListFrame.Visible = false
	end)
end
refreshTargetDropdown()
Players.PlayerAdded:Connect(refreshTargetDropdown)
Players.PlayerRemoving:Connect(function(p)
	if selectedTarget == p then selectedTarget = nil; targetDropdownButton.Text = "Select Target ▼" end
	refreshTargetDropdown()
end)

targetDropdownButton.MouseButton1Click:Connect(function()
	targetListFrame.Visible = not targetListFrame.Visible
end)

-- Toggle creation helper
local function addToggle(y, name, onFunc, offFunc)
	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.new(1,-20,0,30)
	btn.Position = UDim2.new(0,10,0,y)
	btn.Text = name .. ": OFF"
	btn.BackgroundColor3 = Color3.fromRGB(180,0,0)
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 16
	Instance.new("UICorner", btn)
	local active = false
	btn.MouseButton1Click:Connect(function()
		active = not active
		if active then
			btn.Text = name .. ": ON"
			btn.BackgroundColor3 = Color3.fromRGB(0,150,0)
			onFunc()
		else
			btn.Text = name .. ": OFF"
			btn.BackgroundColor3 = Color3.fromRGB(180,0,0)
			offFunc()
		end
	end)
end

-- Y positions for elements
local y = 240

-- Target Actions
addToggle(y, "Fling Target",
	function() start("flingTarget", function() while threads["flingTarget"] do if not selectedTarget then task.wait(1); continue end fling(selectedTarget); task.wait(0.5) end end) end,
	function() stop("flingTarget") end)
y += 35

addToggle(y, "Cage Target",
	function() start("cageTarget", function() while threads["cageTarget"] do if not selectedTarget then task.wait(1); continue end cagePlayer(selectedTarget); task.wait(0.5) end end) end,
	function() stop("cageTarget") end)
y += 35

addToggle(y, "Nuke Target",
	function() start("nukeTarget", function() while threads["nukeTarget"] do if not selectedTarget then task.wait(0.5); continue end local folder = builtFolder:FindFirstChild(selectedTarget.Name) if folder then destroyAllParts(folder) end task.wait(0.5) end end) end,
	function() stop("nukeTarget") end)
y += 35

-- Global Actions
addToggle(y, "Fling All",
	function() start("flingAll", function() while threads["flingAll"] do for _, p in ipairs(Players:GetPlayers()) do if p~=player then fling(p); task.wait(0.8) end end task.wait(1) end end) end,
	function() stop("flingAll") end)
y += 35

addToggle(y, "Cage All",
	function() start("cageAll", function() while threads["cageAll"] do for _, p in ipairs(Players:GetPlayers()) do if p~=player then cagePlayer(p); task.wait(0.5) end end task.wait(1) end end) end,
	function() stop("cageAll") end)
y += 35

addToggle(y, "Nuke All (Teleport)",
	function() start("nukeAll", nukeAllLoop) end,
	function() stop("nukeAll") end)
y += 35

-- Destroy all once
local destroyBtn = Instance.new("TextButton", frame)
destroyBtn.Size = UDim2.new(1,-20,0,35)
destroyBtn.Position = UDim2.new(0,10,0,y)
destroyBtn.Text = "🗑️ DESTROY ALL NOW"
destroyBtn.BackgroundColor3 = Color3.fromRGB(220,20,20)
destroyBtn.TextColor3 = Color3.new(1,1,1)
destroyBtn.Font = Enum.Font.SourceSansBold
destroyBtn.TextSize = 18
Instance.new("UICorner", destroyBtn)
destroyBtn.MouseButton1Click:Connect(function() destroyAllParts(builtFolder) end)
y += 40

-- Aura (around player)
addToggle(y, "Destroy Aura (Self)",
	function() start("aura", function() local radius=20 while threads["aura"] do if character and character.PrimaryPart then local pos=character.PrimaryPart.Position task.spawn(function() for _,v in ipairs(builtFolder:GetDescendants()) do if v:IsA("BasePart") and v.Parent and (v.Position-pos).Magnitude<=radius then pcall(function() destroyRemote:InvokeServer(v) end) end end end) end task.wait(0.1) end end) end,
	function() stop("aura") end)
y += 35

-- Spammer (fill sphere)
addToggle(y, "Spammer (Sphere Fill)",
	function()
		start("spammer", function()
			local radius = 20
			while threads["spammer"] do
				if character and character.PrimaryPart then
					local center = character.PrimaryPart.Position
					for x = -radius, radius do
						for y = -radius, radius do
							for z = -radius, radius do
								if not threads["spammer"] then break end
								local pos = Vector3.new(center.X+x, center.Y+y, center.Z+z)
								if (pos - center).Magnitude <= radius then
									placeBlock("Glass", pos)
								end
							end
						end
					end
					task.wait(0.5) -- wait before next sphere
				else
					task.wait(1)
				end
			end
		end)
	end,
	function() stop("spammer") end)
y += 35

-- Local Player sliders
local wsLabel = Instance.new("TextLabel", frame)
wsLabel.Position = UDim2.new(0,10,0,y); wsLabel.Size = UDim2.new(0.4,0,0,20); wsLabel.BackgroundTransparency = 1; wsLabel.Text = "WalkSpeed"; wsLabel.TextColor3 = Color3.new(1,1,1); wsLabel.Font = Enum.Font.SourceSans; wsLabel.TextSize = 14
local wsInput = Instance.new("TextBox", frame)
wsInput.Position = UDim2.new(0.4,5,0,y); wsInput.Size = UDim2.new(0.6,-5,0,20); wsInput.Text = "16"; wsInput.PlaceholderText = "16"; wsInput.BackgroundColor3 = Color3.fromRGB(50,50,50); wsInput.TextColor3 = Color3.new(1,1,1); wsInput.Font = Enum.Font.SourceSans; wsInput.TextSize = 14
Instance.new("UICorner", wsInput)
wsInput.FocusLost:Connect(function() local v = tonumber(wsInput.Text) if v and character and character:FindFirstChildOfClass("Humanoid") then character:FindFirstChildOfClass("Humanoid").WalkSpeed = v end end)
y += 25

local jpLabel = Instance.new("TextLabel", frame)
jpLabel.Position = UDim2.new(0,10,0,y); jpLabel.Size = UDim2.new(0.4,0,0,20); jpLabel.BackgroundTransparency = 1; jpLabel.Text = "JumpPower"; jpLabel.TextColor3 = Color3.new(1,1,1); jpLabel.Font = Enum.Font.SourceSans; jpLabel.TextSize = 14
local jpInput = Instance.new("TextBox", frame)
jpInput.Position = UDim2.new(0.4,5,0,y); jpInput.Size = UDim2.new(0.6,-5,0,20); jpInput.Text = "50"; jpInput.PlaceholderText = "50"; jpInput.BackgroundColor3 = Color3.fromRGB(50,50,50); jpInput.TextColor3 = Color3.new(1,1,1); jpInput.Font = Enum.Font.SourceSans; jpInput.TextSize = 14
Instance.new("UICorner", jpInput)
jpInput.FocusLost:Connect(function() local v = tonumber(jpInput.Text) if v and character and character:FindFirstChildOfClass("Humanoid") then character:FindFirstChildOfClass("Humanoid").JumpPower = v end end)
y += 25

local gravLabel = Instance.new("TextLabel", frame)
gravLabel.Position = UDim2.new(0,10,0,y); gravLabel.Size = UDim2.new(0.4,0,0,20); gravLabel.BackgroundTransparency = 1; gravLabel.Text = "Gravity"; gravLabel.TextColor3 = Color3.new(1,1,1); gravLabel.Font = Enum.Font.SourceSans; gravLabel.TextSize = 14
local gravInput = Instance.new("TextBox", frame)
gravInput.Position = UDim2.new(0.4,5,0,y); gravInput.Size = UDim2.new(0.6,-5,0,20); gravInput.Text = "196.2"; gravInput.PlaceholderText = "196.2"; gravInput.BackgroundColor3 = Color3.fromRGB(50,50,50); gravInput.TextColor3 = Color3.new(1,1,1); gravInput.Font = Enum.Font.SourceSans; gravInput.TextSize = 14
Instance.new("UICorner", gravInput)
gravInput.FocusLost:Connect(function() local v = tonumber(gravInput.Text) if v then workspace.Gravity = v end end)
y += 25

-- Fly toggle
addToggle(y, "Fly",
	function()
		if character and character.PrimaryPart and character:FindFirstChildOfClass("Humanoid") then
			local hum = character:FindFirstChildOfClass("Humanoid")
			hum.PlatformStand = true
			local gyro = Instance.new("BodyGyro", character.PrimaryPart)
			gyro.CFrame = character.PrimaryPart.CFrame; gyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
			local vel = Instance.new("BodyVelocity", character.PrimaryPart)
			vel.MaxForce = Vector3.new(9e9,9e9,9e9)
			start("fly", function()
				local conn = RunService.Heartbeat:Connect(function()
					if not threads["fly"] then conn:Disconnect(); return end
					gyro.CFrame = workspace.CurrentCamera.CFrame
					local dir = Vector3.zero
					if UIS:IsKeyDown(Enum.KeyCode.W) then dir += gyro.CFrame.LookVector end
					if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= gyro.CFrame.LookVector end
					if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= gyro.CFrame.RightVector end
					if UIS:IsKeyDown(Enum.KeyCode.D) then dir += gyro.CFrame.RightVector end
					if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
					if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
					vel.Velocity = dir * 50
				end)
				while threads["fly"] do task.wait() end
				conn:Disconnect()
				gyro:Destroy(); vel:Destroy()
				hum.PlatformStand = false
			end)
		end
	end,
	function() stop("fly") end)
y += 35

-- Stop All button
local stopBtn = Instance.new("TextButton", frame)
stopBtn.Size = UDim2.new(1,-20,0,35)
stopBtn.Position = UDim2.new(0,10,0,y)
stopBtn.Text = "STOP ALL"
stopBtn.BackgroundColor3 = Color3.fromRGB(255,0,0)
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.Font = Enum.Font.SourceSansBold
stopBtn.TextSize = 18
Instance.new("UICorner", stopBtn)
stopBtn.MouseButton1Click:Connect(function()
	for name in pairs(threads) do stop(name) end
	print("All tasks stopped")
end)

-- Draggable
local dragStart, startPos, dragging
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
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
	end
end)

print("✅ Build Exploit Pack – Final Classic GUI Loaded. Use toggles.")