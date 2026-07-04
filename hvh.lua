--// BloxStrike HvH Script – WindUI
--// Features: Aimbot (camera & silent raycast), FOV circle (outline), Triggerbot, Hitbox expander,
--//           Bunnyhop, ESP (Box/Name/Health/Distance), Anti‑Flash, Anti‑Smoke, Controller aim.
--// Silent aim hooks the weapon remote – adjust the remote name (line ~130) if needed.
--// All exploits functions (mouse1click, mousemoverel) are checked before use.

local WindUI = nil
local function loadWindUI()
    local ok, result = pcall(function()
        if game:GetService("RunService"):IsStudio() then
            return require(game:GetService("ReplicatedStorage"):WaitForChild("WindUI"):WaitForChild("Init"))
        else
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
        end
    end)
    if ok then WindUI = result end
end
loadWindUI()
if not WindUI then return end

-- Services & Globals
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local CharactersFolder = Workspace:WaitForChild("Characters", 10)

-- Team helpers (BloxStrike structure)
local function getTFolder() return CharactersFolder:FindFirstChild("Terrorists") end
local function getCTFolder() return CharactersFolder:FindFirstChild("Counter-Terrorists") end
local function isAlive()
    local t, ct = getTFolder(), getCTFolder()
    return (t and t:FindFirstChild(LocalPlayer.Name)) or (ct and ct:FindFirstChild(LocalPlayer.Name))
end
local function getEnemyFolder()
    if not isAlive() then return nil end
    local t, ct = getTFolder(), getCTFolder()
    if t and t:FindFirstChild(LocalPlayer.Name) then return ct end
    if ct and ct:FindFirstChild(LocalPlayer.Name) then return t end
    return nil
end
local function teamCheck(plr)
    local enemyFolder = getEnemyFolder()
    return enemyFolder and plr.Character and plr.Character.Parent == enemyFolder
end

-- Features state
local Aimbot = {Enabled = false, Silent = true, FOV = 200, Smoothness = 0.1, HitPart = "Head", VisibleCheck = true}
local Triggerbot = {Enabled = false, Delay = 0}
local Hitbox = {Enabled = false, Size = 3}
local ESP = {Enabled = false, Box = true, Name = true, HealthBar = true, Distance = true}
local Bhop = false
local AntiFlash = false
local AntiSmoke = false
local UseController = false
local ControllerSensitivity = 0.5

-- Drawing objects
local Drawing = nil
pcall(function() Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/Insei/PenisMan/refs/heads/main/DrawingLib.lua"))() end)
if not Drawing then pcall(function() Drawing = { new = function() return {Visible = false} end } end) end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
FOVCircle.Radius = Aimbot.FOV
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = false
FOVCircle.Thickness = 1

-- Silent aim target
local SilentAimTarget = nil

-- =============================================
--  AIMBOT
-- =============================================
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin).Unit * 1000
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit and hit:IsDescendantOf(part.Parent)
end

local function getClosestEnemy()
    local closest = nil
    local closestDist = Aimbot.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local enemyFolder = getEnemyFolder()
    if not enemyFolder then return nil end

    for _, enemy in pairs(enemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChildWhichIsA("Humanoid")
        local part
        if Aimbot.HitPart == "Head" then part = enemy:FindFirstChild("Head")
        elseif Aimbot.HitPart == "UpperTorso" then part = enemy:FindFirstChild("UpperTorso")
        else part = enemy:FindFirstChild("HumanoidRootPart") end
        if not hum or hum.Health <= 0 or not part then continue end

        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < closestDist then
            if Aimbot.VisibleCheck and not isVisible(part) then continue end
            closestDist = dist
            closest = part
        end
    end
    return closest
end

-- Aim key (right mouse button)
local isAiming = false
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then isAiming = false end
end)

RunService.RenderStepped:Connect(function()
    -- FOV circle
    if Aimbot.Enabled then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Radius = Aimbot.FOV
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if not Aimbot.Enabled or not isAlive() then
        SilentAimTarget = nil
        return
    end

    local target = getClosestEnemy()
    SilentAimTarget = (Aimbot.Silent and target) or nil

    if not Aimbot.Silent and isAiming and target then
        local headPos = Camera:WorldToViewportPoint(target.Position)
        local mousePos = UIS:GetMouseLocation()
        local moveX = (headPos.X - mousePos.X) / (Aimbot.Smoothness * 5)
        local moveY = (headPos.Y - mousePos.Y) / (Aimbot.Smoothness * 5)
        if mousemoverel then mousemoverel(moveX, moveY) end
    end
end)

