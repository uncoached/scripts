-- Minimal GUI Build Exploit Pack – No external UI library, works on all exploits.
-- Uses remote: PlaceBlockEvent & DestroyBlockEven (exact spelling from spy).
-- Features: Cage, TNT spam, Sphere fill, Orbit, Fling, Scatter 5 blocks.

--==== Services ====
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

--==== Remotes (exact names) ====
local placeEvent = ReplicatedStorage:WaitForChild("PlaceBlockEvent", 10)
local destroyEvent = ReplicatedStorage:WaitForChild("DestroyBlockEven", 10)
if not placeEvent or not destroyEvent then
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title="Error", Text="Remote not found!"}) end)
    return
end

--==== Character ====
local character
local function onCharAdded(char)
    character = char
    char:WaitForChild("HumanoidRootPart")
end
if player.Character then onCharAdded(player.Character) end
player.CharacterAdded:Connect(onCharAdded)

--==== Fling globals ====
getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

--==== Thread management ====
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
    local thread = task.spawn(function() loopFunc(flag) end)
    activeFeatures[name] = { thread = thread, running = flag }
end

--==== Placer (50 concurrent) ====
local MAX_CONCURRENT = 50
local activePlaces = 0
local placeQueue = {}
local function processQueue()
    while #placeQueue > 0 and activePlaces < MAX_CONCURRENT do
        local job = table.remove(placeQueue, 1)
        activePlaces = activePlaces + 1
        task.spawn(function()
            pcall(job.fn)
            activePlaces = activePlaces - 1
            processQueue()
        end)
    end
end
local function placeBlock(blockType, pos)
    table.insert(placeQueue, {
        fn = function()
            local uuid = "{" .. HttpService:GenerateGUID(false) .. "}"
            placeEvent:FireServer(pos, blockType, 0, uuid, "Block")
        end
    })
    processQueue()
end

--==== Destroy ====
local function destroyBlock(part)
    if not part or not part.Parent then return end
    local uuid = part.Name
    if not uuid or uuid == "" then return end
    local temp = Instance.new("Part")
    temp.Parent = nil
    pcall(function() destroyEvent:FireServer(temp, uuid) end)
    temp:Destroy()
end

local function getAllBlocks()
    local blocks = {}
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part:GetAttribute("BlockType") ~= nil then
            local model = part:FindFirstAncestorOfClass("Model")
            if not model or not Players:GetPlayerFromCharacter(model) then
                table.insert(blocks, part)
            end
        end
    end
    return blocks
end

local function destroyAll()
    for _, part in ipairs(getAllBlocks()) do
        task.spawn(function() destroyBlock(part) end)
    end
end

--==== Cage (teleports to target, fills 5x5 grid) ====
local function cagePlayer(target)
    if not target or not target.Character or not target.Character.PrimaryPart then return end
    local root = target.Character.PrimaryPart
    if character and character.PrimaryPart then
        pcall(function() character:PivotTo(root.CFrame + Vector3.new(0,2,0)) end)
    end
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

--==== Fling ====
local function fling(targetPlayer, flag)
    local Character = character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = targetPlayer.Character
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
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle),0,0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0,0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90),0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90),0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0,0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90),0,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0,0,0))
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

--==== GUI Setup ====
local gui = Instance.new("ScreenGui")
gui.Parent = game:GetService("CoreGui")
gui.Name = "BuildExploit"
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 250, 0, 350)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Size = UDim2.new(1,0,0,30)
titleLabel.BackgroundColor3 = Color3.fromRGB(50,50,50)
titleLabel.Text = "Build Exploit Pack"
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.Font = Enum.Font.SourceSansBold

local function createButton(text, y, callback)
    local btn = Instance.new("TextButton", mainFrame)
    btn.Size = UDim2.new(1,-10,0,28)
    btn.Position = UDim2.new(0,5,0,y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.SourceSans
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createToggle(text, y, state, callback)
    local frame = Instance.new("Frame", mainFrame)
    frame.Size = UDim2.new(1,-10,0,28)
    frame.Position = UDim2.new(0,5,0,y)
    frame.BackgroundColor3 = Color3.fromRGB(70,70,70)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7,0,1,0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.3,0,1,0)
    btn.Position = UDim2.new(0.7,0,0,0)
    btn.Text = state and "ON" or "OFF"
    btn.BackgroundColor3 = state and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.SourceSansBold

    local active = state
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.Text = active and "ON" or "OFF"
        btn.BackgroundColor3 = active and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
        callback(active)
    end)
    return frame
end

