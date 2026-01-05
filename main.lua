-- Updated by clankergirl
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {} 
rt.Players = game:GetService("Players")
rt.player = rt.Players.LocalPlayer

rt.coinContainer = nil
rt.octree = Octree.new()
rt.radius = 200 
rt.walkspeed = 25
rt.touchedCoins = {} 
rt.TargetNames = {"Coin_Server", "SnowToken", "Coin"}

local screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "FarmStatusGui"
screenGui.ResetOnSpawn = false

local statusLabel = Instance.new("TextLabel", screenGui)
statusLabel.Size = UDim2.new(0, 300, 0, 50)
statusLabel.Position = UDim2.new(0.5, -150, 0.85, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.BackgroundTransparency = 0.3
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 18
statusLabel.Text = "Initializing..."

local function updateStatus(text, color)
    statusLabel.Text = text
    if color then statusLabel.TextColor3 = color end
end

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
    
    while tick() - startTime < duration do
        local alpha = (tick() - startTime) / duration
        char:PivotTo(CFrame.new(startPos:Lerp(targetPosition, alpha)))
        task.wait()
    end
    char:PivotTo(CFrame.new(targetPosition))
end

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
            updateStatus("Waiting for Character...", Color3.fromRGB(255, 255, 255))
            task.wait(1) 
            continue 
        end

        local bagContainer = rt.player.PlayerGui:WaitForChild("MainGUI"):WaitForChild("Game").CoinBags.Container
        local tokenUI = bagContainer:FindFirstChild("SnowToken") or bagContainer:FindFirstChild("Coin")

        if tokenUI and tokenUI.FullBagIcon.Visible then
            updateStatus("Bag is Full! Resetting...", Color3.fromRGB(255, 50, 50))
            humanoid.Health = 0
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue 
        end

        local nearestNode = rt.octree:GetNearest(rootPart.Position, rt.radius, 1)[1]
        if nearestNode then
            local closestCoin = nearestNode.Object
            if not isCoinTouched(closestCoin) then
                updateStatus("Collecting Coins (" .. sessionCoins .. ")", Color3.fromRGB(100, 255, 100))
                
                local dist = (rootPart.Position - closestCoin.Position).Magnitude
                moveToPositionSlowly(closestCoin.Position, dist / rt.walkspeed)
                markCoinAsTouched(closestCoin)
                
                sessionCoins = sessionCoins + 1
                task.wait(0.1)
            end
        else
            updateStatus("Scanning for Coins...", Color3.fromRGB(200, 200, 255))
            task.wait(1)
        end
    end
end

task.spawn(collectCoins)

-- Cleanup on Leave
rt.Players.PlayerRemoving:Connect(function(p)
    if p == rt.player then screenGui:Destroy() end
end)
