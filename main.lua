-- Updated by clankergirl
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {} 
rt.Players = game:GetService("Players")
rt.player = rt.Players.LocalPlayer
rt.RunService = game:GetService("RunService")

rt.coinContainer = nil
rt.octree = Octree.new()
rt.radius = 200 
rt.walkspeed = 25
rt.undergroundDepth = 4 
rt.touchedCoins = {} 
rt.TargetNames = {"Coin_Server", "SnowToken", "Coin"}

-- UI SETUP
local screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "FarmStatusGui"
screenGui.ResetOnSpawn = false

local statusLabel = Instance.new("TextLabel", screenGui)
statusLabel.Size = UDim2.new(0, 350, 0, 50)
statusLabel.Position = UDim2.new(0.5, -175, 0.85, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.BackgroundTransparency = 0.2
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 16
statusLabel.Text = "Ghost Mode Initializing..."

local function updateStatus(text, color)
    statusLabel.Text = text
    if color then statusLabel.TextColor3 = color end
end

-- NOCLIP HANDLER
-- This runs every frame to ensure collisions stay disabled
rt.RunService.Stepped:Connect(function()
    local char = rt.player.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- HELPER FUNCTIONS
function rt:Character()
    return self.player.Character or self.player.CharacterAdded:Wait()
end

function rt:Map()
    for _, v in workspace:GetDescendants() do
        if v:IsA("Model") and v.Name == "Base" then
            return v.Parent
        end
    end
    return nil
end

local function isCoinTouched(coin)
    return rt.touchedCoins[coin]
end

local function markCoinAsTouched(coin)
    rt.touchedCoins[coin] = true
    local node = rt.octree:FindFirstNode(coin)
    if node then rt.octree:RemoveNode(node) end
end

local function isValidCurrency(obj)
    for _, name in ipairs(rt.TargetNames) do
        if obj.Name == name then return true end
    end
    return false
end

local function populateOctree()
    rt.octree:ClearAllNodes()
    rt.coinContainer = rt:Map():FindFirstChild("CoinContainer")
    if not rt.coinContainer then return end
    for _, descendant in pairs(rt.coinContainer:GetDescendants()) do
        if descendant:IsA("TouchTransmitter") then
            local parentCoin = descendant.Parent
            if isValidCurrency(parentCoin) and not isCoinTouched(parentCoin) then 
                rt.octree:CreateNode(parentCoin.Position, parentCoin)
            end
        end
    end
end

local function moveToPositionSlowly(targetPosition, duration)
    local char = rt:Character()
    local startTime = tick()
    local startPos = char:GetPivot().Position
    local horizontalRotation = CFrame.Angles(math.rad(90), 0, 0)

    while tick() - startTime < duration do
        local alpha = (tick() - startTime) / duration
        local currentPos = startPos:Lerp(targetPosition, alpha)
        
        -- Depth + Rotation + Noclip position
        local finalCFrame = CFrame.new(currentPos - Vector3.new(0, rt.undergroundDepth, 0)) * horizontalRotation
        char:PivotTo(finalCFrame)
        task.wait()
    end
end

-- MAIN LOOP
local function collectCoins()
    local sessionCoins = 0 
    
    while true do
        local map = rt:Map()
        if not map then
            updateStatus("Waiting for Map...", Color3.fromRGB(255, 150, 0))
            task.wait(2)
            continue
        end

        rt.coinContainer = map:FindFirstChild("CoinContainer")
        if not rt.coinContainer then
            updateStatus("Searching for CoinContainer...", Color3.fromRGB(255, 150, 0))
            task.wait(2)
            continue
        end
        
        populateOctree()

        local char = rt:Character()
        local humanoid = char:WaitForChild("Humanoid", 5)
        local rootPart = char:WaitForChild("HumanoidRootPart", 5)

        if not humanoid or not rootPart then 
            updateStatus("Respawning...", Color3.fromRGB(255, 255, 255))
            task.wait(1) 
            continue 
        end

        -- Check Bag Status
        local bagContainer = rt.player.PlayerGui:WaitForChild("MainGUI"):WaitForChild("Game").CoinBags.Container
        local tokenUI = bagContainer:FindFirstChild("SnowToken") or bagContainer:FindFirstChild("Coin")

        if tokenUI and tokenUI.FullBagIcon.Visible then
            updateStatus("Bag Full! Resetting Character...", Color3.fromRGB(255, 50, 50))
            humanoid.Health = 0
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue 
        end

        -- Find Nearest Coin
        local nearestNode = rt.octree:GetNearest(rootPart.Position, rt.radius, 1)[1]
        if nearestNode then
            local closestCoin = nearestNode.Object
            if not isCoinTouched(closestCoin) then
                updateStatus("Ghost Farming (Total: " .. sessionCoins .. ")", Color3.fromRGB(150, 255, 255))
                
                local dist = (rootPart.Position - closestCoin.Position).Magnitude
                moveToPositionSlowly(closestCoin.Position, dist / rt.walkspeed)
                markCoinAsTouched(closestCoin)
                
                sessionCoins = sessionCoins + 1
                task.wait(0.1)
            end
        else
            updateStatus("All coins collected! Waiting for respawn...", Color3.fromRGB(200, 200, 255))
            task.wait(1)
        end
    end
end

task.spawn(collectCoins)
