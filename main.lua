-- Updated by clankergirl
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 25,
    radius = 300,
    depth = 4
}
rt.player = rt.Players.LocalPlayer

-- NOCLIP & CACHE
local charParts = {}
local function updateCache(char)
    charParts = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then table.insert(charParts, p) end
    end
end
rt.player.CharacterAdded:Connect(updateCache)
if rt.player.Character then updateCache(rt.player.Character) end

-- Frame-stable Noclip
rt.RunService.Stepped:Connect(function()
    for i = 1, #charParts do charParts[i].CanCollide = false end
end)

-- LITE UI
local screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "AndroidLiteUI"
local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 220, 0, 35)
label.Position = UDim2.new(0.5, -110, 0.05, 0)
label.BackgroundColor3 = Color3.new(0,0,0)
label.BackgroundTransparency = 0.6
label.TextColor3 = Color3.new(1,1,1)
label.TextSize = 14
label.Font = Enum.Font.SourceSansBold

-- MOVEMENT ENGINE (The "Anti-Snap" Fix)
local function moveGhost(targetPos)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local startPos = root.Position
    local goalPos = targetPos - Vector3.new(0, rt.depth, 0)
    local dist = (startPos - goalPos).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()

    -- ANCHOR: Stops the physics engine from fighting the script
    root.Anchored = true 

    while tick() - startTick < duration do
        local alpha = (tick() - startTick) / duration
        local currentFramePos = startPos:Lerp(goalPos, alpha)
        
        -- Apply position and laying flat rotation
        char:PivotTo(CFrame.new(currentFramePos) * CFrame.Angles(math.rad(90), 0, 0))
        
        -- Heartbeat is safer for Android CPU than task.wait()
        rt.RunService.Heartbeat:Wait()
    end
    
    char:PivotTo(CFrame.new(goalPos) * CFrame.Angles(math.rad(90), 0, 0))
end

-- MAIN LITE LOOP
local function startFarm()
    local sessionTotal = 0
    
    while true do
        local char = rt.player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")

        if not hum or not root then task.wait(1) continue end

        -- Fast Bag Check
        local gui = rt.player.PlayerGui:FindFirstChild("MainGUI")
        local fullIcon = gui and gui:FindFirstChild("FullBagIcon", true)
        
        if fullIcon and fullIcon.Visible then
            label.Text = "Bag Full! Resetting..."
            root.Anchored = false -- Must unanchor to die
            hum.Health = 0
            rt.player.CharacterAdded:Wait()
            task.wait(5)
            continue
        end

        -- Refresh Octree only when standing still to save CPU
        local map = workspace:FindFirstChild("Base", true)
        local container = map and map.Parent:FindFirstChild("CoinContainer")
        if container then
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetChildren()) do
                if rt.TargetNames[v.Name] and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v)
                end
            end
        end

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            label.Text = "Farming: " .. sessionTotal
            moveGhost(nearest.Object.Position)
            
            rt.touchedCoins[nearest.Object] = true
            rt.octree:RemoveNode(nearest)
            sessionTotal = sessionTotal + 1
        else
            label.Text = "Scanning for coins..."
            task.wait(2)
        end
    end
end

task.spawn(startFarm)
