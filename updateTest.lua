local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")

if CoreGui:FindFirstChild("MM2_Premium_Menu") then CoreGui:FindFirstChild("MM2_Premium_Menu"):Destroy() end

local lp = Players.LocalPlayer
local collecting, killing, espM, espS, espI, wsEnabled, jpEnabled = false, false, false, false, false, false, false
local showNames, noclip, grabGun = false, false, false
local customWS, customJP = 16, 50
local autoTPTarget = nil
local targets = {"SkiVillage_RegularMode", "Office3", "ChristmasItaly", "LogCabin", "Mansion2", "Workplace", "House2", "SkiLodge", "Station", "IceCastle", "PoliceStation", "BioLab", "Hotel", "Workshop", "Factory", "Bank2", "MilBase", "Hospital3", "ResearchFacility"}

local sg = Instance.new("ScreenGui", CoreGui)
sg.Name = "MM2_Premium_Menu"
sg.ResetOnSpawn = false

local main = Instance.new("Frame", sg)
main.Size = UDim2.new(0, 480, 0, 350)
main.Position = UDim2.new(0.5, -240, 0.5, -175)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
main.BorderSizePixel = 0
main.Visible = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local sidebar = Instance.new("Frame", main)
sidebar.Size = UDim2.new(0, 130, 1, -20)
sidebar.Position = UDim2.new(0, 10, 0, 10)
sidebar.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

local sideLayout = Instance.new("UIListLayout", sidebar)
sideLayout.Padding = UDim.new(0, 5)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", sidebar).PaddingTop = UDim.new(0, 10)

local container = Instance.new("Frame", main)
container.Size = UDim2.new(1, -160, 1, -20)
container.Position = UDim2.new(0, 150, 0, 10)
container.BackgroundTransparency = 1

local pages = { 
    Farming = Instance.new("Frame", container), 
    Teleport = Instance.new("Frame", container), 
    ESP = Instance.new("Frame", container), 
    Walk = Instance.new("Frame", container),
    Players = Instance.new("ScrollingFrame", container),
    Chat = Instance.new("Frame", container)
}

for name, p in pairs(pages) do 
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    if p:IsA("ScrollingFrame") then
        p.ScrollBarThickness = 0
        p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end
    Instance.new("UIListLayout", p).Padding = UDim.new(0, 8)
end
pages.Farming.Visible = true

local function makeTabBtn(name, page)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(0, 110, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.BuilderSansExtraBold
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(function() 
        for _, v in pairs(pages) do v.Visible = false end 
        page.Visible = true 
    end)
end

local function makeBtn(name, parent, callback)
    local bg = Instance.new("Frame", parent)
    bg.Size = UDim2.new(0.98, 0, 0, 40)
    bg.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", bg)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Font = Enum.Font.BuilderSansExtraBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local switchBg = Instance.new("Frame", bg)
    switchBg.Size = UDim2.new(0, 45, 0, 22)
    switchBg.Position = UDim2.new(1, -55, 0.5, -11)
    switchBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", switchBg)
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(50, 50, 55)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = active and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
        if callback then callback(active) end
    end)
    return function() return active end
end

local function bypassName(name)
    local newName = ""
    for i = 1, #name do
        newName = newName .. name:sub(i,i) .. "."
    end
    return newName:sub(1, -2)
end

local function sayInChat(msg)
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = TextChatService.TextChannels.RBXGeneral
        if channel then channel:SendAsync(msg) end
    else
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
    end
end

makeTabBtn("FARMING", pages.Farming)
makeTabBtn("TELEPORT", pages.Teleport)
makeTabBtn("ESP", pages.ESP)
makeTabBtn("WALK", pages.Walk)
makeTabBtn("PLAYERS", pages.Players)
makeTabBtn("CHAT", pages.Chat)

local isFarm = makeBtn("COIN FARM", pages.Farming, function(v) collecting = v end)
local isKill = makeBtn("KILL ALL", pages.Farming, function(v) killing = v end)
local isAfk = makeBtn("ANTI-AFK", pages.Farming)
local isName = makeBtn("SHOW NAMES", pages.Farming, function(v) showNames = v end)
local isNoclip = makeBtn("NOCLIP", pages.Farming, function(v) noclip = v end)
local isGrab = makeBtn("GUN GRABBER", pages.Farming, function(v) grabGun = v end)

local isEspS = makeBtn("ESP: SHERIFF", pages.ESP, function(v) espS = v end)
local isEspM = makeBtn("ESP: MURDERER", pages.ESP, function(v) espM = v end)
local isEspI = makeBtn("ESP: INNOCENT", pages.ESP, function(v) espI = v end)

