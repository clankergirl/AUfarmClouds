-- Optimized for Android 10 (High Compatibility)
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 25,
    radius = 300,=
    depth = 4
}
rt.player = rt.Players.LocalPlayer

local screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "DebugUI"
local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 300, 0, 50)
label.Position = UDim2.new(0.5, -150, 0.1, 0)
label.BackgroundColor3 = Color3.new(0,0,0)
label.TextColor3 = Color3.new(1,1,1)
label.Text = "Script Started - Searching..."

local function updateStatus(txt) label.Text = txt end

rt.RunService.Stepped:Connect(function()
    local char = rt.player.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

local function moveGhost(targetPos)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local goalPos = targetPos - Vector3.new(0, rt.depth, 0)
    root.Anchored = true
    
    local startPos = root.Position
    local dist = (startPos - goalPos).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()

    while tick() - startTick < duration do
        local alpha = (tick() - startTick) / duration
        char:PivotTo(CFrame.new(startPos:Lerp(goalPos, alpha)) * CFrame.Angles(math.rad(90), 0, 0))
        rt.RunService.Heartbeat:Wait()
    end
    
    char:PivotTo(CFrame.new(targetPos))
    task.wait(0.1)
    root.Anchored = false
end

local function start()
    while true do
        task.wait(0.5)
        
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then 
            updateStatus("Waiting for Character...")
            continue 
        end

        local bag = rt.player.PlayerGui:FindFirstChild("MainGUI", true)
        local full = bag and bag:FindFirstChild("FullBagIcon", true)
        if full and full.Visible then
            updateStatus("Bag Full - Resetting")
            char.Humanoid.Health = 0
            rt.player.CharacterAdded:Wait()
            task.wait(3)
            continue
        end

        rt.octree:ClearAllNodes()
        local coinsFound = 0
        
        for _, container in ipairs(workspace:GetDescendants()) do
            if container.Name == "CoinContainer" then
                for _, coin in ipairs(container:GetDescendants()) do
                    if rt.TargetNames[coin.Name] and not rt.touchedCoins[coin] then
                        rt.octree:CreateNode(coin.Position, coin)
                        coinsFound = coinsFound + 1
                    end
                end
            end
        end

        if coinsFound == 0 then
            updateStatus("No Coins Found on Map")
            continue
        end

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            updateStatus("Moving to Coin...")
            moveGhost(nearest.Object.Position)
            rt.touchedCoins[nearest.Object] = true
        else
            updateStatus("Coins exist but none in radius")
        end
    end
end

task.spawn(start)
