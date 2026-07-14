-- Tulip.lua – Full HvH using WindUI + Vodka Silent Aim method
-- Features: Silent Aim (hookmetamethod Raycast), Spinbot, Bunny Hop, Walk Speed, Third Person,
--           Full ESP (Box, Name, Health, Distance, Tracers, Skeleton), FOV Circle, Discord Invite

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
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==================== SETTINGS ====================
local Settings = {
    SilentAim = {
        Enabled = false,
        FOV = 200,
        VisibleCheck = true,
        TeamCheck = false,
        HitPart = "Head", -- Head, UpperTorso, HumanoidRootPart
    },
    Spinbot = {
        Enabled = false,
        Speed = 10,
    },
    Bhop = false,
    WalkSpeed = 16,
    ThirdPerson = false,
    ThirdPersonDistance = 10,
    ESP = {
        Enabled = true,
        Box = true,
        Name = true,
        HealthBar = true,
        Distance = true,
        Tracers = true,
        Skeleton = true,
    },
    FOVCircle = false,
}

-- ==================== FEATURE VARIABLES ====================
local silentAimTarget = nil
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1

-- ==================== UTILITY FUNCTIONS ====================
local function getCharacter(player) return player.Character end
local function getHead(char) return char and char:FindFirstChild("Head") end
local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function getHumanoid(char) return char and char:FindFirstChildWhichIsA("Humanoid") end
local function teamCheck(plr)
    return Settings.SilentAim.TeamCheck and plr.Team == LocalPlayer.Team
end
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin).Unit * 1000
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit and hit:IsDescendantOf(part.Parent)
end

-- ==================== SILENT AIM TARGET ACQUISITION ====================
local function getClosestTarget()
    if not Settings.SilentAim.Enabled then return nil end
    local closest = nil
    local closestDist = Settings.SilentAim.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or teamCheck(player) then continue end
        local char = getCharacter(player)
        if not char then continue end
        local hum = getHumanoid(char)
        if not hum or hum.Health <= 0 then continue end
        local part
        if Settings.SilentAim.HitPart == "Head" then part = getHead(char)
        elseif Settings.SilentAim.HitPart == "UpperTorso" then part = char:FindFirstChild("UpperTorso")
        else part = getHRP(char) end
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

-- ==================== SILENT AIM HOOK (Vodka method) ====================
local Hooks = {}
Hooks.Raycast = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod():lower()
    if Settings.SilentAim.Enabled and silentAimTarget and method == "raycast" and self == Workspace then
        local dir = (silentAimTarget - Camera.CFrame.Position).Unit * 200
        -- The second argument is the direction vector; replace it
        args[2] = dir
        return Hooks.Raycast(self, unpack(args))
    end
    return Hooks.Raycast(self, ...)
end))

-- ==================== FOV CIRCLE + TARGET UPDATER ====================
RunService.RenderStepped:Connect(function()
    if Settings.SilentAim.Enabled and Settings.FOVCircle then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        fovCircle.Radius = Settings.SilentAim.FOV
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
    if Settings.SilentAim.Enabled then
        silentAimTarget = getClosestTarget()
    else
        silentAimTarget = nil
    end
end)

-- ==================== SPINBOT (character rotation) ====================
local spinConnection = nil
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

-- ==================== BUNNY HOP ====================
local bhopConnection = nil
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

-- ==================== WALK SPEED ====================
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = Settings.WalkSpeed
    if Settings.Bhop then updateBhop() end
end)

-- ==================== THIRD PERSON ====================
local function updateThirdPerson()
    if Settings.ThirdPerson then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = Settings.ThirdPersonDistance
        LocalPlayer.CameraMinZoomDistance = Settings.ThirdPersonDistance
    else
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end