local function makeActionBtn(name, parent, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.98, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btn.Text = name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.BuilderSansExtraBold
    btn.TextSize = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
end

makeActionBtn("Chat: Sheriff", pages.Chat, function()
    local f = false
    for _, v in pairs(Players:GetPlayers()) do
        if v.Character and (v.Backpack:FindFirstChild("Gun") or v.Character:FindFirstChild("Gun")) then
            sayInChat("Sheriff = " .. bypassName(v.Name))
            f = true break
        end
    end
    if not f then sayInChat("Sheriff not found") end
end)

makeActionBtn("Chat: Murderer", pages.Chat, function()
    local f = false
    for _, v in pairs(Players:GetPlayers()) do
        if v.Character and (v.Backpack:FindFirstChild("Knife") or v.Character:FindFirstChild("Knife")) then
            sayInChat("Murderer = " .. bypassName(v.Name))
            f = true break
        end
    end
    if not f then sayInChat("Murderer not found") end
end)

makeActionBtn("TP: MAP", pages.Teleport, function()
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, name in pairs(targets) do
            local map = Workspace:FindFirstChild(name)
            if map then 
                hrp.CFrame = map:GetPivot() * CFrame.new(0, 6, 0)
                hrp.Anchored = true
                task.wait(0.5)
                hrp.Anchored = false
                break 
            end
        end
    end
end)

makeActionBtn("TP: SHERIFF", pages.Teleport, function() for _, v in pairs(Players:GetPlayers()) do if v ~= lp and v.Character and (v.Backpack:FindFirstChild("Gun") or v.Character:FindFirstChild("Gun")) then lp.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame break end end end)
makeActionBtn("TP: MURDERER", pages.Teleport, function() for _, v in pairs(Players:GetPlayers()) do if v ~= lp and v.Character and (v.Backpack:FindFirstChild("Knife") or v.Character:FindFirstChild("Knife")) then lp.Character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame break end end end)
makeActionBtn("TP: LOBBY", pages.Teleport, function() local l = Workspace:FindFirstChild("Lobby") if l and l:FindFirstChild("Spawns") and lp.Character then lp.Character.HumanoidRootPart.CFrame = l.Spawns:GetModelCFrame() end end)

local function makeWalkRow(title, placeholder, parent, toggleCallback, valueCallback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0.98, 0, 0, 50)
    f.BackgroundTransparency = 1
    local box = Instance.new("TextBox", f)
    box.Size = UDim2.new(0.6, -5, 1, 0)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    box.PlaceholderText = placeholder
    box.Text = ""
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Font = Enum.Font.BuilderSansExtraBold
    box.TextSize = 14
    Instance.new("UICorner", box)
    local switchBg = Instance.new("Frame", f)
    switchBg.Size = UDim2.new(0, 45, 0, 22)
    switchBg.Position = UDim2.new(1, -55, 0.5, -11)
    switchBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    local circle = Instance.new("Frame", switchBg)
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton", switchBg)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = active and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(50, 50, 55)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = active and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
        toggleCallback(active)
    end)
    box.FocusLost:Connect(function() local val = tonumber(box.Text) if val then box.Text = title .. " = " .. tostring(val) valueCallback(val) else box.Text = "" end end)
end

makeWalkRow("Speed", "Enter Speed", pages.Walk, function(v) wsEnabled = v end, function(v) customWS = v or 16 end)
makeWalkRow("Jump", "Enter Jump", pages.Walk, function(v) jpEnabled = v end, function(v) customJP = v or 50 end)

local function getCoin()
    local res = {}
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _, m in pairs(Workspace:GetChildren()) do
        local ok = false
        for _, n in pairs(targets) do if m.Name == n then ok = true break end end
        if ok and m:FindFirstChild("CoinContainer") then
            for _, c in pairs(m.CoinContainer:GetChildren()) do
                if c.Name == "Coin_Server" and c:FindFirstChild("TouchInterest") then
                    table.insert(res, {obj = c, dist = (hrp.Position - c.Position).Magnitude})
                end
            end
        end
    end
    table.sort(res, function(a, b) return a.dist < b.dist end)
    return res[1] and res[1].obj or nil
end

task.spawn(function()
    while task.wait() do
        if collecting and isFarm() then
            local char, target = lp.Character, getCoin()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if hrp and hum and target then
                hum.PlatformStand = true
                local targetPos = target.Position - Vector3.new(0, 1.5, 0)
                local tween = TweenService:Create(hrp, TweenInfo.new((hrp.Position - targetPos).Magnitude / 25, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos) * CFrame.Angles(math.rad(90), 0, 0)})
                tween:Play()
                repeat RunService.Heartbeat:Wait() if hrp then hrp.Velocity = Vector3.new(0,0,0) end until not isFarm() or not target or not target.Parent or not target:FindFirstChild("TouchInterest")
                tween:Cancel()
            else task.wait(0.1) end
        elseif lp.Character and lp.Character:FindFirstChild("Humanoid") then lp.Character.Humanoid.PlatformStand = false end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if grabGun then
            for _, m in pairs(Workspace:GetChildren()) do
                local ok = false
                for _, n in pairs(targets) do if m.Name == n then ok = true break end end
                if ok then
                    local gd = m:FindFirstChild("GunDrop")
                    if gd and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = lp.Character.HumanoidRootPart
                        local old = hrp.CFrame
                        hrp.CFrame = gd.CFrame
                        task.wait(0.2)
                        hrp.CFrame = old
                    end
                end
            end
        end
    end
