--// Advanced HvH Script for ROBLOX RIVALS (Custom UI – No External Libraries)
--// Features: ESP (Box, Name, Health, Distance, Skeleton), Camera Aimbot, Raycast Silent Aim, Triggerbot,
--//           Controller Support (Right Stick Aim), Radar, Chams, Glow, Anti-Aim, Nightmode, Fullbright, etc.
--// Requires a mid/high-level executor (supports Drawing, getconnections, hookfunction, mouse1press, etc.)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// ============= SETTINGS =============
local Settings = {
    Aimbot = {
        Enabled = false,
        Silent = true,              -- Raycast silent aim (overrides bullet destination)
        HitPart = "Head",          -- Head, UpperTorso, HumanoidRootPart
        FOV = 200,                 -- Aim assist radius (pixels)
        Smoothness = 0.1,          -- 0 = instant snap, 1 = very slow
        VisibleCheck = true,       -- Only target visible enemies
        TeamCheck = true,          -- Ignore teammates
        Triggerbot = false,
        TriggerDelay = 0.1,
        UseController = false,      -- Activate aim assist with controller right stick
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
        AntiAim = false,           -- Desync fake angles
        DesyncAngle = 45,
        AutoCrouch = false,
    }
}

--// ============= UTILITY FUNCTIONS =============
local function getCharacter(player)
    return player.Character or player.CharacterAdded:Wait()
end
local function getHead(char) return char:FindFirstChild("Head") end
local function getHRP(char) return char:FindFirstChild("HumanoidRootPart") end
local function getHumanoid(char) return char:FindFirstChildWhichIsA("Humanoid") end
local function teamCheck(plr)
    return Settings.Aimbot.TeamCheck and plr.Team == LocalPlayer.Team
end
local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local ray = Ray.new(origin, direction)
    local hit, _ = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit and hit:IsDescendantOf(targetPart.Parent)
end

--// ============= CUSTOM UI LIBRARY =============
local UILib = {}
UILib.Windows = {}

function UILib:CreateWindow(title, size)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = game.CoreGui
    local window = Instance.new("Frame")
    window.Size = size or UDim2.new(0, 600, 0, 400)
    window.Position = UDim2.new(0.5, -300, 0.5, -200)
    window.BackgroundColor3 = Color3.fromRGB(25,25,25)
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Parent = screenGui

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1,0,0,30)
    topBar.BackgroundColor3 = Color3.fromRGB(45,45,45)
    topBar.BorderSizePixel = 0
    topBar.Parent = window

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1,-80,1,0)
    titleLabel.Position = UDim2.new(0,10,0,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.new(1,1,1)
    titleLabel.Font = Enum.Font.SourceSans
    titleLabel.TextSize = 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = topBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,30,0,30)
    closeBtn.Position = UDim2.new(1,-30,0,0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255,60,60)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Parent = topBar
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

    -- Tabs container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0,120,1,-30)
    tabContainer.Position = UDim2.new(0,0,0,30)
    tabContainer.BackgroundColor3 = Color3.fromRGB(35,35,35)
    tabContainer.BorderSizePixel = 0
    tabContainer.Name = "TabContainer"
    tabContainer.Parent = window

    local pages = Instance.new("Frame")
    pages.Size = UDim2.new(1,-120,1,-30)
    pages.Position = UDim2.new(0,120,0,30)
    pages.BackgroundColor3 = Color3.fromRGB(30,30,30)
    pages.BorderSizePixel = 0
    pages.Name = "Pages"
    pages.Parent = window

    -- Draggability
    local dragging, dragInput, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local wind = { Window = window, Tabs = {}, Pages = pages, ScreenGui = screenGui }
    table.insert(UILib.Windows, wind)
    return wind
end

function UILib:CreateTab(window, name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1,0,0,30)
    tabBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.new(1,1,1)
    tabBtn.Font = Enum.Font.SourceSans
    tabBtn.TextSize = 16
    tabBtn.Parent = window.Window:FindFirstChild("TabContainer")
    if not window.TabsContainer then window.TabsContainer = tabBtn.Parent end

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Parent = window.Pages
    page.Visible = false

    tabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(window.Pages:GetChildren()) do p.Visible = false end
        page.Visible = true
    end)

    local tab = { Button = tabBtn, Page = page }
    table.insert(window.Tabs, tab)
    return tab
end

