-- V6.2 TOUCH-TRACKED: Uses Character Hitbox to Validate Collection
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    octree = Octree.new(),
    touchedCoins = {}, -- Tracks coins we have personally hit
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 22, -- [cite: 1]
    radius = 300, -- [cite: 1]
    depth = 3 -- [cite: 1]
}
rt.player = rt.Players.LocalPlayer
local lastContainer = nil 

-- UI SETUP [cite: 1, 2]
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
label.Font = Enum.Font.GothamBold
label.TextSize = 24
label.Text = "Touch-Track Snatcher Active"

-- ANTI-AFK [cite: 2]
rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
end)

-- TOUCH LISTENER: Immediately blacklists coins we touch
local function setupTouchListener(char)
    local root = char:WaitForChild("HumanoidRootPart")
    root.Touched:Connect(function(hit)
        if hit and rt.TargetNames[hit.Name] then
            rt.touchedCoins[hit] = true -- Mark as collected instantly on touch
        end
    end)
end

-- MOVEMENT ENGINE [cite: 3, 4, 6]
local function moveAndValidate(targetCoin)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not targetCoin or not targetCoin.Parent then return "CANCELLED" end -- 

    -- PHYSICS STABILITY
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.Massless = true end
    end

    local startPos = root.Position
    local targetPos = targetCoin.Position
    local ghostTarget = targetPos - Vector3.new(0, rt.depth, 0)
    local duration = (startPos - ghostTarget).Magnitude / rt.walkspeed
    local startTick = tick()
    local horizontalRotation = CFrame.Angles(math.rad(90), 0, 0) -- 

    while tick() - startTick < duration do -- [cite: 4]
        -- GHOST CHECK: Cancel if coin disappears or if we already touched it
        if not targetCoin or not targetCoin.Parent or rt.touchedCoins[targetCoin] then
            return "CANCELLED" 
        end
        
        local alpha = (tick() - startTick) / duration
        char:PivotTo(CFrame.new(startPos:Lerp(ghostTarget, alpha)) * horizontalRotation) -- 
        rt.RunService.Heartbeat:Wait()
    end
    
    char:PivotTo(CFrame.new(ghostTarget) * horizontalRotation) -- 
    return "SUCCESS"
end

-- MAIN LOOP [cite: 8, 10, 12]
local function start()
    local sessionCoins = 0
    rt.player.CharacterAdded:Connect(setupTouchListener)
    if rt.player.Character then setupTouchListener(rt.player.Character) end

    while true do
        task.wait(0.05) -- [cite: 8]
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        -- BAG CHECK [cite: 7, 9]
        local mainGui = rt.player.PlayerGui:FindFirstChild("MainGUI")
        local gameUI = mainGui and mainGui:FindFirstChild("Game")
        local coinBags = gameUI and gameUI:FindFirstChild("CoinBags")
        if coinBags then
            for _, bag in ipairs(coinBags:GetDescendants()) do
                if bag.Name == "FullBagIcon" and bag.Visible == true then
                    char.Humanoid.Health = 0
                    rt.player.CharacterAdded:Wait()
                    task.wait(4)
                end
            end
        end

        -- CONTAINER DETECTION [cite: 10]
        local container = nil
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "CoinContainer" then container = v break end
        end

        if container ~= lastContainer then -- [cite: 11]
            lastContainer = container
            rt.touchedCoins = {}
            if container ~= nil then task.wait(9) end
        end

        if container then -- [cite: 12]
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                -- Only target coins that haven't been touched yet
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v) -- [cite: 12]
                end
            end

            local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1] -- [cite: 13]
            if nearest then
                label.Text = "Snatched: " .. sessionCoins
                if moveAndValidate(nearest.Object) == "SUCCESS" then
                    rt.touchedCoins[nearest.Object] = true -- [cite: 14]
                    sessionCoins = sessionCoins + 1
                end
            end
        end
    end
end

task.spawn(start)
