-- Updated by clankergirl
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {} 
rt.Players = game:GetService("Players")
rt.player = rt.Players.LocalPlayer

rt.coinContainer = nil
rt.octree = Octree.new()
rt.radius = 200 
rt.walkspeed = 30 
rt.touchedCoins = {} 
rt.positionChangeConnections = setmetatable({}, { __mode = "v" }) 
rt.TargetNames = {"Coin_Server", "SnowToken", "Coin"}

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

-- This function now stays alive permanently
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
        -- Ensure map and container are ready
        rt.coinContainer = rt:Map():FindFirstChild("CoinContainer")
        if not rt.coinContainer then task.wait(1) continue end
        
        populateOctree()

        local char = rt:Character()
        local humanoid = char:WaitForChild("Humanoid", 5)
        local rootPart = char:WaitForChild("HumanoidRootPart", 5)

        if not humanoid or not rootPart then task.wait(1) continue end

        -- 1. Check Bag Status
        local bagContainer = rt.player.PlayerGui:WaitForChild("MainGUI"):WaitForChild("Game").CoinBags.Container
        local tokenUI = bagContainer:FindFirstChild("SnowToken") or bagContainer:FindFirstChild("Coin")

        if tokenUI and tokenUI.FullBagIcon.Visible then
            print("Bag full! Total: " .. sessionCoins .. ". Resetting...")
            humanoid.Health = 0
            rt.player.CharacterAdded:Wait() -- Wait for respawn
            task.wait(3) -- Safety buffer for UI to clear
            continue 
        end

        -- 2. Find Nearest Coin
        local nearestNode = rt.octree:GetNearest(rootPart.Position, rt.radius, 1)[1]
        if nearestNode then
            local closestCoin = nearestNode.Object
            if not isCoinTouched(closestCoin) then
                local dist = (rootPart.Position - closestCoin.Position).Magnitude
                moveToPositionSlowly(closestCoin.Position, dist / rt.walkspeed)
                markCoinAsTouched(closestCoin)
                sessionCoins = sessionCoins + 1
                print("Collected: " .. closestCoin.Name .. " | Total: " .. sessionCoins)
                task.wait(0.1)
            end
        else
            task.wait(1) -- No coins nearby, wait and check again
        end
    end
end

-- Run in a thread that doesn't get destroyed on death
task.spawn(collectCoins)

-- ONLY cleanup when you actually leave the game
rt.Players.PlayerRemoving:Connect(function(player)
    if player == rt.player then
        print("Player left. Shutting down script.")
        rt = nil
    end
end)
