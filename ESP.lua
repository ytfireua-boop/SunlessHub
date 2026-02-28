-- ESP Script with Rayfield Settings UI
-- Place as LocalScript in StarterPlayerScripts

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Configuration (driven by Rayfield UI)
local CONFIG = {
    Enabled = true,
    BoxEnabled = true,
    HealthBarEnabled = true,
    NamesEnabled = true,
    DistanceEnabled = true,
    BoxColor = Color3.fromRGB(255, 0, 0),
    NameColor = Color3.fromRGB(255, 255, 255),
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    HealthBarLowColor = Color3.fromRGB(255, 50, 50),
    MaxDistance = 1000,
    TextSize = 14,
    ScaleMultiplier = 400, -- Lower = smaller boxes
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ESP Storage
local espObjects = {}

local function getScreenPosition(worldPos)
    local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function createESP(player)
    local esp = {
        box         = Drawing.new("Square"),
        nameTag     = Drawing.new("Text"),
        distanceTag = Drawing.new("Text"),
        healthBarBG = Drawing.new("Square"),
        healthBar   = Drawing.new("Square"),
    }

    -- Box
    esp.box.Visible   = false
    esp.box.Color     = CONFIG.BoxColor
    esp.box.Thickness = 1.5
    esp.box.Filled    = false

    -- Name Tag
    esp.nameTag.Visible      = false
    esp.nameTag.Color        = CONFIG.NameColor
    esp.nameTag.Size         = CONFIG.TextSize
    esp.nameTag.Center       = true
    esp.nameTag.Outline      = true
    esp.nameTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.nameTag.Font         = Drawing.Fonts.UI

    -- Distance Tag
    esp.distanceTag.Visible      = false
    esp.distanceTag.Color        = Color3.fromRGB(200, 200, 200)
    esp.distanceTag.Size         = CONFIG.TextSize - 2
    esp.distanceTag.Center       = true
    esp.distanceTag.Outline      = true
    esp.distanceTag.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.distanceTag.Font         = Drawing.Fonts.UI

    -- Health Bar Background
    esp.healthBarBG.Visible   = false
    esp.healthBarBG.Color     = Color3.fromRGB(0, 0, 0)
    esp.healthBarBG.Filled    = true
    esp.healthBarBG.Thickness = 1

    -- Health Bar
    esp.healthBar.Visible   = false
    esp.healthBar.Color     = CONFIG.HealthBarColor
    esp.healthBar.Filled    = true
    esp.healthBar.Thickness = 1

    espObjects[player] = esp
end

local function removeESP(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            obj:Remove()
        end
        espObjects[player] = nil
    end
end

local function hideESP(esp)
    esp.box.Visible         = false
    esp.nameTag.Visible     = false
    esp.distanceTag.Visible = false
    esp.healthBarBG.Visible = false
    esp.healthBar.Visible   = false
end

local function updateESP()
    for player, esp in pairs(espObjects) do
        if not CONFIG.Enabled then
            hideESP(esp)
            continue
        end

        local visible = false

        if player ~= localPlayer and player.Character then
            local char      = player.Character
            local rootPart  = char:FindFirstChild("HumanoidRootPart")
            local humanoid  = char:FindFirstChildOfClass("Humanoid")
            local head      = char:FindFirstChild("Head")

            if rootPart and humanoid and humanoid.Health > 0 then
                local rootPos = rootPart.Position
                local distance = (camera.CFrame.Position - rootPos).Magnitude

                if distance <= CONFIG.MaxDistance then
                    local screenPos, onScreen, depth = getScreenPosition(rootPos)

                    if onScreen then
                        visible = true

                        local scaleFactor = math.clamp(1 / depth * CONFIG.ScaleMultiplier, 0.5, 5)
                        local boxWidth    = 50 * scaleFactor
                        local boxHeight   = 80 * scaleFactor
                        local boxX        = screenPos.X - boxWidth / 2
                        local boxY        = screenPos.Y - boxHeight / 2

                        -- Bounding Box
                        if CONFIG.BoxEnabled then
                            esp.box.Size     = Vector2.new(boxWidth, boxHeight)
                            esp.box.Position = Vector2.new(boxX, boxY)
                            esp.box.Color    = CONFIG.BoxColor
                            esp.box.Visible  = true
                        else
                            esp.box.Visible = false
                        end

                        -- Name Tag
                        if CONFIG.NamesEnabled then
                            esp.nameTag.Text     = player.DisplayName
                            esp.nameTag.Color    = CONFIG.NameColor
                            esp.nameTag.Position = Vector2.new(screenPos.X, boxY - 18)
                            esp.nameTag.Visible  = true
                        else
                            esp.nameTag.Visible = false
                        end

                        -- Distance Tag
                        if CONFIG.DistanceEnabled then
                            esp.distanceTag.Text     = string.format("[%.0f studs]", distance)
                            esp.distanceTag.Position = Vector2.new(screenPos.X, boxY + boxHeight + 2)
                            esp.distanceTag.Visible  = true
                        else
                            esp.distanceTag.Visible = false
                        end

                        -- Health Bar
                        if CONFIG.HealthBarEnabled then
                            local healthPct  = humanoid.Health / humanoid.MaxHealth
                            local barWidth   = 4
                            local barX       = boxX - barWidth - 2
                            local barHeight  = boxHeight

                            esp.healthBarBG.Size     = Vector2.new(barWidth, barHeight)
                            esp.healthBarBG.Position = Vector2.new(barX, boxY)
                            esp.healthBarBG.Visible  = true

                            local filledHeight   = barHeight * healthPct
                            esp.healthBar.Size     = Vector2.new(barWidth, filledHeight)
                            esp.healthBar.Position = Vector2.new(barX, boxY + (barHeight - filledHeight))
                            esp.healthBar.Color    = healthPct > 0.5 and CONFIG.HealthBarColor or CONFIG.HealthBarLowColor
                            esp.healthBar.Visible  = true
                        else
                            esp.healthBarBG.Visible = false
                            esp.healthBar.Visible   = false
                        end
                    end
                end
            end
        end

        if not visible then
            hideESP(esp)
        end
    end
end

-- Player hooks
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)
RunService.RenderStepped:Connect(updateESP)

-- =============================================
--              RAYFIELD UI
-- =============================================

local Window = Rayfield:CreateWindow({
    Name             = "ESP Hub",
    LoadingTitle     = "ESP Hub",
    LoadingSubtitle  = "by you",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "ESPHub",
        FileName   = "ESPConfig",
    },
    KeySystem = false,
})

