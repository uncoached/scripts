-- Adapted Build Exploit Pack: Spammer centered on target, cage follows without teleport.
-- Remotes: ReplicatedStorage.Remotes.DestroyBlock (FireServer with Model)
--          ReplicatedStorage.Remotes.PlaceBlock (InvokeServer with blockType, CFrame)

local WindUI = nil
pcall(function()
    if game:GetService("RunService"):IsStudio() then
        WindUI = require(game:GetService("ReplicatedStorage"):WaitForChild("WindUI"):WaitForChild("Init"))
    else
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end)
if not WindUI then return end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

-- Character reference
local character = nil
local function onCharAdded(char)
    character = char
    char:WaitForChild("HumanoidRootPart")
end
if player.Character then onCharAdded(player.Character) end
player.CharacterAdded:Connect(onCharAdded)

-- Remotes
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local placeRemote = remotes:WaitForChild("PlaceBlock")   -- InvokeServer(blockType, CFrame)
local destroyRemote = remotes:WaitForChild("DestroyBlock") -- FireServer(Model)

local builtFolder = workspace:FindFirstChild("Built") or Instance.new("Folder", workspace)
builtFolder.Name = "Built"

-- Fling globals
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- Thread management
local activeFeatures = {}
local function stopFeature(name)
    if activeFeatures[name] then
        activeFeatures[name].running = false
        task.cancel(activeFeatures[name].thread)
        activeFeatures[name] = nil
    end
end
local function startFeature(name, loopFunc)
    stopFeature(name)
    local flag = { running = true }
    local thread = task.spawn(function()
        loopFunc(flag)
    end)
    activeFeatures[name] = { thread = thread, running = flag }
end

-- Place block helper – exact CFrame (0,0,1,0,1,0,-1,0,0), no Baseplate
local function placeBlock(blockType, pos)
    local roundedPos = Vector3.new(math.round(pos.X), math.round(pos.Y), math.round(pos.Z))
    local cf = CFrame.new(roundedPos.X, roundedPos.Y, roundedPos.Z, 0, 0, 1, 0, 1, 0, -1, 0, 0)
    pcall(function()
        placeRemote:InvokeServer(blockType, cf)
    end)
end

-- Destroy a single part by wrapping it in a Model for the remote
local function destroyPart(part)
    if not part or not part.Parent then return end
    local tempModel = Instance.new("Model")
    part.Parent = tempModel
    pcall(function()
        destroyRemote:FireServer(tempModel)
    end)
    tempModel:Destroy()
end

-- Cage a player – no teleport, just place blocks around target
local function cagePlayer(target)
    if not target or not target.Character or not target.Character.PrimaryPart then return end
    local root = target.Character.PrimaryPart
    local center = root.Position
    for x = -2,2 do
        for y = -2,2 do
            for z = -2,2 do
                if x==0 and y==0 and z==0 then continue end
                placeBlock("Glass", center + Vector3.new(x*4, y*4, z*4))
            end
        end
    end
end

-- Destroy all parts in folder
local function destroyAllParts(folder)
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") then
            task.spawn(function() destroyPart(v) end)
        end
    end
end

-- Fling function (unchanged)
local function SkidFling(TargetPlayer, flag)
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
        if RootPart.Velocity.Magnitude < 50 then getgenv().OldPos = RootPart.CFrame end
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
            until Time + TimeToWait < tick() or not flag.running
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
            until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25 or not flag.running
            workspace.FallenPartsDestroyHeight = getgenv().FPDH
        end
    end
end

-- ==================== UI ====================
local Window = WindUI:CreateWindow({
    Title = "Build Exploit Pack",
    Folder = "BuildExploit",
    Icon = "solar:hammer-bold",
    OpenButton = { Title = "Open", Enabled = true },
})

local function refreshDropdown(dropdown)
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then table.insert(names, plr.Name) end
    end
    dropdown:Refresh(names)
end