-- Silent aim remote hook (change "FireBullet" if needed)
local function hookSilentAim()
    local remote = nil
    local remotesFolder = RS:FindFirstChild("Remotes") or RS
    if remotesFolder then
        remote = remotesFolder:FindFirstChild("FireBullet") or remotesFolder:FindFirstChild("Shoot") or remotesFolder:FindFirstChild("WeaponFire")
        if remote and remote:IsA("RemoteEvent") then
            local old = hookfunction(remote.FireServer, function(self, ...)
                local args = {...}
                if SilentAimTarget and Aimbot.Enabled and Aimbot.Silent then
                    args[1] = SilentAimTarget.Position
                end
                return old(self, unpack(args))
            end)
        end
    end
end
pcall(hookSilentAim)

-- =============================================
--  TRIGGERBOT
-- =============================================
task.spawn(function()
    while task.wait(0.01) do
        if Triggerbot.Enabled and isAlive() then
            local viewportSize = Camera.ViewportSize
            local ray = Camera:ViewportPointToRay(viewportSize.X/2, viewportSize.Y/2)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local ignore = {Camera}
            if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
            params.FilterDescendantsInstances = ignore

            local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            if result and result.Instance then
                local model = result.Instance:FindFirstAncestorOfClass("Model")
                if model then
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    local enemyFolder = getEnemyFolder()
                    if hum and hum.Health > 0 and enemyFolder and model.Parent == enemyFolder then
                        if Triggerbot.Delay > 0 then task.wait(Triggerbot.Delay/1000) end
                        if mouse1click then mouse1click() end
                        task.wait(0.05)
                    end
                end
            end
        end
    end
end)

-- =============================================
--  HITBOX EXPANDER
-- =============================================
local originalHeadSizes = {}
task.spawn(function()
    while task.wait(0.5) do
        local enemyFolder = getEnemyFolder()
        if enemyFolder then
            for _, enemy in pairs(enemyFolder:GetChildren()) do
                local head = enemy:FindFirstChild("Head")
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health > 0 then
                    if not originalHeadSizes[head] then originalHeadSizes[head] = head.Size end
                    if Hitbox.Enabled then
                        head.Size = Vector3.new(Hitbox.Size, Hitbox.Size, Hitbox.Size)
                        head.CanCollide = false
                        head.Transparency = 0.5
                    else
                        if originalHeadSizes[head] then
                            head.Size = originalHeadSizes[head]
                            head.Transparency = 0
                        end
                    end
                end
            end
        end
    end
end)

-- =============================================
--  BUNNY HOP
-- =============================================
RunService.RenderStepped:Connect(function()
    if Bhop and UIS:IsKeyDown(Enum.KeyCode.Space) and isAlive() then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                hum.Jump = true
            end
        end
    end
end)

-- =============================================
--  ESP (Box, Name, Health, Distance)
-- =============================================
local espCache = {}
local function createESPobj()
    local esp = {
        boxOutline = Drawing.new("Square"), box = Drawing.new("Square"),
        name = Drawing.new("Text"), distance = Drawing.new("Text"),
        healthOutline = Drawing.new("Line"), healthBar = Drawing.new("Line")
    }
    esp.boxOutline.Thickness = 3; esp.boxOutline.Filled = false; esp.boxOutline.Color = Color3.new(0,0,0)
    esp.box.Thickness = 1; esp.box.Filled = false; esp.box.Color = Color3.fromRGB(255, 50, 50)
    esp.name.Center = true; esp.name.Outline = true; esp.name.Color = Color3.new(1,1,1); esp.name.Size = 16
    esp.distance.Center = true; esp.distance.Outline = true; esp.distance.Color = Color3.new(0.8,0.8,0.8); esp.distance.Size = 13
    esp.healthOutline.Thickness = 3; esp.healthOutline.Color = Color3.new(0,0,0)
    esp.healthBar.Thickness = 1; esp.healthBar.Color = Color3.new(0,1,0)
    return esp
