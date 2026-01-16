-- im tired
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

-- PERSISTENT CENTERED UI -- 
local screenGui = rt.player.PlayerGui:FindFirstChild("ClassicFarmUI")
if screenGui then screenGui:Destroy() end
screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "ClassicFarmUI"
screenGui.ResetOnSpawn = false 

local label = Instance.new("TextLabel", screenGui) -- 
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

-- ANTI-AFK -- 
rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
    updateStatus("Anti-AFK Reset", Color3.fromRGB(255, 200, 0))
    task.wait(1)
end)

-- ORIGINAL MOVEMENT LOGIC -- 
local function moveAndValidate(targetCoin)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
   
    if not root or not targetCoin or not targetCoin.Parent then return "CANCELLED" end -- 

    -- PHYSICS STABILITY: Prevents flickering/teleporting down by making character weightless
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then part.Massless = true end
    end

    local startPos = root.Position
    local targetPos = targetCoin.Position
    local ghostTarget = targetPos - Vector3.new(0, rt.depth, 0)
    
    local dist = (startPos - ghostTarget).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()
    
    local horizontalRotation = CFrame.Angles(math.rad(90), 0, 0) -- 

    while tick() - startTick < duration do -- 
        -- Mid-flight existence check to fix "Ghost Coins" 
        if not targetCoin or not targetCoin.Parent then
            return "CANCELLED" 
        end

        if root.Position.Y < -100 then return "FELL" end -- 
        
        local alpha = (tick() - startTick) / duration
        local lerpPos = startPos:Lerp(ghostTarget, alpha) -- 
        
        char:PivotTo(CFrame.new(lerpPos) * horizontalRotation) -- 
        rt.RunService.Heartbeat:Wait()
    end
    
    char:PivotTo(CFrame.new(ghostTarget) * horizontalRotation) -- 
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
            for _, bag in ipairs(coinBags:GetDescendants()) do -- 
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
        task.wait(0.05) -- 
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if not root or not hum then continue end

        if isBagFull() then -- 
            updateStatus("BAG FULL! RESETTING...", Color3.fromRGB(255, 50, 50))
            hum.Health = 0
            rt.player.CharacterRemoving:Wait()
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue
        end

        local container = nil
        for _, v in ipairs(workspace:GetDescendants()) do -- 
            if v.Name == "CoinContainer" then container = v break end
        end

        if container ~= lastContainer then -- 
            lastContainer = container
            rt.touchedCoins = {}
            if container ~= nil then
                for i = 9, 1, -1 do
                    updateStatus("NEW MAP: Waiting " .. i .. "s...", Color3.fromRGB(255, 165, 0))
                    task.wait(1)
                end
            end
        end

        if container then -- 
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and v.Parent ~= nil and not rt.touchedCoins
