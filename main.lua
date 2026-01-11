-- Updated again
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 25,
    radius = 300,
    depth = 3
}
rt.player = rt.Players.LocalPlayer
local lastContainer = nil 

-- PERSISTENT CENTERED UI --
local screenGui = rt.player.PlayerGui:FindFirstChild("ClassicFarmUI")
if screenGui then screenGui:Destroy() end
screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "ClassicFarmUI"
screenGui.ResetOnSpawn = false 

local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 400, 0, 60)
label.Position = UDim2.new(0.5, -200, 0.5, -30) 
label.BackgroundTransparency = 1 
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextStrokeTransparency = 0 
label.TextStrokeColor3 = Color3.new(0,0,0)
label.Font = Enum.Font.GothamBold
label.TextSize = 24
label.Text = "Smooth Ghost Initializing..."

local function updateStatus(text, color)
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
end

-- ANTI-AFK --
rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
    updateStatus("Anti-AFK Active", Color3.fromRGB(255, 200, 0))
    task.wait(2)
end)

-- SMOOTH UNDERGROUND MOVEMENT (No Teleport Flicker) --
local function moveSmoothGhost(targetPos)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- We travel just deep enough to be hidden, but high enough to touch coins
    local ghostTarget = targetPos - Vector3.new(0, rt.depth, 0)
    local startPos = root.Position
    local dist = (startPos - ghostTarget).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()
    
    local horizontalRotation = CFrame.Angles(math.rad(90), 0, 0)

    while tick() - startTick < duration do
        -- Check if the coin was deleted by someone else while we are moving
        -- (Optional: add a check here if accuracy is still an issue)
        
        local alpha = (tick() - startTick) / duration
        local lerpPos = startPos:Lerp(ghostTarget, alpha)
        
        char:PivotTo(CFrame.new(lerpPos) * horizontalRotation)
        rt.RunService.Heartbeat:Wait()
    end
    
    -- Finish exactly at the underground target (No "pop up" teleport)
    char:PivotTo(CFrame.new(ghostTarget) * horizontalRotation)
    return "SUCCESS"
end

-- BAG CHECK --
local function isBagFull()
    local mainGui = rt.player.PlayerGui:FindFirstChild("MainGUI")
    if not mainGui then return false end
    local gameUI = mainGui:FindFirstChild("Game")
    if gameUI then
        local coinBags = gameUI:FindFirstChild("CoinBags")
        if coinBags then
            for _, bag in ipairs(coinBags:GetDescendants()) do
                if bag.Name == "FullBagIcon" and bag.Visible == true then
                    return true
                end
            end
        end
    end
    return false
end

-- MAIN LOOP --
local function start()
    local sessionCoins = 0
    while true do
        task.wait(0.1)
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if not root or not hum then continue end

        -- VOID PROTECTION
        if root.Position.Y < -100 then
            updateStatus("V-Limit Reached! Resetting...", Color3.fromRGB(255, 100, 0))
            hum.Health = 0
            rt.player.CharacterAdded:Wait()
            task.wait(5)
            continue
        end

        -- BAG CHECK
        if isBagFull() then
            updateStatus("BAG FULL! SELLING...", Color3.fromRGB(255, 50, 50))
            hum.Health = 0
            rt.player.CharacterRemoving:Wait()
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue
        end

        -- ROUND DETECTION
        local container = nil
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "CoinContainer" then container = v break end
        end

        if container ~= lastContainer then
            lastContainer = container
            rt.touchedCoins = {}
            if container ~= nil then
                for i = 3, 1, -1 do
                    updateStatus("NEW MAP: Loading " .. i .. "s...", Color3.fromRGB(255, 165, 0))
                    task.wait(1)
                end
            end
        end

        -- RE-SCAN OCTREE (Accuracy)
        if container then
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and v.Parent ~= nil and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v)
                end
            end
        end

        -- TARGETING
        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            local coin = nearest.Object
            if coin and coin.Parent then
                updateStatus("Ghost Farming: " .. sessionCoins, Color3.fromRGB(150, 255, 255))
                local result = moveSmoothGhost(coin.Position)
                if result == "SUCCESS" then
                    rt.touchedCoins[coin] = true
                    sessionCoins = sessionCoins + 1
                end
            end
        else
            updateStatus("Scanning for Coins...", Color3.fromRGB(150, 200, 255))
            task.wait(0.5)
        end
    end
end

task.spawn(start)
