local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 24,
    radius = 300,
    depth = 0
}
rt.player = rt.Players.LocalPlayer
local lastContainer = nil 

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
label.Text = "Welcome to Clankerfarm!"

rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
    task.wait(1)
end)

local function confirmCollection(targetCoin)
    local timeout = tick() + 0.3
    while tick() < timeout do
        if not targetCoin or not targetCoin.Parent then
            return true
        end
        task.wait()
    end
    return false
end

local function moveAndValidate(targetCoin)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
   
    if not root or not targetCoin or not targetCoin.Parent then return "CANCELLED" end --

    local startPos = root.Position
    local targetPos = targetCoin.Position
    local ghostTarget = targetPos - Vector3.new(0, rt.depth, 0)
    local duration = (startPos - ghostTarget).Magnitude / rt.walkspeed
    local startTick = tick()

    local alpha = 0
    while alpha < 0.95 do
        if not targetCoin or not targetCoin.Parent then return "CANCELLED" end --
        
        alpha = (tick() - startTick) / duration
        char:PivotTo(CFrame.new(startPos:Lerp(ghostTarget, alpha))) -- Upright
        rt.RunService.Heartbeat:Wait()
    end
    
    if confirmCollection(targetCoin) then
        return "SUCCESS"
    else
        return "STUCK"
    end
end

local function isBagFull()
    local mainGui = rt.player.PlayerGui:FindFirstChild("MainGUI")
    local gameUI = mainGui and mainGui:FindFirstChild("Game")
    local coinBags = gameUI and gameUI:FindFirstChild("CoinBags")
    if coinBags then
        for _, bag in ipairs(coinBags:GetDescendants()) do --
            if bag.Name == "FullBagIcon" and bag.Visible == true then
                return true
            end
        end
    end
    return false
end

local function start()
    local sessionCoins = 0
    while true do
        task.wait(0.05)
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        if isBagFull() then --
            label.Text = "BAG FULL! RESETTING..."
            char.Humanoid.Health = 0
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
            if container ~= nil then task.wait(9) end
        end

        if container then --
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v) --
                end
            end
        end

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            label.Text = "Debugging:" .. sessionCoins
            local result = moveAndValidate(nearest.Object) --
            if result == "SUCCESS" then
                rt.touchedCoins[nearest.Object] = true
                sessionCoins = sessionCoins + 1
            elseif result == "STUCK" then
                rt.touchedCoins[nearest.Object] = true
            end
        end
    end
end

task.spawn(start)
