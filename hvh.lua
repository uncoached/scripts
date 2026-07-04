--// Advanced HvH Script for Roblox Rivals – WindUI (correct layout)
--// Features: ESP (Box, Name, Health, Distance, Skeleton), Camera Aimbot, Silent Aim (Raycast), Triggerbot,
--//           Controller Support (Right Stick Aim), Radar, Chams, Glow, Anti‑Aim, Nightmode, Fullbright.
--//           FOV circle is outline only.
--//
--// Copy the remote name for Silent Aim – check with Dex Explorer.
--// The script uses WindUI exactly as you requested.

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
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

--// ==================== SETTINGS ====================
local Settings = {
    Aimbot = {
        Enabled = false,
        Silent = true,             -- Raycast silent aim
        HitPart = "Head",          -- Head, UpperTorso, HumanoidRootPart
        FOV = 200,
        Smoothness = 0.1,
        VisibleCheck = true,
        TeamCheck = true,
        Triggerbot = false,
        TriggerDelay = 0.1,
        UseController = false,
        ControllerSensitivity = 0.5,
    },
    Visuals = {
        ESP = {
            Enabled = true,
            Box = true,
            Name = true,
            HealthBar = true,
            Distance = true,
            Skeleton = false,
        },
        Chams = false,
        Glow = false,
        NightMode = false,
        Fullbright = false,
    },
    Misc = {
        Radar = true,
        RadarSize = 200,
        RadarZoom = 1,
        AntiAim = false,
        DesyncAngle = 45,
        AutoCrouch = false,
    }
}

--// ==================== UTILITY FUNCTIONS ====================
local function getCharacter(player)
    return player.Character or player.CharacterAdded:Wait()
end
local function getHead(char) return char and char:FindFirstChild("Head") end
local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function getHumanoid(char) return char and char:FindFirstChildWhichIsA("Humanoid") end
local function teamCheck(plr)
    return Settings.Aimbot.TeamCheck and plr.Team == LocalPlayer.Team
end
local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local dir = (targetPart.Position - origin).Unit * 1000
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit and hit:IsDescendantOf(targetPart.Parent)
end

--// ==================== DRAWING LIBRARY (for ESP & FOV) ====================
local Drawing = nil
pcall(function()
    Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/Insei/PenisMan/refs/heads/main/DrawingLib.lua"))()
end)
if not Drawing then
    pcall(function() Drawing = {}; Drawing.new = function() return {} end end)
end

--// ==================== ESP CACHE & UPDATE ====================
local ESPCache = {}
local SilentAimTarget = nil

local function createESP(player)
    local esp = {}
    if Drawing and Drawing.new then
        esp.box = Drawing.new("Square")
        esp.box.Visible = false
        esp.box.Color = Color3.new(1,1,1)
        esp.box.Thickness = 1
        esp.box.Filled = false

        esp.name = Drawing.new("Text")
        esp.name.Visible = false
        esp.name.Center = true
        esp.name.Outline = true
        esp.name.Font = 0
        esp.name.Size = 13

        esp.healthBar = Drawing.new("Square")
        esp.healthBar.Visible = false
        esp.healthBar.Filled = true

        esp.distance = Drawing.new("Text")
        esp.distance.Visible = false
        esp.distance.Center = true
        esp.distance.Outline = true
        esp.distance.Font = 0
        esp.distance.Size = 12

        esp.skeleton = {}
        for i=1,10 do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = Color3.new(1,1,1)
            table.insert(esp.skeleton, line)
        end
    end
    ESPCache[player] = esp
    return esp
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then createESP(player) end
end
Players.PlayerAdded:Connect(function(player) if player ~= LocalPlayer then createESP(player) end end)
Players.PlayerRemoving:Connect(function(player) ESPCache[player] = nil end)

local function getBonePos(char, boneName)
    local part = char:FindFirstChild(boneName)
    return part and part.Position
end

