-- Build Exploit Pack – WindUI Edition (Final Fixed)
-- Handles all features, proper thread cancellation, missing services.

-- ==================== WindUI Load ====================
local WindUI
do
	local ok, result = pcall(function()
		return require("./src/Init")
	end)
	if ok then
		WindUI = result
	elseif cloneref and cloneref(game:GetService("RunService")):IsStudio() then
		WindUI = require(cloneref(game:GetService("ReplicatedStorage")):WaitForChild("WindUI"):WaitForChild("Init"))
	else
		local success, lib = pcall(function()
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
		end)
		if not success then
			warn("WindUI failed to load: " .. tostring(lib))
			return
		end
		WindUI = lib
	end
end

-- ==================== Services ====================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

-- Character
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

-- Fling state
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- ==================== Feature States ====================
local selectedTarget = nil
local auraTarget = nil

-- States and threads
local states = {
	nukeAll = false, nukeTarget = false,
	flingAll = false, flingTarget = false,
	cageAll = false, cageTarget = false,
	touchFling = false,
	aura = false,
	spammer = false,
	fly = false, noclip = false,
}

local threads = {}

local function cancelThread(name)
	if threads[name] then
		task.cancel(threads[name])
		threads[name] = nil
	end
end

local function startThread(name, f)
	cancelThread(name)
	threads[name] = task.spawn(f)
end

-- ==================== Utility Functions ====================
local function placeBlock(blockType, pos)
	local bp = workspace:FindFirstChild("Baseplate") or workspace
	local roundedPos = Vector3.new(math.round(pos.X), math.round(pos.Y), math.round(pos.Z))
	pcall(function()
		placeRemote:InvokeServer(blockType, CFrame.new(roundedPos), bp)
	end)
end

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

local function destroyAllParts(folder)
	for _, v in ipairs(folder:GetDescendants()) do
		if v:IsA("BasePart") then
			task.spawn(function() pcall(function() destroyRemote:InvokeServer(v) end) end)
		end
	end
end

-- Fling function (same as before, but uses a passed running flag)
local function SkidFling(TargetPlayer, runningFlag)
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
			until Time + TimeToWait < tick() or not runningFlag()
		end

		workspace.FallenPartsDestroyHeight = 0/0

		local BV = Instance.new("BodyVelocity")
		BV.Parent = RootPart; BV.Velocity = Vector3.zero; BV.MaxForce = Vector3.new(9e9,9e9,9e9)
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
			until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25 or not runningFlag()
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

-- Shared target dropdown helpers
local function refreshTargetDropdown(dropdown)
	local names = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then table.insert(names, plr.Name) end
	end
	dropdown:Refresh(names)
end

