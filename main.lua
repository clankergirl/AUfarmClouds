-- Fixes: Coin detection depth and "Touch" registration
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 28, -- Slightly faster for mobile
    radius = 500,
    depth = 4.0
}
rt.player = rt.Players.LocalPlayer

-- NOCLIP CACHE (Fast)
local charParts = {}
local function updateCache(char)
    charParts = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(charParts, p) end
    end
end
rt.player.CharacterAdded:Connect(updateCache)
if rt.player.Character then updateCache(rt.player.Character) end

rt.RunService.Stepped:Connect(function()
    for i = 1, #charParts do charParts[i].CanCollide = false end
end)

-- UI
local screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "AndroidBalancedUI"
local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 250, 0, 40)
label.Position = UDim2.new(0.5, -125, 0.1, 0)
label.BackgroundTransparency = 0.5
label.BackgroundColor3 = Color3.new(0,0,0)
label.TextColor3 = Color3.new(1,1,1)
label.Text = "Starting..."

-- IMPROVED MOVEMENT (Anti-Rubberband)
local function moveGhost(targetPos)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local startPos = root.Position
    local goalPos = targetPos - Vector3.new(0, rt.depth, 0)
    local dist = (startPos - goalPos).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()

    -- We anchor the Root to prevent snapping
    root.Anchored = true 

    while tick() - startTick < duration do
        local alpha = (tick() - startTick) / duration
        local currentFramePos = startPos:Lerp(goalPos, alpha)
        char:PivotTo(CFrame.new(currentFramePos) * CFrame.Angles(math.rad(90), 0, 0))
        rt.RunService.Heartbeat:Wait()
    end
    
    -- Teleport directly onto the coin for 1 frame to ensure "Touch" works
    char:PivotTo(CFrame.new(targetPos) * CFrame.Angles(math.rad(90), 0, 0))
    task.wait(0.05) 
    root.Anchored = false -- Unanchor so the server registers the touch
end

-- DEEP-SEARCH COIN FINDER
local function populateOctree()
    rt.octree:ClearAllNodes()
    -- Look for 'Base' then look for 'CoinContainer'
    local base = workspace:FindFirstChild("Base", true)
    local container = base and base.Parent:FindFirstChild("CoinContainer")
    
    if container then
        -- We must use GetDescendants here because coins are often nested in folders
        for _, v in ipairs(container:GetDescendants()) do
            if rt.TargetNames[v.Name] and v:IsA("BasePart") and not rt.touchedCoins[v] then
                rt.octree:CreateNode(v.Position, v)
            end
        end
    end
end

-- MAIN LOOP
local function startFarm()
    local sessionTotal = 0
    
    while true do
        local char = rt.player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then task.wait(1) continue end

        -- Bag Check
        local gui = rt.player.PlayerGui:FindFirstChild("MainGUI")
        local fullIcon = gui and gui:FindFirstChild("FullBagIcon", true)
        
        if fullIcon and fullIcon.Visible then
            label.Text = "Bag Full! Resetting..."
            hum.Health = 0
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue
        end

        populateOctree()

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            label.Text = "Farming: " .. sessionTotal
            moveGhost(nearest.Object.Position)
            
            rt.touchedCoins[nearest.Object] = true
            sessionTotal = sessionTotal + 1
            task.wait(0.1)
        else
            label.Text = "No Coins in Radius (" .. rt.radius .. ")"
            task.wait(1)
        end
    end
end

task.spawn(startFarm)
