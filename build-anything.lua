-- Build Exploit Pack – Universal Stable (WindUI)
-- Removed executor-specific checks, use _G for fling state, general fixes.

-- Load WindUI
local WindUI = nil
local success, result = pcall(function()
    if game:GetService("RunService"):IsStudio() then
        return require(game:GetService("ReplicatedStorage"):WaitForChild("WindUI"):WaitForChild("Init"))
    else
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end)
if success then WindUI = result
else
    game:GetService("StarterGui"):SetCore("SendNotification",{Title="Error",Text="WindUI failed: "..tostring(result)})
    return
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

-- Character
local character
local function onChar(char) character = char; char:WaitForChild("HumanoidRootPart") end
if player.Character then onChar(player.Character) end
player.CharacterAdded:Connect(onChar)

-- Remotes
local events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
local placeRemote = events:WaitForChild("Place")          -- (blockType, CFrame, Baseplate)
local destroyRemote = events:WaitForChild("DestroyBlock") -- (part)
local baseplate = workspace:WaitForChild("Baseplate", 10) or workspace
local builtFolder = workspace:FindFirstChild("Built") or Instance.new("Folder", workspace)
builtFolder.Name = "Built"

-- Fling state stored in _G
_G.OldPos = nil
_G.FPDH = workspace.FallenPartsDestroyHeight

-- Feature management
local activeFeatures = {}  -- [name] = thread
local function stopFeature(name)
    if activeFeatures[name] then
        task.cancel(activeFeatures[name])
        activeFeatures[name] = nil
    end
end
local function startFeature(name, loopFunc)
    stopFeature(name)
    activeFeatures[name] = task.spawn(loopFunc)
end

-- Utility
local function placeBlock(blockType, pos)
    local cf = CFrame.new(math.round(pos.X), math.round(pos.Y), math.round(pos.Z))
    pcall(function()
        placeRemote:InvokeServer(blockType, cf, baseplate)
    end)
end

local function cagePlayer(target)
    if not target or not target.Character or not target.Character.PrimaryPart then return end
    local root = target.Character.PrimaryPart
    -- Teleport local player for proximity
    if character and character.PrimaryPart then
        pcall(function() character:PivotTo(root.CFrame + Vector3.new(0,2,0)) end)
    end
    local center = root.Position
    for x = -2,2 do for y = -2,2 do for z = -2,2 do
        if x==0 and y==0 and z==0 then continue end
        placeBlock("Glass", center + Vector3.new(x*4, y*4, z*4))
    end end end
end

local function destroyAllParts(folder)
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") then
            task.spawn(function() pcall(function() destroyRemote:InvokeServer(v) end) end)
        end
    end
end

-- Fling function (uses a global flag to stop)
local function SkidFling(target, flagRef)
    local char = character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    local tChar = target.Character
    if not tChar then return end
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    local tRoot = tHum and tHum.RootPart
    local tHead = tChar:FindFirstChild("Head")
    local acc = tChar:FindFirstChildOfClass("Accessory")
    local handle = acc and acc:FindFirstChild("Handle")
    if not char or not hum or not root then return end
    if root.Velocity.Magnitude < 50 then _G.OldPos = root.CFrame end
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
        until tick()-t0 > 2 or not flagRef()
    end

    workspace.FallenPartsDestroyHeight = 0/0
    local bv = Instance.new("BodyVelocity"); bv.Parent = root; bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    if tRoot then SF(tRoot) elseif tHead then SF(tHead) elseif handle then SF(handle) end
    bv:Destroy(); hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = hum
    if _G.OldPos then
        repeat
            root.CFrame = _G.OldPos * CFrame.new(0,.5,0)
            char:SetPrimaryPartCFrame(_G.OldPos * CFrame.new(0,.5,0))
            hum:ChangeState("GettingUp")
            for _, p in pairs(char:GetChildren()) do if p:IsA("BasePart") then p.Velocity, p.RotVelocity = Vector3.new(), Vector3.new() end end
            task.wait()
        until (root.Position - _G.OldPos.p).Magnitude < 25 or not flagRef()
        workspace.FallenPartsDestroyHeight = _G.FPDH
    end
end

-- UI
local Window = WindUI:CreateWindow({
    Title = "Build Exploit Pack",
    Folder = "BuildExploit",
    Icon = "solar:hammer-bold",
    OpenButton = { Title = "Open", Enabled = true },
})

