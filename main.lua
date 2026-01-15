-- Reverted & Refined Version
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 22,
    radius = 300,
    depth = 3
}
rt.player = rt.Players.LocalPlayer
local lastContainer = nil 

-- UI SETUP
local screenGui = rt.player.PlayerGui:FindFirstChild("ClassicFarmUI")
if screenGui then screenGui:Destroy() end
screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "ClassicFarmUI"
screenGui.ResetOnSpawn = false 

local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 400, 0, 60)
label.Position = UDim2.new(0.5, -200, 0.5, -30) 
label.BackgroundTransparency = 0.5
label.BackgroundColor3 = Color3.new(0,0,0)
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 20
label.Text = "Refined V2: Momentum Snatcher"

-- ANTI-AFK [cite: 3]
rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
end)

-- SEAMLESS MOVEMENT ENGINE [cite: 3, 4, 5]
local function moveAndValidate(targetCoin)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not targetCoin or not targetCoin.Parent then return "CANCELLED" end

    local startPos = root.Position
    local targetPos = targetCoin.Position
    local ghostTarget = targetPos - Vector3.new(0, rt.depth, 0)
    local dist = (startPos - ghostTarget).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()
    local horizontalRotation = CFrame.Angles(math.rad(90), 0, 0)

    local alpha = 0
    -- MOMENTUM FIX: Exit at 95% to prevent "standing still" [cite: 6]
    while alpha < 0.95 do 
        -- EXISTENCE CHECK: Stop if someone else grabs it mid-flight [cite: 4, 5]
        if not targetCoin or not targetCoin.Parent then return "CANCELLED" end
        
        alpha = (tick() - startTick) / duration
        char:PivotTo(CFrame.new(startPos:Lerp(ghostTarget, alpha)) * horizontalRotation)
        rt.RunService.Heartbeat:Wait()
    end
    
    return "SUCCESS"
end

-- BAG CHECK [cite: 7]
local function isBagFull()
    local mainGui = rt.player.PlayerGui:FindFirstChild("MainGUI")
    local gameUI = mainGui and mainGui:FindFirstChild("Game")
    local coinBags = gameUI and gameUI:FindFirstChild("CoinBags")
    if coinBags then
        for _, bag in ipairs(coinBags:GetDescendants()) do
            if bag.Name == "FullBagIcon" and bag.Visible == true then return true end
        end
    end
    return false
end

-- MAIN LOOP [cite: 8, 9, 10]
local function start()
    local sessionCoins = 0
    while true do
        task.wait(0.01) -- High-frequency loop
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        if isBagFull() then
            char.Humanoid.Health = 0 [cite: 9]
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue
        end

        local container = nil
        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name == "CoinContainer" or v:FindFirstChild("CoinContainer") then 
                container = v.Name == "CoinContainer" and v or v.CoinContainer
                break 
            end
        end

        if container ~= lastContainer then
            lastContainer = container
            rt.touchedCoins = {} [cite: 11]
            if container ~= nil then
                label.Text = "ROUND START: Waiting 9s..."
                task.wait(9) [cite: 11]
            end
        end

        if container then
            -- RE-SCAN: Frequent clearing of Octree nodes for accuracy [cite: 12, 13]
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and v.Parent ~= nil and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v)
                end
            end

            local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
            if nearest then
                label.Text = "Coins Snatched: " .. sessionCoins
                local coin = nearest.Object
                if moveAndValidate(coin) == "SUCCESS" then [cite: 14]
                    rt.touchedCoins[coin] = true
                    sessionCoins = sessionCoins + 1
                end
            else
                label.Text = "Scanning Radius..."
            end
        end
    end
end

task.spawn(start)