-- TARGET TAB
local TargetTab = Window:Tab({ Title = "Target", Icon = "solar:user-bold" })
local selectedTarget = nil
local targetDropdown = TargetTab:Section({ Title = "Select Target" }):Dropdown({
    Title = "Target Player", Values = {}, AllowNone = true,
    Callback = function(value)
        if value then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name == value and plr ~= player then selectedTarget = plr return end
            end
        else selectedTarget = nil end
    end,
})
refreshDropdown(targetDropdown)
Players.PlayerAdded:Connect(function() refreshDropdown(targetDropdown) end)
Players.PlayerRemoving:Connect(function(p)
    if selectedTarget == p then selectedTarget = nil; targetDropdown:Select(nil) end
    refreshDropdown(targetDropdown)
end)

local TargetActions = TargetTab:Section({ Title = "Actions" })

TargetActions:Toggle({
    Title = "Fling Target",
    Callback = function(state)
        if state then
            startFeature("flingTarget", function(flag)
                while flag.running do
                    if not selectedTarget then task.wait(1); continue end
                    if not selectedTarget.Parent then selectedTarget = nil; break end
                    SkidFling(selectedTarget, flag)
                    task.wait(0.5)
                end
            end)
        else stopFeature("flingTarget") end
    end,
})

TargetActions:Toggle({
    Title = "Cage Target",
    Callback = function(state)
        if state then
            startFeature("cageTarget", function(flag)
                while flag.running do
                    if not selectedTarget then task.wait(1); continue end
                    cagePlayer(selectedTarget)  -- now no teleport, just places blocks
                    task.wait(0.3)  -- faster interval
                end
            end)
        else stopFeature("cageTarget") end
    end,
})

TargetActions:Toggle({
    Title = "Nuke Target",
    Callback = function(state)
        if state then
            startFeature("nukeTarget", function(flag)
                local radius = 20
                while flag.running do
                    if not selectedTarget then task.wait(0.5); continue end
                    local folder = builtFolder:FindFirstChild(selectedTarget.Name)
                    if not folder then task.wait(0.5); continue end
                    local parts = {}
                    pcall(function()
                        for _, v in ipairs(folder:GetDescendants()) do
                            if v:IsA("BasePart") and v.Parent then table.insert(parts, v) end
                        end
                    end)
                    for _, part in ipairs(parts) do
                        if not flag.running then break end
                        if part and part.Parent then
                            if character and character.PrimaryPart then
                                pcall(function() character:PivotTo(part.CFrame) end)
                            end
                            local pos = part.Position
                            local toDelete = {}
                            pcall(function()
                                for _, v in ipairs(folder:GetDescendants()) do
                                    if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= radius then
                                        table.insert(toDelete, v)
                                    end
                                end
                            end)
                            for _, d in ipairs(toDelete) do
                                task.spawn(function() destroyPart(d) end)
                            end
                            task.wait(0.05)
                        end
                    end
                    task.wait(0.3)
                end
            end)
        else stopFeature("nukeTarget") end
    end,
})

TargetActions:Button({
    Title = "Teleport to Target",
    Callback = function()
        if selectedTarget and selectedTarget.Character and selectedTarget.Character.PrimaryPart then
            if character and character.PrimaryPart then
                pcall(function() character:PivotTo(selectedTarget.Character.PrimaryPart.CFrame + Vector3.new(0,2,0)) end)
            end
        end
    end,
})

-- MAIN TAB
local MainTab = Window:Tab({ Title = "Main", Icon = "solar:globus-bold" })

MainTab:Section({ Title = "Destroy All" }):Button({
    Title = "🗑️ DESTROY ALL",
    Color = Color3.fromRGB(220,20,20),
    Callback = function()
        destroyAllParts(builtFolder)
        WindUI:Notify({ Title = "Done", Content = "All parts destroyed." })
    end,
})

-- Place Blocks (Once) with speed slider
local placeDelay = 0.005
MainTab:Button({
    Title = "🧱 PLACE BLOCKS (Once)",
    Callback = function()
        local totalBlocks = 5000
        local heightLayers = 1
        local centerPos = character and character.PrimaryPart and character.PrimaryPart.Position or Vector3.new(0,2,0)
        local blocksPerLayer = math.ceil(totalBlocks / heightLayers)
        local gridSize = math.ceil(math.sqrt(blocksPerLayer))
        local blockType = "Oak Planks"
        local placed = 0
        for layer = 0, heightLayers - 1 do
            local count = 0
            for x = -gridSize, gridSize do
                for z = -gridSize, gridSize do
                    if count >= blocksPerLayer then break end
                    local posX = centerPos.X + (x * 4)
                    local posZ = centerPos.Z + (z * 4)
                    local posY = centerPos.Y + (layer * 4) + 2
                    placeBlock(blockType, Vector3.new(posX, posY, posZ))
                    placed = placed + 1
                    count = count + 1
                    if placeDelay > 0 then task.wait(placeDelay) end
                end
                if count >= blocksPerLayer then break end
            end
        end
        WindUI:Notify({ Title = "Placed", Content = "Placed " .. placed .. " blocks." })
    end,
})

