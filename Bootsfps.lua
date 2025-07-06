-- 🚀 Roblox FPS Booster Script
-- 📌 ทำงานฝั่ง Local เท่านั้น
-- ✨ ปรับปรุงประสิทธิภาพและเพิ่ม FPS ในทุกแมพ

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MaterialService = game:GetService("MaterialService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- 🎮 การตั้งค่า (ปรับได้ตามต้องการ)
local Settings = {
    -- Graphics Settings
    RemoveShadows = true,
    RemoveBlur = true,
    RemoveColorCorrection = true,
    RemoveSunRays = true,
    RemoveParticles = true,
    RemovePostEffects = true,
    SimplifyMaterials = true,
    
    -- Performance Settings
    RenderDistance = 500,  -- ระยะการเรนเดอร์ (studs)
    RemoveDecals = true,
    RemoveTextures = true,  -- false = ยังเห็น texture แต่ลดคุณภาพ
    DisableGlobalShadows = true,
    SimplifyTerrain = true,
    
    -- Advanced Settings
    StreamingEnabled = true,
    ReduceParticleCount = true,
    OptimizeLighting = true,
    RemoveFog = true,
    DisableNeonGlow = true,  -- false = ยังเห็น neon แต่ลดเอฟเฟกต์
    
    -- Anti-Aliasing & Edge Settings
    DisableAntiAliasing = true,  -- ปิด Anti-aliasing
    SimplifyEdges = true,        -- ลดรอยหยักของขอบ
    FlatShading = true,          -- ใช้การ shading แบบ flat
    RemoveOutlines = true,       -- ลบเส้นขอบ
    
    -- UI Settings
    ShowFPSCounter = true,
    FPSCounterPosition = UDim2.new(0, 10, 0, 10)
}

print("🚀 FPS Booster Script เริ่มทำงาน...")

-- 📊 สร้าง FPS Counter
local screenGui, fpsLabel
if Settings.ShowFPSCounter then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FPSCounter"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
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
    
    fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, 0, 1, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    fpsLabel.TextScaled = true
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.Parent = frame
    
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    -- FPS Counter Logic
    local frameCount = 0
    local lastUpdate = tick()
    
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local currentTime = tick()
        
        if currentTime - lastUpdate >= 1 then
            local fps = frameCount / (currentTime - lastUpdate)
            fpsLabel.Text = string.format("FPS: %d", math.floor(fps))
            
            -- เปลี่ยนสีตาม FPS
            if fps >= 50 then
                fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)  -- เขียว
            elseif fps >= 30 then
                fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 0)  -- เหลือง
            else
                fpsLabel.TextColor3 = Color3.fromRGB(255, 0, 0)  -- แดง
            end
            
            frameCount = 0
            lastUpdate = currentTime
        end
    end)
end

-- 🎨 ฟังก์ชันหลักสำหรับ Optimize Graphics
local function OptimizeGraphics()
    -- 1. ปรับ Lighting
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
    
    -- 2. ลบ Post Processing Effects
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
    
    -- 3. ตั้งค่า Rendering
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        
        -- ปิด Anti-Aliasing
        if Settings.DisableAntiAliasing then
            settings().Rendering.EnableFRM = false
            settings().Rendering.FrameRateManager = 0
            game:GetService("UserSettings").GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end
    end)
    
    -- 4. Streaming Settings
    if Settings.StreamingEnabled then
        Workspace.StreamingEnabled = true
        Workspace.StreamingMinRadius = 64
        Workspace.StreamingTargetRadius = Settings.RenderDistance
        Workspace.StreamOutBehavior = Enum.StreamOutBehavior.LowMemory
    end
end

