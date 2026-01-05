-- Updated by clankergirl
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {} 
rt.Players = game:GetService("Players")
rt.player = rt.Players.LocalPlayer

rt.coinContainer = nil
rt.octree = Octree.new()
rt.Material = Enum.Material.Ice
rt.TpBackToStart = true
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

local function setupPositionTracking(coin: MeshPart, LastPositonY: number)
    local connection
    connection = coin:GetPropertyChangedSignal("Position"):Connect(function()
        local currentY = coin.Position.Y
        if LastPositonY and LastPositonY ~= currentY then
            markCoinAsTouched(coin)
            rt.Disconnect(connection)
            coin:Destroy()
            return
        end
    end)
    rt.positionChangeConnections[coin] = connection
end

local function isValidCurrency(obj)
    for _, name in ipairs(rt.TargetNames) do
        if obj.Name == name then
            return true
        end
    end
    return false
end

local function populateOctree()
    rt.octree:ClearAllNodes() 

    for _, descendant in pairs(rt.coinContainer:GetDescendants()) do
        if descendant:IsA("TouchTransmitter") then
            local parentCoin = descendant.Parent
            if isValidCurrency(parentCoin) then 
                if not isCoinTouched(parentCoin) then
                    rt.octree:CreateNode(parentCoin.Position, parentCoin)
                    setupTouchTracking(parentCoin)
                end
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

    rt.Removing = rt.coinContainer.DescendantRemoving:Connect(function(descendant)
        if descendant:IsA("TouchTransmitter") then
            local parentCoin = descendant.Parent
            if isValidCurrency(parentCoin) then
                markCoinAsTouched(parentCoin)
            end
        end
    end)
end

local function moveToPositionSlowly(targetPosition: Vector3, duration: number)
    rt.humanoidRootPart = rt:Character().PrimaryPart
    local startPosition = rt.humanoidRootPart.Position
    local startTime = tick()
    
    while true do
        local elapsedTime = tick() - startTime
        local alpha = math.min(elapsedTime / duration, 1)
        rt:Character():PivotTo(CFrame.new(startPosition:Lerp(targetPosition, alpha)))

        if alpha >= 1 then
            task.wait(0.2)
            break
        end
        task.wait() 
    end
end

local function collectCoins()
    rt.coinContainer = rt:Map():FindFirstChild("CoinContainer")
    assert(rt.coinContainer, "CoinContainer not found in the map!")
    rt.waypoint = rt:Character():GetPivot()
    
    local sessionCoins = 0 -- Local counter for this session

    populateOctree()

    while true do
        local bagContainer = rt.MainGUI:WaitForChild("Game").CoinBags.Container
        local tokenUI = bagContainer:FindFirstChild("SnowToken") or bagContainer:FindFirstChild("Coin")

        if tokenUI and tokenUI.FullBagIcon.Visible then
            print("Bag is full. Session Total: " .. sessionCoins .. " items.")
            break
        end

        local nearestNode = rt.octree:GetNearest(rt:Character().PrimaryPart.Position, rt.radius, 1)[1]

        if nearestNode then
            local closestCoin = nearestNode.Object
            if not isCoinTouched(closestCoin) then
                local closestCoinPosition = closestCoin.Position
                local distance = (rt:Character().PrimaryPart.Position - closestCoinPosition).Magnitude
                local duration = distance / rt.walkspeed 

                moveToPositionSlowly(closestCoinPosition, duration)
                markCoinAsTouched(closestCoin)
                
                sessionCoins = sessionCoins + 1 -- Increase counter
                print("Collected: " .. closestCoin.Name .. " | Total: " .. sessionCoins)
                
                task.wait(0.2) 
            end
        else
            task.wait(1) 
        end
    end

    if rt.TpBackToStart then
        rt:Character():PivotTo(rt.waypoint)
    end
end

local start = coroutine.create(collectCoins)
coroutine.resume(start)

local died = rt.player.CharacterRemoving:Connect(function()
    coroutine.close(start)
    for _, connection in pairs(rt.positionChangeConnections) do
        rt.Disconnect(connection)
    end
    rt.Disconnect(rt.Added)
    rt.Disconnect(rt.Removing)
    rt = nil
    Octree = nil
end)

rt.Players.PlayerRemoving:Connect(function()
    died:Disconnect()
end)
