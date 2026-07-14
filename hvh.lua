-- Tulip.lua – Ultimate HvH (WindUI) – All UI visible, ESP death fix, Magic Bullet
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
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- Settings
local Settings = {
    SilentAim = { Enabled = false, FOV = 200, HitPart = "Head", VisibleCheck = true, Wallbang = false, TeamCheck = false },
    CameraAim = { Enabled = false, Smoothness = 0.2, FOV = 200, VisibleCheck = true, TeamCheck = false, AimKey = "RightMouse" },
    MagicBullet = { Enabled = false, FOV = 200 },
    Spinbot = { Enabled = false, Speed = 15, PitchAngle = 0 },
    Bhop = false,
    AirJump = false,
    WalkSpeed = 16,
    ThirdPerson = { Enabled = false, Distance = 10 },
    ESP = {
        Enabled = true, Box = true, Name = true, HealthBar = true, Distance = true, Tracers = true, Skeleton = true,
        VisibleOnly = false, OnlyTarget = false, NPCs = true
    },
    Chams = { Enabled = false, FillColor = Color3.fromRGB(255,0,0), OutlineColor = Color3.new(0,0,0) },
    Glow = { Enabled = false, Color = Color3.fromRGB(255,0,0) },
    FOVCircle = false,
}

-- Feature variables
local silentAimTarget, silentAimTargetModel = nil, nil
local cameraAimTarget = nil
local espCache = {}
local chamHighlights = {}
local glowBillboards = {}
local aimKeyHeld = false

-- Utility
local function getHum(c) return c and c:FindFirstChildWhichIsA("Humanoid") end
local function getHead(c) return c and c:FindFirstChild("Head") end
local function getHRP(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function teamCheck(plr) return Settings.SilentAim.TeamCheck and plr.Team == LocalPlayer.Team end
local function isVisible(part)
    local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit and hit:IsDescendantOf(part.Parent)
end

-- Target list (players + npcs)
local function getTargetList()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not teamCheck(plr) then
            local char = plr.Character
            if char and getHum(char) and getHum(char).Health > 0 then table.insert(list, char) end
        end
    end
    if Settings.ESP.NPCs then
        for _, model in ipairs(Workspace:GetDescendants()) do
            if model:IsA("Model") and not Players:GetPlayerFromCharacter(model) then
                local hum = getHum(model)
                if hum and hum.Health > 0 then
                    if getHead(model) and getHRP(model) then table.insert(list, model) end
                end
            end
        end
    end
    return list
end

-- Silent aim target update
local function updateSilentAim()
    if not Settings.SilentAim.Enabled then
        silentAimTarget, silentAimTargetModel = nil, nil; return
    end
    local closest, closestDist, center = nil, Settings.SilentAim.FOV, Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local bestPos, bestModel = nil, nil
    for _, char in ipairs(getTargetList()) do
        local part = (Settings.SilentAim.HitPart=="Head" and getHead(char)) or (Settings.SilentAim.HitPart=="UpperTorso" and char:FindFirstChild("UpperTorso")) or getHRP(char)
        if not part then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < closestDist then
            if not Settings.SilentAim.Wallbang and Settings.SilentAim.VisibleCheck and not isVisible(part) then continue end
            closestDist, bestPos, bestModel = dist, part.Position, char
        end
    end
    silentAimTarget, silentAimTargetModel = bestPos, bestModel
end

-- Silent aim hook
local Hooks = {}
Hooks.Raycast = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod():lower()
    if Settings.SilentAim.Enabled and silentAimTarget and method == "raycast" and self == Workspace then
        local dir = (silentAimTarget - Camera.CFrame.Position).Unit * 200
        args[2] = dir
        return Hooks.Raycast(self, unpack(args))
    end
    return Hooks.Raycast(self, ...)
end))

-- Magic Bullet: When you fire, shoots all visible enemies in FOV
local magicBulletRemote = nil
local function findRemote()
    if magicBulletRemote then return magicBulletRemote end
    local remotes = RS:FindFirstChild("Remotes")
    if remotes then
        magicBulletRemote = remotes:FindFirstChild("FireBullet") or remotes:FindFirstChild("Shoot") or remotes:FindFirstChild("WeaponFire")
    end
    return magicBulletRemote