MainTab:Slider({
    Title = "Place Delay (s)",
    Step = 0.001,
    Value = { Min = 0, Max = 0.1, Default = 0.005 },
    Callback = function(v) placeDelay = v end,
})

-- Fling All
MainTab:Toggle({
    Title = "Fling All",
    Callback = function(state)
        if state then
            startFeature("flingAll", function(flag)
                while flag.running do
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= player then
                            SkidFling(plr, flag)
                            task.wait(0.8)
                        end
                    end
                    task.wait(1)
                end
            end)
        else stopFeature("flingAll") end
    end,
})

-- Cage All
MainTab:Toggle({
    Title = "Cage All",
    Callback = function(state)
        if state then
            startFeature("cageAll", function(flag)
                while flag.running do
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= player then
                            cagePlayer(plr)
                            task.wait(0.3)
                        end
                    end
                    task.wait(1)
                end
            end)
        else stopFeature("cageAll") end
    end,
})

-- Nuke All
MainTab:Toggle({
    Title = "Nuke All",
    Callback = function(state)
        if state then
            startFeature("nukeAll", function(flag)
                local radius = 20
                while flag.running do
                    local parts = {}
                    pcall(function()
                        for _, v in ipairs(builtFolder:GetDescendants()) do
                            if v:IsA("BasePart") and v.Parent then table.insert(parts, v) end
                        end
                    end)
                    for _, part in ipairs(parts) do
                        if not flag.running then break end
                        if part and part.Parent then
                            if character and character.PrimaryPart then
                                pcall(function() character:PivotTo(part.CFrame) end)
                            end
                            local pos = part.Position
                            local toDelete = {}
                            pcall(function()
                                for _, v in ipairs(builtFolder:GetDescendants()) do
                                    if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= radius then
                                        table.insert(toDelete, v)
                                    end
                                end
                            end)
                            for _, d in ipairs(toDelete) do
                                task.spawn(function() destroyPart(d) end)
                            end
                            task.wait(0.05)
                        end
                    end
                    task.wait(0.3)
                end
            end)
        else stopFeature("nukeAll") end
    end,
})

-- ==================== ORBIT TAB ====================
local OrbitTab = Window:Tab({ Title = "Orbit", Icon = "solar:star-bold" })
local auraTarget = nil
local auraDropdown = OrbitTab:Section({ Title = "Orbit Target" }):Dropdown({
    Title = "Select Target", Values = {}, AllowNone = true,
    Callback = function(value)
        if value then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name == value and plr ~= player then auraTarget = plr return end
            end
        else auraTarget = nil end
    end,
})
refreshDropdown(auraDropdown)
Players.PlayerAdded:Connect(function() refreshDropdown(auraDropdown) end)
Players.PlayerRemoving:Connect(function(p)
    if auraTarget == p then auraTarget = nil; auraDropdown:Select(nil) end
    refreshDropdown(auraDropdown)
end)

-- Orbit parameters
local orbitSpeed = 0.3
local orbitClearDist = 20
local orbitRadius = 20
local orbitMinHeight = -5
local orbitMaxHeight = 10
local orbitYOffset = 0
local orbitAngle = 0