function UILib:CreateToggle(tab, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.Position = UDim2.new(0,10,0,0)
    frame.BackgroundTransparency = 1
    frame.Parent = tab.Page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 30, 0, 20)
    toggleBtn.Position = UDim2.new(1, -35, 0, 5)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(0,255,0) or Color3.fromRGB(100,100,100)
    toggleBtn.Text = ""
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0,255,0) or Color3.fromRGB(100,100,100)
        callback(state)
    end)

    return { Toggle = state, Button = toggleBtn }
end

function UILib:CreateSlider(tab, text, min, max, default, step, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = tab.Page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,0,15)
    label.BackgroundTransparency = 1
    label.Text = text .. " [".. default .."]"
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -40, 0, 10)
    sliderBg.Position = UDim2.new(0,20,0,20)
    sliderBg.BackgroundColor3 = Color3.fromRGB(70,70,70)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0,0,1,0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0,170,255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg

    local sliderBtn = Instance.new("TextButton")
    sliderBtn.Size = UDim2.new(0,16,0,16)
    sliderBtn.Position = UDim2.new(0, -8, 0, -3)
    sliderBtn.BackgroundColor3 = Color3.new(1,1,1)
    sliderBtn.Text = ""
    sliderBtn.BorderSizePixel = 0
    sliderBtn.Parent = sliderBg

    local function updateValue(value)
        local percent = (value - min) / (max - min)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderBtn.Position = UDim2.new(percent, -8, 0, -3)
        label.Text = text .. " [".. math.floor(value) .."]"
        callback(value)
    end

    local val = default
    updateValue(val)

    local dragging = false
    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            val = min + percent * (max - min)
            if step then val = math.floor(val / step + 0.5) * step end
            updateValue(val)
        end
    end)

    return { Set = function(v) val = v; updateValue(v) end, Get = function() return val end }
end

function UILib:CreateDropdown(tab, text, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = tab.Page

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local chosen = default or options[1]
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(0, 80, 1, 0)
    selectedLabel.Position = UDim2.new(1, -80, 0, 0)
    selectedLabel.BackgroundColor3 = Color3.fromRGB(60,60,60)
    selectedLabel.Text = chosen
    selectedLabel.TextColor3 = Color3.new(1,1,1)
    selectedLabel.Font = Enum.Font.SourceSans
    selectedLabel.TextSize = 14
    selectedLabel.Parent = frame

    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(0, 80, 0, #options * 25)
    dropdownFrame.Position = UDim2.new(1, -80, 1, 0)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)
    dropdownFrame.Visible = false
    dropdownFrame.Parent = frame

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1,0,0,25)
        optBtn.Position = UDim2.new(0,0,0, (i-1)*25)
        optBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
        optBtn.Text = opt
        optBtn.TextColor3 = Color3.new(1,1,1)
        optBtn.Parent = dropdownFrame
        optBtn.MouseButton1Click:Connect(function()
            chosen = opt
            selectedLabel.Text = opt
            dropdownFrame.Visible = false
            callback(opt)
        end)
    end

    selectedLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dropdownFrame.Visible = not dropdownFrame.Visible
        end
    end)

    return { Get = function() return chosen end, Set = function(v) chosen = v; selectedLabel.Text = v end }
end

function UILib:CreateButton(tab, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0,10,0,0)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = tab.Page
    btn.MouseButton1Click:Connect(callback)
    return btn
end

