local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local ESPData = {}
local Connections = {}
local ESPEnabled = true

-- Destroy everything function
local function DestroyESP()
    for player, data in pairs(ESPData) do
        if data.NameTag then data.NameTag:Destroy() end
        if data.Outline then data.Outline:Destroy() end
    end
    ESPData = {}
    -- Disconnect all connections
    for _, conn in pairs(Connections) do
        conn:Disconnect()
    end
    Connections = {}
end

-- Toggle function
local function ToggleESP()
    ESPEnabled = not ESPEnabled
    if not ESPEnabled then
        DestroyESP()
    else
        for _, player in ipairs(Players:GetPlayers()) do
            createSmoothESP(player)
        end
    end
end

local function isEnemy(player)
    return LocalPlayer.Team ~= player.Team and player.Team ~= nil
end

local function createSmoothESP(player)
    if player == LocalPlayer or ESPData[player] or not isEnemy(player) then return end
    if not player.Character then return end

    ESPData[player] = {}

    -- NameTag
    local head = player.Character:FindFirstChild("Head")
    if head then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NameTag"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0,130,0,25)
        billboard.StudsOffset = Vector3.new(0,2,0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1,0,1,0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1,1,1)
        textLabel.Font = Enum.Font.Cartoon
        textLabel.TextScaled = true
        textLabel.TextStrokeTransparency = 0.6
        textLabel.Parent = billboard

        ESPData[player].NameTag = textLabel
    end

    -- Outline
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local boxGui = Instance.new("BillboardGui")
        boxGui.Name = "SmoothESP"
        boxGui.AlwaysOnTop = true
        boxGui.Size = UDim2.new(0,60,0,150)
        boxGui.Parent = root

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1,0,1,0)
        frame.BackgroundTransparency = 1
        frame.Position = UDim2.new(0,0,0,0)
        frame.Parent = boxGui

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = Color3.fromRGB(255,0,0)
        stroke.Parent = frame

        ESPData[player].Outline = boxGui
    end
end

local function updateESP(player)
    if not ESPEnabled or not player.Character or not ESPData[player] then return end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if isEnemy(player) and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local minX, maxX, minY, maxY
        local parts = {}
        for _, part in ipairs(player.Character:GetChildren()) do
            if part:IsA("BasePart") then
                table.insert(parts, part)
            end
        end

        for _, part in ipairs(parts) do
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                if not minX or screenPos.X < minX then minX = screenPos.X end
                if not maxX or screenPos.X > maxX then maxX = screenPos.X end
                if not minY or screenPos.Y < minY then minY = screenPos.Y end
                if not maxY or screenPos.Y > maxY then maxY = screenPos.Y end
            end
        end

        if minX and maxX and minY and maxY and ESPData[player].Outline then
            ESPData[player].Outline.Size = UDim2.new(0, maxX-minX, 0, maxY-minY)
        end

        if ESPData[player].NameTag then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
            ESPData[player].NameTag.Text = player.Name.." | "..string.format("%.0f",distance).."m | ❤️"..math.floor(humanoid.Health)
        end
    else
        if ESPData[player].NameTag then ESPData[player].NameTag.Text = "" end
        if ESPData[player].Outline then ESPData[player].Outline.Size = UDim2.new(0,0,0,0) end
    end
end

local function setupPlayer(player)
    local conn1 = player.CharacterAdded:Connect(function()
        wait(0.1)
        createSmoothESP(player)
    end)
    table.insert(Connections, conn1)
    if player.Character then createSmoothESP(player) end
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end
table.insert(Connections, Players.PlayerAdded:Connect(setupPlayer))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then updateESP(player) end
    end
end))

return {
    Toggle = ToggleESP,
    Destroy = DestroyESP
}
