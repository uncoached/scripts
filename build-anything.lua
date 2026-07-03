-- Build Exploit Pack – WindUI Edition (Feature‑Rich)
-- All exploits, spammer, cage, local player, visuals, ESP, and more.

-- ==================== WindUI Load ====================
local WindUI
do
	local ok, result = pcall(function()
		return require("./src/Init")
	end)
	if ok then
		WindUI = result
	else
		if cloneref and cloneref(game:GetService("RunService")):IsStudio() then
			WindUI = require(cloneref(game:GetService("ReplicatedStorage")):WaitForChild("WindUI"):WaitForChild("Init"))
		else
			WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
		end
	end
end

-- ==================== Services & Globals ====================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- Character handling
local character
local function updateCharacter()
	character = player.Character
	if character and not character:FindFirstChild("HumanoidRootPart") then
		character = nil
	end
end
updateCharacter()
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	character:WaitForChild("HumanoidRootPart")
end)

-- Remote references
local events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
local placeRemote = events:WaitForChild("Place")
local destroyRemote = events:WaitForChild("DestroyBlock")
local baseplate = workspace:WaitForChild("Baseplate", 10) or workspace
local builtFolder = workspace:FindFirstChild("Built") or Instance.new("Folder", workspace)
builtFolder.Name = "Built"

-- Global fling state
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- Shared target selection
local selectedTarget = nil

-- Feature states
local nukeAllActive = false; local nukeAllThread = nil
local nukeTargetActive = false; local nukeTargetThread = nil

local flingAllActive = false; local flingAllThread = nil
local flingTargetActive = false; local flingTargetThread = nil

local cageAllActive = false; local cageAllThread = nil
local cageTargetActive = false; local cageTargetThread = nil

local touchFlingActive = false; local touchConns = {}

local auraActive = false; local auraThread = nil; local auraAngle = 0
local auraSpeed = 0.3; local auraClear = 20; local auraOrbit = 20

local spammerActive = false; local spammerThread = nil
local spammerDelay = 0.1; local spammerBlockType = "Glass"; local spammerRadius = 20

-- ==================== Utility Functions ====================
local function getSource(folderName)
	-- If no target, return builtFolder
	return builtFolder
end

-- Place a block at an integer position with given block type
local function placeBlock(blockType, position)
	local bp = workspace:FindFirstChild("Baseplate") or workspace
	local roundedPos = Vector3.new(math.round(position.X), math.round(position.Y), math.round(position.Z))
	-- Ensure Y is at least 0? Keep as is.
	pcall(function()
		placeRemote:InvokeServer(blockType, CFrame.new(roundedPos), bp)
	end)
end

-- Cage a player's HumanoidRootPart
local function cagePlayer(targetPlayer)
	if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character.PrimaryPart then return end
	local root = targetPlayer.Character.PrimaryPart
	local center = root.Position
	for x = -2, 2 do
		for y = -2, 2 do
			for z = -2, 2 do
				if x == 0 and y == 0 and z == 0 then continue end
				local pos = center + Vector3.new(x*4, y*4, z*4)
				placeBlock("Glass", pos)
			end
		end
	end
end

-- Destroy all parts in a folder
local function destroyAllParts(folder)
	local targets = {}
	for _, v in ipairs(folder:GetDescendants()) do
		if v:IsA("BasePart") then table.insert(targets, v) end
	end
	for _, part in ipairs(targets) do
		task.spawn(function() pcall(function() destroyRemote:InvokeServer(part) end) end)
	end
end

