-- REFINED VERSION: Exact V2 Logic + Mid-Flight Validation
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 22, -- [cite: 1]
    radius = 300, -- [cite: 1]
    depth = 3 -- [cite: 1]
}
rt.player = rt.Players.LocalPlayer
local lastContainer = nil 

-- PERSISTENT CENTERED UI -- [cite: 1]
local screenGui = rt.player.PlayerGui:FindFirstChild("ClassicFarmUI")
if screenGui then screenGui:Destroy() end
screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "ClassicFarmUI"
screenGui.ResetOnSpawn = false 

local label = Instance.new("TextLabel", screenGui) -- [cite: 2]
label.Size = UDim2.new(0, 400, 0, 60)
label.Position = UDim2.new(0.5, -200, 0.5, -30) 
label.BackgroundTransparency = 1 
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextStrokeTransparency = 0 
label.TextStrokeColor3 = Color3.new(0,0,0)
label.Font = Enum.Font.GothamBold
label.TextSize = 24
label.Text = "Snatcher Mode Active..."

-- ANTI-AFK -- [cite: 2]
rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
    task.wait(1)
end)

-- UPDATED MOVEMENT: Includes Mid-Flight Existence Check -- [cite: 3]
local function moveAndValidate(targetCoin)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
   
    if not root or not targetCoin or not targetCoin.Parent then return "CANCELLED" end -- [cite: 3]

    -- PHYSICS STABILITY: Making character weightless prevents the 'teleport down' flicker
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.Massless = true end
    end

    local startPos = root.Position
    local targetPos = targetCoin.Position
    local ghostTarget = targetPos - Vector3.new(0, rt.depth, 0)
    
    local dist = (startPos - ghostTarget).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()
    
    local horizontalRotation = CFrame.Angles(math.rad(90), 0, 0) -- [cite: 3]

    while tick() - startTick < duration do -- [cite: 4]
        -- GHOST COIN FIX: If the coin is deleted by another player, STOP immediately. 
        if not targetCoin or not targetCoin.Parent then
            return "CANCELLED" 
        end

        -- VOID SAFETY [cite: 5]
        if root.Position.Y < -100 then return "FELL" end
        
        local alpha = (tick() - startTick) / duration
        local lerpPos = startPos:Lerp(ghostTarget, alpha) -- [cite: 5]
        
        char:PivotTo(CFrame.new(lerpPos) * horizontalRotation) -- 
        rt.RunService.Heartbeat:Wait()
    end
    
    char:PivotTo(CFrame.new(ghostTarget) * horizontalRotation) -- 
    return "SUCCESS"
end

-- BAG CHECK -- 
local function isBagFull()
    local mainGui = rt.player.PlayerGui:FindFirstChild("MainGUI")
    local gameUI = mainGui and mainGui:FindFirstChild("Game")
    local coinBags = gameUI and gameUI:FindFirstChild("CoinBags")
    if coinBags then
        for _, bag in ipairs(coinBags:GetDescendants()) do -- [cite: 7]
            if bag.Name == "FullBagIcon" and bag.Visible == true then
                return true
            end
        end
    end
    return false
end

-- MAIN LOOP -- [cite: 8]
local function start()
    local sessionCoins = 0
    while true do
        task.wait(0.05) -- [cite: 8]
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if not root or not hum then continue end

        if isBagFull() then -- [cite: 9]
            label.Text = "BAG FULL! RESETTING..."
            hum.Health = 0
            rt.player.CharacterRemoving:Wait()
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue
        end

        local container = nil
        for _, v in ipairs(workspace:GetDescendants()) do -- [cite: 10]
            if v.Name == "CoinContainer" then container = v break end
        end

        if container ~= lastContainer then -- [cite: 11]
            lastContainer = container
            rt.touchedCoins = {}
            if container ~= nil then
                for i = 9, 1, -1 do
                    label.Text = "NEW MAP: Waiting " .. i .. "s..."
                    task.wait(1)
                end
            end
        end

        -- RE-SCAN (Accuracy) 
        if container then
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and v.Parent ~= nil and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v) -- 
                end
            end
        end

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1] -- [cite: 13]
        if nearest then
            local coin = nearest.Object
            label.Text = "Snatching: " .. sessionCoins
            
            local result = moveAndValidate(coin) -- [cite: 14]
            
            if result == "SUCCESS" then
                rt.touchedCoins[coin] = true
                sessionCoins = sessionCoins + 1
            elseif result == "CANCELLED" then -- [cite: 15]
                label.Text = "Re-routing..." -- [cite: 16]
            end
        else
            label.Text = "Scanning Radius..."
            task.wait(0.3)
        end
    end
end

task.spawn(start)