OrbitTab:Toggle({
    Title = "Orbit",
    Callback = function(state)
        if state then
            startFeature("orbit", function(flag)
                while flag.running do
                    local target = auraTarget
                    if target and target.Character and target.Character.PrimaryPart then
                        local tpos = target.Character.PrimaryPart.Position
                        local hPos = Vector3.new(math.cos(orbitAngle) * orbitRadius, 0, math.sin(orbitAngle) * orbitRadius)
                        local yOffset = orbitYOffset
                        local minH = orbitMinHeight
                        local maxH = orbitMaxHeight
                        local t = (math.sin(orbitAngle * 2) + 1) / 2
                        local y = tpos.Y + yOffset + minH + (maxH - minH) * t
                        local myPos = Vector3.new(tpos.X + hPos.X, y, tpos.Z + hPos.Z)

                        if character and character.PrimaryPart then
                            pcall(function() character:PivotTo(CFrame.new(myPos)) end)
                        end
                        task.spawn(function()
                            for _, v in ipairs(builtFolder:GetDescendants()) do
                                if v:IsA("BasePart") and v.Parent and (v.Position - myPos).Magnitude <= orbitClearDist then
                                    destroyPart(v)
                                end
                            end
                        end)
                        orbitAngle = orbitAngle + orbitSpeed
                    elseif character and character.PrimaryPart then
                        local pos = character.PrimaryPart.Position
                        task.spawn(function()
                            for _, v in ipairs(builtFolder:GetDescendants()) do
                                if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= orbitClearDist then
                                    destroyPart(v)
                                end
                            end
                        end)
                    end
                    task.wait()
                end
            end)
        else
            stopFeature("orbit")
        end
    end,
})

OrbitTab:Slider({ Title = "Speed", Step = 0.01, Value = { Min = 0.05, Max = 1, Default = 0.3 }, Callback = function(v) orbitSpeed = v end })
OrbitTab:Slider({ Title = "Clear Dist", Step = 1, Value = { Min = 5, Max = 50, Default = 20 }, Callback = function(v) orbitClearDist = v end })
OrbitTab:Slider({ Title = "Orbit Radius", Step = 1, Value = { Min = 5, Max = 50, Default = 20 }, Callback = function(v) orbitRadius = v end })
OrbitTab:Slider({ Title = "Min Height", Step = 1, Value = { Min = -10, Max = 10, Default = -5 }, Callback = function(v) orbitMinHeight = v end })
OrbitTab:Slider({ Title = "Max Height", Step = 1, Value = { Min = -10, Max = 20, Default = 10 }, Callback = function(v) orbitMaxHeight = v end })
OrbitTab:Slider({ Title = "Y Offset", Step = 1, Value = { Min = -10, Max = 10, Default = 0 }, Callback = function(v) orbitYOffset = v end })

-- SPAMMER TAB (Radius 13) – now follows a selected target
local SpammerTab = Window:Tab({ Title = "Spammer", Icon = "solar:layers-bold" })
local spamTarget = nil
local spamDropdown = SpammerTab:Section({ Title = "Spammer Target" }):Dropdown({
    Title = "Select Target", Values = {}, AllowNone = true,
    Callback = function(value)
        if value then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name == value and plr ~= player then spamTarget = plr return end
            end
        else spamTarget = nil end
    end,
})
refreshDropdown(spamDropdown)
Players.PlayerAdded:Connect(function() refreshDropdown(spamDropdown) end)
Players.PlayerRemoving:Connect(function(p)
    if spamTarget == p then spamTarget = nil; spamDropdown:Select(nil) end
    refreshDropdown(spamDropdown)
end)

local spamDelay = 0
-- Precompute offsets for sphere radius 13
local sphereOffsets = {}
for x = -13,13 do
    for y = -13,13 do
        for z = -13,13 do
            if math.sqrt(x*x + y*y + z*z) <= 13 then
                table.insert(sphereOffsets, Vector3.new(x, y, z))
            end
        end
    end
end

SpammerTab:Toggle({
    Title = "Sphere Fill (r=13)",
    Callback = function(state)
        if state then
            startFeature("spammer", function(flag)
                while flag.running do
                    local target = spamTarget
                    if target and target.Character and target.Character.PrimaryPart then
                        local center = target.Character.PrimaryPart.Position
                        for _, offset in ipairs(sphereOffsets) do
                            if not flag.running then return end
                            placeBlock("Glass", center + offset)
                            if spamDelay > 0 then task.wait(spamDelay) end
                        end
                        -- loop immediately to keep filling (sphere moves with target)
                    else
                        task.wait(0.5)
                    end
                end
            end)
        else
            stopFeature("spammer")
        end
    end,
})
SpammerTab:Slider({
    Title = "Delay (s)",
    Step = 0.001,
    Value = { Min = 0, Max = 0.1, Default = 0 },
    Callback = function(v) spamDelay = v end,
})