end

RunService.RenderStepped:Connect(function()
    if not ESP.Enabled or not isAlive() then
        for _, e in pairs(espCache) do for _, d in pairs(e) do d.Visible = false end end
        return
    end
    local enemyFolder = getEnemyFolder()
    if not enemyFolder then return end

    local aliveSet = {}
    for _, enemy in pairs(enemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local root = enemy:FindFirstChild("HumanoidRootPart")
        local head = enemy:FindFirstChild("Head")
        if hum and hum.Health > 0 and root and head then
            aliveSet[enemy] = true
            if not espCache[enemy] then espCache[enemy] = createESPobj() end
            local esp = espCache[enemy]
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            if onScreen then
                local boxH = math.abs(headPos.Y - legPos.Y)
                local boxW = boxH / 2
                local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)

                if ESP.Box then
                    esp.boxOutline.Size = Vector2.new(boxW, boxH); esp.boxOutline.Position = Vector2.new(rootPos.X - boxW/2, headPos.Y); esp.boxOutline.Visible = true
                    esp.box.Size = esp.boxOutline.Size; esp.box.Position = esp.boxOutline.Position; esp.box.Visible = true
                else
                    esp.boxOutline.Visible = false; esp.box.Visible = false
                end

                if ESP.HealthBar then
                    local hpPct = hum.Health / hum.MaxHealth
                    local barX = rootPos.X - boxW/2 - 6
                    esp.healthOutline.From = Vector2.new(barX, headPos.Y - 1); esp.healthOutline.To = Vector2.new(barX, headPos.Y + boxH + 1); esp.healthOutline.Visible = true
                    esp.healthBar.From = Vector2.new(barX, headPos.Y + boxH); esp.healthBar.To = Vector2.new(barX, headPos.Y + boxH - (boxH * hpPct))
                    esp.healthBar.Color = Color3.new(1 - hpPct, hpPct, 0); esp.healthBar.Visible = true
                else
                    esp.healthOutline.Visible = false; esp.healthBar.Visible = false
                end

                esp.name.Text = ESP.Name and enemy.Name or ""; esp.name.Position = Vector2.new(rootPos.X, headPos.Y - 20); esp.name.Visible = ESP.Name
                esp.distance.Text = ESP.Distance and ("[" .. dist .. "m]") or ""; esp.distance.Position = Vector2.new(rootPos.X, headPos.Y + boxH + 2); esp.distance.Visible = ESP.Distance
            else
                for _, d in pairs(esp) do d.Visible = false end
            end
        end
    end
    for enemy, esp in pairs(espCache) do
        if not aliveSet[enemy] then
            for _, d in pairs(esp) do d:Remove() end
            espCache[enemy] = nil
        end
    end
end)

-- =============================================
--  ANTI-FLASH & ANTI-SMOKE
-- =============================================
task.spawn(function()
    while task.wait(0.2) do
        if AntiFlash then
            local gui = LocalPlayer.PlayerGui:FindFirstChild("FlashbangEffect")
            local effect = Lighting:FindFirstChild("FlashbangColorCorrection")
            if gui then gui:Destroy() end
            if effect then effect:Destroy() end
        end
    end
end)
task.spawn(function()
    while task.wait(0.5) do
        if AntiSmoke then
            local debris = Workspace:FindFirstChild("Debris")
            if debris then
                for _, folder in pairs(debris:GetChildren()) do
                    if string.match(folder.Name, "Voxel") then folder:ClearAllChildren(); folder:Destroy() end
                end
            end
        end
    end
end)

-- =============================================
--  CONTROLLER AIM
-- =============================================
UIS.InputChanged:Connect(function(input)
    if UseController and (input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2) then
        if input.KeyCode == Enum.KeyCode.Thumbstick2 then
            local delta = input.Delta
            local sens = ControllerSensitivity * 5
            if mousemoverel then mousemoverel(math.floor(delta.X * sens), math.floor(delta.Y * -sens)) end
        end
    end
end)

-- =============================================
--  WINDUI INTERFACE
-- =============================================
local Window = WindUI:CreateWindow({
    Title = "BloxStrike HvH",
    Folder = "bloxstrike_hvh",
    Icon = "solar:target-bold",
    OpenButton = { Title = "Open HvH", Enabled = true, Scale = 0.5 },
})