-- 🔧 ฟังก์ชันสำหรับ Optimize Parts และ Models
local function OptimizePart(part)
    if not part:IsA("BasePart") then return end
    
    -- ลด Material Quality
    if Settings.SimplifyMaterials then
        if part.Material == Enum.Material.Grass or 
           part.Material == Enum.Material.Slate or
           part.Material == Enum.Material.Concrete then
            part.Material = Enum.Material.SmoothPlastic
        end
    end
    
    -- ปิด Shadows
    if Settings.RemoveShadows then
        part.CastShadow = false
    end
    
    -- ลด Reflectance
    if part.Reflectance > 0 then
        part.Reflectance = 0
    end
    
    -- จัดการ Neon
    if Settings.DisableNeonGlow and part.Material == Enum.Material.Neon then
        part.Material = Enum.Material.SmoothPlastic
        -- เก็บสีไว้แต่ลด brightness
        local h, s, v = part.Color:ToHSV()
        part.Color = Color3.fromHSV(h, s, v * 0.8)
    end
    
    -- ลดรอยหยักและปรับ Edges
    if Settings.SimplifyEdges then
        -- ปิด Outlines
        if part:FindFirstChildOfClass("SelectionBox") or 
           part:FindFirstChildOfClass("Highlight") then
            for _, outline in pairs(part:GetChildren()) do
                if outline:IsA("SelectionBox") or outline:IsA("Highlight") then
                    outline:Destroy()
                end
            end
        end
        
        -- ลด Mesh Detail สำหรับ MeshParts
        if part:IsA("MeshPart") then
            part.RenderFidelity = Enum.RenderFidelity.Performance
            part.CollisionFidelity = Enum.CollisionFidelity.Box
        end
        
        -- ปรับ Surface Type เป็น Smooth
        if Settings.FlatShading then
            part.TopSurface = Enum.SurfaceType.Smooth
            part.BottomSurface = Enum.SurfaceType.Smooth
            part.LeftSurface = Enum.SurfaceType.Smooth
            part.RightSurface = Enum.SurfaceType.Smooth
            part.FrontSurface = Enum.SurfaceType.Smooth
            part.BackSurface = Enum.SurfaceType.Smooth
        end
    end
end

-- 🎨 ฟังก์ชันเพิ่มเติมสำหรับลดรอยหยัก
local function OptimizeEdgesAndAliasing()
    -- ปรับ Mesh Detail Level
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("MeshPart") then
            -- ใช้ LOD ต่ำสุด
            obj.RenderFidelity = Enum.RenderFidelity.Performance
            
            -- ใช้ Collision แบบ Box (เร็วที่สุด)
            obj.CollisionFidelity = Enum.CollisionFidelity.Box
        elseif obj:IsA("UnionOperation") then
            -- ปรับ Union operations
            obj.RenderFidelity = Enum.RenderFidelity.Performance
            obj.CollisionFidelity = Enum.CollisionFidelity.Box
        elseif obj:IsA("SpecialMesh") and Settings.SimplifyEdges then
            -- ลด Mesh Scale precision
            local scale = obj.Scale
            obj.Scale = Vector3.new(
                math.floor(scale.X * 10) / 10,
                math.floor(scale.Y * 10) / 10,
                math.floor(scale.Z * 10) / 10
            )
        end
    end
    
    -- ลบ Selection Boxes และ Highlights ทั้งหมด
    if Settings.RemoveOutlines then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("SelectionBox") or 
               obj:IsA("Highlight") or 
               obj:IsA("SurfaceSelection") or
               obj:IsA("SelectionSphere") then
                obj:Destroy()
            end
        end
    end
end