-- Fling a player (same as before)
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

		if THead then workspace.CurrentCamera.CameraSubject = THead
		elseif Handle then workspace.CurrentCamera.CameraSubject = Handle
		elseif THumanoid and TRootPart then workspace.CurrentCamera.CameraSubject = THumanoid end

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
			repeat
				if RootPart and THumanoid then
					if BasePart.Velocity.Magnitude < 50 then
						Angle = Angle + 100
						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0 ,0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
						task.wait()
					else
						FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
						task.wait()
						FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
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
			until Time + TimeToWait < tick() or not flingTargetActive
		end

		workspace.FallenPartsDestroyHeight = 0/0

		local BV = Instance.new("BodyVelocity")
		BV.Parent = RootPart; BV.Velocity = Vector3.new(0,0,0); BV.MaxForce = Vector3.new(9e9,9e9,9e9)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

		if TRootPart then SFBasePart(TRootPart)
		elseif THead then SFBasePart(THead)
		elseif Handle then SFBasePart(Handle) end

		BV:Destroy(); Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		workspace.CurrentCamera.CameraSubject = Humanoid

		if getgenv().OldPos then
			repeat
				RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
				Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
				Humanoid:ChangeState("GettingUp")
				for _, part in pairs(Character:GetChildren()) do
					if part:IsA("BasePart") then part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new() end
				end
				task.wait()
			until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25 or not flingTargetActive
			workspace.FallenPartsDestroyHeight = getgenv().FPDH
		end
	end
end

-- ==================== UI Creation ====================
local Window = WindUI:CreateWindow({
	Title = "Build Exploit Pack",
	Folder = "BuildExploit",
	Icon = "solar:hammer-bold",
	OpenButton = {
		Title = "Open Exploit Menu",
		Enabled = true,
	},
})

-- Target Selection (shared)
local function refreshTargetDropdown(dropdown)
	local names = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then table.insert(names, plr.Name) end
	end
	dropdown:Refresh(names)
end

-- ==================== Tab: Target ====================
local TargetTab = Window:Tab({ Title = "Target", Icon = "solar:user-bold" })
local TargetSection = TargetTab:Section({ Title = "Select a player" })
local targetDropdown = TargetSection:Dropdown({
	Title = "Target",
	Values = {},
	AllowNone = true,
	Callback = function(value)
		if value then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Name == value and plr ~= player then
					selectedTarget = plr
					return
				end
			end
		else
			selectedTarget = nil
		end
	end,
})
refreshTargetDropdown(targetDropdown)
Players.PlayerAdded:Connect(function() refreshTargetDropdown(targetDropdown) end)
Players.PlayerRemoving:Connect(function(p)
	if selectedTarget == p then selectedTarget = nil; targetDropdown:Select(nil) end
	refreshTargetDropdown(targetDropdown)
end)

-- Target actions
local TargetActionsSection = TargetTab:Section({ Title = "Actions on Target" })
TargetActionsSection:Toggle({
	Title = "Fling Target",
	Callback = function(state)
		flingTargetActive = state
		if state then
			flingTargetThread = task.spawn(function()
				while flingTargetActive do
					if not selectedTarget then task.wait(1); continue end
					if not selectedTarget.Parent then selectedTarget = nil; task.wait(1); continue end
					SkidFling(selectedTarget)
					task.wait(0.5)
				end
			end)
		else
			if flingTargetThread then task.cancel(flingTargetThread) end
		end
	end,
})
TargetActionsSection:Toggle({
	Title = "Cage Target",
	Callback = function(state)
		cageTargetActive = state
		if state then
			cageTargetThread = task.spawn(function()
				while cageTargetActive do
					if not selectedTarget then task.wait(1); continue end
					cagePlayer(selectedTarget)
					task.wait(0.5)
				end
			end)
		else
			if cageTargetThread then task.cancel(cageTargetThread) end
		end
	end,
})
TargetActionsSection:Toggle({
	Title = "Nuke Target's Blocks",
	Callback = function(state)
		nukeTargetActive = state
		if state then
			nukeTargetThread = task.spawn(function()
				while nukeTargetActive do
					if not selectedTarget then task.wait(1); continue end
					local folder = builtFolder:FindFirstChild(selectedTarget.Name)
					if folder then
						destroyAllParts(folder)
					end
					task.wait(0.5)
				end
			end)
		else
			if nukeTargetThread then task.cancel(nukeTargetThread) end
		end
	end,
})
TargetActionsSection:Button({
	Title = "Teleport to Target",
	Callback = function()
		if selectedTarget and selectedTarget.Character and selectedTarget.Character.PrimaryPart then
			if character and character.PrimaryPart then
				pcall(function()
					character:PivotTo(selectedTarget.Character.PrimaryPart.CFrame + Vector3.new(0,2,0))
				end)
			end
		else
			WindUI:Notify({ Title = "Error", Content = "Target not available.", Duration = 2 })
		end
	end,
})