-- ==================== TARGET TAB ====================
local TargetTab = Window:Tab({ Title = "Target", Icon = "solar:user-bold" })
local sharedTargetDropdown = TargetTab:Section({ Title = "Select Target" }):Dropdown({
	Title = "Target Player",
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
refreshTargetDropdown(sharedTargetDropdown)
Players.PlayerAdded:Connect(function() refreshTargetDropdown(sharedTargetDropdown) end)
Players.PlayerRemoving:Connect(function(p)
	if selectedTarget == p then selectedTarget = nil; sharedTargetDropdown:Select(nil) end
	refreshTargetDropdown(sharedTargetDropdown)
end)

-- Target Actions Section
local TargetActions = TargetTab:Section({ Title = "Actions on Target" })

-- Fling Target
TargetActions:Toggle({
	Title = "Fling Target",
	Callback = function(state)
		states.flingTarget = state
		if state then
			startThread("flingTarget", function()
				while states.flingTarget do
					if not selectedTarget then task.wait(1); continue end
					if not selectedTarget.Parent then selectedTarget = nil; break end
					SkidFling(selectedTarget, function() return states.flingTarget end)
					task.wait(0.5)
				end
			end)
		else
			cancelThread("flingTarget")
		end
	end,
})

-- Cage Target
TargetActions:Toggle({
	Title = "Cage Target",
	Callback = function(state)
		states.cageTarget = state
		if state then
			startThread("cageTarget", function()
				while states.cageTarget do
					if not selectedTarget then task.wait(1); continue end
					cagePlayer(selectedTarget)
					task.wait(0.5)
				end
			end)
		else
			cancelThread("cageTarget")
		end
	end,
})

-- Nuke Target (Teleport Delete)
TargetActions:Toggle({
	Title = "Nuke Target (Teleport Delete)",
	Callback = function(state)
		states.nukeTarget = state
		if state then
			startThread("nukeTarget", function()
				local SPOOF_RADIUS = 20
				while states.nukeTarget do
					if not selectedTarget then task.wait(0.5); continue end
					local folder = builtFolder:FindFirstChild(selectedTarget.Name)
					if not folder then task.wait(0.5); continue end
					local parts = {}
					for _, v in ipairs(folder:GetDescendants()) do
						if v:IsA("BasePart") and v.Parent then table.insert(parts, v) end
					end
					for _, part in ipairs(parts) do
						if not states.nukeTarget then break end
						if part and part.Parent then
							if character and character.PrimaryPart then
								pcall(function() character:PivotTo(part.CFrame) end)
							end
							local pos = part.Position
							for _, v in ipairs(folder:GetDescendants()) do
								if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= SPOOF_RADIUS then
									task.spawn(function() pcall(function() destroyRemote:InvokeServer(v) end) end)
								end
							end
							task.wait(0.05)
						end
					end
				end
			end)
		else
			cancelThread("nukeTarget")
		end
	end,
})

-- Teleport to Target
TargetActions:Button({
	Title = "Teleport to Target",
	Callback = function()
		if selectedTarget and selectedTarget.Character and selectedTarget.Character.PrimaryPart then
			if character and character.PrimaryPart then
				pcall(function() character:PivotTo(selectedTarget.Character.PrimaryPart.CFrame + Vector3.new(0,2,0)) end)
			end
		else
			WindUI:Notify({ Title = "Error", Content = "Target not available", Duration = 2 })
		end
	end,
})

-- ==================== MAIN TAB ====================
local MainTab = Window:Tab({ Title = "Main", Icon = "solar:globus-bold" })

MainTab:Section({ Title = "Destroy All" })
MainTab:Button({
	Title = "🗑️ DESTROY ALL",
	Color = Color3.fromRGB(220, 20, 20),
	Callback = function()
		destroyAllParts(builtFolder)
		WindUI:Notify({ Title = "Destroy All", Content = "Done.", Duration = 2 })
	end,
})

MainTab:Toggle({
	Title = "Fling All Players",
	Callback = function(state)
		states.flingAll = state
		if state then
			startThread("flingAll", function()
				while states.flingAll do
					for _, plr in ipairs(Players:GetPlayers()) do
						if plr ~= player then
							SkidFling(plr, function() return states.flingAll end)
							task.wait(1) -- slower to prevent overload
						end
					end
					task.wait(1)
				end
			end)
		else
			cancelThread("flingAll")
		end
	end,
})

MainTab:Toggle({
	Title = "Cage All Players",
	Callback = function(state)
		states.cageAll = state
		if state then
			startThread("cageAll", function()
				while states.cageAll do
					for _, plr in ipairs(Players:GetPlayers()) do
						if plr ~= player then
							cagePlayer(plr)
							task.wait(1)
						end
					end
					task.wait(1)
				end
			end)
		else
			cancelThread("cageAll")
		end
	end,
})

MainTab:Toggle({
	Title = "Nuke All (Teleport Delete)",
	Callback = function(state)
		states.nukeAll = state
		if state then
			startThread("nukeAll", function()
				local SPOOF_RADIUS = 20
				while states.nukeAll do
					local parts = {}
					for _, v in ipairs(builtFolder:GetDescendants()) do
						if v:IsA("BasePart") and v.Parent then table.insert(parts, v) end
					end
					for _, part in ipairs(parts) do
						if not states.nukeAll then break end
						if part and part.Parent then
							if character and character.PrimaryPart then
								pcall(function() character:PivotTo(part.CFrame) end)
							end
							local pos = part.Position
							for _, v in ipairs(builtFolder:GetDescendants()) do
								if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= SPOOF_RADIUS then
									task.spawn(function() pcall(function() destroyRemote:InvokeServer(v) end) end)
								end
							end
							task.wait(0.05)
						end
					end
					task.wait(0.1)
				end
			end)
		else
			cancelThread("nukeAll")
		end
	end,
})

-- Touch Fling
MainTab:Toggle({
	Title = "Touch Fling",
	Callback = function(state)
		states.touchFling = state
		if state then
			local function connectTouch()
				if not character then return end
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						local con = part.Touched:Connect(function(hit)
							if not states.touchFling then return end
							local hitPlr = Players:GetPlayerFromCharacter(hit.Parent)
							if hitPlr and hitPlr ~= player then
								task.spawn(function()
									SkidFling(hitPlr, function() return states.touchFling end)
								end)
							end
						end)
						-- Store connection? Not needed for simple implementation.
					end
				end
			end
			connectTouch()
			player.CharacterAdded:Connect(connectTouch)
		end
	end,
})

-- ==================== AURA TAB ====================
local AuraTab = Window:Tab({ Title = "Aura", Icon = "solar:star-bold" })
local auraTargetDropdown = AuraTab:Section({ Title = "Aura Target" }):Dropdown({
	Title = "Select Aura Target",
	Values = {},
	AllowNone = true,
	Callback = function(value)
		if value then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Name == value and plr ~= player then
					auraTarget = plr
					return
				end
			end
		else
			auraTarget = nil
		end
	end,
})
refreshTargetDropdown(auraTargetDropdown)
Players.PlayerAdded:Connect(function() refreshTargetDropdown(auraTargetDropdown) end)
Players.PlayerRemoving:Connect(function(p)
	if auraTarget == p then auraTarget = nil; auraTargetDropdown:Select(nil) end
	refreshTargetDropdown(auraTargetDropdown)
end)

-- Aura Toggle and Sliders
local auraSpeed = 0.3
local auraClearDist = 20
local auraOrbitDist = 20
local auraAngle = 0

AuraTab:Toggle({
	Title = "Destroy Aura",
	Callback = function(state)
		states.aura = state
		if state then
			startThread("aura", function()
				while states.aura do
					local source = builtFolder
					local target = auraTarget
					if target and target.Character and target.Character.PrimaryPart then
						local tpos = target.Character.PrimaryPart.Position
						local dynamicR = auraOrbitDist + math.sin(auraAngle*0.5)*5
						local offset = Vector3.new(
							math.cos(auraAngle)*dynamicR,
							2+math.sin(auraAngle*2)*10,
							math.sin(auraAngle)*dynamicR
						)
						local myPos = tpos + offset
						if character and character.PrimaryPart then
							pcall(function() character:PivotTo(CFrame.new(myPos)) end)
						end
						task.spawn(function()
							for _, v in ipairs(source:GetDescendants()) do
								if v:IsA("BasePart") and v.Parent and (v.Position - myPos).Magnitude <= auraClearDist then
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
									if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= auraClearDist then
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
			cancelThread("aura")
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
	Callback = function(value) auraClearDist = value end,
})
AuraTab:Slider({
	Title = "Orbit Distance",
	Step = 1,
	Value = { Min = 5, Max = 50, Default = 20 },
	Callback = function(value) auraOrbitDist = value end,
})

-- ==================== SPAMMER TAB ====================
local SpammerTab = Window:Tab({ Title = "Spammer", Icon = "solar:layers-bold" })
local spammerDelay = 0.1
SpammerTab:Toggle({
	Title = "Block Spammer",
	Callback = function(state)
		states.spammer = state
		if state then
			startThread("spammer", function()
				while states.spammer do
					if character and character.PrimaryPart then
						local center = character.PrimaryPart.Position
						local r = math.random() * 20
						local theta = math.random() * math.pi*2
						local phi = math.random() * math.pi
						local pos = center + Vector3.new(
							r * math.cos(theta) * math.sin(phi),
							r * math.sin(theta) * math.sin(phi),
							r * math.cos(phi)
						)
						placeBlock("Glass", pos)
					end
					task.wait(spammerDelay)
				end
			end)
		else
			cancelThread("spammer")
		end
	end,
})
SpammerTab:Slider({
	Title = "Delay (s)",
	Step = 0.01,
	Value = { Min = 0.01, Max = 2, Default = 0.1 },
	Callback = function(value) spammerDelay = value end,
})

-- ==================== LOCAL PLAYER TAB ====================
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

LocalTab:Toggle({
	Title = "Fly",
	Callback = function(state)
		states.fly = state
		if state then
			if character and character.PrimaryPart and character:FindFirstChildOfClass("Humanoid") then
				local hum = character:FindFirstChildOfClass("Humanoid")
				hum.PlatformStand = true
				local bodyGyro = Instance.new("BodyGyro", character.PrimaryPart)
				bodyGyro.CFrame = character.PrimaryPart.CFrame
				bodyGyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
				local bodyVel = Instance.new("BodyVelocity", character.PrimaryPart)
				bodyVel.MaxForce = Vector3.new(9e9,9e9,9e9)
				bodyVel.Velocity = Vector3.zero
				local flyConn
				flyConn = RunService.Heartbeat:Connect(function()
					if not states.fly then flyConn:Disconnect(); return end
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
				-- Cleanup on toggle off
				local cleanup
				cleanup = function()
					if bodyGyro then bodyGyro:Destroy() end
					if bodyVel then bodyVel:Destroy() end
					if flyConn then flyConn:Disconnect() end
					if hum then hum.PlatformStand = false end
				end
				task.spawn(function()
					while states.fly do task.wait() end
					cleanup()
				end)
			end
		else
			-- The cleanup is handled by the watcher above
		end
	end,
})

LocalTab:Toggle({
	Title = "Noclip",
	Callback = function(state)
		states.noclip = state
		local function setNoclip()
			if character then
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = not state end
				end
			end
		end
		if state then
			setNoclip()
			states.noclipConn = RunService.Stepped:Connect(setNoclip)
		else
			if states.noclipConn then states.noclipConn:Disconnect() end
			setNoclip()
		end
	end,
})

-- ==================== VISUALS TAB ====================
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })

VisualsTab:Toggle({
	Title = "Fullbright",
	Callback = function(state)
		Lighting.Brightness = state and 2 or 1
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = not state
	end,
})

VisualsTab:Toggle({
	Title = "Player ESP",
	Callback = function(state)
		local espFolder = workspace:FindFirstChild("ESP_Folder") or Instance.new("Folder", workspace)
		espFolder.Name = "ESP_Folder"
		if not state then
			for _, v in ipairs(espFolder:GetChildren()) do v:Destroy() end
			return
		end
		local function createESP(plr)
			if plr == player then return end
			local function onCharAdded(char)
				local highlight = Instance.new("Highlight")
				highlight.FillColor = Color3.fromRGB(255,0,0)
				highlight.OutlineColor = Color3.fromRGB(255,255,255)
				highlight.FillTransparency = 0.5
				highlight.Adornee = char
				highlight.Parent = espFolder
			end
			if plr.Character then onCharAdded(plr.Character) end
			plr.CharacterAdded:Connect(onCharAdded)
		end
		for _, plr in ipairs(Players:GetPlayers()) do createESP(plr) end
		Players.PlayerAdded:Connect(createESP)
	end,
})

VisualsTab:Toggle({
	Title = "Wireframe",
	Callback = function(state)
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				pcall(function()
					obj.Material = state and Enum.Material.Wireframe or Enum.Material.Plastic
				end)
			end
		end
	end,
})

-- ==================== STOP ALL ====================
Window:Button({
	Title = "STOP ALL",
	Color = Color3.fromRGB(255,0,0),
	Callback = function()
		for name, _ in pairs(states) do
			if type(states[name]) == "boolean" then
				states[name] = false
			end
		end
		-- Cancel all threads
		for name, thread in pairs(threads) do
			task.cancel(thread)
		end
		table.clear(threads)
		-- Reset toggle UI to off (need references but we can skip)
		WindUI:Notify({ Title = "Stopped", Content = "All tasks deactivated.", Duration = 2 })
	end,
})

-- ==================== Load Notification ====================
WindUI:Notify({ Title = "Exploit Pack Loaded", Content = "All features ready!", Duration = 3 })
print("Build Exploit Pack – Final Fixed Version Loaded")