-- V6.0 MOMENTUM FLOW: 95% Threshold + Background Octree Prep
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TeleportService = game:GetService("TeleportService"),
    VirtualUser = game:GetService("VirtualUser"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 28, 
    radius = 300,
    depth = 3
}
rt.player = rt.Players.LocalPlayer
local lastContainer = nil 
local stallTime = 0 

-- UI SETUP
local screenGui = rt.player.PlayerGui:FindFirstChild("ClassicFarmUI")
if screenGui then screenGui:Destroy() end
screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "ClassicFarmUI"
screenGui.ResetOnSpawn = false 

local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 450, 0, 70)
label.Position = UDim2.new(0.5, -225, 0.5, -35) 
label.BackgroundTransparency = 1 
label.TextColor3 = Color3.fromRGB(100, 255, 200)
label.TextStrokeTransparency = 0 
label.Font = Enum.Font.GothamBold
label.TextSize = 22
label.Text = "Momentum Flow: 95%"

-- SIMPLE HOP --
local function serverHop()
    rt.TeleportService:Teleport(game.PlaceId, rt.player)
end

-- ANTI-AFK --
rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
end)

-- MOMENTUM MOVEMENT ENGINE --
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

    -- 95% THRESHOLD: Exit just before the 'dead stop'
    local alpha = 0
    while alpha < 0.95 do 
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
        task.wait() -- Minimal wait for maximum response
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        -- Map/Container Logic
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
            stallTime = 0 
            if container ~= nil then task.wait(9) end
        end

        -- Stall/Refresh Check
        if container == nil or #container:GetChildren() == 0 then
            stallTime = stallTime + 1
            if stallTime >= 600 then serverHop() break end
            task.wait(1)
            continue
        end

        -- REFRESH OCTREE BEFORE MOVING (Efficiency)
        rt.octree:ClearAllNodes()
        for _, v in ipairs(container:GetDescendants()) do
            if rt.TargetNames[v.Name] and v:IsA("BasePart") and not rt.touchedCoins[v] then
                rt.octree:CreateNode(v.Position, v)
            end
        end

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            stallTime = 0
            label.Text = "Snatching Seamlessly: " .. sessionCoins
            
            -- Move to coin
            local target = nearest.Object
            if moveAndValidate(target) == "SUCCESS" then
                rt.touchedCoins[target] = true
                sessionCoins = sessionCoins + 1
            end
        else
            label.Text = "Scanning... Stall: " .. math.floor(stallTime) .. "s"
        end
    end
end

task.spawn(start)
