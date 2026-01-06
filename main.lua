-- Optimized by clankergirl
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 30,
    radius = 200,
    undergroundDepth = 4
}
rt.player = rt.Players.LocalPlayer

-- LIGHTWEIGHT NOCLIP CACHE
local charParts = {}
local function updateCharCache(char)
    charParts = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(charParts, p) end
    end
end
rt.player.CharacterAdded:Connect(updateCharCache)
if rt.player.Character then updateCharCache(rt.player.Character) end

rt.RunService.Stepped:Connect(function()
    for i = 1, #charParts do charParts[i].CanCollide = false end
end)

-- UI SETUP
local screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "LiteFarmUI"
local statusLabel = Instance.new("TextLabel", screenGui)
statusLabel.Size = UDim2.new(0, 250, 0, 40)
statusLabel.Position = UDim2.new(0.5, -125, 0.8, 0)
statusLabel.BackgroundTransparency = 0.5
statusLabel.BackgroundColor3 = Color3.new(0,0,0)
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Text = "Lite Mode Active"

local lastStatus = ""
local function updateStatus(text)
    if text ~= lastStatus then
        statusLabel.Text = text
        lastStatus = text
    end
end

-- EFFICIENT MAP FINDER
local function getMap()
    local b = workspace:FindFirstChild("Base", true)
    return b and b.Parent
end

-- EVENT-DRIVEN OCTREE (No constant scanning)
local function startCoinListener(container)
    container.DescendantAdded:Connect(function(obj)
        if rt.TargetNames[obj.Name] and obj:IsA("BasePart") then
            rt.octree:CreateNode(obj.Position, obj)
        end
    end)
end

-- MAIN LITE LOOP
local function collectCoins()
    local sessionCoins = 0
    local map = getMap()
    if not map then return updateStatus("Map Error") end
    
    local container = map:FindFirstChild("CoinContainer")
    if container then
        for _, v in ipairs(container:GetDescendants()) do
            if rt.TargetNames[v.Name] and v:IsA("BasePart") then
                rt.octree:CreateNode(v.Position, v)
            end
        end
        startCoinListener(container)
    end

    while true do
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if not root or not hum then task.wait(1) continue end

        -- Check Bag (Direct Access)
        local bag = rt.player.PlayerGui:FindFirstChild("MainGUI", true)
        local icon = bag and bag:FindFirstChild("FullBagIcon", true)
        
        if icon and icon.Visible then
            updateStatus("Full! Resetting...")
            hum.Health = 0
            rt.player.CharacterAdded:Wait()
            task.wait(5)
            continue
        end

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            local coin = nearest.Object
            updateStatus("Farming: " .. sessionCoins)
            
            local startPos = root.Position
            local targetPos = coin.Position - Vector3.new(0, rt.undergroundDepth, 0)
            local duration = (startPos - targetPos).Magnitude / rt.walkspeed
            local startTick = tick()

            while tick() - startTick < duration do
                local alpha = (tick() - startTick) / duration
                char:PivotTo(CFrame.new(startPos:Lerp(targetPos, alpha)) * CFrame.Angles(math.rad(90), 0, 0))
                rt.RunService.Heartbeat:Wait()
            end
            
            rt.octree:RemoveNode(nearest)
            sessionCoins = sessionCoins + 1
            task.wait(0.1)
        else
            updateStatus("Idle - No Coins")
            task.wait(2)
        end
    end
end

task.spawn(collectCoins)
