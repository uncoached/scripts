--// Universal HvH Script (WindUI) – Raycast Silent Aim
--// Works in most Roblox FPS games. Auto‑detects common weapon remotes.
--// If Silent Aim doesn't work, enter the correct remote name in the UI.
--// All exploit functions are checked before use – no crashes.
--//
--// This version uses proper WindUI syntax (no method chaining on sections)
--// to ensure all UI elements appear correctly.

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

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- Settings
local Settings = {
    Aimbot = {
        Enabled = false,
        Silent = true,
        FOV = 200,
        Smoothness = 0.1,
        HitPart = "Head",
        VisibleCheck = true,
        TeamCheck = false,
        AimKey = Enum.UserInputType.MouseButton2,
    },
    Triggerbot = {
        Enabled = false,
        Delay = 0,
    },
    Hitbox = {
        Enabled = false,
        Size = 3,
    },
    ESP = {
        Enabled = false,
        Box = true,
        Name = true,
        HealthBar = true,
        Distance = true,
    },
    Bhop = false,
    AntiFlash = false,
    AntiSmoke = false,
    Controller = {
        Enabled = false,
        Sensitivity = 0.5,
    },
    SilentAimRemote = "FireBullet",
}

-- Drawing library
local Drawing = nil
pcall(function()
    Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/Insei/PenisMan/refs/heads/main/DrawingLib.lua"))()
end)
if not Drawing then pcall(function() Drawing = { new = function() return {} end } end) end

-- FOV circle (outline)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255,255,255)
FOVCircle.Thickness = 1

-- Silent aim target
local SilentAimTarget = nil

-- ================= UTILITY FUNCTIONS =================
local function getCharacter(player) return player.Character end
local function getHead(char) return char and char:FindFirstChild("Head") end
local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function getHumanoid(char) return char and char:FindFirstChildWhichIsA("Humanoid") end
local function teamCheck(player)
    if not Settings.Aimbot.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin).Unit * 1000
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit and hit:IsDescendantOf(part.Parent)
end

-- ================= AIMBOT TARGET ACQUISITION =================
local function getClosestEnemy()
    local closest = nil
    local closestDist = Settings.Aimbot.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or teamCheck(player) then continue end
        local char = player.Character
        if not char then continue end
        local hum = getHumanoid(char)
        if not hum or hum.Health <= 0 then continue end

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
            closest = part
        end
    end
    return closest
end

-- ================= AIM KEY HANDLING =================
local isAiming = false
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Settings.Aimbot.AimKey then isAiming = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Settings.Aimbot.AimKey then isAiming = false end
end)

-- ================= RENDER LOOP (FOV + CAMERA AIM) =================
RunService.RenderStepped:Connect(function()
    -- FOV circle
    if Settings.Aimbot.Enabled then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Radius = Settings.Aimbot.FOV
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if not Settings.Aimbot.Enabled then
        SilentAimTarget = nil
        return
    end

    local target = getClosestEnemy()
    SilentAimTarget = (Settings.Aimbot.Silent and target) or nil

    if not Settings.Aimbot.Silent and isAiming and target then
        local headPos = Camera:WorldToViewportPoint(target.Position)
        local mousePos = UIS:GetMouseLocation()
        local moveX = (headPos.X - mousePos.X) / (Settings.Aimbot.Smoothness * 5)
        local moveY = (headPos.Y - mousePos.Y) / (Settings.Aimbot.Smoothness * 5)
        if mousemoverel then mousemoverel(moveX, moveY) end
    end
end)

-- ================= SILENT AIM HOOK =================
local function hookSilentAim(remoteName)
    -- Try to find and hook the remote
    local function findRemote(name)
        for _, remote in ipairs(RS:GetDescendants()) do
            if remote:IsA("RemoteEvent") and remote.Name == name then
                return remote
            end
        end
        return nil
    end

    local remote = findRemote(remoteName)
    if not remote then
        -- Try a few common names
        for _, name in ipairs({"FireBullet", "Shoot", "WeaponFire", "Fire", "RaycastHit"}) do
            remote = findRemote(name)
            if remote then break end
        end
    end

    if remote then
        local oldFire = hookfunction(remote.FireServer, function(self, ...)
            local args = {...}
            if SilentAimTarget and Settings.Aimbot.Enabled and Settings.Aimbot.Silent then
                args[1] = SilentAimTarget.Position
            end
            return oldFire(self, unpack(args))
        end)
        return true
    end
    return false
