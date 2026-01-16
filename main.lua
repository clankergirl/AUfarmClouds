-- REVERTED TO V2.txt BASELINE [cite: 1]
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
    depth = 3 -- Original V2 depth [cite: 1]
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
label.TextStrokeColor3 = Color3.new(0,0,0)
label.Font = Enum.Font.GothamBold
label.TextSize = 24
label.Text = "Snatcher Mode Active..."

local function updateStatus(text, color)
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
end

-- ANTI-AFK [cite: 2]
rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
    updateStatus("Anti-AFK Reset", Color3.fromRGB(255, 200, 0))
    task.wait(1)
end)

-- MOVEMENT: Fixed with 95% Momentum and Ghost-Check [cite: 3, 4, 5]
local function moveAndValidate(targetCoin)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
   
    if not root or not targetCoin or not targetCoin.Parent then return "CANCELLED" end [cite: 3]

    local startPos = root.Position
    local targetPos = targetCoin.Position
    local ghostTarget = targetPos - Vector3.new(0, rt.depth, 0)
    
    local dist = (startPos - ghostTarget).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()
    
    local horizontalRotation = CFrame.Angles(math.rad(90), 0, 0)

    -- FIX: Exit at 0.95 to keep momentum and check for 'Ghost Coins' [cite: 4, 5]
    local alpha = 0
    while alpha < 0.95 do 
        if not targetCoin or not targetCoin.Parent then [cite: 5]
            return "CANCELLED" 
        end

        if root.Position.Y < -100 then return "FELL" end [cite: 5]
        
        alpha = (tick() - startTick) / duration
        local lerpPos = startPos:Lerp(ghostTarget, alpha)
        
        char:PivotTo(CFrame.new(lerpPos) * horizontalRotation) [cite: 6]
        rt.RunService.Heartbeat:Wait()
    end
    
    return "SUCCESS"
end

-- BAG CHECK [cite: 6, 7]
local function isBagFull()
    local mainGui = rt.player.PlayerGui:FindFirstChild("MainGUI")
    if not mainGui then return false end
    local gameUI = mainGui:FindFirstChild("Game")
    if gameUI then
        local coinBags = gameUI:FindFirstChild("CoinBags")
        if coinBags then
            for _, bag in ipairs(coinBags:GetDescendants()) do
                if bag.Name == "FullBagIcon" and bag.Visible == true then [cite: 7]
                    return true
                end
            end
        end
    end
    return false
end

-- MAIN LOOP [cite: 8, 9, 10, 11, 12]
local function start()
    local sessionCoins = 0
    while true do
        task.wait(0.05) 
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if not root or not hum then continue end

        if isBagFull() then [cite: 8, 9]
            updateStatus("BAG FULL! RESETTING...", Color3.fromRGB(255, 50, 50))
            hum.Health = 0
            rt.player.CharacterRemoving:Wait()
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue
        end

        local container = nil
        for _, v in ipairs(workspace:GetDescendants()) do [cite: 10]
            if v.Name == "CoinContainer" then container = v break end
        end

        if container ~= lastContainer then [cite: 11]
            lastContainer = container
            rt.touchedCoins = {}
            if container ~= nil then
                for i = 9, 1, -1 do
                    updateStatus("NEW MAP: Waiting " .. i .. "s...", Color3.fromRGB(255, 165, 0))
                    task.wait(1)
                end
            end
        end

        if container then [cite: 12]
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and v.Parent ~= nil and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v) [cite: 12, 13]
                end
            end
        end

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            local coin = nearest.Object
            updateStatus("Snatching: " .. sessionCoins, Color3.fromRGB(100, 255, 200)) [cite: 13]
            
            local result = moveAndValidate(coin) [cite: 14]
            
            if result == "SUCCESS" then [cite: 14]
                rt.touchedCoins[coin] = true
                sessionCoins = sessionCoins + 1
            elseif result == "CANCELLED" then [cite: 15, 16]
                updateStatus("Re-routing...", Color3.fromRGB(255, 100, 100))
            end
        else
            updateStatus("Scanning...", Color3.fromRGB(150, 200, 255))
            task.wait(0.3) [cite: 16]
        end
    end
end

task.spawn(start)
