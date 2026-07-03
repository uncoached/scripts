-- Build Exploit Pack – Final Robust (WindUI)
-- Simplified UI, all features, test place button.

local WindUI = nil
local success, result = pcall(function()
    if game:GetService("RunService"):IsStudio() then
        return require(game:GetService("ReplicatedStorage"):WaitForChild("WindUI"):WaitForChild("Init"))
    else
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end)
if not success then
    game:GetService("StarterGui"):SetCore("SendNotification",{Title="Error",Text="WindUI: "..tostring(result)})
    return
end
WindUI = result

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

-- Character update helper
local function getChar()
    local c = player.Character
    if c and c:FindFirstChild("HumanoidRootPart") then return c end
    return nil
end

-- Remotes
local events = game:GetService("ReplicatedStorage"):WaitForChild("Events")
local placeRemote = events:WaitForChild("Place")          -- (string, CFrame, Instance)
local destroyRemote = events:WaitForChild("DestroyBlock") -- (Instance)
local baseplate = workspace:FindFirstChild("Baseplate") or workspace
local builtFolder = workspace:FindFirstChild("Built") or Instance.new("Folder", workspace)
builtFolder.Name = "Built"

-- Fling globals
_G.OldPos = nil
_G.FPDH = workspace.FallenPartsDestroyHeight

-- Thread manager
local tasks = {}
local function stop(name)
    if tasks[name] then
        task.cancel(tasks[name])
        tasks[name] = nil
    end
end
local function start(name, fn)
    stop(name)
    tasks[name] = task.spawn(fn)
end

-- ================= Utility =================
local function placeBlock(blockType, pos)
    local cf = CFrame.new(math.round(pos.X), math.round(pos.Y), math.round(pos.Z))
    print("PLACE", blockType, "at", cf.Position)
    pcall(function()
        placeRemote:InvokeServer(blockType, cf, baseplate)
    end)
end

local function destroyAllParts(folder)
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") then
            task.spawn(function()
                pcall(function() destroyRemote:InvokeServer(v) end)
            end)
        end
    end
end

local function cagePlayer(target)
    local char = getChar()
    if not target or not target.Character or not target.Character.PrimaryPart then return end
    local root = target.Character.PrimaryPart
    if char and char.PrimaryPart then
        pcall(function() char:PivotTo(root.CFrame + Vector3.new(0,2,0)) end)
    end
    local center = root.Position
    for x = -2,2 do for y = -2,2 do for z = -2,2 do
        if x==0 and y==0 and z==0 then continue end
        placeBlock("Glass", center + Vector3.new(x*4, y*4, z*4))
    end end end
end

local function fling(target)
    local char = getChar()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    local tChar = target.Character
    if not tChar or not hum or not root then return end
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    local tRoot = tHum and tHum.RootPart
    local tHead = tChar:FindFirstChild("Head")
    local acc = tChar:FindFirstChildOfClass("Accessory")
    local handle = acc and acc:FindFirstChild("Handle")
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
        until tick()-t0 > 2 or not tasks["fling"]
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
        until (root.Position - _G.OldPos.p).Magnitude < 25 or not tasks["fling"]
        workspace.FallenPartsDestroyHeight = _G.FPDH
    end
end

-- ================= UI =================
local Window = WindUI:CreateWindow({
    Title = "Build Exploit Pack",
    Folder = "BuildExploit",
    Icon = "solar:hammer-bold",
    OpenButton = { Title = "Open", Enabled = true },
})

-- Helper to refresh dropdown
local function fillPlayers(dropdown)
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(names, p.Name) end
    end
    dropdown:Refresh(names)
end

-- ===== Test Build =====
Window:Tab({ Title = "Test", Icon = "solar:tools-bold" }):Button({
    Title = "Place Glass at My Position",
    Callback = function()
        local char = getChar()
        if char and char.PrimaryPart then
            placeBlock("Glass", char.PrimaryPart.Position)
        end
    end,
})

-- ===== Target Tab =====
local TargetTab = Window:Tab({ Title = "Target", Icon = "solar:user-bold" })
local targetPlayer = nil
local targetDropdown
targetDropdown = TargetTab:Dropdown({
    Title = "Target Player",
    Values = {},
    AllowNone = true,
    Callback = function(v)
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name == v and p ~= player then targetPlayer = p; return end
            end
        else targetPlayer = nil end
    end,
})
fillPlayers(targetDropdown)
Players.PlayerAdded:Connect(function() fillPlayers(targetDropdown) end)
Players.PlayerRemoving:Connect(function(p)
    if targetPlayer == p then targetPlayer = nil; targetDropdown:Select(nil) end
    fillPlayers(targetDropdown)
end)