-- LOCAL PLAYER TAB
local LocalTab = Window:Tab({ Title = "Local", Icon = "solar:user-speak-bold" })
LocalTab:Slider({ Title = "WalkSpeed", Step = 1, Value = { Min = 16, Max = 200, Default = 16 }, Callback = function(v)
    if character and character:FindFirstChildOfClass("Humanoid") then character:FindFirstChildOfClass("Humanoid").WalkSpeed = v end
end })
LocalTab:Slider({ Title = "JumpPower", Step = 1, Value = { Min = 50, Max = 300, Default = 50 }, Callback = function(v)
    if character and character:FindFirstChildOfClass("Humanoid") then character:FindFirstChildOfClass("Humanoid").JumpPower = v end
end })
LocalTab:Slider({ Title = "HipHeight", Step = 0.1, Value = { Min = 0, Max = 5, Default = 0 }, Callback = function(v)
    if character and character:FindFirstChildOfClass("Humanoid") then character:FindFirstChildOfClass("Humanoid").HipHeight = v end
end })
LocalTab:Slider({ Title = "Gravity", Step = 0.01, Value = { Min = 0, Max = 196.2, Default = 196.2 }, Callback = function(v) workspace.Gravity = v end })

LocalTab:Toggle({
    Title = "Fly",
    Callback = function(state)
        if state then
            if character and character.PrimaryPart and character:FindFirstChildOfClass("Humanoid") then
                local hum = character:FindFirstChildOfClass("Humanoid")
                hum.PlatformStand = true
                local gyro = Instance.new("BodyGyro", character.PrimaryPart)
                gyro.CFrame = character.PrimaryPart.CFrame; gyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
                local vel = Instance.new("BodyVelocity", character.PrimaryPart)
                vel.MaxForce = Vector3.new(9e9,9e9,9e9)
                startFeature("fly", function(flag)
                    local conn = RunService.Heartbeat:Connect(function()
                        if not flag.running then conn:Disconnect(); return end
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
                    while flag.running do task.wait() end
                    conn:Disconnect()
                    gyro:Destroy(); vel:Destroy()
                    hum.PlatformStand = false
                end)
            end
        else stopFeature("fly") end
    end,
})

LocalTab:Toggle({
    Title = "Noclip",
    Callback = function(state)
        if state then
            local function apply()
                if character then for _, p in ipairs(character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
            end
            apply()
            local conn = RunService.Stepped:Connect(apply)
            startFeature("noclip", function(flag)
                while flag.running do task.wait() end
                conn:Disconnect()
                if character then for _, p in ipairs(character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
            end)
        else stopFeature("noclip") end
    end,
})

-- VISUALS TAB
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
        if not state then espFolder:ClearAllChildren(); return end
        local function addESP(plr)
            if plr == player then return end
            local function onChar(char)
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255,0,0)
                hl.OutlineColor = Color3.fromRGB(255,255,255)
                hl.FillTransparency = 0.5
                hl.Adornee = char
                hl.Parent = espFolder
            end
            if plr.Character then onChar(plr.Character) end
            plr.CharacterAdded:Connect(onChar)
        end
        for _, plr in ipairs(Players:GetPlayers()) do addESP(plr) end
        Players.PlayerAdded:Connect(addESP)
    end,
})
VisualsTab:Toggle({
    Title = "Wireframe",
    Callback = function(state)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                pcall(function() obj.Material = state and Enum.Material.Wireframe or Enum.Material.Plastic end)
            end
        end
    end,
})

-- STOP ALL
Window:Button({
    Title = "STOP ALL",
    Color = Color3.fromRGB(255,0,0),
    Callback = function()
        for name in pairs(activeFeatures) do stopFeature(name) end
        WindUI:Notify({ Title = "Stopped", Content = "All tasks deactivated." })
    end,
})

WindUI:Notify({ Title = "Build Exploit Pack", Content = "Spammer follows target, cage no teleport." })
print("Build Exploit Pack – Follow features loaded.")