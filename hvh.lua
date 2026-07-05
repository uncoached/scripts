-- Tulip.lua - Advanced HvH Script for Roblox Rivals (Custom UI)
-- Full script with integrated HvH features using the provided UI library.

-- (Paste the entire UI library code from the two user messages here, 
--  up to just before the existing menu.Initialize call. 
--  Then continue with the rest of this script.)

-- =============================================
--  REPLACE THE OLD MENU.INITIALIZE WITH THIS:
-- =============================================

-- Overwrite the existing menu.Initialize call with our custom tabs and features.
menu.Initialize({
    {
        name = "Aimbot",
        content = {
            {
                name = "Main",
                autopos = "left",
                content = {
                    {
                        type = "toggle",
                        name = "Enable Aimbot",
                        value = false,
                        callback = function(bool) getgenv().AimbotEnabled = bool end
                    },
                    {
                        type = "toggle",
                        name = "Camera Aimbot (Viewport)",
                        value = false,
                        callback = function(bool) getgenv().CameraAim = bool end
                    },
                    {
                        type = "toggle",
                        name = "Silent Aim (Raycast)",
                        value = true,
                        callback = function(bool) getgenv().SilentAim = bool end
                    },
                    {
                        type = "toggle",
                        name = "Show FOV Circle",
                        value = true,
                        callback = function(bool) getgenv().ShowFOV = bool end
                    },
                    {
                        type = "toggle",
                        name = "Visibility Check",
                        value = true,
                        callback = function(bool) getgenv().VisCheck = bool end
                    },
                    {
                        type = "toggle",
                        name = "Team Check",
                        value = false,
                        callback = function(bool) getgenv().TeamCheck = bool end
                    },
                    {
                        type = "slider",
                        name = "FOV",
                        value = 200,
                        minvalue = 10,
                        maxvalue = 500,
                        stradd = "px",
                        callback = function(v) getgenv().AimbotFOV = v end
                    },
                    {
                        type = "slider",
                        name = "Smoothness",
                        value = 0.1,
                        minvalue = 0.1,
                        maxvalue = 1,
                        decimal = 0.1,
                        callback = function(v) getgenv().Smoothness = v end
                    },
                    {
                        type = "dropbox",
                        name = "Hit Part",
                        value = 1,
                        values = {"Head", "UpperTorso", "HumanoidRootPart"},
                        callback = function(v) getgenv().HitPart = v end
                    },
                    {
                        type = "dropbox",
                        name = "Aim Key",
                        value = 1,
                        values = {"Right Mouse", "Left Mouse", "E", "Q"},
                        callback = function(v)
                            if v == "Right Mouse" then getgenv().AimKey = Enum.UserInputType.MouseButton2
                            elseif v == "Left Mouse" then getgenv().AimKey = Enum.UserInputType.MouseButton1
                            else getgenv().AimKey = Enum.KeyCode[v] end
                        end
                    },
                }
            },
            {
                name = "Silent Aim Remote",
                autopos = "right",
                content = {
                    {
                        type = "input",
                        name = "Remote Name",
                        value = "FireBullet",
                        placeholder = "e.g. FireBullet",
                        callback = function(v)
                            getgenv().RemoteName = v
                            pcall(function() hookSilentAim(v) end)
                        end
                    },
                    {
                        type = "button",
                        name = "Auto-Detect Remote",
                        callback = function()
                            local names = {"FireBullet", "Shoot", "WeaponFire", "Fire", "RaycastHit"}
                            for _, n in ipairs(names) do
                                local ok = pcall(function() hookSilentAim(n) end)
                                if ok then
                                    CreateNotification("Hooked remote: " .. n)
                                    return
                                end
                            end
                            CreateNotification("No remote found.")
                        end
                    },
                }
            },
        }
    },
    {
        name = "Visuals",
        content = {
            {
                name = "ESP",
                autopos = "left",
                content = {
                    {
                        type = "toggle",
                        name = "Enable ESP",
                        value = false,
                        callback = function(bool) getgenv().ESPEnabled = bool end
                    },
                    {
                        type = "toggle",
                        name = "Box",
                        value = true,
                        callback = function(bool) getgenv().ESPBox = bool end
                    },
                    {
                        type = "toggle",
                        name = "Name",
                        value = true,
                        callback = function(bool) getgenv().ESPName = bool end
                    },
                    {
                        type = "toggle",
                        name = "Health Bar",
                        value = true,
                        callback = function(bool) getgenv().ESPHealth = bool end
                    },
                    {
                        type = "toggle",
                        name = "Distance",
                        value = true,
                        callback = function(bool) getgenv().ESPDistance = bool end
                    },
                    {
                        type = "toggle",
                        name = "Tracers",
                        value = true,
                        callback = function(bool) getgenv().ESPTracers = bool end
                    },
                    {
                        type = "toggle",
                        name = "Skeleton (R6/R15)",
                        value = false,
                        callback = function(bool) getgenv().ESPSkeleton = bool end
                    },
                }
            },
            {
                name = "World",
                autopos = "right",
                content = {
                    {
                        type = "toggle",
                        name = "Anti-Flash",
                        value = false,
                        callback = function(bool) getgenv().AntiFlash = bool end
                    },
                    {
                        type = "toggle",
                        name = "Anti-Smoke",
                        value = false,
                        callback = function(bool) getgenv().AntiSmoke = bool end
                    },
                }
            },
        }
    },
    {
        name = "Misc",
        content = {
            {
                name = "Triggerbot",
                autopos = "left",
                content = {
                    {
                        type = "toggle",
                        name = "Enable Triggerbot",
                        value = false,
                        callback = function(bool) getgenv().TriggerbotEnabled = bool end
                    },
                    {
                        type = "slider",
                        name = "Delay (ms)",
                        value = 0,
                        minvalue = 0,
                        maxvalue = 500,
                        stradd = "ms",
                        callback = function(v) getgenv().TriggerbotDelay = v end
                    },
                }
            },
            {
                name = "Hitbox",
                autopos = "right",
                content = {
                    {
                        type = "toggle",
                        name = "Enable Hitbox",
                        value = false,
                        callback = function(bool) getgenv().HitboxEnabled = bool end
                    },
                    {
                        type = "slider",
                        name = "Head Size",
                        value = 3,
                        minvalue = 1,
                        maxvalue = 3,
                        decimal = 0.1,
                        stradd = "Studs",
                        callback = function(v) getgenv().HitboxSize = v end
                    },
                }
            },
            {
                name = "Movement",
                autopos = "left",
                autofill = true,
                content = {
                    {
                        type = "toggle",
                        name = "Bunny Hop",
                        value = false,
                        callback = function(bool) getgenv().BhopEnabled = bool end
                    },
                }
            },
            {
                name = "Controller",
                autopos = "right",
                autofill = true,
                content = {
                    {
                        type = "toggle",
                        name = "Use Controller (Right Stick)",
                        value = false,
                        callback = function(bool) getgenv().ControllerEnabled = bool end
                    },
                    {
                        type = "slider",
                        name = "Sensitivity",
                        value = 0.5,
                        minvalue = 0.1,
                        maxvalue = 2,
                        decimal = 0.1,
                        callback = function(v) getgenv().ControllerSensitivity = v end
                    },
                }
            },
        }
    },
    {
        name = "Settings",
        content = {
            {
                name = "Cheat Settings",
                x = menu.columns.left,
                y = 66,
                width = menu.columns.width,
                height = 200,
                content = {
                    {
                        type = "toggle",
                        name = "Watermark",
                        value = true,
                        callback = function(bool)
                            for k, v in pairs(menu.watermark.rect) do v.Visible = bool end
                            menu.watermark.text[1].Visible = bool
                        end
                    },
                    {
                        type = "button",
                        name = "Unload Cheat",
                        doubleclick = true,
                        callback = function()
                            menu.fading = true
                            wait()
                            menu:unload()
                        end
                    },
                }
            },
        }
    },
})

