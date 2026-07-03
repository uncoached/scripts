-- Build Exploit Pack - WindUI Edition (Feature Packed)
-- All essential exploits in a modern, mobile-friendly interface.

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
local player = Players.LocalPlayer

-- Character reference (handles respawn)
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
local replicatedStorage = game:GetService("ReplicatedStorage")
local events = replicatedStorage:WaitForChild("Events")
local placeRemote = events:WaitForChild("Place")          -- args: blockType, CFrame, Baseplate
local destroyRemote = events:WaitForChild("DestroyBlock") -- args: partInstance

local baseplate = workspace:WaitForChild("Baseplate", 10) or workspace
local builtFolder = workspace:FindFirstChild("Built") or Instance.new("Folder", workspace)
builtFolder.Name = "Built"

-- Global fling state
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- Feature states
local selectedTarget = nil

local nukeActive = false
local nukeThread = nil
local nukeTarget = nil  -- nil = all parts, player object = specific target's parts

local flingActive = false
local flingThread = nil

local touchFlingActive = false
local touchConns = {}

local cageActive = false
local cageThread = nil

local auraActive = false
local auraThread = nil
local auraAngle = 0
local auraSpeed = 0.3
local auraClearDist = 20
local auraOrbitDist = 20

local spammerActive = false
local spammerThread = nil
local spammerDelay = 0.1
local spammerBlockType = "Oak Planks"

-- ==================== Fling Function (reused) ====================
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
			until Time + TimeToWait < tick() or not flingActive
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
			until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25 or not flingActive
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

-- ==================== Main Tab ====================
local MainTab = Window:Tab({ Title = "Main", Icon = "solar:settings-bold" })

