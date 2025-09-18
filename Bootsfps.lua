wait(30)
-- ⚡ Roblox Potato Mode VRAM Saver
-- 🥔 ตัดทุกอย่างที่ไม่จำเป็น เหลือแต่ UI + Black Screen Toggle + Mute Sounds

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

-- 🔻 ฟังก์ชัน Potato Saver
local function applySaver()
    -- Lighting ultra low
    Lighting.Brightness = 0
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    for _, c in pairs(Lighting:GetChildren()) do
        if c:IsA("Sky") then c:Destroy() end
    end
    for _, e in pairs(Lighting:GetDescendants()) do
        if e:IsA("PostProcessingEffect") then e.Enabled = false end
    end

    -- Streaming ultra low
    Workspace.StreamingEnabled = true
    Workspace.StreamingTargetRadius = 20
    Workspace.StreamOutBehavior = Enum.StreamOutBehavior.LowMemory

    -- Terrain remove detail
    local terrain = Workspace:FindFirstChild("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterReflectance = 0
        pcall(function() terrain.Decoration = false end)
    end

    -- ลบทุกอย่างยกเว้น UI
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
            v.Enabled = false
        elseif v:IsA("Decal") or v:IsA("Texture") then
            if not v:IsDescendantOf(Players.LocalPlayer.PlayerGui) then
                v:Destroy()
            end
        elseif v:IsA("MeshPart") or v:IsA("SpecialMesh") then
            v.MeshId = ""
            v.TextureID = ""
        elseif v:IsA("UnionOperation") then
            v.UsePartColor = true
        elseif v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
            v:Destroy()
        elseif v:IsA("Sound") and not v:IsDescendantOf(Players.LocalPlayer.PlayerGui) then
            v:Stop()
            v.Volume = 0
        end
    end
end

-- ✅ ปิดเสียงแบบ real-time
local function muteAllSounds(obj)
    if obj:IsA("Sound") and not obj:IsDescendantOf(Players.LocalPlayer.PlayerGui) then
        obj:Stop()
        obj.Volume = 0
    end
end
for _, s in pairs(Workspace:GetDescendants()) do muteAllSounds(s) end
Workspace.DescendantAdded:Connect(muteAllSounds)

-- 🔻 GUI หลัก
local saverGui = Instance.new("ScreenGui", CoreGui)
saverGui.Name = "SaverUI"
saverGui.IgnoreGuiInset = true
saverGui.ResetOnSpawn = false

-- Black Screen Frame
local blackFrame = Instance.new("Frame", saverGui)
blackFrame.Size = UDim2.new(1, 0, 1, 0)
blackFrame.Position = UDim2.new(0, 0, 0, 0)
blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
blackFrame.BorderSizePixel = 0

-- FPS/VRAM Label
local statusLabel = Instance.new("TextLabel", saverGui)
statusLabel.Size = UDim2.new(1, 0, 0, 50)
statusLabel.Position = UDim2.new(0, 0, 0.45, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(0, 1, 0)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.Text = "FPS: 0 | VRAM: 0 MB"

-- Toggle Button
local toggleButton = Instance.new("TextButton", saverGui)
toggleButton.Size = UDim2.new(0, 150, 0, 40)
toggleButton.Position = UDim2.new(0.5, -75, 0.8, 0)
toggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Text = "Black Screen: ON"

-- FPS & VRAM Counter
local frames, lastTime = 0, tick()
RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - lastTime >= 1 then
        local fps = frames
        frames = 0
        lastTime = now

        local vramMB = 0
        local memStats = Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.GraphicsTexture)
        if memStats then vramMB = math.floor(memStats) end

        statusLabel.Text = "FPS: " .. tostring(fps) .. " | VRAM: " .. tostring(vramMB) .. " MB"
    end
end)

-- Toggle Function
local blackEnabled = true
toggleButton.MouseButton1Click:Connect(function()
    blackEnabled = not blackEnabled
    blackFrame.Visible = blackEnabled
    toggleButton.Text = blackEnabled and "Black Screen: ON" or "Black Screen: OFF"
end)

-- ✅ Apply Saver ตอนแรก
applySaver()
blackFrame.Visible = true
print("✅ Potato Mode Loaded (UI Only + VRAM Saver Extreme)")