-- ==================== Tab: Main (Global) ====================
local MainTab = Window:Tab({ Title = "Main", Icon = "solar:globus-bold" })
local GlobalSection = MainTab:Section({ Title = "Global Actions" })
GlobalSection:Button({
	Title = "🗑️ NUKE ALL",
	Color = Color3.fromRGB(220, 20, 20),
	Callback = function() destroyAllParts(builtFolder) end,
})
GlobalSection:Toggle({
	Title = "Fling All Players",
	Callback = function(state)
		flingAllActive = state
		if state then
			flingAllThread = task.spawn(function()
				while flingAllActive do
					for _, plr in ipairs(Players:GetPlayers()) do
						if plr ~= player then
							SkidFling(plr)
						end
					end
					task.wait(0.5)
				end
			end)
		else
			if flingAllThread then task.cancel(flingAllThread) end
		end
	end,
})
GlobalSection:Toggle({
	Title = "Cage All Players",
	Callback = function(state)
		cageAllActive = state
		if state then
			cageAllThread = task.spawn(function()
				while cageAllActive do
					for _, plr in ipairs(Players:GetPlayers()) do
						if plr ~= player then
							cagePlayer(plr)
						end
					end
					task.wait(0.5)
				end
			end)
		else
			if cageAllThread then task.cancel(cageAllThread) end
		end
	end,
})
GlobalSection:Toggle({
	Title = "Nuke All (Continuous)",
	Callback = function(state)
		nukeAllActive = state
		if state then
			nukeAllThread = task.spawn(function()
				while nukeAllActive do
					destroyAllParts(builtFolder)
					task.wait(0.5)
				end
			end)
		else
			if nukeAllThread then task.cancel(nukeAllThread) end
		end
	end,
})

-- ==================== Tab: Spammer ====================
local SpammerTab = Window:Tab({ Title = "Spammer", Icon = "solar:layers-bold" })
SpammerTab:Toggle({
	Title = "Block Spammer",
	Callback = function(state)
		spammerActive = state
		if state then
			spammerThread = task.spawn(function()
				while spammerActive do
					if character and character.PrimaryPart then
						local center = character.PrimaryPart.Position
						-- Place blocks in a 20‑stud radius, using integer positions
						for x = -20, 20 do
							for y = -20, 20 do
								for z = -20, 20 do
									if not spammerActive then break end
									local pos = Vector3.new(center.X + x, center.Y + y, center.Z + z)
									if (pos - center).Magnitude <= 20 then
										placeBlock(spammerBlockType, pos)
									end
								end
							end
						end
					end
					task.wait(spammerDelay)
				end
			end)
		else
			if spammerThread then task.cancel(spammerThread) end
		end
	end,
})
SpammerTab:Input({
	Title = "Block Type",
	Value = "Glass",
	Callback = function(value) spammerBlockType = value end,
})
SpammerTab:Slider({
	Title = "Delay (s)",
	Step = 0.01,
	Value = { Min = 0.01, Max = 2, Default = 0.1 },
	Callback = function(value) spammerDelay = value end,
})

