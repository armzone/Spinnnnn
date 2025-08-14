-- 🔴 รวมโค้ด: Black Background + FPS Booster (รันแล้วทำงานทันที)
-- 📌 วางใน LocalScript (ฝั่ง Client)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MaterialService = game:GetService("MaterialService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- 🌑 ฟังก์ชันตั้งพื้นหลังเป็นดำแบบรวดเร็ว
local function quickBlackBackground()
    -- ลบ Sky เดิมทั้งหมด
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end

    -- ตั้งค่าแสงพื้นฐาน
    Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    Lighting.Brightness = 0.1
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000

    -- ถ้าต้องการใช้ texture ดำที่อัปโหลด ให้เปิดใช้ setBlackBackground() แทน
    print("🌑 พื้นหลังสีดำแบบง่ายถูกตั้งค่าแล้ว!")
end

-- 🌌 ฟังก์ชันใช้ texture ดำ (ถ้ามี ID)
local function setBlackBackgroundWithTexture()
    -- ลบ Sky เดิม
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end

    local sky = Instance.new("Sky")
    sky.Name = "BlackSky"

    -- 🔧 ใส่ ID texture ของคุณที่นี่
    local blackTextureId = "rbxassetid://120717192726049"  -- เปลี่ยน ID นี้ได้

    sky.SkyboxBk = blackTextureId
    sky.SkyboxDn = blackTextureId
    sky.SkyboxFt = blackTextureId
    sky.SkyboxLf = blackTextureId
    sky.SkyboxRt = blackTextureId
    sky.SkyboxUp = blackTextureId

    sky.Parent = Lighting

    Lighting.Ambient = Color3.fromRGB(5, 5, 5)
    Lighting.Brightness = 0.2
    Lighting.OutdoorAmbient = Color3.fromRGB(5, 5, 5)

    print("🌌 พื้นหลังสีดำด้วย texture ถูกตั้งค่าแล้ว!")
end

-- 🚀 การตั้งค่า FPS Booster
local Settings = {
    RemoveShadows = true,
    RemoveBlur = true,
    RemoveColorCorrection = true,
    RemoveSunRays = true,
    RemoveParticles = true,
    RemovePostEffects = true,
    SimplifyMaterials = true,
    RenderDistance = 50,
    RemoveDecals = true,
    RemoveTextures = true,
    DisableGlobalShadows = true,
    SimplifyTerrain = true,
    StreamingEnabled = true,
    ReduceParticleCount = true,
    OptimizeLighting = true,
    RemoveFog = true,
    DisableNeonGlow = true,
    DisableAntiAliasing = true,
    SimplifyEdges = true,
    FlatShading = true,
    RemoveOutlines = true,
    ShowFPSCounter = true,
    FPSCounterPosition = UDim2.new(0, 10, 0, 10)
}

-- 📊 สร้าง FPS Counter
if Settings.ShowFPSCounter then
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FPSCounter"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 120, 0, 40)
    frame.Position = Settings.FPSCounterPosition
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, 0, 1, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    fpsLabel.TextScaled = true
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.Parent = frame

    local frameCount = 0
    local lastUpdate = tick()

    RunService.RenderStepped:Connect(function()
        frameCount += 1
        local currentTime = tick()
        if currentTime - lastUpdate >= 1 then
            local fps = frameCount / (currentTime - lastUpdate)
            fpsLabel.Text = string.format("FPS: %d", math.floor(fps))
            fpsLabel.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 0) or
                                  fps >= 30 and Color3.fromRGB(255, 255, 0) or
                                  Color3.fromRGB(255, 0, 0)
            frameCount = 0
            lastUpdate = currentTime
        end
    end)
end

-- 🎨 ปรับแต่งกราฟิก
local function OptimizeGraphics()
    if Settings.OptimizeLighting then
        Lighting.GlobalShadows = not Settings.DisableGlobalShadows
        Lighting.FogEnd = Settings.RemoveFog and 100000 or Lighting.FogEnd
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GeographicLatitude = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        if Settings.RemoveShadows then
            Lighting.ShadowSoftness = 0
        end
    end

    if Settings.RemovePostEffects then
        for _, effect in pairs(Lighting:GetDescendants()) do
            if effect:IsA("BloomEffect") and Settings.RemoveBlur then
                effect.Enabled = false
            elseif effect:IsA("BlurEffect") and Settings.RemoveBlur then
                effect.Enabled = false
            elseif effect:IsA("ColorCorrectionEffect") and Settings.RemoveColorCorrection then
                effect.Enabled = false
            elseif effect:IsA("SunRaysEffect") and Settings.RemoveSunRays then
                effect.Enabled = false
            elseif effect:IsA("DepthOfFieldEffect") then
                effect.Enabled = false
            end
        end
    end

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        if Settings.DisableAntiAliasing then
            settings().Rendering.EnableFRM = false
            settings().Rendering.FrameRateManager = 0
            game:GetService("UserSettings").GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end
    end)

    if Settings.StreamingEnabled then
        Workspace.StreamingEnabled = true
        Workspace.StreamingMinRadius = 64
        Workspace.StreamingTargetRadius = Settings.RenderDistance
        Workspace.StreamOutBehavior = Enum.StreamOutBehavior.LowMemory
    end