-- Target Selection
local TargetSection = MainTab:Section({ Title = "Target Player" })
local targetDropdown = TargetSection:Dropdown({
	Title = "Select Target",
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

local function refreshTargetList()
	local names = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			table.insert(names, plr.Name)
		end
	end
	targetDropdown:Refresh(names)
end
refreshTargetList()
Players.PlayerAdded:Connect(refreshTargetList)
Players.PlayerRemoving:Connect(function(p)
	if selectedTarget == p then
		selectedTarget = nil
		targetDropdown:Select(nil)
	end
	refreshTargetList()
end)

-- Destroy All
local DestroySection = MainTab:Section({ Title = "Destroy All" })
DestroySection:Button({
	Title = "🗑️ DESTROY ALL",
	Color = Color3.fromRGB(220, 20, 20),
	Callback = function()
		local targets = {}
		for _, v in ipairs(builtFolder:GetDescendants()) do
			if v:IsA("BasePart") then table.insert(targets, v) end
		end
		for _, part in ipairs(targets) do
			task.spawn(function() pcall(function() destroyRemote:InvokeServer(part) end) end)
		end
		WindUI:Notify({ Title = "Destroy All", Content = "All parts destroyed", Duration = 2 })
	end,
})

-- Nuke (Spoof Delete)
local NukeSection = MainTab:Section({ Title = "Nuke (Spoof Delete)" })
local nukeToggle = NukeSection:Toggle({
	Title = "Nuke Active",
	Callback = function(state)
		nukeActive = state
		if state then
			nukeTarget = nil -- GUI nuke always global
			nukeThread = task.spawn(function()
				while nukeActive do
					local source = builtFolder
					local part = nil
					for _, v in ipairs(source:GetDescendants()) do
						if v:IsA("BasePart") and v.Parent then
							part = v
							break
						end
					end
					if not part then
						task.wait(0.2)
						continue
					end
					if character and character.PrimaryPart then
						pcall(function() character:PivotTo(part.CFrame) end)
					end
					local pos = part.Position
					for _, v in ipairs(source:GetDescendants()) do
						if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= 20 then
							task.spawn(function() pcall(function() destroyRemote:InvokeServer(v) end) end)
						end
					end
					task.wait(0.05)
				end
			end)
		else
			if nukeThread then task.cancel(nukeThread) end
		end
	end,
})

-- Fling (Continuous)
local FlingSection = MainTab:Section({ Title = "Fling" })
local flingToggle = FlingSection:Toggle({
	Title = "Continuous Fling Target",
	Callback = function(state)
		flingActive = state
		if state then
			flingThread = task.spawn(function()
				while flingActive do
					if not selectedTarget then task.wait(1); continue end
					if not selectedTarget.Parent then
						selectedTarget = nil
						task.wait(1)
						continue
					end
					SkidFling(selectedTarget)
					task.wait(0.5)
				end
			end)
		else
			if flingThread then task.cancel(flingThread) end
		end
	end,
})

-- Touch Fling
local TouchSection = MainTab:Section({ Title = "Touch Fling" })
local touchToggle = TouchSection:Toggle({
	Title = "Touch Fling Active",
	Callback = function(state)
		touchFlingActive = state
		if state then
			local function connectTouch()
				if not character then return end
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						local con = part.Touched:Connect(function(hit)
							if not touchFlingActive then return end
							local hitPlr = Players:GetPlayerFromCharacter(hit.Parent)
							if hitPlr and hitPlr ~= player then
								task.spawn(function()
									-- One-shot fling (simplified)
									local t = hitPlr
									local c = character
									local h = c and c:FindFirstChildOfClass("Humanoid")
									local r = h and h.RootPart
									local tc = t.Character
									if not c or not h or not r or not tc then return end
									local th = tc:FindFirstChildOfClass("Humanoid")
									local tr = th and th.RootPart
									if r.Velocity.Magnitude < 50 then getgenv().OldPos = r.CFrame end
									if th and th.Sit then return end
									workspace.FallenPartsDestroyHeight = 0/0
									local bv = Instance.new("BodyVelocity")
									bv.Parent = r
									bv.Velocity = Vector3.new(0,0,0)
									bv.MaxForce = Vector3.new(9e9,9e9,9e9)
									h:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
									local function FPos(bp, pos, ang)
										r.CFrame = CFrame.new(bp.Position) * pos * ang
										c:SetPrimaryPartCFrame(CFrame.new(bp.Position) * pos * ang)
										r.Velocity = Vector3.new(9e7, 9e7*10, 9e7)
										r.RotVelocity = Vector3.new(9e8,9e8,9e8)
									end
									local ang = 0
									for _ = 1, 3 do
										if tr then
											ang = ang + 100
											FPos(tr, CFrame.new(0,1.5,0)+th.MoveDirection*tr.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(ang),0,0))
											task.wait()
											FPos(tr, CFrame.new(0,-1.5,0)+th.MoveDirection*tr.Velocity.Magnitude/1.25, CFrame.Angles(math.rad(ang),0,0))
											task.wait()
										end
									end
									bv:Destroy()
									h:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
									if getgenv().OldPos then
										repeat
											r.CFrame = getgenv().OldPos * CFrame.new(0,.5,0)
											c:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0,.5,0))
											h:ChangeState("GettingUp")
											for _, p in pairs(c:GetChildren()) do
												if p:IsA("BasePart") then p.Velocity, p.RotVelocity = Vector3.new(), Vector3.new() end
											end
											task.wait()
										until (r.Position - getgenv().OldPos.p).Magnitude < 25
										workspace.FallenPartsDestroyHeight = getgenv().FPDH
									end
								end)
							end
						end)
						table.insert(touchConns, con)
					end
				end
			end
			connectTouch()
			player.CharacterAdded:Connect(function(newChar)
				for _, con in ipairs(touchConns) do con:Disconnect() end
				touchConns = {}
				character = newChar
				connectTouch()
			end)
		else
			for _, con in ipairs(touchConns) do con:Disconnect() end
			touchConns = {}
		end
	end,
})