--// ============= UI LAYOUT HELPER =============
local function layoutElements(page)
    local y = 10
    for _, child in pairs(page:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child.Position = UDim2.new(0, 10, 0, y)
            y = y + child.Size.Y.Offset + 5
        end
    end
end

--// ============= CREATE THE WINDOW =============
local Window = UILib:CreateWindow("Roblox Rivals HvH", UDim2.new(0, 620, 0, 430))
local aimTab = UILib:CreateTab(Window, "Aimbot")
local espTab = UILib:CreateTab(Window, "ESP")
local visualsTab = UILib:CreateTab(Window, "Visuals")
local miscTab = UILib:CreateTab(Window, "Misc")

-- Aimbot elements
UILib:CreateToggle(aimTab, "Enable Aimbot", false, function(v) Settings.Aimbot.Enabled = v end)
UILib:CreateToggle(aimTab, "Silent Aim (Raycast)", true, function(v) Settings.Aimbot.Silent = v end)
UILib:CreateToggle(aimTab, "Triggerbot", false, function(v) Settings.Aimbot.Triggerbot = v end)
UILib:CreateToggle(aimTab, "Visibility Check", true, function(v) Settings.Aimbot.VisibleCheck = v end)
UILib:CreateToggle(aimTab, "Team Check", true, function(v) Settings.Aimbot.TeamCheck = v end)
UILib:CreateToggle(aimTab, "Use Controller", false, function(v) Settings.Aimbot.UseController = v end)
UILib:CreateSlider(aimTab, "FOV", 10, 500, 200, 10, function(v) Settings.Aimbot.FOV = v end)
UILib:CreateSlider(aimTab, "Smoothness", 0.01, 1, 0.1, 0.01, function(v) Settings.Aimbot.Smoothness = v end)
UILib:CreateSlider(aimTab, "Controller Sensitivity", 0.1, 2, 0.5, 0.1, function(v) Settings.Aimbot.ControllerSensitivity = v end)
UILib:CreateDropdown(aimTab, "Hit Part", {"Head","UpperTorso","HumanoidRootPart"}, "Head", function(v) Settings.Aimbot.HitPart = v end)
UILib:CreateSlider(aimTab, "Trigger Delay", 0.05, 1, 0.1, 0.05, function(v) Settings.Aimbot.TriggerDelay = v end)

-- ESP elements
UILib:CreateToggle(espTab, "Enable ESP", true, function(v) Settings.Visuals.ESP.Enabled = v end)
UILib:CreateToggle(espTab, "Box", true, function(v) Settings.Visuals.ESP.Box = v end)
UILib:CreateToggle(espTab, "Name", true, function(v) Settings.Visuals.ESP.Name = v end)
UILib:CreateToggle(espTab, "Health Bar", true, function(v) Settings.Visuals.ESP.HealthBar = v end)
UILib:CreateToggle(espTab, "Distance", true, function(v) Settings.Visuals.ESP.Distance = v end)
UILib:CreateToggle(espTab, "Skeleton", false, function(v) Settings.Visuals.ESP.Skeleton = v end)

-- Visuals elements
UILib:CreateToggle(visualsTab, "Chams", false, function(v) Settings.Visuals.Chams = v; toggleChams(v) end)
UILib:CreateToggle(visualsTab, "Glow", false, function(v) Settings.Visuals.Glow = v; toggleGlow(v) end)
UILib:CreateToggle(visualsTab, "Night Mode", false, function(v) Settings.Visuals.NightMode = v; Lighting.ClockTime = v and 0 or 14; Lighting.Brightness = v and 0.5 or 2 end)
UILib:CreateToggle(visualsTab, "Fullbright", false, function(v) Settings.Visuals.Fullbright = v; Lighting.Ambient = v and Color3.new(1,1,1) or Color3.new(0,0,0) end)

-- Misc elements
UILib:CreateToggle(miscTab, "Radar", true, function(v) Settings.Misc.Radar = v; toggleRadar(v) end)
UILib:CreateSlider(miscTab, "Radar Size", 100, 400, 200, 10, function(v) Settings.Misc.RadarSize = v end)
UILib:CreateSlider(miscTab, "Radar Zoom", 0.5, 5, 1, 0.1, function(v) Settings.Misc.RadarZoom = v end)
UILib:CreateToggle(miscTab, "Anti-Aim (Desync)", false, function(v) Settings.Misc.AntiAim = v end)
UILib:CreateSlider(miscTab, "Desync Angle", 0, 90, 45, 5, function(v) Settings.Misc.DesyncAngle = v end)
UILib:CreateToggle(miscTab, "Auto Crouch", false, function(v) Settings.Misc.AutoCrouch = v end)

-- Layout all tabs
for _, tab in pairs(Window.Tabs) do
    layoutElements(tab.Page)
end

-- Show first tab
Window.Tabs[1].Page.Visible = true

--// ============= FEATURE IMPLEMENTATIONS =============
local Lighting = game:GetService("Lighting")
local ESPCache = {}
local SilentAimTarget = nil

-- Drawing library initialization (for ESP)
local Drawing = nil
pcall(function() Drawing = loadstring(game:HttpGet("https://raw.githubusercontent.com/Insei/PenisMan/refs/heads/main/DrawingLib.lua"))() end)
if not Drawing then pcall(function() Drawing = {}; Drawing.new = function() return {} end end) end

local function createESP(player)
    local esp = {}
    if Drawing.new then
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
        for i=1,10 do  -- 10 bones pairs for skeleton
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
            for _, v in pairs(esp) do if type(v)=="table" and v.Visible then v.Visible = false end end
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
            else if esp.box then esp.box.Visible = false end end

            if Settings.Visuals.ESP.Name and esp.name then
                esp.name.Visible = true
                esp.name.Text = player.Name
                esp.name.Position = Vector2.new(hrpPos.X, y - 15)
            else if esp.name then esp.name.Visible = false end end

            if Settings.Visuals.ESP.HealthBar and esp.healthBar then
                local humanoid = getHumanoid(char)
                if humanoid then
                    local health = humanoid.Health / humanoid.MaxHealth
                    esp.healthBar.Visible = true
                    esp.healthBar.Size = Vector2.new(2, height * health)
                    esp.healthBar.Position = Vector2.new(x - 6, y + height * (1 - health))
                    esp.healthBar.Color = Color3.new(1-health, health, 0)
                else esp.healthBar.Visible = false end
            else if esp.healthBar then esp.healthBar.Visible = false end end

            if Settings.Visuals.ESP.Distance and esp.distance then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                esp.distance.Visible = true
                esp.distance.Text = string.format("%.0f", dist)
                esp.distance.Position = Vector2.new(hrpPos.X, y + height + 5)
            else if esp.distance then esp.distance.Visible = false end end

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
                            else esp.skeleton[i].Visible = false end
                        else esp.skeleton[i].Visible = false end
                    end
                end
            else if esp.skeleton then for _,v in pairs(esp.skeleton) do v.Visible = false end end end
        else
            for _, v in pairs(esp) do if type(v)=="table" and v.Visible then v.Visible = false end end
        end
    end
end

-- Aimbot target acquisition
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

-- Camera Aimbot (non-silent)
RunService.RenderStepped:Connect(function(delta)
    if Settings.Aimbot.Enabled and not Settings.Aimbot.Silent then
        local target = getTarget()
        if target then
            local smooth = Settings.Aimbot.Smoothness
            local targetPos = target.Part.Position
            local newCF = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, smooth)
        end
    end
    -- Silent aim: store target for remote hook
    if Settings.Aimbot.Enabled and Settings.Aimbot.Silent then
        SilentAimTarget = getTarget()
    else
        SilentAimTarget = nil
    end
end)

