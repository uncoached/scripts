-- =====================================================
--  NEW SIMPLE FEATURE SET (Third Person, Spinbot, BHop, WalkSpeed, Name ESP, Info)
-- =====================================================

menu.Initialize({
    {
        name = "Combat",
        content = {
            {
                name = "Spinbot",
                autopos = "left",
                content = {
                    {
                        type = "toggle",
                        name = "Enabled",
                        value = false,
                    },
                    {
                        type = "slider",
                        name = "Speed",
                        value = 10,
                        minvalue = 1,
                        maxvalue = 50,
                        stradd = "°/s",
                    },
                }
            },
            {
                name = "Movement",
                autopos = "right",
                content = {
                    {
                        type = "toggle",
                        name = "Bunny Hop",
                        value = false,
                    },
                    {
                        type = "slider",
                        name = "Walk Speed",
                        value = 16,
                        minvalue = 16,
                        maxvalue = 50,
                        stradd = " studs",
                    },
                }
            },
        }
    },
    {
        name = "Visuals",
        content = {
            {
                name = "Camera",
                autopos = "left",
                content = {
                    {
                        type = "toggle",
                        name = "Third Person",
                        value = false,
                    },
                    {
                        type = "slider",
                        name = "Distance",
                        value = 10,
                        minvalue = 5,
                        maxvalue = 30,
                        stradd = " studs",
                    },
                }
            },
            {
                name = "Player ESP",
                autopos = "right",
                content = {
                    {
                        type = "toggle",
                        name = "Name ESP",
                        value = true,
                    },
                }
            },
        }
    },
    {
        name = "Info",
        content = {
            {
                name = "Discord",
                x = menu.columns.left,
                y = 66,
                width = menu.columns.width,
                height = 120,
                content = {
                    {
                        type = "button",
                        name = "Copy Discord Link",
                        doubleclick = true,
                    },
                }
            },
        }
    },
})

-- =====================================================
--  FEATURE CODE
-- =====================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Variables
local spinbotActive = false
local spinSpeed = 10
local thirdPerson = false
local thirdPersonDistance = 10
local bhopActive = false
local walkSpeed = 16
local nameESP = true

-- Spinbot
local spinConnection
local function updateSpinbot()
    if spinConnection then spinConnection:Disconnect() end
    if not spinbotActive then return end
    spinConnection = RunService.RenderStepped:Connect(function(dt)
        Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.rad(spinSpeed * dt * 10), 0)
    end)
end

-- Third Person
local function updateThirdPerson()
    if thirdPerson then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = thirdPersonDistance
        LocalPlayer.CameraMinZoomDistance = thirdPersonDistance
    else
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end

-- Bunny Hop
local bhopConnection
local function updateBhop()
    if bhopConnection then bhopConnection:Disconnect() end
    if not bhopActive then return end
    bhopConnection = UserInputService.JumpRequest:Connect(function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChildOfClass("Humanoid") then
            local hum = char.Humanoid
            if hum:GetState() == Enum.HumanoidStateType.Landed then
                hum.Jump = true
            end
        end
    end)
end

-- Walk Speed (apply continuously)
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char.Humanoid.WalkSpeed = walkSpeed
    end
end)

-- Name ESP
local espTexts = {}
local function createNameESP(player)
    if player == LocalPlayer or espTexts[player] then return end
    local text = Drawing.new("Text")
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0,0,0)
    text.Visible = false
    text.Font = 2
    espTexts[player] = text
end

local function removeNameESP(player)
    if espTexts[player] then
        espTexts[player]:Remove()
        espTexts[player] = nil
    end
end

local function updateNameESP()
    for player, text in pairs(espTexts) do
        if not nameESP or not player.Character then
            text.Visible = false
            continue
        end
        local head = player.Character:FindFirstChild("Head")
        if head then
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,1,0))
            if onScreen then
                text.Text = player.Name
                text.Position = Vector2.new(pos.X, pos.Y)
                text.Visible = true
            else
                text.Visible = false
            end
        else
            text.Visible = false
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    createNameESP(player)
end
Players.PlayerAdded:Connect(createNameESP)
Players.PlayerRemoving:Connect(removeNameESP)