end

-- Initial hook attempt
local silentAimHooked = false
pcall(function() silentAimHooked = hookSilentAim(Settings.SilentAimRemote) end)

-- ================= TRIGGERBOT =================
task.spawn(function()
    while task.wait(0.01) do
        if Settings.Triggerbot.Enabled then
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
                    if hum and hum.Health > 0 then
                        local plr = Players:GetPlayerFromCharacter(model)
                        if plr and plr ~= LocalPlayer and not teamCheck(plr) then
                            if Settings.Triggerbot.Delay > 0 then task.wait(Settings.Triggerbot.Delay/1000) end
                            if mouse1click then mouse1click() end
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end
end)

-- ================= HITBOX EXPANDER =================
local originalHeadSizes = {}
task.spawn(function()
    while task.wait(0.5) do
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or teamCheck(player) then continue end
            local char = player.Character
            if char then
                local head = getHead(char)
                local hum = getHumanoid(char)
                if head and hum and hum.Health > 0 then
                    if not originalHeadSizes[head] then originalHeadSizes[head] = head.Size end
                    if Settings.Hitbox.Enabled then
                        head.Size = Vector3.new(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
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

-- ================= BUNNY HOP =================
RunService.RenderStepped:Connect(function()
    if Settings.Bhop and UIS:IsKeyDown(Enum.KeyCode.Space) then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                hum.Jump = true
            end
        end
    end
end)

-- ================= ESP =================
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
    if not Settings.ESP.Enabled then
        for _, e in pairs(espCache) do for _, d in pairs(e) do d.Visible = false end end
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
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            if onScreen then
                local boxH = math.abs(headPos.Y - legPos.Y)
                local boxW = boxH / 2
                local dist = math.floor((Camera.CFrame.Position - root.Position).Magnitude)

                if Settings.ESP.Box then
                    esp.boxOutline.Size = Vector2.new(boxW, boxH); esp.boxOutline.Position = Vector2.new(rootPos.X - boxW/2, headPos.Y); esp.boxOutline.Visible = true
                    esp.box.Size = esp.boxOutline.Size; esp.box.Position = esp.boxOutline.Position; esp.box.Visible = true
                else
                    esp.boxOutline.Visible = false; esp.box.Visible = false
                end

                if Settings.ESP.HealthBar then
                    local hpPct = hum.Health / hum.MaxHealth
                    local barX = rootPos.X - boxW/2 - 6
                    esp.healthOutline.From = Vector2.new(barX, headPos.Y - 1); esp.healthOutline.To = Vector2.new(barX, headPos.Y + boxH + 1); esp.healthOutline.Visible = true
                    esp.healthBar.From = Vector2.new(barX, headPos.Y + boxH); esp.healthBar.To = Vector2.new(barX, headPos.Y + boxH - (boxH * hpPct))
                    esp.healthBar.Color = Color3.new(1 - hpPct, hpPct, 0); esp.healthBar.Visible = true
                else
                    esp.healthOutline.Visible = false; esp.healthBar.Visible = false
                end

                esp.name.Text = Settings.ESP.Name and player.Name or ""; esp.name.Position = Vector2.new(rootPos.X, headPos.Y - 20); esp.name.Visible = Settings.ESP.Name
                esp.distance.Text = Settings.ESP.Distance and ("[" .. dist .. "m]") or ""; esp.distance.Position = Vector2.new(rootPos.X, headPos.Y + boxH + 2); esp.distance.Visible = Settings.ESP.Distance
            else
                for _, d in pairs(esp) do d.Visible = false end
            end
        end
    end
    for plr, esp in pairs(espCache) do
        if not aliveSet[plr] then
            for _, d in pairs(esp) do d:Remove() end
            espCache[plr] = nil
        end
    end
end)

-- ================= ANTI-FLASH & ANTI-SMOKE =================
task.spawn(function()
    while task.wait(0.2) do
        if Settings.AntiFlash then
            local gui = LocalPlayer.PlayerGui:FindFirstChild("FlashbangEffect")
            local effect = Lighting:FindFirstChild("FlashbangColorCorrection")
            if gui then gui:Destroy() end
            if effect then effect:Destroy() end
        end
    end
end)
task.spawn(function()
    while task.wait(0.5) do
        if Settings.AntiSmoke then
            local debris = Workspace:FindFirstChild("Debris")
            if debris then
                for _, folder in pairs(debris:GetChildren()) do
                    if string.match(folder.Name, "Voxel") then folder:ClearAllChildren(); folder:Destroy() end
                end
            end
        end
    end
end)

-- ================= CONTROLLER AIM =================
UIS.InputChanged:Connect(function(input)
    if Settings.Controller.Enabled and (input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2) then
        if input.KeyCode == Enum.KeyCode.Thumbstick2 then
            local delta = input.Delta
            local sens = Settings.Controller.Sensitivity * 5
            if mousemoverel then mousemoverel(math.floor(delta.X * sens), math.floor(delta.Y * -sens)) end
        end
    end
end)

-- ================= WINDUI INTERFACE (proper syntax) =================
local Window = WindUI:CreateWindow({
    Title = "Universal HvH",
    Folder = "universal_hvh",
    Icon = "solar:target-bold",
    OpenButton = { Title = "Open HvH", Enabled = true, Scale = 0.5 },
})

-- Tabs
local Tab_Aim = Window:Tab({ Title = "Aimbot", Icon = "solar:target-bold" })
local Tab_Trig = Window:Tab({ Title = "Triggerbot", Icon = "solar:mouse-bold" })
local Tab_Hit = Window:Tab({ Title = "Hitbox", Icon = "solar:size-bold" })
local Tab_ESP = Window:Tab({ Title = "ESP", Icon = "solar:eye-bold" })
local Tab_World = Window:Tab({ Title = "World", Icon = "solar:globus-bold" })
local Tab_Move = Window:Tab({ Title = "Movement", Icon = "solar:run-bold" })
local Tab_Ctrl = Window:Tab({ Title = "Controller", Icon = "solar:gamepad-bold" })
local Tab_Misc = Window:Tab({ Title = "Misc", Icon = "solar:settings-bold" })

-- Aimbot sections and elements
do
    local Section1 = Tab_Aim:Section({ Title = "Main" })
    Section1:Toggle({ Title = "Enable Aimbot", Value = false, Callback = function(v) Settings.Aimbot.Enabled = v end })
    Section1:Toggle({ Title = "Silent Aim (Raycast)", Value = true, Callback = function(v) Settings.Aimbot.Silent = v end })
    Section1:Toggle({ Title = "Visibility Check", Value = true, Callback = function(v) Settings.Aimbot.VisibleCheck = v end })
    Section1:Toggle({ Title = "Team Check", Value = false, Callback = function(v) Settings.Aimbot.TeamCheck = v end })
    Section1:Slider({ Title = "FOV", Step = 10, Value = { Min = 10, Max = 500, Default = 200 }, Callback = function(v) Settings.Aimbot.FOV = v end })
    Section1:Slider({ Title = "Smoothness", Step = 0.1, Value = { Min = 0.1, Max = 1, Default = 0.1 }, Callback = function(v) Settings.Aimbot.Smoothness = v end })
    Section1:Dropdown({ Title = "Hit Part", Values = { "Head", "UpperTorso", "HumanoidRootPart" }, Value = "Head", Callback = function(v) Settings.Aimbot.HitPart = v end })
    Section1:Dropdown({ Title = "Aim Key", Values = { "Right Mouse", "Left Mouse", "E", "Q" }, Value = "Right Mouse", Callback = function(v)
        if v == "Right Mouse" then Settings.Aimbot.AimKey = Enum.UserInputType.MouseButton2
        elseif v == "Left Mouse" then Settings.Aimbot.AimKey = Enum.UserInputType.MouseButton1
        else Settings.Aimbot.AimKey = Enum.KeyCode[v] end
    end })

    local Section2 = Tab_Aim:Section({ Title = "Silent Aim Remote" })
    Section2:Input({ Title = "Remote Name", Value = "FireBullet", Placeholder = "e.g. FireBullet", Callback = function(v)
        Settings.SilentAimRemote = v
        local ok = pcall(function() silentAimHooked = hookSilentAim(v) end)
        if not ok or not silentAimHooked then
            WindUI:Notify({ Title = "Error", Content = "Remote not found. Try a different name.", Duration = 3 })
        else
            WindUI:Notify({ Title = "Success", Content = "Silent aim hooked!", Duration = 2 })
        end
    end })
    Section2:Button({ Title = "Auto-Detect Remote", Callback = function()
        local names = {"FireBullet", "Shoot", "WeaponFire", "Fire", "RaycastHit", "ShootEvent"}
        for _, name in ipairs(names) do
            local ok = pcall(function() silentAimHooked = hookSilentAim(name) end)
            if ok and silentAimHooked then
                Settings.SilentAimRemote = name
                WindUI:Notify({ Title = "Detected", Content = "Hooked remote: " .. name, Duration = 3 })
                return
            end
        end
        WindUI:Notify({ Title = "Failed", Content = "No known remote found. Enter manually.", Duration = 3 })
    end })
end

-- Triggerbot
do
    local Section = Tab_Trig:Section({ Title = "Triggerbot" })
    Section:Toggle({ Title = "Enable Triggerbot", Value = false, Callback = function(v) Settings.Triggerbot.Enabled = v end })
    Section:Slider({ Title = "Delay (ms)", Step = 10, Value = { Min = 0, Max = 500, Default = 0 }, Callback = function(v) Settings.Triggerbot.Delay = v end })
end

-- Hitbox
do
    local Section = Tab_Hit:Section({ Title = "Hitbox" })
    Section:Toggle({ Title = "Enable Hitbox", Value = false, Callback = function(v) Settings.Hitbox.Enabled = v end })
    Section:Slider({ Title = "Head Size", Step = 0.1, Value = { Min = 1, Max = 3, Default = 3 }, Callback = function(v) Settings.Hitbox.Size = v end })
end

-- ESP
do
    local Section = Tab_ESP:Section({ Title = "Player ESP" })
    Section:Toggle({ Title = "Enable ESP", Value = false, Callback = function(v) Settings.ESP.Enabled = v end })
    Section:Toggle({ Title = "Box", Value = true, Callback = function(v) Settings.ESP.Box = v end })
    Section:Toggle({ Title = "Name", Value = true, Callback = function(v) Settings.ESP.Name = v end })
    Section:Toggle({ Title = "Health Bar", Value = true, Callback = function(v) Settings.ESP.HealthBar = v end })
    Section:Toggle({ Title = "Distance", Value = true, Callback = function(v) Settings.ESP.Distance = v end })
end

-- World effects
do
    local Section = Tab_World:Section({ Title = "Effects" })
    Section:Toggle({ Title = "Anti-Flashbang", Value = false, Callback = function(v) Settings.AntiFlash = v end })
    Section:Toggle({ Title = "Anti-Smoke", Value = false, Callback = function(v) Settings.AntiSmoke = v end })
end

-- Movement
do
    local Section = Tab_Move:Section({ Title = "Bunny Hop" })
    Section:Toggle({ Title = "Bunny Hop (Hold Space)", Value = false, Callback = function(v) Settings.Bhop = v end })
end

-- Controller
do
    local Section = Tab_Ctrl:Section({ Title = "Aim Assist" })
    Section:Toggle({ Title = "Use Controller Aim (Right Stick)", Value = false, Callback = function(v) Settings.Controller.Enabled = v end })
    Section:Slider({ Title = "Sensitivity", Step = 0.1, Value = { Min = 0.1, Max = 2, Default = 0.5 }, Callback = function(v) Settings.Controller.Sensitivity = v end })
end

-- Misc
Tab_Misc:Button({
    Title = "UNLOAD ALL",
    Color = Color3.fromRGB(255,0,0),
    Callback = function()
        Settings.Aimbot.Enabled = false
        Settings.Triggerbot.Enabled = false
        Settings.Hitbox.Enabled = false
        Settings.ESP.Enabled = false
        Settings.Bhop = false
        Settings.AntiFlash = false
        Settings.AntiSmoke = false
        Settings.Controller.Enabled = false
        WindUI:Notify({ Title = "HvH", Content = "All features disabled.", Duration = 3 })
    end,
})

WindUI:Notify({ Title = "Universal HvH", Content = "Loaded! Use Auto-Detect or enter remote name for Silent Aim.", Duration = 5 })
print("Universal HvH (Raycast Silent Aim) ready. If aim doesn't work, adjust remote name in Aimbot tab.")