end

local oldFireServer
local function hookMagicBullet()
    local remote = findRemote()
    if not remote or not remote:IsA("RemoteEvent") then return end
    if oldFireServer then return end
    oldFireServer = hookfunction(remote.FireServer, function(self, ...)
        local args = {...}
        if Settings.MagicBullet.Enabled then
            local targets = {}
            for _, char in ipairs(getTargetList()) do
                local head = getHead(char)
                if head and isVisible(head) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                        if dist <= Settings.MagicBullet.FOV then
                            table.insert(targets, char)
                        end
                    end
                end
            end
            for _, targetChar in ipairs(targets) do
                task.spawn(function()
                    oldFireServer(self, targetChar:FindFirstChild("Head") and targetChar.Head.Position or args[1], unpack(args, 2))
                end)
            end
            return
        end
        return oldFireServer(self, ...)
    end)
end
pcall(hookMagicBullet)

-- Camera aimbot
local function updateCameraAim()
    if not Settings.CameraAim.Enabled then return end
    if Settings.CameraAim.AimKey ~= "Always" and not aimKeyHeld then return end
    local closest, closestDist = nil, Settings.CameraAim.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, char in ipairs(getTargetList()) do
        local head = getHead(char)
        if not head then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if dist < closestDist then
            if Settings.CameraAim.VisibleCheck and not isVisible(head) then continue end
            closestDist, closest = dist, char
        end
    end
    if closest then
        local head = getHead(closest)
        if head then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, head.Position), Settings.CameraAim.Smoothness)
        end
    end
end

-- Spinbot
local spinConnection
local function updateSpinbot()
    if spinConnection then spinConnection:Disconnect() end
    if not Settings.Spinbot.Enabled then return end
    spinConnection = RunService.RenderStepped:Connect(function(dt)
        local char = LocalPlayer.Character
        if char then
            local hrp = getHRP(char)
            if hrp then
                hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(Settings.Spinbot.PitchAngle), math.rad(Settings.Spinbot.Speed) * dt, 0)
            end
        end
    end)
end

-- Movement jumps
local bhopConnection, airJumpConnection
local function updateMovementJumps()
    if bhopConnection then bhopConnection:Disconnect() end
    if airJumpConnection then airJumpConnection:Disconnect() end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = getHum(char)
    if not hum then return end
    if Settings.Bhop then
        bhopConnection = hum.StateChanged:Connect(function(_, new)
            if new == Enum.HumanoidStateType.Landed and UIS:IsKeyDown(Enum.KeyCode.Space) then hum.Jump = true end
        end)
    end
    if Settings.AirJump then
        airJumpConnection = hum.StateChanged:Connect(function(_, new)
            if new == Enum.HumanoidStateType.Freefall and UIS:IsKeyDown(Enum.KeyCode.Space) then hum.Jump = true end
        end)
    end
end

-- WalkSpeed & Third Person
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").WalkSpeed = Settings.WalkSpeed
    updateMovementJumps()
    if Settings.ThirdPerson.Enabled then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPerson.Distance
        LocalPlayer.CameraMinZoomDistance = Settings.ThirdPerson.Distance
    end
end)
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = getHum(char)
        if hum then hum.WalkSpeed = Settings.WalkSpeed end
    end
end)
local function updateThirdPerson()
    if Settings.ThirdPerson.Enabled then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPerson.Distance
        LocalPlayer.CameraMinZoomDistance = Settings.ThirdPerson.Distance
    else
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end

