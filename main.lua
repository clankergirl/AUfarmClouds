-- FINAL STABLE VERSION: V5.2 (6-Player Filtered Hop)
local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    TeleportService = game:GetService("TeleportService"),
    VirtualUser = game:GetService("VirtualUser"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 25,
    radius = 300,
    depth = 3
}
rt.player = rt.Players.LocalPlayer
local lastContainer = nil 
local stallTime = 0 

local screenGui = rt.player.PlayerGui:FindFirstChild("ClassicFarmUI")
if screenGui then screenGui:Destroy() end
screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "ClassicFarmUI"
screenGui.ResetOnSpawn = false 

local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 450, 0, 70)
label.Position = UDim2.new(0.5, -225, 0.5, -35) 
label.BackgroundTransparency = 1 
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextStrokeTransparency = 0 
label.TextStrokeColor3 = Color3.new(0,0,0)
label.Font = Enum.Font.GothamBold
label.TextSize = 22
label.Text = "Loading Farm..."

local function updateStatus(text, color)
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
end

local function serverHop()
    updateStatus("STALL DETECTED: Searching (Min 6 Players)...", Color3.fromRGB(255, 50, 50))
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
    local success, raw = pcall(function() return game:HttpGet(url) end)
    
    if success then
        local decoded = rt.HttpService:JSONDecode(raw)
        local possibleServers = {}
        for _, s in ipairs(decoded.data) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers and s.playing >= 6 then
                table.insert(possibleServers, s.id)
            end
        end
        if #possibleServers > 0 then
            rt.TeleportService:TeleportToPlaceInstance(game.PlaceId, possibleServers[math.random(1, #possibleServers)])
        else
            updateStatus("No 6+ player servers found. Retrying in 30s...", Color3.fromRGB(255, 150, 0))
            task.wait(30)
            stallTime = 570 -- Give it 30 more seconds before trying again
        end
    end
end

local function applyAntiFling(char)
    local parts = {}
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then 
            p.CanCollide = false 
            table.insert(parts, p)
        end
    end
    rt.RunService.Heartbeat:Connect(function()
        for i = 1, #parts do
            local p = parts[i]
            if p and p.Parent and (p.Velocity.Magnitude > 45 or p.RotVelocity.Magnitude > 45) then
                p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero
            end
        end
    end)
    task.spawn(function()
        while char and char.Parent do
            task.wait(5)
            for i = 1, #parts do
                local p = parts[i]
                if p and p.Parent then p.Velocity, p.RotVelocity = Vector3.zero, Vector3.zero end
            end
        end
    end)
end
rt.player.CharacterAdded:Connect(applyAntiFling)
if rt.player.Character then applyAntiFling(rt.player.Character) end

rt.player.Idled:Connect(function()
    rt.VirtualUser:CaptureController()
    rt.VirtualUser:ClickButton2(Vector2.new())
end)

local function moveAndValidate(targetCoin)
    local char = rt.player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not targetCoin or not targetCoin.Parent then return "CANCELLED" end

    local startPos = root.Position
    local targetPos = targetCoin.Position
    local ghostTarget = targetPos - Vector3.new(0, rt.depth, 0)
    local dist = (startPos - ghostTarget).Magnitude
    local duration = dist / rt.walkspeed
    local startTick = tick()
    local horizontalRotation = CFrame.Angles(math.rad(90), 0, 0)

    while tick() - startTick < duration do
        if not targetCoin or not targetCoin.Parent then return "CANCELLED" end
        if root.Position.Y < -100 then return "FELL" end
        local alpha = (tick() - startTick) / duration
        char:PivotTo(CFrame.new(startPos:Lerp(ghostTarget, alpha)) * horizontalRotation)
        rt.RunService.Heartbeat:Wait()
    end
    char:PivotTo(CFrame.new(ghostTarget) * horizontalRotation)
    return "SUCCESS"
end

local function isBagFull()
    local mainGui = rt.player.PlayerGui:FindFirstChild("MainGUI")
    local gameUI = mainGui and mainGui:FindFirstChild("Game")
    local coinBags = gameUI and gameUI:FindFirstChild("CoinBags")
    if coinBags then
        for _, bag in ipairs(coinBags:GetDescendants()) do
            if bag.Name == "FullBagIcon" and bag.Visible == true then return true end
        end
    end
    return false
end

local function start()
    local sessionCoins = 0
    while true do
        task.wait(0.1)
        local char = rt.player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not hum then continue end

        if isBagFull() then
            updateStatus("BAG FULL! RESETTING...", Color3.fromRGB(255, 50, 50))
            hum.Health = 0
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue
        end

        local container = nil
        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name == "CoinContainer" or v:FindFirstChild("CoinContainer") then 
                container = v.Name == "CoinContainer" and v or v.CoinContainer
                break 
            end
        end

        if container ~= lastContainer then
            lastContainer = container
            rt.touchedCoins = {}
            stallTime = 0 
            if container ~= nil then
                for i = 9, 1, -1 do
                    updateStatus("NEW MAP: Waiting " .. i .. "s...", Color3.fromRGB(255, 165, 0))
                    task.wait(1)
                end
            end
        end

        if container == nil or #container:GetChildren() == 0 then
            stallTime = stallTime + 1
            if stallTime >= 600 then serverHop() break end
        end

        if container then
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v)
                end
            end
        end

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            stallTime = 0
            updateStatus("Coins: " .. sessionCoins .. " | Snatching...", Color3.fromRGB(100, 255, 200))
            if moveAndValidate(nearest.Object) == "SUCCESS" then
                rt.touchedCoins[nearest.Object] = true
                sessionCoins = sessionCoins + 1
            end
        else
            updateStatus("Searching... Stall: " .. math.floor(stallTime) .. "s", Color3.fromRGB(150, 200, 255))
            task.wait(0.5)
        end
    end
end

task.spawn(start)