end)

local toggleBtn = Instance.new("TextButton", sg)
toggleBtn.Size = UDim2.new(0, 80, 0, 30)
toggleBtn.Position = UDim2.new(0, 5, 0, 5)
toggleBtn.Text = "MM2"
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.BuilderSansExtraBold
toggleBtn.TextSize = 15
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
toggleBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

RunService.Heartbeat:Connect(function()
    local char = lp.Character
    if not char then return end
    local hum, hrp = char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart")
    if hum then hum.WalkSpeed = wsEnabled and customWS or 16 hum.JumpPower = jpEnabled and customJP or 50 end
    if autoTPTarget and autoTPTarget.Character and autoTPTarget.Character:FindFirstChild("HumanoidRootPart") and hrp then hrp.CFrame = autoTPTarget.Character.HumanoidRootPart.CFrame end
    if noclip or collecting then for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end end
    if hrp and killing then
        local k = char:FindFirstChild("Knife") or lp.Backpack:FindFirstChild("Knife")
        if k then k.Parent = char for _, v in pairs(Players:GetPlayers()) do if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then k:Activate() if firetouchinterest and k:FindFirstChild("Handle") then firetouchinterest(v.Character.HumanoidRootPart, k.Handle, 0) firetouchinterest(v.Character.HumanoidRootPart, k.Handle, 1) end end end end
    end
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local p_hrp = v.Character.HumanoidRootPart
            local isM, isS = v.Backpack:FindFirstChild("Knife") or v.Character:FindFirstChild("Knife"), v.Backpack:FindFirstChild("Gun") or v.Character:FindFirstChild("Gun")
            local oldBox = p_hrp:FindFirstChild("ESP_BOX")
            if (espM and isM) or (espS and isS) or (espI and not isM and not isS) then
                if not oldBox then
                    local b = Instance.new("BoxHandleAdornment", p_hrp)
                    b.Name, b.Adornee, b.AlwaysOnTop, b.Size, b.Transparency, b.ZIndex = "ESP_BOX", p_hrp, true, p_hrp.Size + Vector3.new(0.5,0.5,0.5), 0.5, 10
                    b.Color3 = isM and Color3.new(1,0,0) or (isS and Color3.new(0,0,1) or Color3.new(0,1,0))
                else oldBox.Color3 = isM and Color3.new(1,0,0) or (isS and Color3.new(0,0,1) or Color3.new(0,1,0)) end
            elseif oldBox then oldBox:Destroy() end
            local oldTag = p_hrp:FindFirstChild("NameTag")
            if showNames then
                if not oldTag then
                    local bg = Instance.new("BillboardGui", p_hrp)
                    bg.Name, bg.Size, bg.AlwaysOnTop, bg.ExtentsOffset = "NameTag", UDim2.new(0, 150, 0, 50), true, Vector3.new(0, 3.5, 0)
                    local tl = Instance.new("TextLabel", bg)
                    tl.Size, tl.BackgroundTransparency, tl.Text = UDim2.new(1, 0, 1, 0), 1, v.Name
                    tl.TextColor3, tl.Font, tl.TextSize, tl.TextStrokeTransparency = Color3.new(1, 1, 1), Enum.Font.BuilderSansExtraBold, 14, 0
                end
            elseif oldTag then oldTag:Destroy() end
        end
    end
end)

local function updatePlayerList()
    for _, v in pairs(pages.Players:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then
            local pf = Instance.new("Frame", pages.Players)
            pf.Size = UDim2.new(0.98, 0, 0, 45)
            pf.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            Instance.new("UICorner", pf)
            local plbl = Instance.new("TextLabel", pf)
            plbl.Size = UDim2.new(0.5, 0, 1, 0)
            plbl.Position = UDim2.new(0, 10, 0, 0)
            plbl.BackgroundTransparency = 1
            plbl.Text = p.Name
            plbl.TextColor3 = Color3.new(1, 1, 1)
            plbl.Font = Enum.Font.BuilderSansExtraBold
            plbl.TextSize = 13
            plbl.TextXAlignment = Enum.TextXAlignment.Left
            local switchBg = Instance.new("Frame", pf)
            switchBg.Size = UDim2.new(0, 40, 0, 20)
            switchBg.Position = UDim2.new(1, -50, 0.5, -10)
            switchBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
            local circle = Instance.new("Frame", switchBg)
            circle.Size = UDim2.new(0, 14, 0, 14)
            circle.Position = UDim2.new(0, 3, 0.5, -7)
            circle.BackgroundColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
            local btn = Instance.new("TextButton", pf)
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.MouseButton1Click:Connect(function()
                if autoTPTarget == p then autoTPTarget = nil
                    TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play()
                    TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -7)}):Play()
                else autoTPTarget = p
                    TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 180, 80)}):Play()
                    TweenService:Create(circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -17, 0.5, -7)}):Play()
                end
            end)
        end
    end
end
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()
lp.Idled:Connect(function() VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) task.wait(1) VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame) end)