-- ESP (Drawing) with death fix
local hasDrawing = pcall(function() return Drawing.new end)
if hasDrawing then
    local function getBonePositions(char)
        local bones = {}
        local head = getHead(char)
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if head and torso then
            bones.Head = head.Position
            bones.Torso = torso.Position
            bones.LeftArm = (char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm") or torso).Position
            bones.RightArm = (char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm") or torso).Position
            bones.LeftLeg = (char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg") or {Position = torso.Position - Vector3.new(0,2,0)}).Position
            bones.RightLeg = (char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg") or {Position = torso.Position - Vector3.new(0,2,0)}).Position
        end
        return bones
    end

    local function createESPobj()
        local esp = {
            boxOutline = Drawing.new("Square"), box = Drawing.new("Square"),
            name = Drawing.new("Text"), distance = Drawing.new("Text"),
            healthOutline = Drawing.new("Line"), healthBar = Drawing.new("Line"),
            tracer = Drawing.new("Line"),
            skeletonLines = {}
        }
        esp.boxOutline.Thickness = 3; esp.boxOutline.Filled = false; esp.boxOutline.Color = Color3.new(0,0,0)
        esp.box.Thickness = 1; esp.box.Filled = false; esp.box.Color = Color3.fromRGB(255,50,50)
        esp.name.Center = true; esp.name.Outline = true; esp.name.Color = Color3.new(1,1,1); esp.name.Size = 16
        esp.distance.Center = true; esp.distance.Outline = true; esp.distance.Color = Color3.new(0.8,0.8,0.8); esp.distance.Size = 13
        esp.healthOutline.Thickness = 3; esp.healthOutline.Color = Color3.new(0,0,0)
        esp.healthBar.Thickness = 1; esp.healthBar.Color = Color3.new(0,1,0)
        esp.tracer.Thickness = 1; esp.tracer.Color = Color3.fromRGB(255,255,255)
        return esp
    end

    local function cleanupESP(target)
        if espCache[target] then
            for _, obj in pairs(espCache[target]) do
                if type(obj) == "table" and obj.Remove then obj:Remove() end
            end
            espCache[target] = nil
        end
    end

    RunService.RenderStepped:Connect(function()
        if not Settings.ESP.Enabled then
            for target, _ in pairs(espCache) do cleanupESP(target) end
            return
        end

        local allowed = {}
        if Settings.ESP.OnlyTarget then
            if silentAimTargetModel and getHum(silentAimTargetModel) and getHum(silentAimTargetModel).Health > 0 and silentAimTargetModel.Parent then
                allowed[silentAimTargetModel] = true
            end
        else
            for _, char in ipairs(getTargetList()) do
                if getHum(char) and getHum(char).Health > 0 and char.Parent then allowed[char] = true end
            end
        end

        -- Remove drawings for dead/removed models
        for model, _ in pairs(espCache) do
            local hum = getHum(model)
            if not hum or hum.Health <= 0 or not model.Parent or not allowed[model] then
                cleanupESP(model)
            end
        end

        -- Draw allowed
        for model, _ in pairs(allowed) do
            local hum = getHum(model)
            local root = getHRP(model)
            local head = getHead(model)
            if not hum or not root or not head then continue end
            if not espCache[model] then espCache[model] = createESPobj() end
            local esp = espCache[model]

            local show = true
            if Settings.ESP.VisibleOnly then show = isVisible(head) end

            local rp, on1 = Camera:WorldToViewportPoint(root.Position)
            local hp, on2 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            local lp = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
            if on1 and on2 and show then
                local boxH = math.abs(hp.Y - lp.Y); local boxW = boxH / 2
                local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)

                if Settings.ESP.Box then
                    esp.boxOutline.Size = Vector2.new(boxW, boxH); esp.boxOutline.Position = Vector2.new(rp.X - boxW/2, hp.Y)
                    esp.boxOutline.Visible = true; esp.box.Size = esp.boxOutline.Size; esp.box.Position = esp.boxOutline.Position; esp.box.Visible = true
                else esp.boxOutline.Visible = false; esp.box.Visible = false end

                if Settings.ESP.HealthBar then
                    local pct = hum.Health / hum.MaxHealth
                    local barX = rp.X - boxW/2 - 6
                    esp.healthOutline.From = Vector2.new(barX, hp.Y - 1); esp.healthOutline.To = Vector2.new(barX, hp.Y + boxH + 1); esp.healthOutline.Visible = true
                    esp.healthBar.From = Vector2.new(barX, hp.Y + boxH); esp.healthBar.To = Vector2.new(barX, hp.Y + boxH - (boxH * pct))
                    esp.healthBar.Color = Color3.new(1 - pct, pct, 0); esp.healthBar.Visible = true
                else esp.healthOutline.Visible = false; esp.healthBar.Visible = false end

                if Settings.ESP.Name then
                    local nm = model.Name
                    local plr = Players:GetPlayerFromCharacter(model)
                    if plr then nm = plr.Name end
                    esp.name.Text = nm; esp.name.Position = Vector2.new(rp.X, hp.Y - 20); esp.name.Visible = true
                else esp.name.Visible = false end

                if Settings.ESP.Distance then
                    esp.distance.Text = "[" .. dist .. "m]"; esp.distance.Position = Vector2.new(rp.X, hp.Y + boxH + 2); esp.distance.Visible = true
                else esp.distance.Visible = false end

                if Settings.ESP.Tracers then
                    esp.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); esp.tracer.To = Vector2.new(rp.X, rp.Y); esp.tracer.Visible = true
                else esp.tracer.Visible = false end

                if Settings.ESP.Skeleton then
                    local bones = getBonePositions(model)
                    for _, line in ipairs(esp.skeletonLines) do line:Remove() end; esp.skeletonLines = {}
                    if bones then
                        local pairs = {{"Head","Torso"},{"Torso","LeftArm"},{"Torso","RightArm"},{"Torso","LeftLeg"},{"Torso","RightLeg"}}
                        for _, pair in ipairs(pairs) do
                            local b1, b2 = bones[pair[1]], bones[pair[2]]
                            if b1 and b2 then
                                local s1, o1 = Camera:WorldToViewportPoint(b1)
                                local s2, o2 = Camera:WorldToViewportPoint(b2)
                                if o1 and o2 then
                                    local line = Drawing.new("Line")
                                    line.From = Vector2.new(s1.X, s1.Y); line.To = Vector2.new(s2.X, s2.Y)
                                    line.Color = Color3.fromRGB(255,255,255); line.Thickness = 1; line.Visible = true
                                    table.insert(esp.skeletonLines, line)
                                end
                            end
                        end
                    end
                else for _, line in ipairs(esp.skeletonLines) do line:Remove() end; esp.skeletonLines = {} end
            else
                for _, v in pairs({esp.boxOutline, esp.box, esp.name, esp.distance, esp.healthOutline, esp.healthBar, esp.tracer}) do v.Visible = false end
                for _, line in ipairs(esp.skeletonLines) do line:Remove() end; esp.skeletonLines = {}
            end
        end
    end)
else
    Settings.ESP.Enabled = false
    warn("Drawing library missing – ESP disabled.")
end

-- Chams & Glow
local function refreshChams()
    for _, hl in pairs(chamHighlights) do hl:Destroy() end
    chamHighlights = {}
    if not Settings.Chams.Enabled then return end
    for _, char in ipairs(getTargetList()) do
        local hl = Instance.new("Highlight")
        hl.FillColor = Settings.Chams.FillColor
        hl.OutlineColor = Settings.Chams.OutlineColor
        hl.Parent = char
        chamHighlights[char] = hl
    end
end
local function refreshGlow()
    for _, g in pairs(glowBillboards) do g:Destroy() end
    glowBillboards = {}
    if not Settings.Glow.Enabled then return end
    for _, char in ipairs(getTargetList()) do
        local glow = Instance.new("BillboardGui")
        glow.Adornee = char
        glow.Size = UDim2.new(10,0,10,0)
        glow.StudsOffset = Vector3.new(0,2,0)
        local frame = Instance.new("Frame", glow)
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundColor3 = Settings.Glow.Color
        frame.BackgroundTransparency = 0.5
        frame.BorderSizePixel = 0
        glow.Parent = char
        glowBillboards[char] = glow
    end
end
RunService.Heartbeat:Connect(function()
    if Settings.Chams.Enabled then refreshChams() end
    if Settings.Glow.Enabled then refreshGlow() end
end)

-- Key handling
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then aimKeyHeld = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then aimKeyHeld = false end
end)

-- FOV circle
local fovCircle
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false; fovCircle.Filled = false
    fovCircle.Color = Color3.fromRGB(255,255,255); fovCircle.Thickness = 1
end)