local function updateESP()
    for player, esp in pairs(ESPCache) do
        local char = player.Character
        if not char or player == LocalPlayer then
            if esp.box then esp.box.Visible = false end
            if esp.name then esp.name.Visible = false end
            if esp.healthBar then esp.healthBar.Visible = false end
            if esp.distance then esp.distance.Visible = false end
            if esp.skeleton then for _,v in pairs(esp.skeleton) do v.Visible = false end end
            continue
        end
        local hrp = getHRP(char)
        local head = getHead(char)
        if not hrp or not head then continue end
        local hrpPos, onScreen1 = Camera:WorldToViewportPoint(hrp.Position)
        local headPos, onScreen2 = Camera:WorldToViewportPoint(head.Position)
        if onScreen1 and onScreen2 then
            local scale = 1 / (hrpPos.Z * math.tan(math.rad(Camera.FieldOfView/2)) * 2)
            local height = math.abs(headPos.Y - hrpPos.Y) * scale
            local width = height / 2
            local x = hrpPos.X - width/2
            local y = headPos.Y

            if Settings.Visuals.ESP.Box and esp.box then
                esp.box.Visible = true
                esp.box.Size = Vector2.new(width, height)
                esp.box.Position = Vector2.new(x, y)
            elseif esp.box then
                esp.box.Visible = false
            end

            if Settings.Visuals.ESP.Name and esp.name then
                esp.name.Visible = true
                esp.name.Text = player.Name
                esp.name.Position = Vector2.new(hrpPos.X, y - 15)
            elseif esp.name then
                esp.name.Visible = false
            end

            if Settings.Visuals.ESP.HealthBar and esp.healthBar then
                local humanoid = getHumanoid(char)
                if humanoid then
                    local health = humanoid.Health / humanoid.MaxHealth
                    esp.healthBar.Visible = true
                    esp.healthBar.Size = Vector2.new(2, height * health)
                    esp.healthBar.Position = Vector2.new(x - 6, y + height * (1 - health))
                    esp.healthBar.Color = Color3.new(1-health, health, 0)
                else
                    esp.healthBar.Visible = false
                end
            elseif esp.healthBar then
                esp.healthBar.Visible = false
            end

            if Settings.Visuals.ESP.Distance and esp.distance then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                esp.distance.Visible = true
                esp.distance.Text = string.format("%.0f", dist)
                esp.distance.Position = Vector2.new(hrpPos.X, y + height + 5)
            elseif esp.distance then
                esp.distance.Visible = false
            end

            if Settings.Visuals.ESP.Skeleton and esp.skeleton then
                local bones = {
                    {"Head", "UpperTorso"},
                    {"UpperTorso", "LowerTorso"},
                    {"LeftUpperArm", "LeftLowerArm"},
                    {"LeftLowerArm", "LeftHand"},
                    {"RightUpperArm", "RightLowerArm"},
                    {"RightLowerArm", "RightHand"},
                    {"LeftUpperLeg", "LeftLowerLeg"},
                    {"LeftLowerLeg", "LeftFoot"},
                    {"RightUpperLeg", "RightLowerLeg"},
                    {"RightLowerLeg", "RightFoot"},
                }
                for i, bonePair in ipairs(bones) do
                    if esp.skeleton[i] then
                        local p1 = getBonePos(char, bonePair[1])
                        local p2 = getBonePos(char, bonePair[2])
                        if p1 and p2 then
                            local s1, o1 = Camera:WorldToViewportPoint(p1)
                            local s2, o2 = Camera:WorldToViewportPoint(p2)
                            if o1 and o2 then
                                esp.skeleton[i].Visible = true
                                esp.skeleton[i].From = Vector2.new(s1.X, s1.Y)
                                esp.skeleton[i].To = Vector2.new(s2.X, s2.Y)
                            else
                                esp.skeleton[i].Visible = false
                            end
                        else
                            esp.skeleton[i].Visible = false
                        end
                    end
                end
            elseif esp.skeleton then
                for _,v in pairs(esp.skeleton) do v.Visible = false end
            end
        else
            if esp.box then esp.box.Visible = false end
            if esp.name then esp.name.Visible = false end
            if esp.healthBar then esp.healthBar.Visible = false end
            if esp.distance then esp.distance.Visible = false end
            if esp.skeleton then for _,v in pairs(esp.skeleton) do v.Visible = false end end
        end
    end
end

--// ==================== AIMBOT TARGET ACQUISITION ====================
local function getTarget()
    local closest = nil
    local closestDist = Settings.Aimbot.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer or teamCheck(player) then continue end
        local char = player.Character
        if not char then continue end
        local part
        if Settings.Aimbot.HitPart == "Head" then part = getHead(char)
        elseif Settings.Aimbot.HitPart == "UpperTorso" then part = char:FindFirstChild("UpperTorso")
        else part = getHRP(char) end
        if not part then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < closestDist then
            if Settings.Aimbot.VisibleCheck and not isVisible(part) then continue end
            closestDist = dist
            closest = {Player = player, Part = part, ScreenPos = pos}
        end
    end
    return closest