-- 🗑️ ฟังก์ชันสำหรับลบ/ลด Effects
local function RemoveUnnecessaryEffects()
    local function processDescendant(obj)
        -- ลบ Particles
        if Settings.RemoveParticles and obj:IsA("ParticleEmitter") then
            if Settings.ReduceParticleCount then
                obj.Rate = obj.Rate * 0.1  -- ลดจำนวนแค่ 10%
                obj.Lifetime = NumberRange.new(0.1, 0.5)
            else
                obj.Enabled = false
            end
        end
        
        -- ลบ Decals
        if Settings.RemoveDecals and obj:IsA("Decal") then
            obj.Transparency = 1
        end
        
        -- ลด Texture Quality
        if Settings.RemoveTextures and obj:IsA("Texture") then
            obj.StudsPerTileU = 10
            obj.StudsPerTileV = 10
        end
        
        -- ลบ Smoke/Fire
        if obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        end
        
        -- Optimize BaseParts
        if obj:IsA("BasePart") then
            OptimizePart(obj)
        end
        
        -- ลบ Beams และ Trails
        if obj:IsA("Beam") or obj:IsA("Trail") then
            obj.Enabled = false
        end
    end
    
    -- Process Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        processDescendant(obj)
    end
    
    -- Listen for new objects
    Workspace.DescendantAdded:Connect(function(obj)
        task.wait()
        processDescendant(obj)
    end)
end

-- 🏞️ Optimize Terrain
local function OptimizeTerrain()
    if not Settings.SimplifyTerrain then return end
    
    local terrain = Workspace.Terrain
    terrain.WaterWaveSize = 0
    terrain.WaterWaveSpeed = 0
    terrain.WaterReflectance = 0
    terrain.WaterTransparency = 0.5
    
    -- ลด Decoration
    pcall(function()
        terrain.Decoration = false
    end)
end

-- 🎭 Character Optimization
local function OptimizeCharacter(char)
    if not char then return end
    
    task.wait(0.1)
    
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CastShadow = false
            
            -- ลด Material quality สำหรับ accessories
            if obj.Parent:IsA("Accessory") and Settings.SimplifyMaterials then
                obj.Material = Enum.Material.SmoothPlastic
            end
        elseif obj:IsA("Decal") and obj.Name == "face" then
            -- เก็บหน้าไว้
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
            obj.Enabled = false
        end
    end
end

-- 🔄 Auto-optimize new players
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        if plr ~= player then  -- ไม่ optimize ตัวเอง
            task.wait(1)
            OptimizeCharacter(char)
        end
    end)
end)

-- 🚀 เริ่มการ Optimization
local function StartOptimization()
    print("⚙️ กำลังปรับแต่งการตั้งค่า Graphics...")
    OptimizeGraphics()
    
    print("🗑️ กำลังลบ Effects ที่ไม่จำเป็น...")
    RemoveUnnecessaryEffects()
    
    print("🏞️ กำลังปรับแต่ง Terrain...")
    OptimizeTerrain()
    
    print("🎨 กำลังลดรอยหยักและ Anti-aliasing...")
    OptimizeEdgesAndAliasing()
    
    print("👥 กำลังปรับแต่ง Characters...")
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character and plr ~= player then
            OptimizeCharacter(plr.Character)
        end
    end
    
    print("✅ การปรับแต่งเสร็จสมบูรณ์!")
    
    -- แจ้งเตือนผู้เล่น
    game.StarterGui:SetCore("SendNotification", {
        Title = "FPS Booster",
        Text = "การปรับแต่งเสร็จสมบูรณ์! 🚀",
        Duration = 5,
        Icon = "rbxassetid://7733964719"
    })
end

-- 🎮 คำสั่งพิเศษ (กด F9 เพื่อ toggle)
local UserInputService = game:GetService("UserInputService")
local isOptimized = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F9 then
        isOptimized = not isOptimized
        
        if isOptimized then
            StartOptimization()
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "FPS Booster",
                Text = "โหลดเกมใหม่เพื่อคืนค่าการตั้งค่าเดิม",
                Duration = 5,
                Icon = "rbxassetid://7733964719"
            })
        end
    end
end)

-- 🏁 เริ่มต้นทันที
StartOptimization()

print("✨ FPS Booster พร้อมใช้งาน!")
print("📌 กด F9 เพื่อ toggle การ optimization")