RunService.RenderStepped:Connect(function()
    updateSilentAim()
    updateCameraAim()
    if Settings.SilentAim.Enabled and Settings.FOVCircle and fovCircle then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        fovCircle.Radius = Settings.SilentAim.FOV
        fovCircle.Visible = true
    elseif fovCircle then
        fovCircle.Visible = false
    end
end)

-- ==================== UI (fixed size, all tabs) ====================
local Window = WindUI:CreateWindow({
    Title = "Tulip",
    Folder = "Tulip",
    Icon = "solar:flower-bold",
    OpenButton = { Title = "Open", Enabled = true },
    Size = UDim2.fromOffset(650, 750),  -- enough vertical space
})

local CombatTab = Window:Tab({ Title = "Combat", Icon = "solar:sword-bold" })
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })
local MovementTab = Window:Tab({ Title = "Movement", Icon = "solar:walk-bold" })
local InfoTab = Window:Tab({ Title = "Info", Icon = "solar:info-bold" })

-- ===== COMBAT =====
local SilentSection = CombatTab:Section({ Title = "Silent Aim" })
SilentSection:Toggle({ Title = "Enabled", Callback = function(v) Settings.SilentAim.Enabled = v end })
SilentSection:Toggle({ Title = "Visibility Check", Value = true, Callback = function(v) Settings.SilentAim.VisibleCheck = v end })
SilentSection:Toggle({ Title = "Wallbang", Value = false, Callback = function(v) Settings.SilentAim.Wallbang = v end })
SilentSection:Toggle({ Title = "Team Check", Value = false, Callback = function(v) Settings.SilentAim.TeamCheck = v end })
SilentSection:Slider({ Title = "FOV", Step = 10, Value = { Min = 10, Max = 500, Default = 200 }, Callback = function(v) Settings.SilentAim.FOV = v end })
SilentSection:Dropdown({ Title = "Hit Part", Values = {"Head","UpperTorso","HumanoidRootPart"}, Value = "Head", Callback = function(v) Settings.SilentAim.HitPart = v end })
SilentSection:Toggle({ Title = "Show FOV Circle", Value = false, Callback = function(v) Settings.FOVCircle = v end })