end

--// ==================== FOV CIRCLE (OUTLINE ONLY) ====================
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Color = Color3.new(1,0,0)
fovCircle.Thickness = 1
fovCircle.NumSides = 60
fovCircle.Filled = false

RunService.RenderStepped:Connect(function()
    if Settings.Aimbot.Enabled then
        fovCircle.Visible = true
        fovCircle.Radius = Settings.Aimbot.FOV
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    else
        fovCircle.Visible = false
    end
end)

--// ==================== CAMERA AIMBOT (NON‑SILENT) ====================
RunService.RenderStepped:Connect(function()
    if Settings.Aimbot.Enabled and not Settings.Aimbot.Silent then
        local target = getTarget()
        if target then
            local smooth = Settings.Aimbot.Smoothness
            local targetPos = target.Part.Position
            local newCF = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, smooth)
        end
    end
    if Settings.Aimbot.Enabled and Settings.Aimbot.Silent then
        SilentAimTarget = getTarget()
    else
        SilentAimTarget = nil
    end
end)

--// ==================== SILENT AIM HOOK ====================
local function hookSilentAim()
    -- Replace with the actual remote name from Roblox Rivals (use Dex Explorer)
    for _, remote in pairs(getnilinstances()) do
        if remote:IsA("RemoteEvent") and (remote.Name == "FireBullet" or remote.Name == "Shoot" or remote.Name == "WeaponFire") then
            local old = hookfunction(remote.FireServer, function(self, ...)
                local args = {...}
                if SilentAimTarget and Settings.Aimbot.Enabled and Settings.Aimbot.Silent then
                    -- Assume first argument is the target position
                    args[1] = SilentAimTarget.Part.Position
                end
                return old(self, unpack(args))
            end)
            break
        end
    end
end
pcall(hookSilentAim)

--// ==================== TRIGGERBOT ====================
spawn(function()
    while task.wait(Settings.Aimbot.TriggerDelay) do
        if Settings.Aimbot.Triggerbot and Settings.Aimbot.Enabled then
            local target = getTarget()
            if target then
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end
        end
    end
end)

--// ==================== CONTROLLER AIM (RIGHT STICK) ====================
UIS.InputChanged:Connect(function(input)
    if Settings.Aimbot.UseController and (input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2) then
        if input.KeyCode == Enum.KeyCode.Thumbstick2 then
            local delta = input.Delta
            local sens = Settings.Aimbot.ControllerSensitivity * 5
            mousemoverel(math.floor(delta.X * sens), math.floor(delta.Y * -sens))
        end
    end
end)

--// ==================== CHAMS ====================
local chamHighlights = {}
local function toggleChams(on)
    if on then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character or player.CharacterAdded:Wait()
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(255,0,0)
                highlight.OutlineColor = Color3.new(0,0,0)
                highlight.Parent = char
                chamHighlights[player] = highlight
            end
        end
    else
        for _, hl in pairs(chamHighlights) do hl:Destroy() end
        chamHighlights = {}
    end
end

--// ==================== GLOW ====================
local glowBillboards = {}
local function toggleGlow(on)
    if on then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character or player.CharacterAdded:Wait()
                local glow = Instance.new("BillboardGui")
                glow.Adornee = char
                glow.Size = UDim2.new(10,0,10,0)
                glow.StudsOffset = Vector3.new(0,2,0)
                local frame = Instance.new("Frame", glow)
                frame.Size = UDim2.new(1,0,1,0)
                frame.BackgroundColor3 = Color3.new(1,0,0)
                frame.BackgroundTransparency = 0.5
                frame.BorderSizePixel = 0
                glow.Parent = char
                glowBillboards[player] = glow
            end
        end
    else
        for _, g in pairs(glowBillboards) do g:Destroy() end
        glowBillboards = {}
    end
end