-- =============================================
--  FEATURE CODE (Aimbot, ESP, etc.)
-- =============================================

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")

-- Default settings
getgenv().AimbotEnabled = false
getgenv().CameraAim = false
getgenv().SilentAim = true
getgenv().ShowFOV = true
getgenv().AimbotFOV = 200
getgenv().Smoothness = 0.1
getgenv().HitPart = "Head"
getgenv().VisCheck = true
getgenv().TeamCheck = false
getgenv().AimKey = Enum.UserInputType.MouseButton2
getgenv().TriggerbotEnabled = false
getgenv().TriggerbotDelay = 0
getgenv().HitboxEnabled = false
getgenv().HitboxSize = 3
getgenv().BhopEnabled = false
getgenv().AntiFlash = false
getgenv().AntiSmoke = false
getgenv().ControllerEnabled = false
getgenv().ControllerSensitivity = 0.5
getgenv().ESPEnabled = false
getgenv().ESPBox = true
getgenv().ESPName = true
getgenv().ESPHealth = true
getgenv().ESPDistance = true
getgenv().ESPTracers = true
getgenv().ESPSkeleton = false
getgenv().RemoteName = "FireBullet"

-- Drawing for FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255,255,255)
FOVCircle.Thickness = 1

-- Silent aim target
local SilentAimTarget = nil
local isAiming = false

UIS.InputBegan:Connect(function(input)
    if input.UserInputType == getgenv().AimKey then isAiming = true end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == getgenv().AimKey then isAiming = false end
end)

