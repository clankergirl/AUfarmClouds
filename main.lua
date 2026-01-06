-- Updated by clankergirl
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 25,
    radius = 300
}
rt.player = rt.Players.LocalPlayer

-- LITE STATUS UI
local screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "ClassicFarmUI"
local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 250, 0, 40)
label.Position = UDim2.new(0.5, -125, 0.85, 0)
label.BackgroundColor3 = Color3.new(0,0,0)
label.TextColor3 = Color3.new(1,1,1)
label.BackgroundTransparency = 0.4
label.Text = "Initializing Classic Farm..."

-- HELPER: Find Map & Container
local function getContainer()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "CoinContainer" then return v end
    end
    return nil
end

-- MOVEMENT: Standard Upright Lerp
local function moveToCoin(targetPos)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local startPos = root.Position
    local dist = (startPos - targetPos).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()

    while tick() - startTick < duration do
        local alpha = (tick() - startTick) / duration
        char:PivotTo(CFrame.new(startPos:Lerp(targetPos, alpha)))
        rt.RunService.Heartbeat:Wait()
    end
    char:PivotTo(CFrame.new(targetPos))
end

-- IMPROVED BAG CHECK
local function isBagFull()
    local mainGui = rt.player.PlayerGui:FindFirstChild("MainGUI")
    if not mainGui then return false end
    
    -- We are looking for the specific "Full" indicator in the Game UI
    local gameUI = mainGui:FindFirstChild("Game")
    if gameUI then
        local coinBags = gameUI:FindFirstChild("CoinBags")
        if coinBags then
            -- This looks through all bag types (SnowToken, Coin, etc.)
            for _, bag in ipairs(coinBags:GetDescendants()) do
                if bag.Name == "FullBagIcon" and bag.Visible == true then
                    return true
                end
            end
        end
    end
    return false
end

-- MAIN LOOP
local function start()
    local sessionCoins = 0
    
    while true do
        task.wait(0.2)
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if not root or not hum then 
            label.Text = "Waiting for Character..."
            continue 
        end

        -- BAG CHECK (Now uses the improved function)
        if isBagFull() then
            label.Text = "Bag Full! Resetting..."
            hum.Health = 0
            
            -- Important: Wait for the character to actually be gone and respawned
            rt.player.CharacterRemoving:Wait()
            rt.player.CharacterAdded:Wait()
            task.wait(4) -- Extra time for Android to load the new UI state
            continue
        end

        -- Refresh Octree
        local container = getContainer()
        if container then
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                if rt.TargetNames[v.Name] and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v)
                end
            end
        end

        -- Find Nearest
        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            label.Text = "Collecting: " .. sessionCoins
            moveToCoin(nearest.Object.Position)
            
            rt.touchedCoins[nearest.Object] = true
            sessionCoins = sessionCoins + 1
        else
            label.Text = "Searching for Coins..."
            task.wait(1)
        end
    end
end

task.spawn(start)