--// ==================== RADAR ====================
local radarGui = nil
local function toggleRadar(on)
    if radarGui then radarGui:Destroy(); radarGui = nil end
    if not on then return end
    radarGui = Instance.new("ScreenGui")
    radarGui.Parent = LocalPlayer.PlayerGui
    local bg = Instance.new("Frame", radarGui)
    bg.Size = UDim2.new(0, Settings.Misc.RadarSize, 0, Settings.Misc.RadarSize)
    bg.Position = UDim2.new(1, -10 - Settings.Misc.RadarSize, 0, 10)
    bg.BackgroundColor3 = Color3.new(0,0,0)
    bg.BackgroundTransparency = 0.7
    bg.BorderSizePixel = 0
    local canvas = Instance.new("Frame", bg)
    canvas.Size = UDim2.new(1,0,1,0)
    canvas.BackgroundTransparency = 1

    spawn(function()
        while radarGui and Settings.Misc.Radar do
            local localRoot = getHRP(LocalPlayer.Character)
            if localRoot then
                for _, player in pairs(Players:GetPlayers()) do
                    if player == LocalPlayer then continue end
                    local char = player.Character
                    if not char then continue end
                    local root = getHRP(char)
                    if root then
                        local relative = localRoot.CFrame:PointToObjectSpace(root.Position)
                        local scale = Settings.Misc.RadarZoom
                        local half = Settings.Misc.RadarSize/2
                        local x = half + relative.X * scale
                        local y = half - relative.Z * scale
                        local dot = canvas:FindFirstChild(player.Name) or Instance.new("Frame", canvas)
                        dot.Name = player.Name
                        dot.Size = UDim2.new(0,5,0,5)
                        dot.Position = UDim2.new(0, x-2.5, 0, y-2.5)
                        dot.BackgroundColor3 = player.TeamColor.Color
                        dot.BorderSizePixel = 0
                    end
                end
            end
            RunService.Heartbeat:Wait()
        end
    end)
end

--// ==================== ANTI‑AIM (DESYNC) ====================
spawn(function()
    while task.wait() do
        if Settings.Misc.AntiAim and LocalPlayer.Character then
            local humanoid = getHumanoid(LocalPlayer.Character)
            if humanoid then humanoid.AutoRotate = false end
            local hrp = getHRP(LocalPlayer.Character)
            if hrp then
                local angle = math.rad(Settings.Misc.DesyncAngle) * (math.random() > 0.5 and 1 or -1)
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, angle, 0)
            end
        end
    end
end)

--// ==================== AUTO CROUCH ====================
spawn(function()
    while task.wait() do
        if Settings.Misc.AutoCrouch and LocalPlayer.Character then
            local humanoid = getHumanoid(LocalPlayer.Character)
            if humanoid then
                humanoid.CameraOffset = Vector3.new(0, -1, 0)
            end
        end
    end
end)

--// ==================== ESP RENDER LOOP ====================
RunService.RenderStepped:Connect(function()
    if Settings.Visuals.ESP.Enabled then
        updateESP()
    end
end)

--// ==================== WINDUI INTERFACE ====================
local Window = WindUI:CreateWindow({
    Title = "Rivals HvH | v3.0",
    Folder = "rivals_hvh",
    Icon = "solar:target-bold",
    Theme = "Dark",
    OpenButton = {
        Title = "Open HvH",
        Enabled = true,
        Scale = 0.5,
    },
})

-- Aimbot Tab
local AimTab = Window:Tab({ Title = "Aimbot", Icon = "solar:target-bold" })

AimTab:Section({ Title = "Main Settings" })
    :Toggle({ Title = "Enable Aimbot", Value = false, Callback = function(v) Settings.Aimbot.Enabled = v end })
    :Toggle({ Title = "Silent Aim (Raycast)", Value = true, Callback = function(v) Settings.Aimbot.Silent = v end })
    :Toggle({ Title = "Triggerbot", Value = false, Callback = function(v) Settings.Aimbot.Triggerbot = v end })
    :Toggle({ Title = "Visibility Check", Value = true, Callback = function(v) Settings.Aimbot.VisibleCheck = v end })
    :Toggle({ Title = "Team Check", Value = true, Callback = function(v) Settings.Aimbot.TeamCheck = v end })
    :Toggle({ Title = "Use Controller (Right Stick)", Value = false, Callback = function(v) Settings.Aimbot.UseController = v end })