local function teamCheck(plr)
    return getgenv().TeamCheck and plr.Team == LocalPlayer.Team
end
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local dir = (part.Position - origin).Unit * 1000
    local ray = Ray.new(origin, dir)
    local hit = Workspace:FindPartOnRay(ray, LocalPlayer.Character, false, true)
    return hit and hit:IsDescendantOf(part.Parent)
end

local function getClosestEnemy()
    local closest = nil
    local closestDist = getgenv().AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or teamCheck(player) then continue end
        local char = player.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local part
        if getgenv().HitPart == "Head" then part = char:FindFirstChild("Head")
        elseif getgenv().HitPart == "UpperTorso" then part = char:FindFirstChild("UpperTorso")
        else part = char:FindFirstChild("HumanoidRootPart") end
        if not part then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < closestDist then
            if getgenv().VisCheck and not isVisible(part) then continue end
            closestDist = dist
            closest = part
        end
    end
    return closest
end

function hookSilentAim(remoteName)
    local remote = nil
    local remotesFolder = RS:FindFirstChild("Remotes") or RS
    if remotesFolder then
        remote = remotesFolder:FindFirstChild(remoteName) or remotesFolder:FindFirstChild("FireBullet") or remotesFolder:FindFirstChild("Shoot")
    end
    if remote and remote:IsA("RemoteEvent") then
        local old = hookfunction(remote.FireServer, function(self, ...)
            local args = {...}
            if SilentAimTarget and getgenv().AimbotEnabled and getgenv().SilentAim then
                args[1] = SilentAimTarget.Position
            end
            return old(self, unpack(args))
        end)
        return true
    end
    return false
end

-- Start aimbot loops
RunService.RenderStepped:Connect(function()
    -- FOV circle
    if getgenv().AimbotEnabled and getgenv().ShowFOV then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Radius = getgenv().AimbotFOV
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if not getgenv().AimbotEnabled then
        SilentAimTarget = nil
        return
    end

    local target = getClosestEnemy()
    SilentAimTarget = target

    if getgenv().CameraAim and isAiming and target then
        local targetPos = Camera:WorldToViewportPoint(target.Position)
        local mousePos = UIS:GetMouseLocation()
        local smooth = getgenv().Smoothness * 5
        local moveX = (targetPos.X - mousePos.X) / smooth
        local moveY = (targetPos.Y - mousePos.Y) / smooth
        if mousemoverel then mousemoverel(moveX, moveY) end
    end
end)

-- Triggerbot
spawn(function()
    while task.wait(0.01) do
        if getgenv().TriggerbotEnabled then
            local ray = Camera:ViewportPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
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
                            if getgenv().TriggerbotDelay > 0 then task.wait(getgenv().TriggerbotDelay/1000) end
                            if mouse1click then mouse1click() end
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end
end)

