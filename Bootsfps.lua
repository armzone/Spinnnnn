-- 🔥 Roblox Ultimate FPS Booster (High Performance Mode)
-- 🚀 รันแล้วได้ผลทันที — ไม่ต้องกด F9
-- 📌 เน้นลดโหลด GPU/CPU สูงสุด ด้วยการปิดเอฟเฟกต์ทั้งหมด

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

print("🚀 เริ่ม Ultimate FPS Booster...")

-- 🔅 1. ตั้งค่าแสงต่ำสุด + ท้องฟ้าสีดำ (ไม่มี skybox)
local function setupBlackEnvironment()
    -- ลบ Sky ทั้งหมด
    for _, child in pairs(Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end

    -- ตั้งแสงพื้นฐานต่ำสุด
    Lighting.Ambient = Color3.new(0, 0, 0)
    Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
    Lighting.Brightness = 0.1
    Lighting.GlobalShadows = false
    Lighting.ClockTime = 14
    Lighting.FogEnd = 80
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0

    -- ปิด Shadow ทั้งระบบ
    Lighting.ShadowSoftness = 0

    print("🌑 พื้นหลังและแสงถูกลดสุดแล้ว")
end

-- 🎞️ 2. ปิด Post-Processing Effects (กิน GPU มากที่สุด)
local function disablePostProcessing()
    for _, effect in pairs(Lighting:GetDescendants()) do
        if effect:IsA("PostProcessingEffect") then
            effect.Enabled = false
        end
    end

    -- ปิดเฉพาะตัวหนัก ๆ
    for _, effect in pairs(Lighting:GetDescendants()) do
        if effect:IsA("BloomEffect") then
            effect.Enabled = false
        elseif effect:IsA("BlurEffect") then
            effect.Enabled = false
        elseif effect:IsA("ColorCorrectionEffect") then
            effect.Enabled = false
        elseif effect:IsA("SunRaysEffect") then
            effect.Enabled = false
        elseif effect:IsA("DepthOfFieldEffect") then
            effect.Enabled = false
        end
    end

    print("🚫 ปิดเอฟเฟกต์ภาพทั้งหมดแล้ว (Bloom, Blur, Sun Rays ฯลฯ)")
end

-- ⚙️ 3. ตั้งค่า Rendering ระดับต่ำสุด
local function setLowGraphicsSettings()
    local success = pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        settings().Rendering.EnableFRM = false
        settings().Rendering.FrameRateManager = 0
        game:GetService("UserSettings").GameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)

    if success then
        print("📉 ตั้งค่ากราฟิกต่ำสุดสำเร็จ")
    else
        warn("⚠️ ไม่สามารถตั้งค่ากราฟิกได้ (อาจถูกจำกัดโดยเกม)")
    end
end

-- 🌍 4. ปรับแต่ง Terrain และ Streaming
local function optimizeWorld()
    local terrain = Workspace:FindFirstChild("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0.8
        pcall(function() terrain.Decoration = false end)
    end

    -- เปิด Streaming แต่ตั้งระยะต่ำ
    Workspace.StreamingEnabled = true
    Workspace.StreamingMinRadius = 32
    Workspace.StreamingTargetRadius = 20
    Workspace.StreamOutBehavior = Enum.StreamOutBehavior.LowMemory

    print("🌍 ปรับแต่งโลกและ streaming แล้ว")
end

-- 🧱 5. ปรับแต่งชิ้นส่วนทั้งหมดใน Workspace
local function optimizeParts()
    local function process(obj)
        if obj:IsA("BasePart") then
            obj.CastShadow = false
            obj.Reflectance = 0
            obj.Material = Enum.Material.SmoothPlastic -- ลดความซับซ้อนของวัสดุ

            if obj:IsA("MeshPart") then
                obj.RenderFidelity = Enum.RenderFidelity.Performance
                obj.CollisionFidelity = Enum.CollisionFidelity.Box
            end
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire") or obj:IsA("Smoke") then
            obj.Enabled = false
        elseif obj:IsA("Decal") then
            obj.Transparency = 0.5 -- หรือ obj:Destroy() ถ้าต้องการลบทิ้ง
        elseif obj:IsA("Beam") then
            obj.Enabled = false
        end
    end

    -- ปรับของที่มีอยู่แล้ว
    for _, obj in pairs(Workspace:GetDescendants()) do
        process(obj)
    end

    -- ฟังของใหม่
    Workspace.DescendantAdded:Connect(function(obj)
        task.spawn(process, obj)
    end)

    print("🔧 ปรับแต่งชิ้นส่วนทั้งหมดแล้ว")
end

-- 👥 6. ปรับแต่งตัวละครผู้เล่น (ไม่ใช่ตัวเรา)
local function optimizeOtherCharacters()
    Players.PlayerAdded:Connect(function(plr)
        if plr == player then return end
        plr.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.CastShadow = false
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    obj.Enabled = false
                end
            end
        end)
    end)

    -- ปรับผู้เล่นที่อยู่ก่อนหน้า
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            for _, obj in pairs(plr.Character:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.CastShadow = false
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    obj.Enabled = false
                end
            end
        end
    end

    print("👥 ปรับแต่งตัวละครผู้เล่นอื่นแล้ว")
end

-- 📊 7. เพิ่ม FPS Counter (ไม่บังตา)
local function createFPSCounter()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UltimateFPSCounter"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 100, 0, 30)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "FPS: --"
    label.TextColor3 = Color3.fromRGB(0, 255, 0)
    label.TextSize = 16
    label.Font = Enum.Font.Code
    label.Parent = frame

    local lastTime = tick()
    local frameCount = 0

    RunService.RenderStepped:Connect(function()
        frameCount += 1
        local currentTime = tick()
        if currentTime - lastTime >= 1 then
            local fps = math.floor(frameCount / (currentTime - lastTime))
            label.Text = "FPS: " .. fps
            label.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 0) or
                              fps >= 30 and Color3.fromRGB(255, 255, 0) or
                              Color3.fromRGB(255, 0, 0)
            frameCount = 0
            lastTime = currentTime
        end
    end)

    print("📊 สร้าง FPS Counter แล้ว")
end

-- 🚀 8. เริ่มทุกอย่างทันที
local function startOptimization()
    setupBlackEnvironment()
    disablePostProcessing()
    setLowGraphicsSettings()
    optimizeWorld()
    optimizeParts()
    optimizeOtherCharacters()
    createFPSCounter()

    print("✅ Ultimate FPS Booster ทำงานเสร็จสิ้น!")
    StarterGui:SetCore("SendNotification", {
        Title = "FPS Booster",
        Text = "ระบบเพิ่มประสิทธิภาพทำงานแล้ว! 🚀",
        Duration = 5,
        Icon = "rbxassetid://7733964719"
    })
end

-- ✅ เริ่มทันทีเมื่อรัน
task.spawn(startOptimization)