-- ==================== ESP SYSTEM ====================
local espCache = {}
local function getBonePositions(char)
    local bones = {}
    local head = char:FindFirstChild("Head")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local leftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
    local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    local leftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
    local rightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
    local function pos(part) return part and part.Position end
    if head and torso then
        bones.Head = pos(head)
        bones.Torso = pos(torso)
        bones.LeftArm = pos(leftArm) or bones.Torso
        bones.RightArm = pos(rightArm) or bones.Torso
        bones.LeftLeg = pos(leftLeg) or (bones.Torso - Vector3.new(0,2,0))
        bones.RightLeg = pos(rightLeg) or (bones.Torso - Vector3.new(0,2,0))
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
    esp.box.Thickness = 1; esp.box.Filled = false; esp.box.Color = Color3.fromRGB(255, 50, 50)
    esp.name.Center = true; esp.name.Outline = true; esp.name.Color = Color3.new(1,1,1); esp.name.Size = 16
    esp.distance.Center = true; esp.distance.Outline = true; esp.distance.Color = Color3.new(0.8,0.8,0.8); esp.distance.Size = 13
    esp.healthOutline.Thickness = 3; esp.healthOutline.Color = Color3.new(0,0,0)
    esp.healthBar.Thickness = 1; esp.healthBar.Color = Color3.new(0,1,0)
    esp.tracer.Thickness = 1; esp.tracer.Color = Color3.fromRGB(255,255,255); esp.tracer.Visible = false
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

    local aliveSet = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or teamCheck(player) then continue end
        local char = player.Character
        if not char then continue end
        local hum = getHumanoid(char)
        local root = getHRP(char)
        local head = getHead(char)
        if hum and hum.Health > 0 and root and head then
            aliveSet[player] = true
            if not espCache[player] then espCache[player] = createESPobj() end
            local esp = espCache[player]
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
            if onScreen then
                local boxH = math.abs(headPos.Y - legPos.Y)
                local boxW = boxH / 2
                local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)

                if Settings.ESP.Box then
                    esp.boxOutline.Size = Vector2.new(boxW, boxH); esp.boxOutline.Position = Vector2.new(rootPos.X - boxW/2, headPos.Y)
                    esp.boxOutline.Visible = true
                    esp.box.Size = esp.boxOutline.Size; esp.box.Position = esp.boxOutline.Position; esp.box.Visible = true
                else
                    esp.boxOutline.Visible = false; esp.box.Visible = false
                end

                if Settings.ESP.HealthBar then
                    local hpPct = hum.Health / hum.MaxHealth
                    local barX = rootPos.X - boxW/2 - 6
                    esp.healthOutline.From = Vector2.new(barX, headPos.Y - 1); esp.healthOutline.To = Vector2.new(barX, headPos.Y + boxH + 1)
                    esp.healthOutline.Visible = true
                    esp.healthBar.From = Vector2.new(barX, headPos.Y + boxH); esp.healthBar.To = Vector2.new(barX, headPos.Y + boxH - (boxH * hpPct))
                    esp.healthBar.Color = Color3.new(1 - hpPct, hpPct, 0); esp.healthBar.Visible = true
                else
                    esp.healthOutline.Visible = false; esp.healthBar.Visible = false
                end

                if Settings.ESP.Name then
                    esp.name.Text = player.Name; esp.name.Position = Vector2.new(rootPos.X, headPos.Y - 20); esp.name.Visible = true
                else
                    esp.name.Visible = false
                end

                if Settings.ESP.Distance then
                    esp.distance.Text = "[" .. dist .. "m]"; esp.distance.Position = Vector2.new(rootPos.X, headPos.Y + boxH + 2); esp.distance.Visible = true
                else
                    esp.distance.Visible = false
                end

                if Settings.ESP.Tracers then
                    esp.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    esp.tracer.To = Vector2.new(rootPos.X, rootPos.Y); esp.tracer.Visible = true
                else
                    esp.tracer.Visible = false
                end

                if Settings.ESP.Skeleton then
                    local bones = getBonePositions(char)
                    for _, line in ipairs(esp.skeletonLines) do line:Remove() end
                    esp.skeletonLines = {}
                    if bones then
                        local pairs = {
                            {"Head", "Torso"}, {"Torso", "LeftArm"}, {"Torso", "RightArm"},
                            {"Torso", "LeftLeg"}, {"Torso", "RightLeg"},
                        }
                        for _, pair in ipairs(pairs) do
                            local b1 = bones[pair[1]]; local b2 = bones[pair[2]]
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
                else
                    for _, line in ipairs(esp.skeletonLines) do line:Remove() end; esp.skeletonLines = {}
                end
            else
                esp.boxOutline.Visible = false; esp.box.Visible = false
                esp.name.Visible = false; esp.distance.Visible = false
                esp.healthOutline.Visible = false; esp.healthBar.Visible = false
                esp.tracer.Visible = false
                for _, line in ipairs(esp.skeletonLines) do line.Visible = false end
            end
        end
    end
    -- Cleanup
    for plr, esp in pairs(espCache) do
        if not aliveSet[plr] then
            for _, obj in pairs(esp) do if type(obj) == "table" and obj.Remove then obj:Remove() end end
            espCache[plr] = nil
        end
    end
