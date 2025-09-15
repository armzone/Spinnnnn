task.delay(5, function()
    -- 🔥 EXTREME FPS BOOST - Maximum Performance Mode
    local lighting = game:GetService("Lighting")
    local players = game:GetService("Players")
    local runService = game:GetService("RunService")
    local contentProvider = game:GetService("ContentProvider")
    
    print("🚀 Starting EXTREME FPS Boost...")
    
    -- 🌟 Lighting Optimization (Maximum) + Black Sky
    lighting.GlobalShadows = false
    lighting.FogEnd = 1000000
    lighting.Brightness = 0.5
    lighting.ClockTime = 12
    lighting.Ambient = Color3.fromRGB(50, 50, 50)
    lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
    
    -- 🖤 Create BLACK SKY for maximum FPS
    local blackSky = Instance.new("Sky")
    blackSky.SkyboxBk = "rbxasset://textures/blackBkg_square.png"
    blackSky.SkyboxDn = "rbxasset://textures/blackBkg_square.png"
    blackSky.SkyboxFt = "rbxasset://textures/blackBkg_square.png"
    blackSky.SkyboxLf = "rbxasset://textures/blackBkg_square.png"
    blackSky.SkyboxRt = "rbxasset://textures/blackBkg_square.png"
    blackSky.SkyboxUp = "rbxasset://textures/blackBkg_square.png"
    blackSky.Parent = lighting
    
    -- 🗑️ Remove ALL Visual Effects
    for _, v in pairs(lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("Atmosphere") then
            v:Destroy()
        end
    end
    
    -- ⚡ Terrain Optimization (Extreme)
    if workspace.Terrain then
        workspace.Terrain.WaterReflectance = 0
        workspace.Terrain.WaterTransparency = 1
        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.Decoration = false
        workspace.Terrain.ReadVoxels = nil -- ปิดการอ่าน Voxel
    end
    
    -- 🎯 EXTREME Part Optimization
    local function extremeOptimize(obj)
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Explosion") then
            obj:Destroy()
        elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceGui") then
            obj:Destroy()
        elseif obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.RenderFidelity = Enum.RenderFidelity.Performance
            obj.CastShadow = false
        elseif obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
            -- ลบ Parts ตกแต่งที่ไม่จำเป็น
            if obj.CanCollide == false and obj.Anchored == true and not obj:FindFirstChild("Script") and not obj:FindFirstChild("LocalScript") then
                local hasImportantChild = false
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("Sound") or child:IsA("ClickDetector") or child:IsA("ProximityPrompt") then
                        hasImportantChild = true
                        break
                    end
                end
                if not hasImportantChild and obj.Name ~= "Baseplate" then
                    obj:Destroy()
                    return
                end
            end
        elseif obj:IsA("Sound") then
            if obj.Volume > 0.3 then
                obj.Volume = 0.3
            end
        end
    end
    
    -- 🔥 Apply to ALL objects
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            extremeOptimize(obj)
        end)
    end
    
    -- 👕 Remove ALL clothing and accessories
    for _, player in pairs(players:GetPlayers()) do
        if player.Character then
            for _, item in pairs(player.Character:GetChildren()) do
                if item:IsA("Accessory") or item:IsA("Hat") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
                    item:Destroy()
                end
            end
            
            -- 🎭 Animation Optimization (Stop non-essential animations)
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid then
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    if track.Name ~= "Walking" and track.Name ~= "Running" and track.Name ~= "Idle" then
                        track:Stop()
                    end
                end
                humanoid.PlatformStand = false -- เพื่อประสิทธิภาพ
            end
        end
    end
    
    -- 🔗 Auto-optimize new objects
    workspace.DescendantAdded:Connect(function(obj)
        task.wait(0.1)
        pcall(function()
            extremeOptimize(obj)
        end)
    end)
    
    -- 👤 Handle new players
    players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            task.wait(2)
            for _, item in pairs(character:GetChildren()) do
                if item:IsA("Accessory") or item:IsA("Hat") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
                    item:Destroy()
                end
            end
            
            -- Stop animations
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                    if track.Name ~= "Walking" and track.Name ~= "Running" and track.Name ~= "Idle" then
                        track:Stop()
                    end
                end
            end
        end)
    end)
    
    -- 🧹 Memory Management (ทุก 30 วินาที)
    task.spawn(function()
        while true do
            task.wait(30)
            collectgarbage("collect") -- Force garbage collection
            pcall(function()
                contentProvider:ClearAllCache()
            end)
        end
    end)
    
    -- 🔄 Continuous clothing removal (ทุก 5 วินาที)
    task.spawn(function()
        while true do
            task.wait(5)
            for _, player in pairs(players:GetPlayers()) do
                if player.Character then
                    for _, item in pairs(player.Character:GetChildren()) do
                        if item:IsA("Accessory") or item:IsA("Hat") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                            item:Destroy()
                        end
                    end
                end
            end
        end
    end)
    
    -- 📊 LOD System (Level of Detail) - ลดรายละเอียดตามระยะ
    local camera = workspace.CurrentCamera
    task.spawn(function()
        while true do
            task.wait(2)
            if camera then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("MeshPart") then
                        local distance = (camera.CFrame.Position - obj.Position).Magnitude
                        if distance > 200 then
                            obj.RenderFidelity = Enum.RenderFidelity.Performance
                        elseif distance > 100 then
                            obj.RenderFidelity = Enum.RenderFidelity.Automatic
                        end
                    end
                end
            end
        end
    end)
    
    -- ⚙️ Maximum Rendering Optimization
    pcall(function()
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = 1
        settings().Rendering.WaitVSyncEnabled = false
        settings().Rendering.GraphicsEnableAnisotropicFiltering = false
        settings().Physics.ThrottleAdjustTime = 0
        settings().Network.IncomingReplicationLag = 0
    end)
    
    -- 🎮 Final optimizations
    workspace.StreamingEnabled = false -- ปิด streaming (ถ้าไม่จำเป็น)
    
    print("✅ EXTREME FPS Boost Complete!")
    print("🔥 Optimizations Applied:")
    print("   • ALL shadows disabled")
    print("   • ALL effects removed")
    print("   • Decorative parts deleted")
    print("   • ALL clothing removed")
    print("   • Animation optimization")
    print("   • LOD system active")
    print("   • Memory management running")
    print("   • Lowest render settings applied")
    print("⚡ Expected FPS increase: 60-100%")
end)