-- ==================== Tab: Aura ====================
local AuraTab = Window:Tab({ Title = "Aura", Icon = "solar:star-bold" })
AuraTab:Toggle({
	Title = "Destroy Aura",
	Callback = function(state)
		auraActive = state
		if state then
			auraAngle = 0
			auraThread = task.spawn(function()
				while auraActive do
					local source = builtFolder
					local target = selectedTarget
					if target and target.Character and target.Character.PrimaryPart then
						local tpos = target.Character.PrimaryPart.Position
						local dynamicR = auraOrbit + math.sin(auraAngle*0.5)*5
						local offset = Vector3.new(math.cos(auraAngle)*dynamicR, 2+math.sin(auraAngle*2)*10, math.sin(auraAngle)*dynamicR)
						local myPos = tpos + offset
						if character and character.PrimaryPart then
							pcall(function() character:PivotTo(CFrame.new(myPos)) end)
						end
						task.spawn(function()
							for _, v in ipairs(source:GetDescendants()) do
								if v:IsA("BasePart") and v.Parent and (v.Position - myPos).Magnitude <= auraClear then
									pcall(function() destroyRemote:InvokeServer(v) end)
								end
							end
						end)
						auraAngle = auraAngle + auraSpeed
					else
						if character and character.PrimaryPart then
							local pos = character.PrimaryPart.Position
							task.spawn(function()
								for _, v in ipairs(source:GetDescendants()) do
									if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= auraClear then
										pcall(function() destroyRemote:InvokeServer(v) end)
									end
								end
							end)
						end
					end
					task.wait()
				end
			end)
		else
			if auraThread then task.cancel(auraThread) end
		end
	end,
})
AuraTab:Slider({
	Title = "Speed",
	Step = 0.01,
	Value = { Min = 0.05, Max = 1, Default = 0.3 },
	Callback = function(value) auraSpeed = value end,
})
AuraTab:Slider({
	Title = "Clear Distance",
	Step = 1,
	Value = { Min = 5, Max = 50, Default = 20 },
	Callback = function(value) auraClear = value end,
})
AuraTab:Slider({
	Title = "Orbit Distance",
	Step = 1,
	Value = { Min = 5, Max = 50, Default = 20 },
	Callback = function(value) auraOrbit = value end,
})

-- ==================== Tab: Local Player ====================
local LocalTab = Window:Tab({ Title = "Local", Icon = "solar:user-speak-bold" })
LocalTab:Slider({
	Title = "WalkSpeed",
	Step = 1,
	Value = { Min = 16, Max = 200, Default = 16 },
	Callback = function(value)
		if character and character:FindFirstChildOfClass("Humanoid") then
			character:FindFirstChildOfClass("Humanoid").WalkSpeed = value
		end
	end,
})
LocalTab:Slider({
	Title = "JumpPower",
	Step = 1,
	Value = { Min = 50, Max = 300, Default = 50 },
	Callback = function(value)
		if character and character:FindFirstChildOfClass("Humanoid") then
			character:FindFirstChildOfClass("Humanoid").JumpPower = value
		end
	end,
})
LocalTab:Slider({
	Title = "HipHeight",
	Step = 0.1,
	Value = { Min = 0, Max = 5, Default = 0 },
	Callback = function(value)
		if character and character:FindFirstChildOfClass("Humanoid") then
			character:FindFirstChildOfClass("Humanoid").HipHeight = value
		end
	end,
})
LocalTab:Slider({
	Title = "Gravity",
	Step = 0.01,
	Value = { Min = 0, Max = 196.2, Default = 196.2 },
	Callback = function(value)
		workspace.Gravity = value
	end,
})

-- Fly and Noclip
local flyActive = false
local flyConnection
LocalTab:Toggle({
	Title = "Fly",
	Callback = function(state)
		flyActive = state
		if state then
			local function flyLoop()
				if character and character.PrimaryPart and character:FindFirstChildOfClass("Humanoid") then
					local hum = character:FindFirstChildOfClass("Humanoid")
					hum.PlatformStand = true
					local bodyGyro = Instance.new("BodyGyro", character.PrimaryPart)
					bodyGyro.CFrame = character.PrimaryPart.CFrame
					bodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
					local bodyVel = Instance.new("BodyVelocity", character.PrimaryPart)
					bodyVel.MaxForce = Vector3.new(9e9,9e9,9e9)
					bodyVel.Velocity = Vector3.new(0,0,0)
					flyConnection = RunService.Heartbeat:Connect(function()
						if not flyActive then return end
						bodyGyro.CFrame = workspace.CurrentCamera.CFrame
						local moveDir = Vector3.zero
						if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir += bodyGyro.CFrame.LookVector end
						if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir -= bodyGyro.CFrame.LookVector end
						if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir -= bodyGyro.CFrame.RightVector end
						if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir += bodyGyro.CFrame.RightVector end
						if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
						if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end
						bodyVel.Velocity = moveDir * 50
					end)
				end
			end
			flyLoop()
		else
			if flyConnection then flyConnection:Disconnect() end
			if character and character.PrimaryPart then
				for _, v in pairs(character.PrimaryPart:GetChildren()) do
					if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
				end
			end
			if character and character:FindFirstChildOfClass("Humanoid") then
				character:FindFirstChildOfClass("Humanoid").PlatformStand = false
			end
		end
	end,
})
LocalTab:Toggle({
	Title = "Noclip",
	Callback = function(state)
		local function noclipLoop()
			if character then
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = not state end
				end
			end
		end
		noclipLoop()
		local con = RunService.Stepped:Connect(noclipLoop)
		task.delay(0, function()
			while state and con.Connected do task.wait() end
			if not state then con:Disconnect() end
		end)
	end,
})

