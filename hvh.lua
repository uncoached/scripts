-- Tulip.lua – Full HvH (WindUI, vodka silent aim)
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

-- Settings
local Settings = {
    SilentAim = { Enabled = false, FOV = 200, VisibleCheck = true, TeamCheck = false, HitPart = "Head" },
    Spinbot = { Enabled = false, Speed = 10 },
    Bhop = false,
    WalkSpeed = 16,
    ThirdPerson = false,
    ThirdPersonDistance = 10,
    ESP = { Enabled = true, Box = true, Name = true, HealthBar = true, Distance = true, Tracers = true, Skeleton = true },
    FOVCircle = false,
}

-- Feature globals
local silentAimTarget = nil
local espCache = {}

-- Utility
local function getHead(char) return char and char:FindFirstChild("Head") end
local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function getHumanoid(char) return char and char:FindFirstChildWhichIsA("Humanoid") end
local function teamCheck(plr) return Settings.SilentAim.TeamCheck and plr.Team == LocalPlayer.Team end
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin).Unit * 1000
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit and hit:IsDescendantOf(part.Parent)
end

-- Silent Aim target acquisition
local function getClosestTarget()
    if not Settings.SilentAim.Enabled then return nil end
    local closest = nil
    local closestDist = Settings.SilentAim.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or teamCheck(plr) then continue end
        local char = plr.Character
        if not char then continue end
        local hum = getHumanoid(char)
        if not hum or hum.Health <= 0 then continue end
        local part = (Settings.SilentAim.HitPart == "Head" and getHead(char))
                      or (Settings.SilentAim.HitPart == "UpperTorso" and char:FindFirstChild("UpperTorso"))
                      or getHRP(char)
        if not part then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < closestDist then
            if Settings.SilentAim.VisibleCheck and not isVisible(part) then continue end
            closestDist = dist
            closest = part.Position
        end
    end
    return closest
end

-- Silent Aim hook (vodka method)
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

-- FOV circle
local fovCircle
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false; fovCircle.Filled = false
    fovCircle.Color = Color3.fromRGB(255,255,255); fovCircle.Thickness = 1
end)

-- Update loop for aim & FOV
RunService.RenderStepped:Connect(function()
    if Settings.SilentAim.Enabled then
        silentAimTarget = getClosestTarget()
        if Settings.FOVCircle and fovCircle then
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            fovCircle.Radius = Settings.SilentAim.FOV
            fovCircle.Visible = true
        end
    else
        silentAimTarget = nil
        if fovCircle then fovCircle.Visible = false end
    end
end)

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
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Settings.Spinbot.Speed) * dt, 0)
            end
        end
    end)
end

-- Bunnyhop
local bhopConnection
local function updateBhop()
    if bhopConnection then bhopConnection:Disconnect() end
    if not Settings.Bhop then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = getHumanoid(char)
    if not hum then return end
    bhopConnection = hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.Landed and UIS:IsKeyDown(Enum.KeyCode.Space) then
            hum.Jump = true
        end
    end)
end

-- WalkSpeed
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").WalkSpeed = Settings.WalkSpeed
    if Settings.Bhop then updateBhop() end
end)
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = getHumanoid(char)
        if hum then hum.WalkSpeed = Settings.WalkSpeed end
    end
end)

-- Third Person
local function updateThirdPerson()
    if Settings.ThirdPerson then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPersonDistance
        LocalPlayer.CameraMinZoomDistance = Settings.ThirdPersonDistance
    else
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end

-- ESP (Drawing)
local hasDrawing = pcall(function() return Drawing.new end)
if hasDrawing then
    local function getBonePositions(char)
        local bones = {}
        local head = char:FindFirstChild("Head")
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        local leftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
        local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
        local leftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
        local rightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
        if head and torso then
            bones.Head = head.Position
            bones.Torso = torso.Position
            bones.LeftArm = (leftArm or torso).Position
            bones.RightArm = (rightArm or torso).Position
            bones.LeftLeg = (leftLeg or {Position = torso.Position - Vector3.new(0,2,0)}).Position
            bones.RightLeg = (rightLeg or {Position = torso.Position - Vector3.new(0,2,0)}).Position
        end
        return bones
    end

    local function createESPobj()
        local esp = {
            boxOutline = Drawing.new("Square"), box = Drawing.new("Square"),
            name = Drawing.new("Text"), distance = Drawing.new("Text"),
            healthOutline = Drawing.new("Line"), healthBar = Drawing.new("Line"),
            tracer = Drawing.new("Line"),
            skeletonLines = {},
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

    RunService.RenderStepped:Connect(function()
        if not Settings.ESP.Enabled then
            for _, e in pairs(espCache) do
                e.boxOutline.Visible = false; e.box.Visible = false
                e.name.Visible = false; e.distance.Visible = false
                e.healthOutline.Visible = false; e.healthBar.Visible = false
                e.tracer.Visible = false
                for _, line in ipairs(e.skeletonLines) do line:Remove() end
                e.skeletonLines = {}
            end
            return
        end
        local alive = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer or teamCheck(plr) then continue end
            local char = plr.Character
            if not char then continue end
            local hum = getHumanoid(char); local root = getHRP(char); local head = getHead(char)
            if hum and hum.Health > 0 and root and head then
                alive[plr] = true
                if not espCache[plr] then espCache[plr] = createESPobj() end
                local esp = espCache[plr]
                local rp, on1 = Camera:WorldToViewportPoint(root.Position)
                local hp, on2 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
                local lp = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
                if on1 and on2 then
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
                        esp.name.Text = plr.Name; esp.name.Position = Vector2.new(rp.X, hp.Y - 20); esp.name.Visible = true
                    else esp.name.Visible = false end
                    if Settings.ESP.Distance then
                        esp.distance.Text = "[" .. dist .. "m]"; esp.distance.Position = Vector2.new(rp.X, hp.Y + boxH + 2); esp.distance.Visible = true
                    else esp.distance.Visible = false end
                    if Settings.ESP.Tracers then
                        esp.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); esp.tracer.To = Vector2.new(rp.X, rp.Y); esp.tracer.Visible = true
                    else esp.tracer.Visible = false end
                    if Settings.ESP.Skeleton then
                        local bones = getBonePositions(char)
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
        end
        for plr, esp in pairs(espCache) do
            if not alive[plr] then
                for _, obj in pairs(esp) do if type(obj) == "table" and obj.Remove then obj:Remove() end end
                espCache[plr] = nil
            end
        end
    end)
