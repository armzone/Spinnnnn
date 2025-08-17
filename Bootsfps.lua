-- 🔥 Roblox Ultra Minimal FPS Script
-- 🎯 เป้าหมาย: กินทรัพยากรน้อยที่สุด + FPS คงที่
-- 🚫 ไม่มี UI, ไม่มีเอฟเฟกต์, ไม่มีอะไรที่ไม่จำเป็น

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ⚙️ ปิดทุกอย่างที่กินทรัพยากร
local function ultraMinimalSetup()
    -- 1. ตั้งค่าแสงต่ำสุด
    Lighting.Ambient = Color3.new(0, 0, 0)
    Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
    Lighting.Brightness = 0.1
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    Lighting.ClockTime = 12
    Lighting.FogEnd = 50
    Lighting.FogColor = Color3.new(0, 0, 0)
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    -- 2. ลบ Sky
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end

    -- 3. ปิด Post-Processing ทั้งหมด
    for _, effect in pairs(Lighting:GetDescendants()) do
        if effect:IsA("PostProcessingEffect") then
            effect.Enabled = false
        end
    end

    -- 4. ตั้งค่า Rendering ต่ำสุด
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        settings().Rendering.EnableFRM = false
        settings().Rendering.FrameRateManager = 0
        game:GetService("UserSettings").GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)

    -- 5. ตั้งค่า Streaming ให้โหลดน้อยที่สุด
    Workspace.StreamingEnabled = true
    Workspace.StreamingMinRadius = 32
    Workspace.StreamingTargetRadius = 40  -- โหลดแค่รอบตัว
    Workspace.StreamOutBehavior = Enum.StreamOutBehavior.LowMemory

    -- 6. ปรับ Terrain (ถ้ามี)
    local terrain = Workspace:FindFirstChild("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0.8
        pcall(function() terrain.Decoration = false end)
    end

    -- 7. ปิดทุก Particle, Trail, Beam, Fire, Smoke
    local function disableHeavyObjects(obj)
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or 
           obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") then
            obj.Enabled = false
        elseif obj:IsA("Decal") then
            obj.Transparency = 0.7  -- ลดความละเอียด
        elseif obj:IsA("BasePart") then
            obj.CastShadow = false
            obj.Reflectance = 0
            obj.Material = Enum.Material.SmoothPlastic
            if obj:IsA("MeshPart") then
                obj.RenderFidelity = Enum.RenderFidelity.Performance
                obj.CollisionFidelity = Enum.CollisionFidelity.Box
            end
        end
    end

    -- ปรับของที่มีอยู่
    for _, obj in pairs(Workspace:GetDescendants()) do
        disableHeavyObjects(obj)
    end

    -- ฟังของใหม่
    Workspace.DescendantAdded:Connect(function(obj)
        task.spawn(disableHeavyObjects, obj)
    end)

    -- 8. ปรับตัวละครผู้เล่นอื่น (ไม่ใช่ตัวเรา)
    Players.PlayerAdded:Connect(function(plr)
        if plr == player then return end
        plr.CharacterAdded:Connect(function(char)
            task.wait(0.2)
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.CastShadow = false
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    obj.Enabled = false
                end
            end
        end)
    end)

    -- ✅ จบการตั้งค่า — ไม่มี notification, ไม่มี print, ไม่มีอะไรเพิ่ม
end

-- 🚀 เริ่มทันทีเมื่อรัน
task.spawn(ultraMinimalSetup)