TargetTab:Toggle({
    Title = "Fling Target",
    Callback = function(state)
        if state then
            start("flingTarget", function()
                while tasks["flingTarget"] do
                    if not targetPlayer then task.wait(1); continue end
                    if not targetPlayer.Parent then targetPlayer = nil; break end
                    start("fling", function() end) -- dummy
                    tasks["fling"] = tasks["flingTarget"]
                    fling(targetPlayer)
                    tasks["fling"] = nil
                    task.wait(0.5)
                end
            end)
        else stop("flingTarget") end
    end,
})
TargetTab:Toggle({
    Title = "Cage Target",
    Callback = function(state)
        if state then
            start("cageTarget", function()
                while tasks["cageTarget"] do
                    if not targetPlayer then task.wait(1); continue end
                    cagePlayer(targetPlayer)
                    task.wait(0.5)
                end
            end)
        else stop("cageTarget") end
    end,
})
TargetTab:Toggle({
    Title = "Nuke Target",
    Callback = function(state)
        if state then
            start("nukeTarget", function()
                while tasks["nukeTarget"] do
                    if not targetPlayer then task.wait(0.5); continue end
                    local folder = builtFolder:FindFirstChild(targetPlayer.Name)
                    if not folder then task.wait(0.5); continue end
                    destroyAllParts(folder)
                    task.wait(0.5)
                end
            end)
        else stop("nukeTarget") end
    end,
})
TargetTab:Button({
    Title = "Teleport to Target",
    Callback = function()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character.PrimaryPart then
            local char = getChar()
            if char and char.PrimaryPart then
                pcall(function() char:PivotTo(targetPlayer.Character.PrimaryPart.CFrame + Vector3.new(0,2,0)) end)
            end
        end
    end,
})

-- ===== Main Tab =====
local MainTab = Window:Tab({ Title = "Main", Icon = "solar:globus-bold" })
MainTab:Button({
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
            start("flingAll", function()
                while tasks["flingAll"] do
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player then
                            start("fling", function() end)
                            tasks["fling"] = tasks["flingAll"]
                            fling(p)
                            tasks["fling"] = nil
                            task.wait(0.8)
                        end
                    end
                    task.wait(1)
                end
            end)
        else stop("flingAll") end
    end,
})
MainTab:Toggle({
    Title = "Cage All",
    Callback = function(state)
        if state then
            start("cageAll", function()
                while tasks["cageAll"] do
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= player then cagePlayer(p); task.wait(0.5) end
                    end
                    task.wait(1)
                end
            end)
        else stop("cageAll") end
    end,
})
MainTab:Toggle({
    Title = "Nuke All",
    Callback = function(state)
        if state then
            start("nukeAll", function()
                while tasks["nukeAll"] do
                    destroyAllParts(builtFolder)
                    task.wait(0.5)
                end
            end)
        else stop("nukeAll") end
    end,
})

-- ===== Aura Tab =====
local AuraTab = Window:Tab({ Title = "Aura", Icon = "solar:star-bold" })
local auraTarget = nil
local auraDropdown = AuraTab:Dropdown({
    Title = "Aura Target",
    Values = {},
    AllowNone = true,
    Callback = function(v)
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name == v and p ~= player then auraTarget = p; return end
            end
        else auraTarget = nil end
    end,
})
fillPlayers(auraDropdown)
Players.PlayerAdded:Connect(function() fillPlayers(auraDropdown) end)
Players.PlayerRemoving:Connect(function(p)
    if auraTarget == p then auraTarget = nil; auraDropdown:Select(nil) end
    fillPlayers(auraDropdown)
end)

local auraSpeed, auraClear, auraOrbit = 0.3, 20, 20
local auraAngle = 0