end)

-- ==================== UI CREATION (WindUI) ====================
local Window = WindUI:CreateWindow({
    Title = "Tulip",
    Folder = "Tulip",
    Icon = "solar:flower-bold",
    OpenButton = { Title = "Open", Enabled = true },
})

-- ==================== COMBAT TAB ====================
local CombatTab = Window:Tab({ Title = "Combat", Icon = "solar:sword-bold" })

CombatTab:Section({ Title = "Silent Aim" })
    :Toggle({ Title = "Enabled", Callback = function(v) Settings.SilentAim.Enabled = v end })
    :Toggle({ Title = "Visibility Check", Value = true, Callback = function(v) Settings.SilentAim.VisibleCheck = v end })
    :Toggle({ Title = "Team Check", Value = false, Callback = function(v) Settings.SilentAim.TeamCheck = v end })
    :Slider({ Title = "FOV", Step = 10, Value = { Min = 10, Max = 500, Default = 200 }, Callback = function(v) Settings.SilentAim.FOV = v end })
    :Dropdown({ Title = "Hit Part", Values = {"Head", "UpperTorso", "HumanoidRootPart"}, Value = "Head", Callback = function(v) Settings.SilentAim.HitPart = v end })
    :Toggle({ Title = "Show FOV Circle", Value = false, Callback = function(v) Settings.FOVCircle = v end })

CombatTab:Section({ Title = "Spinbot" })
    :Toggle({ Title = "Enabled", Callback = function(v) Settings.Spinbot.Enabled = v; updateSpinbot() end })
    :Slider({ Title = "Speed", Step = 1, Value = { Min = 1, Max = 50, Default = 10 }, Callback = function(v) Settings.Spinbot.Speed = v end })

CombatTab:Section({ Title = "Movement" })
    :Toggle({ Title = "Bunny Hop", Callback = function(v) Settings.Bhop = v; updateBhop() end })
    :Slider({ Title = "Walk Speed", Step = 1, Value = { Min = 16, Max = 50, Default = 16 }, Callback = function(v)
        Settings.WalkSpeed = v
        local char = LocalPlayer.Character
        if char and getHumanoid(char) then getHumanoid(char).WalkSpeed = v end
    end })

-- ==================== VISUALS TAB ====================
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })

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

-- ==================== INFO TAB ====================
local InfoTab = Window:Tab({ Title = "Info", Icon = "solar:info-bold" })
InfoTab:Section({ Title = "Discord" })
    :Button({ Title = "Copy Discord Invite", Callback = function()
        setclipboard("https://discord.gg/dJJ3psbAxw")
        WindUI:Notify({ Title = "Tulip", Content = "Discord link copied!" })
    end })

-- Initial apply
updateSpinbot()
updateBhop()
updateThirdPerson()

WindUI:Notify({ Title = "Tulip", Content = "Loaded! Insert to open menu." })
print("Tulip.lua – Silent Aim (hookmetamethod) + Full ESP ready.")