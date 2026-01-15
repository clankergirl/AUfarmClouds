-- REVERTED: V4.0 Clean Ghost Snatcher
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 26, 
    radius = 300,
    depth = 3
}
rt.player = rt.Players.LocalPlayer
local lastContainer = nil 

-- SIMPLE OVERLAY --
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
label.Text = "Clean Snatcher Active"

-- ANTI-AFK (Internal) --
rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
end)

-- SEAMLESS MOVEMENT (95% Threshold) --
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
    while alpha < 0.98 do -- Momentum Flow
        if not targetCoin or not targetCoin.Parent then return "CANCELLED" end
        alpha = (tick() - startTick) / duration
        char:PivotTo(CFrame.new(startPos:Lerp(ghostTarget, alpha)) * horizontalRotation)
        rt.RunService.Heartbeat:Wait()
    end
    return "SUCCESS"
end

-- MAIN LOOP --
local function start()
    local sessionCoins = 0
    while true do
        task.wait(0.01)
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        -- Map Detection
        local container = nil
        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name == "CoinContainer" or v:FindFirstChild("CoinContainer") then 
                container = v.Name == "CoinContainer" and v or v.CoinContainer
                break 
            end
        end

        if container ~= lastContainer then
            lastContainer = container
            rt.touchedCoins = {}
            if container ~= nil then
                label.Text = "New Round: Waiting 9s..."
                task.wait(9)
            end
        end

        if container then
            -- Refresh list of coins
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v)
                end
            end

            local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
            if nearest then
                label.Text = "Coins Snatched: " .. sessionCoins
                if moveAndValidate(nearest.Object) == "SUCCESS" then
                    rt.touchedCoins[nearest.Object] = true
                    sessionCoins = sessionCoins + 1
                end
            else
                label.Text = "Scanning for Coins..."
            end
        else
            label.Text = "Waiting for Round to Start..."
        end
    end
end

task.spawn(start)
