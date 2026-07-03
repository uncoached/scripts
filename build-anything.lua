-- Minimal Build Exploit (Robust, Logged)
-- Use the "Test Place" button to verify remote calls work.
-- If it doesn't, check console (F9) for error details.

local player = game.Players.LocalPlayer
if not player then return end

-- Helper to safely get remote
local function getPlaceRemote()
    local rs = game:GetService("ReplicatedStorage")
    local events = rs:FindFirstChild("Events")
    if not events then
        warn("❌ Events folder not found")
        return nil
    end
    local place = events:FindFirstChild("Place")
    if not place then
        warn("❌ Place remote not found inside Events")
        return nil
    end
    return place
end

local function getDestroyRemote()
    local rs = game:GetService("ReplicatedStorage")
    local events = rs:FindFirstChild("Events")
    if not events then return nil end
    return events:FindFirstChild("DestroyBlock")
end

-- Test the remote now
local placeRemote = getPlaceRemote()
if not placeRemote then
    -- Notification
    game.StarterGui:SetCore("SendNotification", {Title="Error",Text="Place remote missing. Script stopped."})
    return
end
local destroyRemote = getDestroyRemote()
if not destroyRemote then
    game.StarterGui:SetCore("SendNotification", {Title="Error",Text="Destroy remote missing. Script stopped."})
    return
end

local baseplate = workspace:FindFirstChild("Baseplate")
if not baseplate then
    game.StarterGui:SetCore("SendNotification", {Title="Error",Text="Baseplate missing."})
    return
end

local builtFolder = workspace:FindFirstChild("Built") or Instance.new("Folder", workspace)
builtFolder.Name = "Built"

-- Character
local character
local function onChar(c)
    character = c
    c:WaitForChild("HumanoidRootPart")
end
if player.Character then onChar(player.Character) end
player.CharacterAdded:Connect(onChar)

-- Utilities
local function placeBlock(blockType, pos)
    local roundedPos = Vector3.new(math.round(pos.X), math.round(pos.Y), math.round(pos.Z))
    local cf = CFrame.new(roundedPos) -- identity rotation
    local ok, err = pcall(function()
        placeRemote:InvokeServer(blockType, cf, baseplate)
    end)
    if ok then
        print("✅ Placed " .. blockType .. " at " .. tostring(roundedPos))
        return true
    else
        warn("❌ Place error: " .. tostring(err))
        return false
    end
end

local function destroyAllParts(folder)
    local count = 0
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") then
            count += 1
            task.spawn(function()
                pcall(function() destroyRemote:InvokeServer(v) end)
            end)
        end
    end
    print("💥 Destroyed " .. count .. " parts")
end

-- GUI (simple)
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "ExploitGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,280,0,500)
frame.Position = UDim2.new(0,20,0,100)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", frame)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-20,0,25)
title.Position = UDim2.new(0,10,0,5)
title.BackgroundTransparency = 1
title.Text = "Build Exploit"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20

-- Test button
local testBtn = Instance.new("TextButton", frame)
testBtn.Size = UDim2.new(1,-20,0,30)
testBtn.Position = UDim2.new(0,10,0,35)
testBtn.Text = "Test Place"
testBtn.BackgroundColor3 = Color3.fromRGB(0,150,0)
testBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", testBtn)
testBtn.MouseButton1Click:Connect(function()
    if character and character.PrimaryPart then
        local pos = character.PrimaryPart.Position
        local success = placeBlock("Glass", pos)
        testBtn.Text = success and "Placed! (check console)" or "Failed (check console)"
        task.delay(2, function() testBtn.Text = "Test Place" end)
    else
        print("Character not ready")
    end
end)

-- Simple toggle helper
local function addToggle(y, name, onFunc, offFunc)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,-20,0,30)
    btn.Position = UDim2.new(0,10,0,y)
    btn.Text = name .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(180,0,0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    Instance.new("UICorner", btn)
    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        if active then
            btn.Text = name .. ": ON"
            btn.BackgroundColor3 = Color3.fromRGB(0,150,0)
            onFunc()
        else
            btn.Text = name .. ": OFF"
            btn.BackgroundColor3 = Color3.fromRGB(180,0,0)
            offFunc()
        end
    end)
end

-- Thread management
local threads = {}
local function stop(name)
    if threads[name] then
        task.cancel(threads[name])
        threads[name] = nil
    end
end
local function start(name, fn)
    stop(name)
    threads[name] = task.spawn(fn)
end

-- Nuke all
addToggle(80, "Nuke All",
    function() start("nuke", function() while threads["nuke"] do destroyAllParts(builtFolder); task.wait(0.5) end end) end,
    function() stop("nuke") end)

-- Spammer (fill sphere)
addToggle(115, "Spammer",
    function()
        start("spammer", function()
            local radius = 20
            while threads["spammer"] do
                if character and character.PrimaryPart then
                    local center = character.PrimaryPart.Position
                    -- iterate sphere
                    for x = -radius, radius do
                        for y = -radius, radius do
                            for z = -radius, radius do
                                if not threads["spammer"] then break end
                                local pos = Vector3.new(center.X+x, center.Y+y, center.Z+z)
                                if (pos - center).Magnitude <= radius then
                                    placeBlock("Glass", pos)
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                else
                    task.wait(1)
                end
            end
        end)
    end,
    function() stop("spammer") end)

-- Cage all
addToggle(150, "Cage All",
    function()
        start("cageAll", function()
            while threads["cageAll"] do
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player and p.Character and p.Character.PrimaryPart then
                        local root = p.Character.PrimaryPart
                        local center = root.Position
                        -- teleport local player to target
                        if character and character.PrimaryPart then
                            character:PivotTo(root.CFrame + Vector3.new(0,2,0))
                        end
                        for x=-2,2 do for y=-2,2 do for z=-2,2 do
                            if x==0 and y==0 and z==0 then continue end
                            placeBlock("Glass", center + Vector3.new(x*4,y*4,z*4))
                        end end end
                        task.wait(0.3)
                    end
                end
                task.wait(1)
            end
        end)
    end,
    function() stop("cageAll") end)

-- Destroy all once
local destroyBtn = Instance.new("TextButton", frame)
destroyBtn.Size = UDim2.new(1,-20,0,30)
destroyBtn.Position = UDim2.new(0,10,0,185)
destroyBtn.Text = "Destroy All Now"
destroyBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
destroyBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", destroyBtn)
destroyBtn.MouseButton1Click:Connect(function() destroyAllParts(builtFolder) end)

-- Stop all
local stopBtn = Instance.new("TextButton", frame)
stopBtn.Size = UDim2.new(1,-20,0,30)
stopBtn.Position = UDim2.new(0,10,0,220)
stopBtn.Text = "Stop All"
stopBtn.BackgroundColor3 = Color3.fromRGB(255,0,0)
stopBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", stopBtn)
stopBtn.MouseButton1Click:Connect(function()
    for name in pairs(threads) do stop(name) end
end)

-- Drag
local dragging, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)

print("✅ Minimal script loaded. Use Test Place button.")