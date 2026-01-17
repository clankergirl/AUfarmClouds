local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()

local rt = {} -- Removable table
rt.__index = rt
rt.octree = Octree.new()

rt.RoundInProgress = false

rt.Players = game.Players
rt.player = game.Players.LocalPlayer

rt.coinContainer = nil
rt.radius = 200 :: number 
rt.walkspeed = 22 :: number 
rt.touchedCoins = {} -- Table to track touched coins
rt.positionChangeConnections = setmetatable({}, { __mode = "v" }) 
rt.Added = nil :: RBXScriptConnection
rt.Removing = nil :: RBXScriptConnection

rt.UserDied = nil :: RBXScriptConnection

local State = {
    Action = "Action",
    StandStillWait = "StandStillWait",
    WaitingForRound = "WaitingForRound",
    WaitingForRoundEnd = "WaitingForRoundEnd",
    RespawnState = "RespawnState"
}

local CurrentState = State.WaitingForRound
local LastPosition = nil
local RoundInProgress = function()
    return rt.RoundInProgress
end
local BagIsFull = false

rt.RoleTracker1 = nil :: RBXScriptConnection
rt.RoleTracker2 = nil :: RBXScriptConnection
rt.InvalidPos = nil :: RBXScriptConnection
local IsMurderer = false
local Working = false
local ROUND_TIMER = workspace:WaitForChild("RoundTimerPart").SurfaceGui.Timer
local PLAYER_GUI = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

function rt:Message(_Title, _Text, Time)
	game:GetService("StarterGui"):SetCore("SendNotification", { Title = _Title, Text = _Text, Duration = Time })
end

function rt:Character () : (Model)
    return self.player.Character or self.player.CharacterAdded:Wait()
end

function rt:GetCharacterLoaded() : (Model)
    repeat
        task.wait(0.02)
    until rt:Character() ~= nil
end

function rt:CheckIfPlayerIsInARound () : (boolean)
    if not PLAYER_GUI:FindFirstChild("MainGUI") then return false end

    if PLAYER_GUI.MainGUI.Game.Timer.Visible then
        return true
    end

    if PLAYER_GUI.MainGUI.Game.EarnedXP.Visible then
        return true
    end

    return false
end

function rt:MainGUI () : (ScreenGui)
    return self.player.PlayerGui:FindFirstChild("MainGUI") or self.player.PlayerGui:WaitForChild("MainGUI")
end

function rt.Disconnect (connection:RBXScriptConnection)
    if connection and connection.Connected then
        connection:Disconnect()
    end
end

function rt:Map () : (Model | nil)
    for _, v in workspace:GetDescendants() do
        if v.Name == "Spawns" and v.Parent.Name ~= "Lobby"  then
            return v.Parent
        end
    end
    return nil
end

function rt:CheckIfGameInProgress () : (boolean)
    if rt:Map() then return true end
    return false
end

function rt:GetAlivePlayers (): (table | nil)
    local aliveplrs = setmetatable({}, {__mode = "v"})
    local OldPos = self:Character():GetPivot()
    local pos = CFrame.new(-121.995956, 134.462997, 46.4180717)
    
    if not rt:CheckIfGameInProgress() then return nil end

    local isAlive = rt:CheckIfPlayerIsInARound()
    if not isAlive then self:Character():PivotTo(pos) end

    for _, v in pairs(rt.Players:GetPlayers()) do
        if v.Character and v.Character:FindFirstChild("PrimaryPart") then
            local distance = (self:Character().PrimaryPart.Position - v.Character.PrimaryPart.Position).Magnitude
            if isAlive then
                if distance <= 500 then table.insert(aliveplrs, v) end
            else
                if distance > 500 then table.insert(aliveplrs, v) end
            end
        end
    end

    if not isAlive then self:Character():PivotTo(OldPos) end
    return aliveplrs
end

function rt:CheckIfPlayerWasInARound () : (boolean)
    return self.player:GetAttribute("Alive") or false
end

function rt:IsElite() : (boolean)
    return self.player:GetAttribute("Elite") or false
end


local function AutoFarmCleanUp()
    for _, connection in pairs(rt.positionChangeConnections) do
        rt.Disconnect(connection)
    end
    rt.Disconnect(rt.Added)
    rt.Disconnect(rt.Removing)

    table.clear(rt.touchedCoins)
    table.clear(rt.positionChangeConnections)
    rt.octree:ClearAllNodes()
end

local function isCoinTouched(coin)
    return rt.touchedCoins[coin]
end

local function markCoinAsTouched(coin)
    if not rt then return end
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
            return
        end
    end)
    rt.positionChangeConnections[coin] = connection
end