AuraTab:Toggle({
    Title = "Destroy Aura",
    Callback = function(state)
        if state then
            start("aura", function()
                while tasks["aura"] do
                    local t = auraTarget
                    local char = getChar()
                    if t and t.Character and t.Character.PrimaryPart then
                        local tpos = t.Character.PrimaryPart.Position
                        local dynR = auraOrbit + math.sin(auraAngle*0.5)*5
                        local off = Vector3.new(math.cos(auraAngle)*dynR, 2+math.sin(auraAngle*2)*10, math.sin(auraAngle)*dynR)
                        local myPos = tpos + off
                        if char and char.PrimaryPart then
                            pcall(function() char:PivotTo(CFrame.new(myPos)) end)
                        end
                        task.spawn(function()
                            for _, v in ipairs(builtFolder:GetDescendants()) do
                                if v:IsA("BasePart") and v.Parent and (v.Position - myPos).Magnitude <= auraClear then
                                    pcall(function() destroyRemote:InvokeServer(v) end)
                                end
                            end
                        end)
                        auraAngle += auraSpeed
                    elseif char and char.PrimaryPart then
                        local pos = char.PrimaryPart.Position
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
        else stop("aura") end
    end,
})
AuraTab:Slider({ Title = "Speed", Step = 0.01, Value = {Min=0.05,Max=1,Default=0.3}, Callback = function(v) auraSpeed = v end })
AuraTab:Slider({ Title = "Clear Dist", Step = 1, Value = {Min=5,Max=50,Default=20}, Callback = function(v) auraClear = v end })
AuraTab:Slider({ Title = "Orbit Dist", Step = 1, Value = {Min=5,Max=50,Default=20}, Callback = function(v) auraOrbit = v end })

-- ===== Spammer Tab =====
local SpammerTab = Window:Tab({ Title = "Spammer", Icon = "solar:layers-bold" })
local spamDelay = 0.05
SpammerTab:Toggle({
    Title = "Fill Sphere (20r)",
    Callback = function(state)
        if state then
            start("spammer", function()
                local radius = 20
                while tasks["spammer"] do
                    local char = getChar()
                    if char and char.PrimaryPart then
                        local center = char.PrimaryPart.Position
                        -- fill sphere with blocks
                        for x = -radius, radius do
                            if not tasks["spammer"] then break end
                            for y = -radius, radius do
                                if not tasks["spammer"] then break end
                                for z = -radius, radius do
                                    if not tasks["spammer"] then break end
                                    local pos = Vector3.new(center.X + x, center.Y + y, center.Z + z)
                                    if (pos - center).Magnitude <= radius then
                                        placeBlock("Glass", pos)
                                        if spamDelay > 0 then task.wait(spamDelay) end
                                    end
                                end
                            end
                        end
                    else
                        task.wait(0.5)
                    end
                    task.wait(0.5)
                end
            end)
        else stop("spammer") end
    end,
})
SpammerTab:Slider({ Title = "Delay (s)", Step = 0.001, Value = {Min=0,Max=0.5,Default=0.05}, Callback = function(v) spamDelay = v end })

-- ===== Local Tab =====
local LocalTab = Window:Tab({ Title = "Local", Icon = "solar:user-speak-bold" })
LocalTab:Slider({ Title = "WalkSpeed", Step=1, Value={Min=16,Max=200,Default=16}, Callback = function(v)
    local char = getChar()
    if char and char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid").WalkSpeed = v end
end })
LocalTab:Slider({ Title = "JumpPower", Step=1, Value={Min=50,Max=300,Default=50}, Callback = function(v)
    local char = getChar()
    if char and char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid").JumpPower = v end
end })
LocalTab:Slider({ Title = "HipHeight", Step=0.1, Value={Min=0,Max=5,Default=0}, Callback = function(v)
    local char = getChar()
    if char and char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid").HipHeight = v end
end })
LocalTab:Slider({ Title = "Gravity", Step=0.01, Value={Min=0,Max=196.2,Default=196.2}, Callback = function(v) workspace.Gravity = v end })

LocalTab:Toggle({
    Title = "Fly",
    Callback = function(state)
        if state then
            local char = getChar()
            if char and char.PrimaryPart and char:FindFirstChildOfClass("Humanoid") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                hum.PlatformStand = true
                local gyro = Instance.new("BodyGyro", char.PrimaryPart)
                gyro.CFrame = char.PrimaryPart.CFrame; gyro.MaxTorque = Vector3.new(9e9,9e9,9e9)
                local vel = Instance.new("BodyVelocity", char.PrimaryPart)
                vel.MaxForce = Vector3.new(9e9,9e9,9e9)
                start("fly", function()
                    local conn = RunService.Heartbeat:Connect(function()
                        if not tasks["fly"] then conn:Disconnect(); return end
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
                    while tasks["fly"] do task.wait() end
                    conn:Disconnect()
                    gyro:Destroy(); vel:Destroy()
                    hum.PlatformStand = false
                end)
            end
        else stop("fly") end
    end,
})
LocalTab:Toggle({
    Title = "Noclip",
    Callback = function(state)
        if state then
            local function apply()
                local char = getChar()
                if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
            end
            apply()
            local conn = RunService.Stepped:Connect(apply)
            start("noclip", function()
                while tasks["noclip"] do task.wait() end
                conn:Disconnect()
                local char = getChar()
                if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
            end)
        else stop("noclip") end
    end,
})

-- ===== Visuals Tab =====
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
        for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
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

-- ===== Stop All =====
Window:Button({
    Title = "STOP ALL",
    Color = Color3.fromRGB(255,0,0),
    Callback = function()
        for name in pairs(tasks) do
            stop(name)
        end
        WindUI:Notify({ Title = "Stopped", Content = "All tasks deactivated." })
    end,
})

WindUI:Notify({ Title = "Build Exploit Pack", Content = "Loaded. Use Test tab to verify place." })
print("Build Exploit Pack – Final Robust Loaded.")