local selectedTarget = nil
local function refreshDropdown(drop, callback)
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then table.insert(names, plr.Name) end
    end
    table.sort(names)
    -- Clear old items
    for _, child in ipairs(drop:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, name in ipairs(names) do
        local btn = Instance.new("TextButton", drop)
        btn.Size = UDim2.new(1,0,0,20)
        btn.Text = name
        btn.BackgroundColor3 = Color3.fromRGB(90,90,90)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.SourceSans
        btn.MouseButton1Click:Connect(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name == name then
                    selectedTarget = plr
                    if callback then callback(plr) end
                    break
                end
            end
        end)
    end
end

-- Target dropdown area
local targetDropFrame = Instance.new("Frame", mainFrame)
targetDropFrame.Size = UDim2.new(1,-10,0,28)
targetDropFrame.Position = UDim2.new(0,5,0,45)
targetDropFrame.BackgroundColor3 = Color3.fromRGB(60,60,60)
local targetDropLabel = Instance.new("TextLabel", targetDropFrame)
targetDropLabel.Size = UDim2.new(1,0,1,0)
targetDropLabel.Text = "Target: None"
targetDropLabel.TextColor3 = Color3.fromRGB(255,255,255)
targetDropLabel.Font = Enum.Font.SourceSans
targetDropLabel.BackgroundTransparency = 1

local targetDropList = Instance.new("Frame", mainFrame)
targetDropList.Size = UDim2.new(1,-10,0,150)
targetDropList.Position = UDim2.new(0,5,0,73)
targetDropList.BackgroundColor3 = Color3.fromRGB(50,50,50)
targetDropList.Visible = false

targetDropFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        targetDropList.Visible = not targetDropList.Visible
        if targetDropList.Visible then
            refreshDropdown(targetDropList, function(plr)
                targetDropLabel.Text = "Target: " .. plr.Name
                targetDropList.Visible = false
            end)
        end
    end
end)

local yOffset = 230
createButton("Teleport to Target", yOffset, function()
    if selectedTarget and selectedTarget.Character and selectedTarget.Character.PrimaryPart and character and character.PrimaryPart then
        pcall(function() character:PivotTo(selectedTarget.Character.PrimaryPart.CFrame + Vector3.new(0,2,0)) end)
    end
end); yOffset = yOffset + 32

createButton("Scatter 5 Blocks", yOffset, function()
    if character and character.PrimaryPart then
        local pos = character.PrimaryPart.Position
        for _=1,5 do
            local offset = Vector3.new(math.random(-10,10), math.random(-5,5), math.random(-10,10))
            placeBlock("Oak Planks", pos + offset)
        end
    end
end); yOffset = yOffset + 32

createButton("Destroy All", yOffset, function() destroyAll() end); yOffset = yOffset + 32

createToggle("Fling Target", yOffset, false, function(state)
    if state then
        startFeature("flingTarget", function(flag)
            while flag.running do
                if selectedTarget then fling(selectedTarget, flag) else task.wait(1) end
                task.wait(0.5)
            end
        end)
    else stopFeature("flingTarget") end
end); yOffset = yOffset + 32

createToggle("Cage Target", yOffset, false, function(state)
    if state then
        startFeature("cageTarget", function(flag)
            while flag.running do
                if selectedTarget then cagePlayer(selectedTarget) end
                task.wait(0.01)
            end
        end)
    else stopFeature("cageTarget") end
end); yOffset = yOffset + 32

createToggle("TNT Spam", yOffset, false, function(state)
    if state then
        startFeature("tntSpam", function(flag)
            while flag.running do
                if selectedTarget and selectedTarget.Character and selectedTarget.Character.PrimaryPart then
                    local root = selectedTarget.Character.PrimaryPart
                    if character and character.PrimaryPart then
                        pcall(function() character:PivotTo(root.CFrame + Vector3.new(0,2,0)) end)
                    end
                    local center = root.Position
                    for x=-2,2 do for y=-2,2 do for z=-2,2 do
                        if x==0 and y==0 and z==0 then continue end
                        placeBlock("TNT", center + Vector3.new(x*4,y*4,z*4))
                    end end end
                end
                task.wait(0.05)
            end
        end)
    else stopFeature("tntSpam") end
end); yOffset = yOffset + 32

-- Spammer (r=13 sphere) – separate target selection
local spamTarget = nil
local spamDropFrame = Instance.new("Frame", mainFrame)
spamDropFrame.Size = UDim2.new(1,-10,0,28)
spamDropFrame.Position = UDim2.new(0,5,0,yOffset)
spamDropFrame.BackgroundColor3 = Color3.fromRGB(60,60,60)
local spamLabel = Instance.new("TextLabel", spamDropFrame)
spamLabel.Size = UDim2.new(1,0,1,0)
spamLabel.Text = "Spam Target: None"
spamLabel.TextColor3 = Color3.fromRGB(255,255,255)
spamLabel.Font = Enum.Font.SourceSans
spamLabel.BackgroundTransparency = 1
yOffset = yOffset + 32

