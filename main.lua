local Octree = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sleitnick/rbxts-octo-tree/main/src/init.lua", true))()
local rt = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    VirtualUser = game:GetService("VirtualUser"),
    octree = Octree.new(),
    touchedCoins = {},
    TargetNames = {Coin_Server = true, SnowToken = true, Coin = true},
    walkspeed = 22,
    radius = 300,
    depth = 3
}
rt.player = rt.Players.LocalPlayer
local lastContainer = nil 

local screenGui = rt.player.PlayerGui:FindFirstChild("ClassicFarmUI")
if screenGui then screenGui:Destroy() end
screenGui = Instance.new("ScreenGui", rt.player.PlayerGui)
screenGui.Name = "ClassicFarmUI"
screenGui.ResetOnSpawn = false 

local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 400, 0, 60)
label.Position = UDim2.new(0.5, -200, 0.5, -30) 
label.BackgroundTransparency = 1 
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextStrokeTransparency = 0 
label.Font = Enum.Font.GothamBold
label.TextSize = 24
label.Text = "Clankerfarm Test"

local function updateStatus(text, color)
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
end

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
    
    local fixedRotation = CFrame.Angles(math.rad(90), 0, 0)

    local alpha = 0
    while alpha < 0.99 do
        if not targetCoin or not targetCoin.Parent then
            return "CANCELLED" 
        end
        
        alpha = (tick() - startTick) / duration
        local lerpPos = startPos:Lerp(ghostTarget, alpha)
        
        char:PivotTo(CFrame.new(lerpPos) * fixedRotation)
        rt.RunService.Heartbeat:Wait()
    end
    
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
        task.wait(0.05) 
        local char = rt.player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        if not root or not hum then continue end

        if isBagFull() then [cite: 9]
            updateStatus("BAG FULL! RESETTING...", Color3.fromRGB(255, 50, 50))
            hum.Health = 0
            rt.player.CharacterRemoving:Wait()
            rt.player.CharacterAdded:Wait()
            task.wait(4)
            continue
        end

        local container = nil
        for _, v in ipairs(workspace:GetChildren()) do [cite: 10]
            if v.Name == "CoinContainer" or v:FindFirstChild("CoinContainer") then 
                container = v.Name == "CoinContainer" and v or v.CoinContainer
                break 
            end
        end

        if container ~= lastContainer then [cite: 11]
            lastContainer = container
            rt.touchedCoins = {}
            if container ~= nil then
                for i = 3, 1, -1 do -- Shortened wait for speed
                    updateStatus("NEW MAP: Waiting " .. i .. "s...", Color3.fromRGB(255, 165, 0))
                    task.wait(1)
                end
            end
        end

        if container then [cite: 12]
            rt.octree:ClearAllNodes()
            for _, v in ipairs(container:GetDescendants()) do [cite: 13]
                if rt.TargetNames[v.Name] and v:IsA("BasePart") and v.Parent ~= nil and not rt.touchedCoins[v] then
                    rt.octree:CreateNode(v.Position, v)
                end
            end
        end

        local nearest = rt.octree:GetNearest(root.Position, rt.radius, 1)[1]
        if nearest then
            local coin = nearest.Object
            updateStatus("Snatching: " .. sessionCoins, Color3.fromRGB(100, 255, 200))
            
            local result = moveAndValidate(coin) [cite: 14]
            
            if result == "SUCCESS" then
                rt.touchedCoins[coin] = true
                sessionCoins = sessionCoins + 1
            elseif result == "CANCELLED" then [cite: 15]
                updateStatus("Re-routing...", Color3.fromRGB(255, 100, 100)) [cite: 16]
            end
        else
            updateStatus("Scanning...", Color3.fromRGB(150, 200, 255))
            task.wait(0.2)
        end
    end
end

task.spawn(start)