-- Cage
local CageSection = MainTab:Section({ Title = "Cage" })
local cageToggle = CageSection:Toggle({
	Title = "Cage Target",
	Callback = function(state)
		cageActive = state
		if state then
			cageThread = task.spawn(function()
				local offsets = {}
				for x = -1, 1 do
					for y = -1, 1 do
						for z = -1, 1 do
							if x == 0 and y == 0 and z == 0 then continue end
							table.insert(offsets, Vector3.new(x*4, y*4, z*4))
						end
					end
				end
				while cageActive do
					if not selectedTarget or not selectedTarget.Character or not selectedTarget.Character.PrimaryPart then
						task.wait(1)
						continue
					end
					local targetRoot = selectedTarget.Character.PrimaryPart
					if character and character.PrimaryPart then
						pcall(function() character:PivotTo(targetRoot.CFrame + Vector3.new(0, 2, 0)) end)
					end
					local bp = workspace:FindFirstChild("Baseplate") or workspace
					for _, offset in ipairs(offsets) do
						if not cageActive then break end
						local pos = targetRoot.Position + offset
						pcall(function() placeRemote:InvokeServer("Oak Planks", CFrame.new(pos), bp) end)
						task.wait(0.02)
					end
					task.wait(0.5)
				end
			end)
		else
			if cageThread then task.cancel(cageThread) end
		end
	end,
})

-- ==================== Aura Tab ====================
local AuraTab = Window:Tab({ Title = "Aura", Icon = "solar:star-bold" })
local auraToggle2 = AuraTab:Toggle({
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
						local targetPos = target.Character.PrimaryPart.Position
						local dynamicRadius = auraOrbitDist + math.sin(auraAngle * 0.5) * 5
						local offset = Vector3.new(
							math.cos(auraAngle) * dynamicRadius,
							2 + math.sin(auraAngle * 2) * 10,
							math.sin(auraAngle) * dynamicRadius
						)
						local myPos = targetPos + offset
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
	Callback = function(value) auraClearDist = value end,
})
AuraTab:Slider({
	Title = "Orbit Distance",
	Step = 1,
	Value = { Min = 5, Max = 50, Default = 20 },
	Callback = function(value) auraOrbitDist = value end,
})

-- ==================== Spammer Tab ====================
local SpammerTab = Window:Tab({ Title = "Spammer", Icon = "solar:layers-bold" })
local spammerToggle = SpammerTab:Toggle({
	Title = "Block Spammer Active",
	Callback = function(state)
		spammerActive = state
		if state then
			spammerThread = task.spawn(function()
				while spammerActive do
					local bp = workspace:FindFirstChild("Baseplate") or workspace
					local blockType = spammerBlockType ~= "" and spammerBlockType or "Oak Planks"
					if character and character.PrimaryPart then
						local center = character.PrimaryPart.Position
						local pos = center + Vector3.new(math.random(-8,8), 2, math.random(-8,8))
						pcall(function() placeRemote:InvokeServer(blockType, CFrame.new(pos), bp) end)
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
	Value = "Oak Planks",
	Callback = function(value) spammerBlockType = value end,
})
SpammerTab:Slider({
	Title = "Delay (s)",
	Step = 0.01,
	Value = { Min = 0.01, Max = 2, Default = 0.1 },
	Callback = function(value) spammerDelay = value end,
})

-- ==================== Stop All Button ====================
Window:Button({
	Title = "STOP ALL TASKS",
	Color = Color3.fromRGB(255, 0, 0),
	Callback = function()
		-- Stop nuke
		if nukeActive then
			nukeActive = false
			if nukeThread then task.cancel(nukeThread) end
			nukeToggle:Set(false)
		end
		-- Stop fling
		if flingActive then
			flingActive = false
			if flingThread then task.cancel(flingThread) end
			flingToggle:Set(false)
		end
		-- Stop touch fling
		if touchFlingActive then
			touchFlingActive = false
			for _, con in ipairs(touchConns) do con:Disconnect() end
			touchConns = {}
			touchToggle:Set(false)
		end
		-- Stop cage
		if cageActive then
			cageActive = false
			if cageThread then task.cancel(cageThread) end
			cageToggle:Set(false)
		end
		-- Stop aura
		if auraActive then
			auraActive = false
			if auraThread then task.cancel(auraThread) end
			auraToggle2:Set(false)
		end
		-- Stop spammer
		if spammerActive then
			spammerActive = false
			if spammerThread then task.cancel(spammerThread) end
			spammerToggle:Set(false)
		end
		WindUI:Notify({ Title = "Stopped", Content = "All tasks have been stopped.", Duration = 2 })
	end,
})

-- ==================== Notify Loaded ====================
WindUI:Notify({
	Title = "Exploit Pack Loaded",
	Content = "All features ready!",
	Duration = 3,
})

print("Build Exploit Pack – WindUI Edition Loaded")