AimTab:Section({ Title = "Aim Parameters" })
    :Slider({ Title = "FOV", Step = 10, Value = { Min = 10, Max = 500, Default = 200 }, Callback = function(v) Settings.Aimbot.FOV = v end })
    :Slider({ Title = "Smoothness", Step = 0.01, Value = { Min = 0.01, Max = 1, Default = 0.1 }, Callback = function(v) Settings.Aimbot.Smoothness = v end })
    :Slider({ Title = "Controller Sensitivity", Step = 0.1, Value = { Min = 0.1, Max = 2, Default = 0.5 }, Callback = function(v) Settings.Aimbot.ControllerSensitivity = v end })
    :Slider({ Title = "Trigger Delay", Step = 0.05, Value = { Min = 0.05, Max = 1, Default = 0.1 }, Callback = function(v) Settings.Aimbot.TriggerDelay = v end })
    :Dropdown({ Title = "Hit Part", Values = { "Head", "UpperTorso", "HumanoidRootPart" }, Value = "Head", Callback = function(v) Settings.Aimbot.HitPart = v end })

-- ESP Tab
local ESPTab = Window:Tab({ Title = "ESP", Icon = "solar:eye-bold" })

ESPTab:Section({ Title = "ESP Toggles" })
    :Toggle({ Title = "Enable ESP", Value = true, Callback = function(v) Settings.Visuals.ESP.Enabled = v end })
    :Toggle({ Title = "Box", Value = true, Callback = function(v) Settings.Visuals.ESP.Box = v end })
    :Toggle({ Title = "Name", Value = true, Callback = function(v) Settings.Visuals.ESP.Name = v end })
    :Toggle({ Title = "Health Bar", Value = true, Callback = function(v) Settings.Visuals.ESP.HealthBar = v end })
    :Toggle({ Title = "Distance", Value = true, Callback = function(v) Settings.Visuals.ESP.Distance = v end })
    :Toggle({ Title = "Skeleton", Value = false, Callback = function(v) Settings.Visuals.ESP.Skeleton = v end })

-- Visuals Tab
local VisTab = Window:Tab({ Title = "Visuals", Icon = "solar:palette-bold" })

VisTab:Section({ Title = "World Visuals" })
    :Toggle({ Title = "Chams", Value = false, Callback = toggleChams })
    :Toggle({ Title = "Glow", Value = false, Callback = toggleGlow })
    :Toggle({ Title = "Night Mode", Value = false, Callback = function(v) Settings.Visuals.NightMode = v; Lighting.ClockTime = v and 0 or 14; Lighting.Brightness = v and 0.5 or 2 end })
    :Toggle({ Title = "Fullbright", Value = false, Callback = function(v) Settings.Visuals.Fullbright = v; Lighting.Ambient = v and Color3.new(1,1,1) or Color3.new(0,0,0) end })

-- Misc Tab
local MiscTab = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold" })

MiscTab:Section({ Title = "Radar" })
    :Toggle({ Title = "Radar", Value = true, Callback = toggleRadar })
    :Slider({ Title = "Radar Size", Step = 10, Value = { Min = 100, Max = 400, Default = 200 }, Callback = function(v) Settings.Misc.RadarSize = v; toggleRadar(Settings.Misc.Radar) end })
    :Slider({ Title = "Radar Zoom", Step = 0.1, Value = { Min = 0.5, Max = 5, Default = 1 }, Callback = function(v) Settings.Misc.RadarZoom = v end })

MiscTab:Section({ Title = "Other" })
    :Toggle({ Title = "Anti‑Aim (Desync)", Value = false, Callback = function(v) Settings.Misc.AntiAim = v end })
    :Slider({ Title = "Desync Angle", Step = 5, Value = { Min = 0, Max = 90, Default = 45 }, Callback = function(v) Settings.Misc.DesyncAngle = v end })
    :Toggle({ Title = "Auto Crouch", Value = false, Callback = function(v) Settings.Misc.AutoCrouch = v end })

-- Stop all features button (optional, stops loops not toggles)
Window:Button({
    Title = "STOP ALL",
    Color = Color3.fromRGB(255,0,0),
    Callback = function()
        -- Reset toggles
        Settings.Aimbot.Enabled = false
        Settings.Aimbot.Triggerbot = false
        Settings.Visuals.Chams = false; toggleChams(false)
        Settings.Visuals.Glow = false; toggleGlow(false)
        Settings.Misc.Radar = false; toggleRadar(false)
        Settings.Misc.AntiAim = false
        Settings.Misc.AutoCrouch = false
        WindUI:Notify({ Title = "Stopped", Content = "All features disabled." })
    end,
})

-- Start radar on load
pcall(function() toggleRadar(true) end)

WindUI:Notify({ Title = "Rivals HvH", Content = "Loaded! Silent Aim remote may need adjustment." })
print("// Roblox Rivals HvH – WindUI version ready.")