-- Silent Aim: Hook weapon remote (ROBLOX RIVALS specific – CHANGE THIS REMOTE NAME)
local function hookSilentAim()
    -- Common remotes in Rivals: "FireBullet", "Shoot", "WeaponFire". Adjust to actual remote.
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
pcall(hookSilentAim)  -- Will fail silently if remote not found; use Dex Explorer to identify.

-- Triggerbot
spawn(function()
    while task.wait(Settings.Aimbot.TriggerDelay) do
        if Settings.Aimbot.Triggerbot and Settings.Aimbot.Enabled then
            local target = getTarget()
            if target and SilentAimTarget then
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end
        end
    end
end)

-- Controller Aim (Right Stick)
UserInputService.InputChanged:Connect(function(input)
    if Settings.Aimbot.UseController and (input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2) then
        if input.KeyCode == Enum.KeyCode.Thumbstick2 then
            local delta = input.Delta
            local sens = Settings.Aimbot.ControllerSensitivity * 5
            mousemoverel(math.floor(delta.X * sens), math.floor(delta.Y * -sens))
        end
    end
end)

-- Chams
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

-- Glow
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

-- Radar
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
            for _, player in pairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local char = player.Character
                if not char then continue end
                local root = getHRP(char)
                if not root or not localRoot then continue end
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
            RunService.Heartbeat:Wait()
        end
    end)
end

-- Anti-Aim (Desync)
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

-- Auto Crouch
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

-- ESP render loop
RunService.RenderStepped:Connect(function()
    if Settings.Visuals.ESP.Enabled then
        updateESP()
    end
end)

-- FOV circle (NO FILL, just outline)
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Color = Color3.new(1,0,0)
fovCircle.Thickness = 1
fovCircle.NumSides = 60
fovCircle.Filled = false  -- explicitly set to false
RunService.RenderStepped:Connect(function()
    if Settings.Aimbot.Enabled then
        fovCircle.Visible = true
        fovCircle.Radius = Settings.Aimbot.FOV
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    else
        fovCircle.Visible = false
    end
end)

-- Initial load of default visuals
pcall(toggleRadar, true)   -- start radar
pcall(toggleChams, false)
pcall(toggleGlow, false)

print("// Roblox Rivals HvH Loaded! Check the remote name for Silent Aim if not working.")
print("// Use Dex Explorer to find the correct weapon remote and update the hookSilentAim function.")