local function moveToPositionSlowly(targetPosition: Vector3, duration: number)
    local char = rt:Character()
    if not char or not char:FindFirstChild("PrimaryPart") then return end
    
    local startPosition = char.PrimaryPart.Position
    local startTime = tick()

    while true do
        local elapsedTime = tick() - startTime
        local alpha = math.min(elapsedTime / duration, 1)

        if not char:FindFirstChild("PrimaryPart") then break end
        char:PivotTo(CFrame.new(startPosition:Lerp(targetPosition, alpha)))

        if alpha >= 1 then
            task.wait(0.1)
            break
        end
        task.wait()
    end
end

local function populateOctree()
    rt.octree:ClearAllNodes()

    for _, descendant in pairs(rt.coinContainer:GetDescendants()) do
        -- UPDATED: Detects any object named Coin_Server with a TouchTransmitter
        if descendant.Name == "Coin_Server" and descendant:FindFirstChildWhichIsA("TouchTransmitter") then
            if not isCoinTouched(descendant) then
                rt.octree:CreateNode(descendant.Position, descendant)
                setupTouchTracking(descendant)
                setupPositionTracking(descendant, descendant.Position.Y)
            end
        end
    end

    rt.Added = rt.coinContainer.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "Coin_Server" then
            task.wait(0.1) -- Ensure TouchTransmitter has time to load
            if not isCoinTouched(descendant) then
                rt.octree:CreateNode(descendant.Position, descendant)
                setupTouchTracking(descendant)
                setupPositionTracking(descendant, descendant.Position.Y)
            end
        end
    end)
end

local function IsBagFull()
    local mainGui = PLAYER_GUI:FindFirstChild("MainGUI")
    if not mainGui then return false end
    
    local container = mainGui.Game.CoinBags.Container
    local activeCurrency = container:FindFirstChildWhichIsA("Frame")
    
    if activeCurrency and activeCurrency:FindFirstChild("CurrencyFrame") then
        local coinText = activeCurrency.CurrencyFrame.Icon.Coins.Text
        local currentAmount = tonumber(coinText) or 0
        local maxAmount = (rt:IsElite() and 50 or 40)
        return currentAmount >= maxAmount
    end
    
    return false
end


local function ChangeState(NewState)
    CurrentState = NewState
end

local function CollectCoins()
    Working = true
    local map = rt:Map()
    if not map then return end
    
    rt.coinContainer = map:FindFirstChild("CoinContainer")
    if not rt.coinContainer then return end
    
    populateOctree()
    
    while CurrentState == State.Action do
        if IsBagFull() then
            rt:Message("Alert", "Bag is full!", 2)
            BagIsFull = true
            break
        end

        local char = rt:Character()
        if not char or not char:FindFirstChild("PrimaryPart") then break end

        local nearestNode = rt.octree:GetNearest(char.PrimaryPart.Position, rt.radius, 1)[1]
        if nearestNode then
            local closestCoin = nearestNode.Object
            if not isCoinTouched(closestCoin) then
                local targetPosition = closestCoin.Position
                local duration = (char.PrimaryPart.Position - targetPosition).Magnitude / rt.walkspeed
                moveToPositionSlowly(targetPosition, duration)
                markCoinAsTouched(closestCoin)
                task.wait(0.1)
            end
        else
            task.wait(0.5)
        end
    end
    AutoFarmCleanUp()
end

local function ActionState()
    LastPosition = nil
    rt:Message("Info", "Starting Farm...", 2)
    CollectCoins()

    if BagIsFull or not RoundInProgress() then
        rt:Message("Info", "Returning to Waiting State...", 2)
        BagIsFull, Working = false, false
        local human = rt:Character():FindFirstChildWhichIsA("Humanoid")
        if human then human.Health = 0 end -- Reset to clear bag/round
        ChangeState(State.WaitingForRoundEnd)
    end
end

local function WaitingForRound()
    rt:Message("Info", "Waiting for round...", 2)
    repeat task.wait(0.5) until RoundInProgress() and rt:CheckIfPlayerWasInARound()
    ChangeState(State.Action)
end

local function waitForRoundEnd()
    repeat task.wait(1) until not RoundInProgress()
    ChangeState(State.WaitingForRound)
end


rt.RoleTracker1 = rt.player.Backpack.ChildAdded:Connect(function(child)
    if child.Name == "Knife" then IsMurderer = true end
end)

ROUND_TIMER:GetPropertyChangedSignal("Text"):Connect(function()
    rt.RoundInProgress = true
end)

PLAYER_GUI.ChildAdded:Connect(function(child)
    if child:IsA("Sound") then
        rt.RoundInProgress = false
        Working = false
        ChangeState(State.WaitingForRound)
    end
end)

rt.UserDied = rt.player.CharacterRemoving:Connect(function()
    AutoFarmCleanUp()
    if CurrentState == State.Action then
        ChangeState(State.WaitingForRound)
    end
end)

while true do
    if CurrentState == State.WaitingForRound then
        WaitingForRound()
    elseif CurrentState == State.Action then
        ActionState()
    elseif CurrentState == State.WaitingForRoundEnd then
        waitForRoundEnd()
    end
    task.wait()
end
