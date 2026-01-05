-- Updated by clankergirl
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {} 
rt.Players = game:GetService("Players")
rt.player = rt.Players.LocalPlayer

rt.coinContainer = nil
rt.octree = Octree.new()
rt.Material = Enum.Material.Ice
rt.radius = 200 
rt.walkspeed = 30 
rt.touchedCoins = {} 
rt.positionChangeConnections = setmetatable({}, { __mode = "v" }) 
rt.Added = nil
rt.Removing = nil
rt.MainGUI = rt.player.PlayerGui.MainGUI or rt.player.PlayerGui:WaitForChild("MainGUI")
rt.TargetNames = {"Coin_Server", "SnowToken", "Coin"}

function rt:Character () : (Model)
    return self.player.Character or self.player.CharacterAdded:Wait()
end

function rt:Map () : (Model | nil)
    for _, v in workspace:GetDescendants() do
        if v:IsA("Model") and v.Name == "Base" then
            return v.Parent
        end
    end
    return nil
end

function rt.Disconnect (connection:RBXScriptConnection)
    if typeof(connection) ~= "RBXScriptConnection" then return end
    if connection.Connected then
        connection:Disconnect()
    end
end

local function isCoinTouched(coin)
    return rt.touchedCoins[coin]
end

local function markCoinAsTouched(coin)
    rt.touchedCoins[coin] = true
    local node = rt.octree:FindFirstNode(coin)
    if node then
        rt.octree:RemoveNode(node)
    end
end

local function setupTouchTracking(coin)
    local touchInterest = coin:FindFirstChildWhichIsA("TouchTransmitter")
    if touchInterest then
        local connection
        connection = touchInterest.AncestryChanged:Connect(function(_, parent)
            if parent == nil then
                markCoinAsTouched(coin)
                rt.Disconnect(connection)
            end
        end)
        rt.positionChangeConnections[coin] = connection
    end
end

local function setupPositionTracking(coin, LastPositonY)
    local connection
    connection = coin:GetPropertyChangedSignal("Position"):Connect(function()
        if coin.Position.Y ~= LastPositonY then
            markCoinAsTouched(coin)
            rt.Disconnect(connection)
            coin:Destroy()
        end
    end)
    rt.positionChangeConnections[coin] = connection
end

local function isValidCurrency(obj)
    for _, name in ipairs(rt.TargetNames) do
        if obj.Name == name then return true end
    end
    return false
end

local function populateOctree()
    rt.octree:ClearAllNodes() 
    for _, descendant in pairs(rt.coinContainer:GetDescendants()) do
        if descendant:IsA("TouchTransmitter") then
            local parentCoin = descendant.Parent
            if isValidCurrency(parentCoin) and not isCoinTouched(parentCoin) then 
                rt.octree:CreateNode(parentCoin.Position, parentCoin)
                setupTouchTracking(parentCoin)
                setupPositionTracking(parentCoin, parentCoin.Position.Y)
            end
        end
    end

    rt.Added = rt.coinContainer.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("TouchTransmitter") then 
            local parentCoin = descendant.Parent
            if isValidCurrency(parentCoin) and not isCoinTouched(parentCoin) then
                rt.octree:CreateNode(parentCoin.Position, parentCoin)
                setupTouchTracking(parentCoin)
                setupPositionTracking(parentCoin, parentCoin.Position.Y)
            end
        end
    end)
end

local function moveToPositionSlowly(targetPosition: Vector3, duration: number)
    local char = rt:Character()
    local startTime = tick()
    local startPos = char.PrimaryPart.Position
    
    while tick() - startTime < duration do
        local alpha = (tick() - startTime) / duration
        char:PivotTo(CFrame.new(startPos:Lerp(targetPosition, alpha)))
        task.wait()
    end
    char:PivotTo(CFrame.new(targetPosition))
end

local function collectCoins()
    rt.coinContainer = rt:Map():FindFirstChild("CoinContainer")
    local sessionCoins = 0 
    populateOctree()

    while true do
        local character = rt:Character()
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")

        -- Check Bag Status
        local bagContainer = rt.MainGUI:WaitForChild("Game").CoinBags.Container
        local tokenUI = bagContainer:FindFirstChild("SnowToken") or bagContainer:FindFirstChild("Coin")

        if tokenUI and tokenUI.FullBagIcon.Visible then
            print("Bag full. Total this session: " .. sessionCoins .. ". Resetting...")
            humanoid.Health = 0
            rt.player.CharacterAdded:Wait()
            task.wait(3) -- Give the game time to spawn and clear UI
            continue 
        end

        local nearestNode = rt.octree:GetNearest(rootPart.Position, rt.radius, 1)[1]
        if nearestNode then
            local closestCoin = nearestNode.Object
            if not isCoinTouched(closestCoin) then
                moveToPositionSlowly(closestCoin.Position, (rootPart.Position - closestCoin.Position).Magnitude / rt.walkspeed)
                markCoinAsTouched(closestCoin)
                sessionCoins = sessionCoins + 1
                print("Collected: " .. closestCoin.Name .. " | Total: " .. sessionCoins)
                task.wait(0.1)
            end
        else
            task.wait(1)
        end
    end
end

-- Start the script
local start = coroutine.create(collectCoins)
coroutine.resume(start)

-- Cleanup ONLY when leaving the game
rt.Players.PlayerRemoving:Connect(function(player)
    if player == rt.player then
        coroutine.close(start)
        rt.Disconnect(rt.Added)
        rt = nil
    end
end)