else
    Settings.ESP.Enabled = false; Settings.FOVCircle = false
    warn("Drawing library missing – ESP disabled.")
end

-- ==================== UI ====================
local Window = WindUI:CreateWindow({
    Title = "Tulip",
    Folder = "Tulip",
    Icon = "solar:flower-bold",
    OpenButton = { Title = "Open", Enabled = true },
})

-- Tabs
local CombatTab = Window:Tab({ Title = "Combat", Icon = "solar:sword-bold" })
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })
local InfoTab = Window:Tab({ Title = "Info", Icon = "solar:info-bold" })

-- === Combat Tab ===
CombatTab:Section({ Title = "Silent Aim" })
    :Toggle({ Title = "Enabled", Callback = function(v) Settings.SilentAim.Enabled = v end })
    :Toggle({ Title = "Visibility Check", Value = true, Callback = function(v) Settings.SilentAim.VisibleCheck = v end })
    :Toggle({ Title = "Team Check", Value = false, Callback = function(v) Settings.SilentAim.TeamCheck = v end })
    :Slider({ Title = "FOV", Step = 10, Value = { Min = 10, Max = 500, Default = 200 }, Callback = function(v) Settings.SilentAim.FOV = v end })
    :Dropdown({ Title = "Hit Part", Values = {"Head","UpperTorso","HumanoidRootPart"}, Value = "Head", Callback = function(v) Settings.SilentAim.HitPart = v end })
    :Toggle({ Title = "Show FOV Circle", Value = false, Callback = function(v) Settings.FOVCircle = v end })

CombatTab:Section({ Title = "Spinbot" })
    :Toggle({ Title = "Enabled", Callback = function(v) Settings.Spinbot.Enabled = v; updateSpinbot() end })
    :Slider({ Title = "Speed", Step = 1, Value = { Min = 1, Max = 50, Default = 10 }, Callback = function(v) Settings.Spinbot.Speed = v end })

CombatTab:Section({ Title = "Movement" })
    :Toggle({ Title = "Bunny Hop", Callback = function(v) Settings.Bhop = v; updateBhop() end })
    :Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 50, Default = 16 }, Callback = function(v)
        Settings.WalkSpeed = v
        local char = LocalPlayer.Character
        if char then
            local hum = getHumanoid(char)
            if hum then hum.WalkSpeed = v end
        end
    end })

-- === Visuals Tab ===
VisualsTab:Section({ Title = "Camera" })
    :Toggle({ Title = "Third Person", Callback = function(v) Settings.ThirdPerson = v; updateThirdPerson() end })
    :Slider({ Title = "Distance", Step = 1, Value = { Min = 5, Max = 30, Default = 10 }, Callback = function(v)
        Settings.ThirdPersonDistance = v
        if Settings.ThirdPerson then
            LocalPlayer.CameraMaxZoomDistance = v
            LocalPlayer.CameraMinZoomDistance = v
        end
    end })

VisualsTab:Section({ Title = "Player ESP" })
    :Toggle({ Title = "Enable ESP", Value = true, Callback = function(v) Settings.ESP.Enabled = v end })
    :Toggle({ Title = "Box", Value = true, Callback = function(v) Settings.ESP.Box = v end })
    :Toggle({ Title = "Name", Value = true, Callback = function(v) Settings.ESP.Name = v end })
    :Toggle({ Title = "Health Bar", Value = true, Callback = function(v) Settings.ESP.HealthBar = v end })
    :Toggle({ Title = "Distance", Value = true, Callback = function(v) Settings.ESP.Distance = v end })
    :Toggle({ Title = "Tracers", Value = true, Callback = function(v) Settings.ESP.Tracers = v end })
    :Toggle({ Title = "Skeleton (R6/R15)", Value = true, Callback = function(v) Settings.ESP.Skeleton = v end })

-- === Info Tab ===
InfoTab:Section({ Title = "Discord" })
    :Button({ Title = "Copy Discord Invite", Callback = function()
        setclipboard("https://discord.gg/dJJ3psbAxw")
        WindUI:Notify({ Title = "Tulip", Content = "Discord link copied!" })
    end })

-- Initialise
updateSpinbot(); updateBhop(); updateThirdPerson()

WindUI:Notify({ Title = "Tulip", Content = "Loaded! Insert to open menu." })
print("Tulip.lua ready.")