-- Tabs
local Tab_Combat  = Window:Tab({ Title = "Combat", Icon = "solar:target-bold" })
local Tab_Visuals = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })
local Tab_Misc    = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold" })

-- ---- Combat Section ----
Tab_Combat:Section({ Title = "Aimbot" })
    :Toggle({ Title = "Enable Aimbot", Value = false, Callback = function(v) Aimbot.Enabled = v end })
    :Toggle({ Title = "Silent Aim (Raycast)", Value = true, Callback = function(v) Aimbot.Silent = v end })
    :Toggle({ Title = "Visibility Check", Value = true, Callback = function(v) Aimbot.VisibleCheck = v end })
    :Slider({ Title = "FOV", Step = 10, Value = { Min = 10, Max = 500, Default = 200 }, Callback = function(v) Aimbot.FOV = v end })
    :Slider({ Title = "Smoothness", Step = 0.1, Value = { Min = 0.1, Max = 1, Default = 0.1 }, Callback = function(v) Aimbot.Smoothness = v end })
    :Dropdown({ Title = "Hit Part", Values = { "Head", "UpperTorso", "HumanoidRootPart" }, Value = "Head", Callback = function(v) Aimbot.HitPart = v end })

Tab_Combat:Section({ Title = "Triggerbot" })
    :Toggle({ Title = "Enable Triggerbot", Value = false, Callback = function(v) Triggerbot.Enabled = v end })
    :Slider({ Title = "Shot Delay (ms)", Step = 10, Value = { Min = 0, Max = 500, Default = 0 }, Callback = function(v) Triggerbot.Delay = v end })

Tab_Combat:Section({ Title = "Hitbox Expander" })
    :Toggle({ Title = "Enable Hitbox", Value = false, Callback = function(v) Hitbox.Enabled = v end })
    :Slider({ Title = "Hitbox Size", Step = 0.1, Value = { Min = 1, Max = 3, Default = 3 }, Callback = function(v) Hitbox.Size = v end })

Tab_Combat:Section({ Title = "Movement" })
    :Toggle({ Title = "Bunny Hop (Hold Space)", Value = false, Callback = function(v) Bhop = v end })

Tab_Combat:Section({ Title = "Controller" })
    :Toggle({ Title = "Use Controller Aim (Right Stick)", Value = false, Callback = function(v) UseController = v end })
    :Slider({ Title = "Controller Sensitivity", Step = 0.1, Value = { Min = 0.1, Max = 2, Default = 0.5 }, Callback = function(v) ControllerSensitivity = v end })

-- ---- Visuals Tab ----
Tab_Visuals:Section({ Title = "ESP" })
    :Toggle({ Title = "Enable ESP", Value = false, Callback = function(v) ESP.Enabled = v end })
    :Toggle({ Title = "Box", Value = true, Callback = function(v) ESP.Box = v end })
    :Toggle({ Title = "Name", Value = true, Callback = function(v) ESP.Name = v end })
    :Toggle({ Title = "Health Bar", Value = true, Callback = function(v) ESP.HealthBar = v end })
    :Toggle({ Title = "Distance", Value = true, Callback = function(v) ESP.Distance = v end })

Tab_Visuals:Section({ Title = "World Effects" })
    :Toggle({ Title = "Anti-Flashbang", Value = false, Callback = function(v) AntiFlash = v end })
    :Toggle({ Title = "Anti-Smoke", Value = false, Callback = function(v) AntiSmoke = v end })

-- ---- Misc Tab ----
Tab_Misc:Button({
    Title = "UNLOAD ALL",
    Color = Color3.fromRGB(255,0,0),
    Callback = function()
        Aimbot.Enabled = false
        Triggerbot.Enabled = false
        Hitbox.Enabled = false
        ESP.Enabled = false
        Bhop = false
        AntiFlash = false
        AntiSmoke = false
        UseController = false
        WindUI:Notify({ Title = "HvH", Content = "All features disabled." })
    end,
})

WindUI:Notify({ Title = "BloxStrike HvH", Content = "Loaded! Adjust remote name for Silent Aim if needed." })
print("BloxStrike HvH (WindUI) ready. Remote: FireBullet (change if different).")