local CameraSection = CombatTab:Section({ Title = "Camera Aimbot" })
CameraSection:Toggle({ Title = "Enabled", Callback = function(v) Settings.CameraAim.Enabled = v end })
CameraSection:Slider({ Title = "Smoothness", Step = 0.05, Value = { Min = 0.01, Max = 1, Default = 0.2 }, Callback = function(v) Settings.CameraAim.Smoothness = v end })
CameraSection:Slider({ Title = "FOV", Step = 10, Value = { Min = 10, Max = 500, Default = 200 }, Callback = function(v) Settings.CameraAim.FOV = v end })
CameraSection:Toggle({ Title = "Visible Check", Value = true, Callback = function(v) Settings.CameraAim.VisibleCheck = v end })
CameraSection:Toggle({ Title = "Team Check", Value = false, Callback = function(v) Settings.CameraAim.TeamCheck = v end })
CameraSection:Dropdown({ Title = "Aim Key", Values = {"RightMouse","Always"}, Value = "RightMouse", Callback = function(v) Settings.CameraAim.AimKey = v end })

local MagicSection = CombatTab:Section({ Title = "Magic Bullet" })
MagicSection:Toggle({ Title = "Enabled", Callback = function(v) Settings.MagicBullet.Enabled = v end })
MagicSection:Slider({ Title = "FOV", Step = 10, Value = { Min = 10, Max = 500, Default = 200 }, Callback = function(v) Settings.MagicBullet.FOV = v end })