local Tab = Window:CreateTab("ESP Settings", 4483362458)

-- Master Toggle
Tab:CreateToggle({
    Name          = "Enable ESP",
    CurrentValue  = CONFIG.Enabled,
    Flag          = "ESPEnabled",
    Callback      = function(val)
        CONFIG.Enabled = val
    end,
})

Tab:CreateSection("Visibility")

Tab:CreateToggle({
    Name          = "Bounding Boxes",
    CurrentValue  = CONFIG.BoxEnabled,
    Flag          = "BoxEnabled",
    Callback      = function(val)
        CONFIG.BoxEnabled = val
    end,
})

Tab:CreateToggle({
    Name          = "Health Bars",
    CurrentValue  = CONFIG.HealthBarEnabled,
    Flag          = "HealthBarEnabled",
    Callback      = function(val)
        CONFIG.HealthBarEnabled = val
    end,
})

Tab:CreateToggle({
    Name          = "Name Tags",
    CurrentValue  = CONFIG.NamesEnabled,
    Flag          = "NamesEnabled",
    Callback      = function(val)
        CONFIG.NamesEnabled = val
    end,
})

Tab:CreateToggle({
    Name          = "Distance Tags",
    CurrentValue  = CONFIG.DistanceEnabled,
    Flag          = "DistanceEnabled",
    Callback      = function(val)
        CONFIG.DistanceEnabled = val
    end,
})

Tab:CreateSection("Box Size")

Tab:CreateSlider({
    Name         = "Box Scale",
    Range        = {100, 800},
    Increment    = 10,
    Suffix       = "",
    CurrentValue = CONFIG.ScaleMultiplier,
    Flag         = "ScaleMultiplier",
    Callback     = function(val)
        CONFIG.ScaleMultiplier = val
    end,
})

Tab:CreateSection("Distance")

Tab:CreateSlider({
    Name         = "Max Distance (studs)",
    Range        = {50, 3000},
    Increment    = 50,
    Suffix       = " studs",
    CurrentValue = CONFIG.MaxDistance,
    Flag         = "MaxDistance",
    Callback     = function(val)
        CONFIG.MaxDistance = val
    end,
})

Tab:CreateSection("Colors")

Tab:CreateColorPicker({
    Name         = "Box Color",
    Color        = CONFIG.BoxColor,
    Flag         = "BoxColor",
    Callback     = function(val)
        CONFIG.BoxColor = val
    end,
})

Tab:CreateColorPicker({
    Name         = "Name Color",
    Color        = CONFIG.NameColor,
    Flag         = "NameColor",
    Callback     = function(val)
        CONFIG.NameColor = val
    end,
})

Tab:CreateColorPicker({
    Name         = "Health Bar Color",
    Color        = CONFIG.HealthBarColor,
    Flag         = "HealthBarColor",
    Callback     = function(val)
        CONFIG.HealthBarColor = val
    end,
})

Tab:CreateColorPicker({
    Name         = "Low Health Color",
    Color        = CONFIG.HealthBarLowColor,
    Flag         = "HealthBarLowColor",
    Callback     = function(val)
        CONFIG.HealthBarLowColor = val
    end,
})

Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title    = "ESP Loaded",
    Content  = "ESP is active. Use the menu to configure settings.",
    Duration = 5,
})