end

-- 🔧 ปรับแต่งชิ้นส่วน
local function OptimizePart(part)
    if not part:IsA("BasePart") then return end

    if Settings.SimplifyMaterials then
        if table.find({Enum.Material.Grass, Enum.Material.Slate, Enum.Material.Concrete}, part.Material) then
            part.Material = Enum.Material.SmoothPlastic
        end
    end

    if Settings.RemoveShadows then
        part.CastShadow = false
    end

    part.Reflectance = 0

    if Settings.DisableNeonGlow and part.Material == Enum.Material.Neon then
        part.Material = Enum.Material.SmoothPlastic
        local h, s, v = part.Color:ToHSV()
        part.Color = Color3.fromHSV(h, s, v * 0.8)
    end

    if Settings.SimplifyEdges then
        if part:IsA("MeshPart") then
            part.RenderFidelity = Enum.RenderFidelity.Performance
            part.CollisionFidelity = Enum.CollisionFidelity.Box
        end
        if Settings.FlatShading then
            local smooth = Enum.SurfaceType.Smooth
            part.TopSurface = smooth
            part.BottomSurface = smooth
            part.LeftSurface = smooth
            part.RightSurface = smooth
            part.FrontSurface = smooth
            part.BackSurface = smooth
        end
    end
end

-- 🗑️ ลบ Effects ที่ไม่จำเป็น
local function RemoveUnnecessaryEffects()
    local function processDescendant(obj)
        if Settings.RemoveParticles and obj:IsA("ParticleEmitter") then
            if Settings.ReduceParticleCount then
                obj.Rate = obj.Rate * 0.1
                obj.Lifetime = NumberRange.new(0.1, 0.5)
            else
                obj.Enabled = false
            end
        end

        if Settings.RemoveDecals and obj:IsA("Decal") then
            obj.Transparency = 1
        end

        if Settings.RemoveTextures and obj:IsA("Texture") then
            obj.StudsPerTileU = 10
            obj.StudsPerTileV = 10
        end

        if obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        end

        if obj:IsA("Beam") or obj:IsA("Trail") then
            obj.Enabled = false
        end

        if obj:IsA("BasePart") then
            OptimizePart(obj)
        end
    end

    for _, obj in pairs(Workspace:GetDescendants()) do
        processDescendant(obj)
    end

    Workspace.DescendantAdded:Connect(function(obj)
        task.wait()
        processDescendant(obj)
    end)
end

-- 🏞️ ปรับแต่ง Terrain
local function OptimizeTerrain()
    if not Settings.SimplifyTerrain then return end
    local terrain = Workspace:FindFirstChild("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0.5
        pcall(function() terrain.Decoration = false end)
    end
end

-- 👥 ปรับแต่งตัวละครผู้เล่น
local function OptimizeCharacter(char)
    if not char then return end
    task.wait(0.1)
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CastShadow = false
            if obj.Parent:IsA("Accessory") and Settings.SimplifyMaterials then
                obj.Material = Enum.Material.SmoothPlastic
            end
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Enabled = false
        end
    end
end

-- 🔁 ฟังก์ชันเริ่มต้นทั้งหมด
local function StartOptimization()
    print("🚀 เริ่มการปรับแต่งระบบ...")

    -- เลือกใช้ quickBlackBackground หรือ setBlackBackgroundWithTexture
    quickBlackBackground()  -- ใช้แบบง่าย
    -- setBlackBackgroundWithTexture()  -- ถ้าต้องการใช้ texture จริง ให้เปิดบรรทัดนี้ แล้วปิดอันบน

    OptimizeGraphics()
    RemoveUnnecessaryEffects()
    OptimizeTerrain()

    -- ปรับแต่งตัวละครผู้เล่นทุกคน
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character and plr ~= player then
            OptimizeCharacter(plr.Character)
        end
    end

    -- ฟังก์ชันฟังผู้เล่นใหม่
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function(char)
            if plr ~= player then
                task.wait(1)
                OptimizeCharacter(char)
            end
        end)
    end)

    print("✅ การปรับแต่งทั้งหมดเสร็จสมบูรณ์!")
    StarterGui:SetCore("SendNotification", {
        Title = "FPS Booster",
        Text = "ระบบปรับแต่งทำงานแล้ว! 🚀",
        Duration = 5,
        Icon = "rbxassetid://7733964719"
    })
end

-- ✅ เริ่มทำงานทันทีเมื่อรันสคริปต์
task.spawn(StartOptimization)