RunService.RenderStepped:Connect(updateNameESP)

-- Read settings from UI (polling)
local function readSettings()
    if not menu or not menu.GetVal then return end
    spinbotActive = menu:GetVal("Combat", "Spinbot", "Enabled")
    spinSpeed = menu:GetVal("Combat", "Spinbot", "Speed")
    bhopActive = menu:GetVal("Combat", "Movement", "Bunny Hop")
    walkSpeed = menu:GetVal("Combat", "Movement", "Walk Speed")
    thirdPerson = menu:GetVal("Visuals", "Camera", "Third Person")
    thirdPersonDistance = menu:GetVal("Visuals", "Camera", "Distance")
    nameESP = menu:GetVal("Visuals", "Player ESP", "Name ESP")
end

-- Button press handler (for Discord link)
local buttonPressed = ButtonPressed:connect(function(tab, group, name)
    if tab == "Info" and group == "Discord" and name == "Copy Discord Link" then
        setclipboard("https://discord.gg/dJJ3psbAxw")  -- replace with your actual link
        CreateNotification("Discord link copied!")
    end
end)

-- Apply settings changes when UI updates
RunService.Heartbeat:Connect(function()
    local prevSpinbot = spinbotActive
    local prevThird = thirdPerson
    local prevDist = thirdPersonDistance
    local prevBhop = bhopActive

    readSettings()

    if spinbotActive ~= prevSpinbot or (spinbotActive and spinSpeed ~= prevSpinSpeed) then
        updateSpinbot()
        prevSpinSpeed = spinSpeed
    end
    if thirdPerson ~= prevThird or thirdPersonDistance ~= prevDist then
        updateThirdPerson()
    end
    if bhopActive ~= prevBhop then
        updateBhop()
    end
end)

-- Initial update
readSettings()
updateSpinbot()
updateThirdPerson()
updateBhop()

-- =====================================================
--  WATERMARK (simplified)
-- =====================================================
do
    local wm = menu.watermark
    wm.textString = " | Tulip | " .. os.date("%b. %d, %Y")
    wm.pos = Vector2.new(50, 9)
    wm.text = {}
    local fulltext = "Tulip" .. wm.textString
    wm.width = #fulltext * 7 + 10
    wm.height = 19
    wm.rect = {}

    Draw:FilledRect(false, wm.pos.x, wm.pos.y + 1, wm.width, 2, { menu.mc[1] - 40, menu.mc[2] - 40, menu.mc[3] - 40, 255 }, wm.rect)
    Draw:FilledRect(false, wm.pos.x, wm.pos.y, wm.width, 2, { menu.mc[1], menu.mc[2], menu.mc[3], 255 }, wm.rect)
    Draw:FilledRect(false, wm.pos.x, wm.pos.y + 3, wm.width, wm.height - 5, { 50, 50, 50, 255 }, wm.rect)
    for i = 0, wm.height - 4 do
        Draw:FilledRect(false, wm.pos.x, wm.pos.y + 3 + i, wm.width, 1, { 50 - i * 1.7, 50 - i * 1.7, 50 - i * 1.7, 255 }, wm.rect)
    end
    Draw:OutlinedRect(false, wm.pos.x, wm.pos.y, wm.width, wm.height, { 0, 0, 0, 255 }, wm.rect)
    Draw:OutlinedRect(false, wm.pos.x - 1, wm.pos.y - 1, wm.width + 2, wm.height + 2, { 0, 0, 0, 255 * 0.4 }, wm.rect)
    Draw:OutlinedText(fulltext, 2, false, wm.pos.x + 5, wm.pos.y + 3, 13, false, { 255, 255, 255, 255 }, { 0, 0, 0, 255 }, wm.text)
end

for k, v in pairs(menu.watermark.rect) do
    v.Visible = true
end
menu.watermark.text[1].Visible = true

-- Final loading
menu.load_time = math.floor((tick() - loadstart) * 1000)
CreateNotification("Tulip.lua loaded in " .. menu.load_time .. " ms")
CreateNotification("Press Right Shift to toggle menu")

loadingthing.Visible = false
if not menu.open then
    menu.fading = true
    menu.fadestart = tick()
end

menu.Initialize = true