local function refreshDropdown(dd)
    local names = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then table.insert(names, plr.Name) end
    end
    dd:Refresh(names)
end

-- ============ TARGET TAB ============
local TargetTab = Window:Tab({ Title = "Target", Icon = "solar:user-bold" })
local selectedTarget = nil
local targetDropdown = TargetTab:Section({ Title = "Select Target" }):Dropdown({
    Title = "Target Player", Values = {}, AllowNone = true,
    Callback = function(v)
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name == v and plr ~= player then selectedTarget = plr return end
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
            startFeature("flingTarget", function()
                while activeFeatures["flingTarget"] do
                    if not selectedTarget then task.wait(1); continue end
                    if not selectedTarget.Parent then selectedTarget = nil; break end
                    local flag = function() return activeFeatures["flingTarget"] ~= nil end
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
            startFeature("cageTarget", function()
                while activeFeatures["cageTarget"] do
                    if not selectedTarget then task.wait(1); continue end
                    cagePlayer(selectedTarget)
                    task.wait(0.5)
                end
            end)
        else stopFeature("cageTarget") end
    end,
})
TargetActions:Toggle({
    Title = "Nuke Target",
    Callback = function(state)
        if state then
            startFeature("nukeTarget", function()
                local radius = 20
                while activeFeatures["nukeTarget"] do
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
                        if not activeFeatures["nukeTarget"] then break end
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
                                task.spawn(function() pcall(function() destroyRemote:InvokeServer(d) end) end)
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

-- ============ MAIN TAB ============
local MainTab = Window:Tab({ Title = "Main", Icon = "solar:globus-bold" })
MainTab:Section({ Title = "Destroy All" }):Button({
    Title = "🗑️ DESTROY ALL",
    Color = Color3.fromRGB(220,20,20),
    Callback = function()
        destroyAllParts(builtFolder)
        WindUI:Notify({ Title = "Done", Content = "All parts destroyed." })
    end,
})
MainTab:Toggle({
    Title = "Fling All",
    Callback = function(state)
        if state then
            startFeature("flingAll", function()
                while activeFeatures["flingAll"] do
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= player then
                            local flag = function() return activeFeatures["flingAll"] ~= nil end
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
MainTab:Toggle({
    Title = "Cage All",
    Callback = function(state)
        if state then
            startFeature("cageAll", function()
                while activeFeatures["cageAll"] do
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= player then cagePlayer(plr); task.wait(0.5) end
                    end
                    task.wait(1)
                end
            end)
        else stopFeature("cageAll") end
    end,
})
MainTab:Toggle({
    Title = "Nuke All",
    Callback = function(state)
        if state then
            startFeature("nukeAll", function()
                local radius = 20
                while activeFeatures["nukeAll"] do
                    local parts = {}
                    pcall(function()
                        for _, v in ipairs(builtFolder:GetDescendants()) do
                            if v:IsA("BasePart") and v.Parent then table.insert(parts, v) end
                        end
                    end)
                    for _, part in ipairs(parts) do
                        if not activeFeatures["nukeAll"] then break end
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
                                task.spawn(function() pcall(function() destroyRemote:InvokeServer(d) end) end)
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

-- ============ AURA TAB ============
local AuraTab = Window:Tab({ Title = "Aura", Icon = "solar:star-bold" })
local auraTarget = nil
local auraDropdown = AuraTab:Section({ Title = "Aura Target" }):Dropdown({
    Title = "Select Target", Values = {}, AllowNone = true,
    Callback = function(v)
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Name == v and plr ~= player then auraTarget = plr return end
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

local auraSpeed, auraClear, auraOrbit = 0.3, 20, 20
local auraAngle = 0

AuraTab:Toggle({
    Title = "Destroy Aura",
    Callback = function(state)
        if state then
            startFeature("aura", function()
                while activeFeatures["aura"] do
                    local t = auraTarget
                    if t and t.Character and t.Character.PrimaryPart then
                        local tpos = t.Character.PrimaryPart.Position
                        local dynR = auraOrbit + math.sin(auraAngle*0.5)*5
                        local off = Vector3.new(math.cos(auraAngle)*dynR, 2+math.sin(auraAngle*2)*10, math.sin(auraAngle)*dynR)
                        local myPos = tpos + off
                        if character and character.PrimaryPart then
                            pcall(function() character:PivotTo(CFrame.new(myPos)) end)
                        end
                        task.spawn(function()
                            for _, v in ipairs(builtFolder:GetDescendants()) do
                                if v:IsA("BasePart") and v.Parent and (v.Position - myPos).Magnitude <= auraClear then
                                    pcall(function() destroyRemote:InvokeServer(v) end)
                                end
                            end
                        end)
                        auraAngle += auraSpeed
                    elseif character and character.PrimaryPart then
                        local pos = character.PrimaryPart.Position
                        task.spawn(function()
                            for _, v in ipairs(builtFolder:GetDescendants()) do
                                if v:IsA("BasePart") and v.Parent and (v.Position - pos).Magnitude <= auraClear then
                                    pcall(function() destroyRemote:InvokeServer(v) end)
                                end
                            end
                        end)
                    end
                    task.wait()
                end
            end)
        else stopFeature("aura") end
    end,
})
AuraTab:Slider({ Title = "Speed", Step = 0.01, Value = { Min=0.05, Max=1, Default=0.3 }, Callback = function(v) auraSpeed = v end })
AuraTab:Slider({ Title = "Clear Dist", Step = 1, Value = { Min=5, Max=50, Default=20 }, Callback = function(v) auraClear = v end })
AuraTab:Slider({ Title = "Orbit Dist", Step = 1, Value = { Min=5, Max=50, Default=20 }, Callback = function(v) auraOrbit = v end })

-- ============ SPAMMER TAB ============
local SpammerTab = Window:Tab({ Title = "Spammer", Icon = "solar:layers-bold" })
local spamDelay = 0.1
SpammerTab:Toggle({
    Title = "Block Spammer",
    Callback = function(state)
        if state then
            startFeature("spammer", function()
                while activeFeatures["spammer"] do
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
                    task.wait(spamDelay)
                end
            end)
        else stopFeature("spammer") end
    end,
})
SpammerTab:Slider({ Title = "Delay (s)", Step = 0.01, Value = { Min=0.01, Max=2, Default=0.1 }, Callback = function(v) spamDelay = v end })

-- ============ LOCAL PLAYER ============
local LocalTab = Window:Tab({ Title = "Local", Icon = "solar:user-speak-bold" })
LocalTab:Slider({ Title = "WalkSpeed", Step=1, Value={Min=16,Max=200,Default=16}, Callback=function(v)
    if character and character:FindFirstChildOfClass("Humanoid") then character:FindFirstChildOfClass("Humanoid").WalkSpeed = v end
end })
LocalTab:Slider({ Title = "JumpPower", Step=1, Value={Min=50,Max=300,Default=50}, Callback=function(v)
    if character and character:FindFirstChildOfClass("Humanoid") then character:FindFirstChildOfClass("Humanoid").JumpPower = v end
end })
LocalTab:Slider({ Title = "HipHeight", Step=0.1, Value={Min=0,Max=5,Default=0}, Callback=function(v)
    if character and character:FindFirstChildOfClass("Humanoid") then character:FindFirstChildOfClass("Humanoid").HipHeight = v end
end })
LocalTab:Slider({ Title = "Gravity", Step=0.01, Value={Min=0,Max=196.2,Default=196.2}, Callback=function(v) workspace.Gravity = v end })

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
                startFeature("fly", function()
                    local conn = RunService.Heartbeat:Connect(function()
                        if not activeFeatures["fly"] then conn:Disconnect(); return end
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
                    while activeFeatures["fly"] do task.wait() end
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
            startFeature("noclip", function()
                while activeFeatures["noclip"] do task.wait() end
                conn:Disconnect()
                if character then for _, p in ipairs(character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
            end)
        else stopFeature("noclip") end
    end,
})

-- ============ VISUALS ============
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

-- ============ STOP ALL ============
Window:Button({
    Title = "STOP ALL",
    Color = Color3.fromRGB(255,0,0),
    Callback = function()
        for name in pairs(activeFeatures) do
            stopFeature(name)
        end
        WindUI:Notify({ Title = "Stopped", Content = "All tasks deactivated." })
    end,
})

WindUI:Notify({ Title = "Build Exploit Pack", Content = "All features ready!" })
print("Build Exploit Pack – Universal Stable Loaded.")