-- Hitbox expander
local originalHeadSizes = {}
spawn(function()
    while task.wait(0.5) do
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer or teamCheck(player) then continue end
            local char = player.Character
            if char then
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health > 0 then
                    if not originalHeadSizes[head] then originalHeadSizes[head] = head.Size end
                    if getgenv().HitboxEnabled then
                        head.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
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

-- Bunnyhop
RunService.RenderStepped:Connect(function()
    if getgenv().BhopEnabled and UIS:IsKeyDown(Enum.KeyCode.Space) then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                hum.Jump = true
            end
        end
    end
end)

-- Anti-Flash/Smoke
spawn(function()
    while task.wait(0.2) do
        if getgenv().AntiFlash then
            local gui = LocalPlayer.PlayerGui:FindFirstChild("FlashbangEffect")
            local effect = Lighting:FindFirstChild("FlashbangColorCorrection")
            if gui then gui:Destroy() end
            if effect then effect:Destroy() end
        end
    end
end)
spawn(function()
    while task.wait(0.5) do
        if getgenv().AntiSmoke then
            local debris = Workspace:FindFirstChild("Debris")
            if debris then
                for _, folder in pairs(debris:GetChildren()) do
                    if string.match(folder.Name, "Voxel") then folder:ClearAllChildren(); folder:Destroy() end
                end
            end
        end
    end
end)

-- Controller aim
UIS.InputChanged:Connect(function(input)
    if getgenv().ControllerEnabled and (input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2) then
        if input.KeyCode == Enum.KeyCode.Thumbstick2 then
            local delta = input.Delta
            local sens = getgenv().ControllerSensitivity * 5
            if mousemoverel then mousemoverel(math.floor(delta.X * sens), math.floor(delta.Y * -sens)) end
        end
    end
end)

-- Full ESP system (using Drawing library from the UI)
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
    esp.box.Thickness = 1; esp.box.Filled = false; esp.box.Color = Color3.fromRGB(255,50,50)
    esp.name.Center = true; esp.name.Outline = true; esp.name.Color = Color3.new(1,1,1); esp.name.Size = 16
    esp.distance.Center = true; esp.distance.Outline = true; esp.distance.Color = Color3.new(0.8,0.8,0.8); esp.distance.Size = 13
    esp.healthOutline.Thickness = 3; esp.healthOutline.Color = Color3.new(0,0,0)
    esp.healthBar.Thickness = 1; esp.healthBar.Color = Color3.new(0,1,0)
    esp.tracer.Thickness = 1; esp.tracer.Color = Color3.fromRGB(255,255,255); esp.tracer.Visible = false
    return esp
end

RunService.RenderStepped:Connect(function()
    if not getgenv().ESPEnabled then
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
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
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

                -- Box
                if getgenv().ESPBox then
                    esp.boxOutline.Size = Vector2.new(boxW, boxH); esp.boxOutline.Position = Vector2.new(rootPos.X - boxW/2, headPos.Y)
                    esp.boxOutline.Visible = true
                    esp.box.Size = esp.boxOutline.Size; esp.box.Position = esp.boxOutline.Position; esp.box.Visible = true
                else
                    esp.boxOutline.Visible = false; esp.box.Visible = false
                end

                -- Health bar
                if getgenv().ESPHealth then
                    local hpPct = hum.Health / hum.MaxHealth
                    local barX = rootPos.X - boxW/2 - 6
                    esp.healthOutline.From = Vector2.new(barX, headPos.Y - 1); esp.healthOutline.To = Vector2.new(barX, headPos.Y + boxH + 1)
                    esp.healthOutline.Visible = true
                    esp.healthBar.From = Vector2.new(barX, headPos.Y + boxH); esp.healthBar.To = Vector2.new(barX, headPos.Y + boxH - (boxH * hpPct))
                    esp.healthBar.Color = Color3.new(1 - hpPct, hpPct, 0); esp.healthBar.Visible = true
                else
                    esp.healthOutline.Visible = false; esp.healthBar.Visible = false
                end

                -- Name
                esp.name.Text = getgenv().ESPName and player.Name or ""
                esp.name.Position = Vector2.new(rootPos.X, headPos.Y - 20); esp.name.Visible = getgenv().ESPName

                -- Distance
                esp.distance.Text = getgenv().ESPDistance and ("[" .. dist .. "m]") or ""
                esp.distance.Position = Vector2.new(rootPos.X, headPos.Y + boxH + 2); esp.distance.Visible = getgenv().ESPDistance

                -- Tracers
                if getgenv().ESPTracers then
                    esp.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    esp.tracer.To = Vector2.new(rootPos.X, rootPos.Y); esp.tracer.Visible = true
                else
                    esp.tracer.Visible = false
                end

                -- Skeleton
                if getgenv().ESPSkeleton then
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
                    for _, line in ipairs(esp.skeletonLines) do line:Remove() end
                    esp.skeletonLines = {}
                end
            else
                -- Off screen, hide everything
                esp.boxOutline.Visible = false; esp.box.Visible = false
                esp.name.Visible = false; esp.distance.Visible = false
                esp.healthOutline.Visible = false; esp.healthBar.Visible = false
                esp.tracer.Visible = false
                for _, line in ipairs(esp.skeletonLines) do line.Visible = false end
            end
        end
    end
    -- Cleanup dead players
    for plr, esp in pairs(espCache) do
        if not aliveSet[plr] then
            for _, obj in pairs(esp) do if type(obj) == "table" and obj.Remove then obj:Remove() end end
            espCache[plr] = nil
        end
    end
end)

-- Final initialization
CreateNotification("Tulip.lua loaded! Enjoy.")

--ANCHOR watermak
for k, v in pairs(menu.watermark.rect) do
	v.Visible = true
end

menu.watermark.text[1].Visible = true

local textbox = menu.options["Settings"]["Configuration"]["ConfigName"]
local relconfigs = GetConfigs()
textbox[1] = relconfigs[menu.options["Settings"]["Configuration"]["Configs"][1]]
textbox[4].Text = textbox[1]

menu.load_time = math.floor((tick() - loadstart) * 1000)
CreateNotification(string.format("Done loading the " .. menu.game .. " cheat. (%d ms)", menu.load_time))
CreateNotification("Press DELETE to open and close the menu!")

loadingthing.Visible = false -- i do it this way because otherwise it would fuck up the Draw:UnRender function, it doesnt cause any lag sooooo
if not menu.open then
	menu.fading = true
	menu.fadestart = tick()
end

menu.Initialize = true -- let me freeeeee