-- Tulip.lua – Simple Cheat using WindUI
-- Features: Spinbot (character rotation), Bunny Hop, Walk Speed, Third Person, Name ESP, Discord Invite
-- All features work, spinbot rotates your character's RootPart.

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
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Feature state variables
local spinbotEnabled = false
local spinbotSpeed = 10
local spinConnection = nil

local bhopEnabled = false
local bhopConnection = nil

local walkSpeed = 16

local thirdPersonEnabled = false
local thirdPersonDistance = 10

local nameEspEnabled = true
local espTexts = {}

-- Check if Drawing library is available (some executors don't support it)
local hasDrawing = pcall(function() return Drawing.new end)
if not hasDrawing then
    warn("Drawing library not available – Name ESP will be disabled.")
    nameEspEnabled = false
end

-- Create the Window
local Window = WindUI:CreateWindow({
    Title = "Tulip",
    Folder = "Tulip",
    Icon = "solar:flower-bold",
    OpenButton = { Title = "Open", Enabled = true },
})

-- ==================== Combat Tab ====================
local CombatTab = Window:Tab({ Title = "Combat", Icon = "solar:sword-bold" })

CombatTab:Section({ Title = "Spinbot" })
    :Toggle({
        Title = "Spinbot",
        Callback = function(state)
            spinbotEnabled = state
            if spinbotEnabled then
                if spinConnection then spinConnection:Disconnect() end
                spinConnection = RunService.RenderStepped:Connect(function(dt)
                    local char = LocalPlayer.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed) * dt, 0)
                        end
                    end
                end)
            else
                if spinConnection then spinConnection:Disconnect() end
                spinConnection = nil
            end
        end,
    })
    :Slider({
        Title = "Speed",
        Step = 1,
        Value = { Min = 1, Max = 50, Default = 10 },
        Callback = function(v)
            spinbotSpeed = v
        end,
    })

CombatTab:Section({ Title = "Movement" })
    :Toggle({
        Title = "Bunny Hop",
        Callback = function(state)
            bhopEnabled = state
            if bhopEnabled then
                local function hookBhop(char)
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        if bhopConnection then bhopConnection:Disconnect() end
                        bhopConnection = hum.StateChanged:Connect(function(_, new)
                            if new == Enum.HumanoidStateType.Landed and UIS:IsKeyDown(Enum.KeyCode.Space) then
                                hum.Jump = true
                            end
                        end)
                    end
                end
                if LocalPlayer.Character then
                    hookBhop(LocalPlayer.Character)
                end
                LocalPlayer.CharacterAdded:Connect(hookBhop)
            else
                if bhopConnection then bhopConnection:Disconnect() end
                bhopConnection = nil
            end
        end,
    })
    :Slider({
        Title = "Walk Speed",
        Step = 1,
        Value = { Min = 16, Max = 50, Default = 16 },
        Callback = function(v)
            walkSpeed = v
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char.Humanoid.WalkSpeed = v
            end
        end,
    })

-- Ensure WalkSpeed and BHOP apply to new characters
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.WalkSpeed = walkSpeed
    if bhopEnabled then
        if bhopConnection then bhopConnection:Disconnect() end
        bhopConnection = hum.StateChanged:Connect(function(_, new)
            if new == Enum.HumanoidStateType.Landed and UIS:IsKeyDown(Enum.KeyCode.Space) then
                hum.Jump = true
            end
        end)
    end
end)

-- ==================== Visuals Tab ====================
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })

VisualsTab:Section({ Title = "Camera" })
    :Toggle({
        Title = "Third Person",
        Callback = function(state)
            thirdPersonEnabled = state
            if state then
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
                LocalPlayer.CameraMaxZoomDistance = thirdPersonDistance
                LocalPlayer.CameraMinZoomDistance = thirdPersonDistance
            else
                LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
            end
        end,
    })
    :Slider({
        Title = "Distance",
        Step = 1,
        Value = { Min = 5, Max = 30, Default = 10 },
        Callback = function(v)
            thirdPersonDistance = v
            if thirdPersonEnabled then
                LocalPlayer.CameraMaxZoomDistance = v
                LocalPlayer.CameraMinZoomDistance = v
            end
        end,
    })

VisualsTab:Section({ Title = "Player ESP" })
    :Toggle({
        Title = "Name ESP",
        Value = true,
        Callback = function(state)
            nameEspEnabled = state
        end,
    })

-- ==================== Info Tab ====================
local InfoTab = Window:Tab({ Title = "Info", Icon = "solar:info-bold" })

InfoTab:Section({ Title = "Discord" })
    :Button({
        Title = "Copy Discord Invite",
        Callback = function()
            setclipboard("https://discord.gg/dJJ3psbAxw")  -- replace with your actual link
            WindUI:Notify({ Title = "Tulip", Content = "Discord link copied to clipboard!" })
        end,
    })

-- ==================== Name ESP (Drawing) ====================
if hasDrawing then
    local function createESP(player)
        if player == LocalPlayer or espTexts[player] then return end
        local text = Drawing.new("Text")
        text.Size = 14
        text.Center = true
        text.Outline = true
        text.OutlineColor = Color3.new(0, 0, 0)
        text.Visible = false
        text.Font = 2
        espTexts[player] = text
    end

    local function removeESP(player)
        if espTexts[player] then
            espTexts[player]:Remove()
            espTexts[player] = nil
        end
    end

    local function updateESP()
        for player, text in pairs(espTexts) do
            if not nameEspEnabled or not player.Character then
                text.Visible = false
                continue
            end
            local head = player.Character:FindFirstChild("Head")
            if head then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
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
        createESP(player)
    end
    Players.PlayerAdded:Connect(createESP)
    Players.PlayerRemoving:Connect(removeESP)
    RunService.RenderStepped:Connect(updateESP)
end

-- ==================== Final notifies ====================
WindUI:Notify({ Title = "Tulip", Content = "Loaded! Press INSERT to toggle menu." })
print("Tulip.lua loaded.")