local SpinSection = CombatTab:Section({ Title = "Spinbot" })
SpinSection:Toggle({ Title = "Enabled", Callback = function(v) Settings.Spinbot.Enabled = v; updateSpinbot() end })
SpinSection:Slider({ Title = "Speed", Step = 1, Value = { Min = 1, Max = 100, Default = 15 }, Callback = function(v) Settings.Spinbot.Speed = v end })
SpinSection:Slider({ Title = "Pitch Angle", Step = 5, Value = { Min = -90, Max = 90, Default = 0 }, Callback = function(v) Settings.Spinbot.PitchAngle = v end })

-- ===== MOVEMENT =====
MovementTab:Section({ Title = "Jumps" })
    :Toggle({ Title = "Bunny Hop", Callback = function(v) Settings.Bhop = v; updateMovementJumps() end })
    :Toggle({ Title = "Air Jump", Callback = function(v) Settings.AirJump = v; updateMovementJumps() end })
MovementTab:Section({ Title = "Speed" })
    :Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 50, Default = 16 }, Callback = function(v) Settings.WalkSpeed = v
        local char = LocalPlayer.Character; if char and getHum(char) then getHum(char).WalkSpeed = v end
    end })
MovementTab:Section({ Title = "Camera" })
    :Toggle({ Title = "Third Person", Callback = function(v) Settings.ThirdPerson.Enabled = v; updateThirdPerson() end })
    :Slider({ Title = "Distance", Step = 1, Value = { Min = 5, Max = 30, Default = 10 }, Callback = function(v)
        Settings.ThirdPerson.Distance = v
        if Settings.ThirdPerson.Enabled then
            LocalPlayer.CameraMaxZoomDistance = v; LocalPlayer.CameraMinZoomDistance = v
        end
    end })

-- ===== VISUALS =====
VisualsTab:Section({ Title = "Player ESP" })
    :Toggle({ Title = "Enable ESP", Value = true, Callback = function(v) Settings.ESP.Enabled = v end })
    :Toggle({ Title = "Box", Value = true, Callback = function(v) Settings.ESP.Box = v end })
    :Toggle({ Title = "Name", Value = true, Callback = function(v) Settings.ESP.Name = v end })
    :Toggle({ Title = "Health Bar", Value = true, Callback = function(v) Settings.ESP.HealthBar = v end })
    :Toggle({ Title = "Distance", Value = true, Callback = function(v) Settings.ESP.Distance = v end })
    :Toggle({ Title = "Tracers", Value = true, Callback = function(v) Settings.ESP.Tracers = v end })
    :Toggle({ Title = "Skeleton", Value = true, Callback = function(v) Settings.ESP.Skeleton = v end })
    :Toggle({ Title = "Visible Only", Value = false, Callback = function(v) Settings.ESP.VisibleOnly = v end })
    :Toggle({ Title = "Only Aimbot Target", Value = false, Callback = function(v) Settings.ESP.OnlyTarget = v end })
    :Toggle({ Title = "Include NPCs", Value = true, Callback = function(v) Settings.ESP.NPCs = v end })

VisualsTab:Section({ Title = "Chams" })
    :Toggle({ Title = "Enabled", Callback = function(v) Settings.Chams.Enabled = v; refreshChams() end })
VisualsTab:Section({ Title = "Glow" })
    :Toggle({ Title = "Enabled", Callback = function(v) Settings.Glow.Enabled = v; refreshGlow() end })

-- ===== INFO =====
InfoTab:Section({ Title = "Discord" })
    :Button({ Title = "Copy Discord Invite", Callback = function()
        setclipboard("https://discord.gg/dJJ3psbAxw")
        WindUI:Notify({ Title = "Tulip", Content = "Discord link copied!" })
    end })

-- Initial activation
updateSpinbot()
updateMovementJumps()
updateThirdPerson()
refreshChams()
refreshGlow()
WindUI:Notify({ Title = "Tulip", Content = "Ultimate HvH loaded!" })
print("Tulip.lua – All features active. Magic Bullet ready.")