-- ==================== Tab: Visuals ====================
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })

-- Fullbright
VisualsTab:Toggle({
	Title = "Fullbright",
	Callback = function(state)
		Lighting.Brightness = state and 2 or 1
		Lighting.ClockTime = state and 14 or 14
		Lighting.FogEnd = state and 100000 or 100000
		Lighting.GlobalShadows = not state
	end,
})

-- ESP
local espFolder = Instance.new("Folder", workspace)
local espEnabled = false
VisualsTab:Toggle({
	Title = "Player ESP",
	Callback = function(state)
		espEnabled = state
		if not state then
			for _, v in ipairs(espFolder:GetChildren()) do v:Destroy() end
			return
		end
		local function createESP(plr)
			if plr == player then return end
			local function onCharAdded(char)
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Color3.fromRGB(255, 0, 0)
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.FillTransparency = 0.5
				highlight.Adornee = char
				highlight.Parent = espFolder
				char.DescendantAdded:Connect(function(child)
					if child:IsA("BasePart") then
						local hl = Instance.new("Highlight")
						hl.FillColor = Color3.fromRGB(255, 0, 0)
						hl.OutlineColor = Color3.fromRGB(255, 255, 255)
						hl.FillTransparency = 0.5
						hl.Adornee = child
						hl.Parent = espFolder
					end
				end)
			end
			if plr.Character then onCharAdded(plr.Character) end
			plr.CharacterAdded:Connect(onCharAdded)
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			createESP(plr)
		end
		Players.PlayerAdded:Connect(function(plr)
			if espEnabled then createESP(plr) end
		end)
	end,
})

-- Wireframe
VisualsTab:Toggle({
	Title = "Wireframe",
	Callback = function(state)
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				pcall(function()
					if state then
						obj.Material = Enum.Material.Wireframe
					else
						obj.Material = Enum.Material.Plastic
					end
				end)
			end
		end
	end,
})

-- Stop all button
Window:Button({
	Title = "STOP ALL",
	Color = Color3.fromRGB(255, 0, 0),
	Callback = function()
		-- stop all toggles and threads
		nukeAllActive = false; if nukeAllThread then task.cancel(nukeAllThread) end
		nukeTargetActive = false; if nukeTargetThread then task.cancel(nukeTargetThread) end
		flingAllActive = false; if flingAllThread then task.cancel(flingAllThread) end
		flingTargetActive = false; if flingTargetThread then task.cancel(flingTargetThread) end
		cageAllActive = false; if cageAllThread then task.cancel(cageAllThread) end
		cageTargetActive = false; if cageTargetThread then task.cancel(cageTargetThread) end
		spammerActive = false; if spammerThread then task.cancel(spammerThread) end
		auraActive = false; if auraThread then task.cancel(auraThread) end
		-- Reset UI toggles (we'll just call Set on each toggle that we have a reference to)
		WindUI:Notify({ Title = "Stopped", Content = "All tasks stopped.", Duration = 2 })
	end,
})

-- Load notification
WindUI:Notify({ Title = "Exploit Pack Loaded", Content = "All features ready!", Duration = 3 })
print("Build Exploit Pack – WindUI Edition Loaded")