local spamList = Instance.new("Frame", mainFrame)
spamList.Size = UDim2.new(1,-10,0,150)
spamList.Position = UDim2.new(0,5,0,yOffset)
spamList.BackgroundColor3 = Color3.fromRGB(50,50,50)
spamList.Visible = false
spamDropFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        spamList.Visible = not spamList.Visible
        if spamList.Visible then
            refreshDropdown(spamList, function(plr)
                spamTarget = plr
                spamLabel.Text = "Spam Target: " .. plr.Name
                spamList.Visible = false
            end)
        end
    end
end)
yOffset = yOffset + 155

local sphereOffsets = {}
for x=-13,13 do for y=-13,13 do for z=-13,13 do
    if math.sqrt(x*x+y*y+z*z) <= 13 then table.insert(sphereOffsets, Vector3.new(x,y,z)) end
end end end

createToggle("Sphere Fill (r=13)", yOffset, false, function(state)
    if state then
        startFeature("spammer", function(flag)
            while flag.running do
                if spamTarget and spamTarget.Character and spamTarget.Character.PrimaryPart then
                    local center = spamTarget.Character.PrimaryPart.Position
                    for _, off in ipairs(sphereOffsets) do
                        if not flag.running then return end
                        placeBlock("Glass", center + off)
                    end
                else task.wait(0.5) end
            end
        end)
    else stopFeature("spammer") end
end); yOffset = yOffset + 32

-- Orbit
local orbitTarget = nil
local orbitDropFrame = Instance.new("Frame", mainFrame)
orbitDropFrame.Size = UDim2.new(1,-10,0,28)
orbitDropFrame.Position = UDim2.new(0,5,0,yOffset)
orbitDropFrame.BackgroundColor3 = Color3.fromRGB(60,60,60)
local orbitLabel = Instance.new("TextLabel", orbitDropFrame)
orbitLabel.Size = UDim2.new(1,0,1,0)
orbitLabel.Text = "Orbit Target: None"
orbitLabel.TextColor3 = Color3.fromRGB(255,255,255)
orbitLabel.Font = Enum.Font.SourceSans
orbitLabel.BackgroundTransparency = 1
yOffset = yOffset + 32

local orbitList = Instance.new("Frame", mainFrame)
orbitList.Size = UDim2.new(1,-10,0,150)
orbitList.Position = UDim2.new(0,5,0,yOffset)
orbitList.BackgroundColor3 = Color3.fromRGB(50,50,50)
orbitList.Visible = false
orbitDropFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        orbitList.Visible = not orbitList.Visible
        if orbitList.Visible then
            refreshDropdown(orbitList, function(plr)
                orbitTarget = plr
                orbitLabel.Text = "Orbit Target: " .. plr.Name
                orbitList.Visible = false
            end)
        end
    end
end)
yOffset = yOffset + 155

local orbitAngle = 0
createToggle("Orbit", yOffset, false, function(state)
    if state then
        startFeature("orbit", function(flag)
            while flag.running do
                if orbitTarget and orbitTarget.Character and orbitTarget.Character.PrimaryPart then
                    local tpos = orbitTarget.Character.PrimaryPart.Position
                    local angle = orbitAngle
                    local h = Vector3.new(math.cos(angle)*20, 0, math.sin(angle)*20)
                    local y = tpos.Y + 2
                    local myPos = tpos + h + Vector3.new(0,y,0)
                    if character and character.PrimaryPart then
                        pcall(function() character:PivotTo(CFrame.new(myPos)) end)
                    end
                    -- destroy nearby blocks
                    task.spawn(function()
                        for _, part in ipairs(getAllBlocks()) do
                            if (part.Position - myPos).Magnitude <= 20 then
                                destroyBlock(part)
                            end
                        end
                    end)
                    orbitAngle = orbitAngle + 0.3
                elseif character and character.PrimaryPart then
                    local pos = character.PrimaryPart.Position
                    task.spawn(function()
                        for _, part in ipairs(getAllBlocks()) do
                            if (part.Position - pos).Magnitude <= 20 then
                                destroyBlock(part)
                            end
                        end
                    end)
                end
                task.wait()
            end
        end)
    else stopFeature("orbit") end
end); yOffset = yOffset + 32

createButton("STOP ALL", yOffset, function()
    for name in pairs(activeFeatures) do stopFeature(name) end
end)

mainFrame.Size = UDim2.new(0, 250, 0, yOffset + 35)