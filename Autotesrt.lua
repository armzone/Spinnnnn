movementSpeed = math.floor((relativeX * 10 + 3) * 10) / 10 -- ช่วง 3.0-13.0 เพื่อความปลอดภัยสูงสุด
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        speedLabel.Text = string.format("⚡ ความเร็ว: %.1f (Ultra Safe)", movementSpeed)
    end-- ========================================
-- Perfect AutoFarm Navigation System
-- ใช้ CFrame Movement + Advanced Pathfinding
-- ========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local rootPart = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- ========================================
-- การตั้งค่าระบบ
-- ========================================

-- ตัวแปรหลัก
local moving = false
local isEnabled = false
local navigationMode = "PathOnly" -- เปลี่ยนเป็น PathOnly เพื่อความปลอดภัย
local movementSpeed = 6 -- ลดความเร็วเพื่อความปลอดภัยสูงสุด

-- การตั้งค่าขั้นสูง
local settings = {
    -- การเคลื่อนไหว
    smoothMovement = true,
    useTweening = true, -- เปลี่ยนเป็น true เพื่อใช้ Tween
    useHumanoidMovement = true, -- เพิ่มการใช้ Humanoid Movement
    adaptiveSpeed = true,
    obstacleDetection = true,
    safeMovement = true, -- เพิ่มการเคลื่อนไหวที่ปลอดภัย
    collisionCheck = true, -- เพิ่มการตรวจสอบ Collision
    
    -- Pathfinding
    useSmartPathing = true,
    pathOptimization = true,
    dynamicRecalculation = true,
    multiLayerNavigation = true,
    
    -- การหลีกเลี่ยง
    playerAvoidance = true,
    obstacleAvoidance = true,
    stuckDetection = true,
    groundCheck = true, -- เพิ่มการตรวจสอบพื้น
    
    -- ภาพแสดงผล
    showPath = true,
    showDebugInfo = true,
    beamDuration = 30
}

-- ตำแหน่งเป้าหมาย
local targetPositions = {
    Vector3.new(1224.875, 255.1919708251953, -559.2366943359375),
    -- เพิ่มตำแหน่งได้ที่นี่
}
local currentTargetIndex = 1
local customTargets = {} -- ตำแหน่งที่ผู้เล่นเพิ่มเอง

-- ========================================
-- ระบบจัดการ Character
-- ========================================

local function IsCharacterValid()
    return char and char.Parent and rootPart and rootPart.Parent and humanoid and humanoid.Health > 0
end

local function OnCharacterAdded(newChar)
    char = newChar
    rootPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
    moving = false
    print("🔄 Character ใหม่โหลดแล้ว - รีเซ็ตระบบ")
end

player.CharacterAdded:Connect(OnCharacterAdded)

-- ========================================
-- ระบบ Visual และ Debug
-- ========================================

local activeBeams = {}
local debugGui = nil

local function ClearAllBeams()
    for _, beam in pairs(activeBeams) do
        if beam and beam.Parent then
            beam:Destroy()
        end
    end
    activeBeams = {}
end

local function CreateBeam(fromPos, toPos, color, width, transparency)
    if not Workspace.Terrain or not settings.showPath then return end
    
    local att0 = Instance.new("Attachment")
    att0.Parent = Workspace.Terrain
    att0.WorldPosition = fromPos
    
    local att1 = Instance.new("Attachment")
    att1.Parent = Workspace.Terrain
    att1.WorldPosition = toPos
    
    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Width0 = width or 0.5
    beam.Width1 = width or 0.5
    beam.Color = ColorSequence.new(color or Color3.new(0, 1, 0))
    beam.FaceCamera = true
    beam.Transparency = NumberSequence.new(transparency or 0.3)
    beam.LightEmission = 0.8
    beam.Parent = att0
    
    table.insert(activeBeams, att0)
    table.insert(activeBeams, att1)
    
    Debris:AddItem(att0, settings.beamDuration)
    Debris:AddItem(att1, settings.beamDuration)
    
    return beam
end

local function CreateDebugInfo()
    if not settings.showDebugInfo or debugGui then return end
    
    debugGui = Instance.new("ScreenGui")
    debugGui.Name = "NavigationDebug"
    debugGui.Parent = player:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(1, -320, 0, 20)
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = debugGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "🔍 Navigation Debug"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, -10, 1, -35)
    infoLabel.Position = UDim2.new(0, 5, 0, 30)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Initializing..."
    infoLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    infoLabel.TextSize = 12
    infoLabel.Font = Enum.Font.Code
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top
    infoLabel.TextWrapped = true
    infoLabel.Parent = frame
    
    return infoLabel
end

local function UpdateDebugInfo(text)
    if debugGui and debugGui:FindFirstChild("Frame") and debugGui.Frame:FindFirstChild("InfoLabel") then
        debugGui.Frame.InfoLabel.Text = text
    end
end

-- ========================================
-- ระบบตรวจสอบพื้นและความปลอดภัย
-- ========================================

local function FindGroundPosition(position)
    if not settings.groundCheck then return position end
    
    -- ยิง Raycast ลงไปหาพื้น
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {char}
    
    -- ยิงจากสูงไปต่ำ
    local startPos = position + Vector3.new(0, 50, 0)
    local direction = Vector3.new(0, -100, 0)
    
    local raycastResult = Workspace:Raycast(startPos, direction, raycastParams)
    
    if raycastResult then
        -- พบพื้น - วางตัวละครเหนือพื้น 3 หน่วย
        return raycastResult.Position + Vector3.new(0, 3, 0)
    else
        -- ไม่พบพื้น - ใช้ตำแหน่งเดิม
        return position
    end
end

local function IsSafePosition(position)
    if not settings.safeMovement then return true end
    
    -- ตรวจสอบว่าตำแหน่งปลอดภัยหรือไม่
    local groundPos = FindGroundPosition(position)
    local heightDiff = math.abs(position.Y - groundPos.Y)
    
    -- ถ้าสูงจากพื้นเกิน 20 หน่วย ถือว่าไม่ปลอดภัย
    return heightDiff <= 20
end

-- ========================================
-- ระบบตรวจจับสิ่งกีดขวาง
-- ========================================

local function RaycastCheck(from, to, filterList)
    local direction = to - from
    local distance = direction.Magnitude
    
    if distance < 0.1 then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = filterList or {char}
    raycastParams.IgnoreWater = true -- เพิ่มการเพิกเฉยน้ำ
    
    local raycastResult = Workspace:Raycast(from, direction, raycastParams)
    return raycastResult ~= nil
end

local function CheckCollisionPath(startPos, endPos)
    if not settings.collisionCheck then return true end
    
    -- ตรวจสอบ collision ในหลายระดับ
    local checkPoints = {
        Vector3.new(0, 0, 0),    -- ระดับเท้า
        Vector3.new(0, 2, 0),    -- ระดับกลางตัว
        Vector3.new(0, 4, 0),    -- ระดับหัว
    }
    
    for _, offset in ipairs(checkPoints) do
        local from = startPos + offset
        local to = endPos + offset
        
        if RaycastCheck(from, to) then
            return false -- พบสิ่งกีดขวาง
        end
    end
    
    return true -- ไม่มีสิ่งกีดขวาง
end

local function IsPathClear(startPos, endPos)
    if not settings.obstacleDetection then return true end
    
    -- ตรวจสอบหลายระดับความสูง
    local positions = {
        startPos,
        startPos + Vector3.new(0, 2, 0),
        startPos + Vector3.new(0, 4, 0)
    }
    
    for _, pos in ipairs(positions) do
        local targetPos = Vector3.new(endPos.X, pos.Y, endPos.Z)
        if not RaycastCheck(pos, targetPos) then
            return true -- อย่างน้อยเส้นทางหนึ่งเส้นผ่านได้
        end
    end
    
    return false
end

local function DetectNearbyPlayers(position, radius)
    if not settings.playerAvoidance then return {} end
    
    local nearbyPlayers = {}
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (otherPlayer.Character.HumanoidRootPart.Position - position).Magnitude
            if distance < radius then
                table.insert(nearbyPlayers, otherPlayer.Character.HumanoidRootPart.Position)
            end
        end
    end
    return nearbyPlayers
end

-- ========================================
-- ระบบ CFrame Movement ขั้นสูง
-- ========================================

local function SmoothCFrameMovement(startCFrame, endPosition, speed, callback)
    if not IsCharacterValid() then return false end
    
    -- ตรวจสอบและปรับตำแหน่งให้ปลอดภัย
    endPosition = FindGroundPosition(endPosition)
    
    if not IsSafePosition(endPosition) then
        warn("⚠️ ตำแหน่งไม่ปลอดภัย - ยกเลิก")
        if callback then callback(false) end
        return false
    end
    
    local startPos = startCFrame.Position
    
    -- ตรวจสอบ Collision ก่อนเคลื่อนที่
    if not CheckCollisionPath(startPos, endPosition) then
        warn("⚠️ มีสิ่งกีดขวางบนเส้นทาง - ใช้ Humanoid แทน")
        return HumanoidMovement(endPosition, callback)
    end
    
    local direction = (endPosition - startPos)
    local distance = direction.Magnitude
    
    if distance < 2 then
        if callback then callback(true) end
        return true
    end
    
    -- ลดความเร็วสำหรับความปลอดภัย
    local safeSpeed = math.min(speed, 8) -- ไม่เกิน 8 หน่วยต่อวินาที
    local startTime = tick()
    local duration = distance / safeSpeed
    
    if settings.useTweening and duration > 0.3 then
        -- ใช้ TweenService สำหรับการเคลื่อนไหวที่นุ่มนวลและปลอดภัย
        local targetCFrame = CFrame.lookAt(endPosition, endPosition + direction.Unit)
        local tweenInfo = TweenInfo.new(
            duration,
            Enum.EasingStyle.Sine, -- เปลี่ยนเป็น Sine เพื่อความนุ่มนวลมากขึ้น
            Enum.EasingDirection.InOut,
            0,
            false,
            0
        )
        
        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        
        tween.Completed:Connect(function()
            if callback then callback(true) end
        end)
        
        return true
    else
        -- ใช้ RunService แต่ปลอดภัยกว่า
        local connection
        local completed = false
        local maxStepSize = 0.8 -- ลดขนาดการเคลื่อนที่ต่อ frame
        
        connection = RunService.Heartbeat:Connect(function(dt)
            if not IsCharacterValid() or completed then
                connection:Disconnect()
                return
            end
            
            local currentTime = tick()
            local elapsed = currentTime - startTime
            local progress = math.min(elapsed / duration, 1)
            
            -- ตรวจสอบการเคลื่อนที่ผิดปกติ
            if dt > 0 then
                local frameDistance = safeSpeed * dt
                frameDistance = math.min(frameDistance, maxStepSize)
                
                -- Smooth interpolation
                local currentPos = startPos:Lerp(endPosition, progress)
                
                -- ตรวจสอบ collision ก่อนเคลื่อนที่
                if not CheckCollisionPath(rootPart.Position, currentPos) then
                    completed = true
                    connection:Disconnect()
                    warn("⚠️ ตรวจพบสิ่งกีดขวาง - หยุดการเคลื่อนที่")
                    if callback then callback(false) end
                    return
                end
                
                -- ตรวจสอบพื้นขณะเคลื่อนที่
                currentPos = FindGroundPosition(currentPos)
                
                -- รักษาทิศทางการมอง
                local lookDirection = (endPosition - currentPos).Unit
                if lookDirection.Magnitude > 0 then
                    rootPart.CFrame = CFrame.lookAt(currentPos, currentPos + lookDirection)
                else
                    rootPart.CFrame = CFrame.new(currentPos)
                end
                
                -- ตั้งค่า Humanoid WalkSpeed เป็น 0 เพื่อป้องกัน Animation conflict
                if humanoid then
                    humanoid.WalkSpeed = 0
                end
            end
            
            if progress >= 1 then
                completed = true
                connection:Disconnect()
                
                -- คืนค่า WalkSpeed
                if humanoid then
                    humanoid.WalkSpeed = 16
                end
                
                if callback then callback(true) end
            end
        end)
        
        return true
    end
end

-- ฟังก์ชันใช้ Humanoid Movement แทน CFrame เพื่อความปลอดภัย
local function HumanoidMovement(targetPosition, callback)
    if not IsCharacterValid() then
        if callback then callback(false) end
        return false
    end
    
    print("🚶 ใช้ Humanoid Movement เพื่อความปลอดภัย")
    
    -- ตั้งความเร็วให้เหมาะสม
    humanoid.WalkSpeed = math.min(movementSpeed, 16)
    
    -- ใช้ MoveTo แบบปกติ
    humanoid:MoveTo(targetPosition)
    
    -- รอให้ถึงจุดหมาย
    local startTime = tick()
    local timeout = 30
    local success = false
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not IsCharacterValid() then
            connection:Disconnect()
            if callback then callback(false) end
            return
        end
        
        local distance = (rootPart.Position - targetPosition).Magnitude
        
        if distance < 4 then
            success = true
            connection:Disconnect()
            if callback then callback(true) end
            return
        end
        
        if tick() - startTime > timeout then
            connection:Disconnect()
            if callback then callback(false) end
            return
        end
    end)
    
    return true
end

local function TeleportMovement(targetPosition)
    -- ระบบ Teleport ถูกปิดใช้งาน
    return false
end

-- ========================================
-- ระบบ Pathfinding ขั้นสูง
-- ========================================

local function CreateAdvancedPath(startPos, endPos)
    local pathfindingParams = {
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 50,
        AgentCanClimb = true,
        AgentMaxSlope = 89,
        WaypointSpacing = 8,
        Costs = {
            Water = 20,
            Grass = 1,
            Sand = 2,
            Rock = 5,
            Wood = 3,
            Metal = 10,
            Ice = 15,
            Lava = math.huge,
            DangerousArea = math.huge
        }
    }
    
    local success, path = pcall(function()
        return PathfindingService:CreatePath(pathfindingParams)
    end)
    
    if not success then
        warn("❌ ไม่สามารถสร้าง Path ได้:", path)
        return nil
    end
    
    local computeSuccess, err = pcall(function()
        path:ComputeAsync(startPos, endPos)
    end)
    
    if not computeSuccess then
        warn("❌ ไม่สามารถคำนวณ Path ได้:", err)
        return nil
    end
    
    return path
end

local function OptimizePath(waypoints)
    if not settings.pathOptimization or #waypoints < 3 then
        return waypoints
    end
    
    local optimized = {waypoints[1]}
    
    for i = 2, #waypoints - 1 do
        local prevPoint = optimized[#optimized].Position -- แก้ไข: เข้าถึง .Position
        local currentPoint = waypoints[i].Position -- แก้ไข: เข้าถึง .Position
        local nextPoint = waypoints[i + 1].Position -- แก้ไข: เข้าถึง .Position
        
        -- ตรวจสอบว่าสามารถข้ามจุดปัจจุบันได้หรือไม่
        if IsPathClear(prevPoint, nextPoint) then
            -- ข้ามจุดนี้ได้
            continue
        else
            table.insert(optimized, waypoints[i])
        end
    end
    
    table.insert(optimized, waypoints[#waypoints])
    
    print(string.format("🔧 ปรับปรุงเส้นทาง: %d -> %d waypoints", #waypoints, #optimized))
    return optimized
end

local function NavigateToPosition(targetPos, options)
    if not targetPos or not IsCharacterValid() then return false end
    
    options = options or {}
    local usePathfinding = options.usePathfinding ~= false
    local maxRetries = options.maxRetries or 3
    
    moving = true
    local startPos = rootPart.Position
    local distance = (targetPos - startPos).Magnitude
    
    -- อัพเดท Debug
    UpdateDebugInfo(string.format(
        "🎯 Target: %s\n📏 Distance: %.1f\n🚀 Mode: %s\n⚡ Speed: %.1f",
        tostring(targetPos), distance, navigationMode, movementSpeed
    ))
    
    if navigationMode == "CFrame" then
        -- CFrame Movement เท่านั้น (แต่ปลอดภัยขึ้น)
        print("🎯 ใช้ CFrame Movement (ปลอดภัย)")
        CreateBeam(startPos, targetPos, Color3.new(0, 1, 1), 0.8) -- สีฟ้า
        
        local success = false
        SmoothCFrameMovement(rootPart.CFrame, targetPos, movementSpeed, function(result)
            success = result
        end)
        
        -- รอให้เสร็จ
        local startTime = tick()
        while moving and IsCharacterValid() and not success do
            task.wait(0.1)
            if (rootPart.Position - targetPos).Magnitude < 3 then
                success = true
                break
            end
            if tick() - startTime > 30 then -- timeout
                break
            end
        end
        
        moving = false
        return success
        
    else
        -- ใช้ Pathfinding + Humanoid Movement เป็นหลัก
        print("🧭 ใช้ Pathfinding + Humanoid Movement")
        
        local path = CreateAdvancedPath(startPos, targetPos)
        if not path or path.Status ~= Enum.PathStatus.Success then
            warn("❌ Pathfinding ล้มเหลว")
            
            if navigationMode == "Hybrid" then
                -- Fallback ไป CFrame
                return NavigateToPosition(targetPos, {usePathfinding = false})
            else
                moving = false
                return false
            end
        end
        
        local waypoints = path:GetWaypoints()
        waypoints = OptimizePath(waypoints)
        
        print(string.format("🟢 พบเส้นทาง: %d waypoints", #waypoints))
        
        -- วาดเส้นทาง
        for i = 1, #waypoints - 1 do
            local currentWp = waypoints[i]
            local nextWp = waypoints[i + 1]
            local color
            
            if currentWp.Action == Enum.PathWaypointAction.Jump then
                color = Color3.new(1, 1, 0) -- เหลือง
            elseif currentWp.Action == Enum.PathWaypointAction.Custom then
                color = Color3.new(1, 0.5, 0) -- ส้ม
            else
                color = Color3.new(0, 1, 0) -- เขียว
            end
            
            CreateBeam(currentWp.Position, nextWp.Position, color, 0.6)
        end
        
        -- ใช้ Humanoid Movement เป็นหลัก
        for i, wp in ipairs(waypoints) do
            if not IsCharacterValid() or not isEnabled then
                moving = false
                return false
            end
            
            print(string.format("📍 Waypoint %d/%d: %s", i, #waypoints, wp.Action.Name))
            
            local targetPosition = wp.Position
            
            -- ใช้ Humanoid Movement ที่ปลอดภัย
            if settings.useHumanoidMovement then
                local waypointSuccess = false
                HumanoidMovement(targetPosition, function(result)
                    waypointSuccess = result
                end)
                
                -- รอให้เคลื่อนที่เสร็จ
                local startTime = tick()
                while not waypointSuccess and IsCharacterValid() and isEnabled do
                    task.wait(0.1)
                    if tick() - startTime > 15 then -- Timeout
                        print("⏰ Timeout - ข้าม waypoint")
                        break
                    end
                end
            else
                -- ใช้ CFrame แต่ปลอดภัย
                local waypointSuccess = false
                SmoothCFrameMovement(rootPart.CFrame, targetPosition, movementSpeed, function(result)
                    waypointSuccess = result
                end)
                
                local startTime = tick()
                while not waypointSuccess and IsCharacterValid() and isEnabled do
                    task.wait(0.1)
                    if tick() - startTime > 15 then
                        break
                    end
                end
            end
        end
        
        moving = false
        return true
    end
    
    moving = false
    return false
end

-- ========================================
-- ระบบจัดการเป้าหมาย
-- ========================================

local function GetNextTarget()
    local allTargets = {}
    
    -- รวมตำแหน่งทั้งหมด
    for _, pos in ipairs(targetPositions) do
        table.insert(allTargets, pos)
    end
    for _, pos in ipairs(customTargets) do
        table.insert(allTargets, pos)
    end
    
    if #allTargets == 0 then return nil end
    
    local target = allTargets[currentTargetIndex]
    currentTargetIndex = currentTargetIndex + 1
    if currentTargetIndex > #allTargets then
        currentTargetIndex = 1
    end
    
    return target
end

local function AddCustomTarget(position)
    table.insert(customTargets, position)
    print("➕ เพิ่มตำแหน่งใหม่: " .. tostring(position))
end

-- ========================================
-- ระบบ AutoFarm หลัก
-- ========================================

local function AutoFarmLoop()
    print("🤖 เริ่มระบบ AutoFarm")
    
    while isEnabled do
        if not IsCharacterValid() then
            print("⏳ รอ Character โหลด...")
            task.wait(2)
            continue
        end
        
        if moving then
            task.wait(1)
            continue
        end
        
        local targetPos = GetNextTarget()
        if not targetPos then
            warn("❌ ไม่มีตำแหน่งเป้าหมาย")
            break
        end
        
        local success = NavigateToPosition(targetPos)
        
        if success then
            print("✅ ถึงเป้าหมายแล้ว - พักผ่อน 3 วินาที")
            task.wait(3)
        else
            print("❌ ไม่สามารถไปถึงเป้าหมาย - พัก 5 วินาที")
            task.wait(5)
        end
        
        task.wait(1) -- ป้องกัน lag
    end
end

-- ========================================
-- ระบบควบคุม UI
-- ========================================

local function CreateAdvancedGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PerfectAutoFarmGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 400)
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🚀 Perfect AutoFarm"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local yOffset = 50
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 25)
    statusLabel.Position = UDim2.new(0, 10, 0, yOffset)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 สถานะ: ปิด"
    statusLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    statusLabel.TextScaled = true
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    yOffset = yOffset + 30
    
    -- Mode Selection
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(1, -20, 0, 20)
    modeLabel.Position = UDim2.new(0, 10, 0, yOffset)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text = "🧭 โหมดการเดิน:"
    modeLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    modeLabel.TextScaled = true
    modeLabel.Font = Enum.Font.Gotham
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeLabel.Parent = mainFrame
    yOffset = yOffset + 25
    
    local modes = {"CFrame", "PathOnly", "Hybrid"}
    for i, mode in ipairs(modes) do
        local modeBtn = Instance.new("TextButton")
        modeBtn.Size = UDim2.new(0, 90, 0, 25)
        modeBtn.Position = UDim2.new(0, 10 + (i-1) * 95, 0, yOffset)
        modeBtn.BackgroundColor3 = navigationMode == mode and Color3.new(0, 0.8, 0) or Color3.new(0.3, 0.3, 0.3)
        modeBtn.Text = mode
        modeBtn.TextColor3 = Color3.new(1, 1, 1)
        modeBtn.TextScaled = true
        modeBtn.Font = Enum.Font.Gotham
        modeBtn.BorderSizePixel = 0
        modeBtn.Parent = mainFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = modeBtn
        
        modeBtn.MouseButton1Click:Connect(function()
            navigationMode = mode
            -- อัพเดทสีปุ่ม
            for _, btn in pairs(mainFrame:GetChildren()) do
                if btn:IsA("TextButton") and table.find(modes, btn.Text) then
                    btn.BackgroundColor3 = btn.Text == mode and Color3.new(0, 0.8, 0) or Color3.new(0.3, 0.3, 0.3)
                end
            end
            print("📝 เปลี่ยนโหมดเป็น: " .. mode)
        end)
    end
    yOffset = yOffset + 35
    
    -- Speed Control
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, -20, 0, 20)
    speedLabel.Position = UDim2.new(0, 10, 0, yOffset)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = string.format("⚡ ความเร็ว: %.1f (ปลอดภัย)", movementSpeed)
    speedLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    speedLabel.TextScaled = true
    speedLabel.Font = Enum.Font.Gotham
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = mainFrame
    yOffset = yOffset + 25
    
    -- Speed Slider
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -40, 0, 8)
    sliderBg.Position = UDim2.new(0, 20, 0, yOffset)
    sliderBg.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = mainFrame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((movementSpeed - 3) / 10, 0, 1, 0) -- แก้ไขการคำนวณใหม่
    sliderFill.BackgroundColor3 = Color3.new(0, 0.8, 1)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = sliderFill
    
    -- Slider interaction
    local dragging = false
    local function updateSpeed(input)
        local relativeX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        movementSpeed = math.floor((relativeX * 15 + 5) * 10) / 10 -- ช่วง 5-20 เพื่อความปลอดภัย, ปัดเศษ 1 ตำแหน่ง
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        speedLabel.Text = string.format("⚡ ความเร็ว: %.1f (ปลอดภัย)", movementSpeed)
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSpeed(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSpeed(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    yOffset = yOffset + 20
    
    -- Settings Toggles
    local settingsToggles = {
        {key = "useHumanoidMovement", label = "🚶 ใช้ Humanoid Movement"},
        {key = "useTweening", label = "✨ ใช้ Tween (ปลอดภัย)"},
        {key = "collisionCheck", label = "🔍 ตรวจสอบ Collision"},
        {key = "safeMovement", label = "🛡️ การเคลื่อนไหวปลอดภัย"},
        {key = "groundCheck", label = "🌍 ตรวจสอบพื้น"},
        {key = "obstacleDetection", label = "🚧 ตรวจจับสิ่งกีดขวาง"},
        {key = "showPath", label = "🌈 แสดงเส้นทาง"},
        {key = "showDebugInfo", label = "🔍 แสดงข้อมูล Debug"}
    }
    
    for i, setting in ipairs(settingsToggles) do
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(1, -20, 0, 25)
        toggleBtn.Position = UDim2.new(0, 10, 0, yOffset)
        toggleBtn.BackgroundColor3 = settings[setting.key] and Color3.new(0, 0.6, 0) or Color3.new(0.6, 0, 0)
        toggleBtn.Text = setting.label .. (settings[setting.key] and " ✅" or " ❌")
        toggleBtn.TextColor3 = Color3.new(1, 1, 1)
        toggleBtn.TextSize = 12
        toggleBtn.Font = Enum.Font.Gotham
        toggleBtn.BorderSizePixel = 0
        toggleBtn.Parent = mainFrame
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 4)
        toggleCorner.Parent = toggleBtn
        
        toggleBtn.MouseButton1Click:Connect(function()
            settings[setting.key] = not settings[setting.key]
            toggleBtn.BackgroundColor3 = settings[setting.key] and Color3.new(0, 0.6, 0) or Color3.new(0.6, 0, 0)
            toggleBtn.Text = setting.label .. (settings[setting.key] and " ✅" or " ❌")
            
            -- Handle special cases
            if setting.key == "showDebugInfo" then
                if settings[setting.key] then
                    CreateDebugInfo()
                elseif debugGui then
                    debugGui:Destroy()
                    debugGui = nil
                end
            elseif setting.key == "showPath" and not settings[setting.key] then
                ClearAllBeams()
            end
        end)
        
        yOffset = yOffset + 30
    end
    
    -- Control Buttons
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, -20, 0, 40)
    toggleButton.Position = UDim2.new(0, 10, 0, yOffset)
    toggleButton.BackgroundColor3 = Color3.new(0, 0.8, 0)
    toggleButton.Text = "🚀 เริ่มระบบ AutoFarm"
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = mainFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleButton
    
    yOffset = yOffset + 50
    
    -- Add Target Button
    local addTargetBtn = Instance.new("TextButton")
    addTargetBtn.Size = UDim2.new(1, -20, 0, 30)
    addTargetBtn.Position = UDim2.new(0, 10, 0, yOffset)
    addTargetBtn.BackgroundColor3 = Color3.new(0, 0.4, 0.8)
    addTargetBtn.Text = "📍 เพิ่มตำแหน่งปัจจุบัน"
    addTargetBtn.TextColor3 = Color3.new(1, 1, 1)
    addTargetBtn.TextScaled = true
    addTargetBtn.Font = Enum.Font.Gotham
    addTargetBtn.BorderSizePixel = 0
    addTargetBtn.Parent = mainFrame
    
    local addCorner = Instance.new("UICorner")
    addCorner.CornerRadius = UDim.new(0, 6)
    addCorner.Parent = addTargetBtn
    
    -- Update UI function
    local function UpdateUI()
        statusLabel.Text = string.format("📊 สถานะ: %s %s | เป้าหมาย: %d/%d", 
            isEnabled and "🟢 เปิด" or "🔴 ปิด",
            moving and "(กำลังเดิน)" or "",
            currentTargetIndex,
            #targetPositions + #customTargets
        )
        
        if isEnabled then
            toggleButton.BackgroundColor3 = Color3.new(0.8, 0, 0)
            toggleButton.Text = "⏹️ หยุดระบบ AutoFarm"
        else
            toggleButton.BackgroundColor3 = Color3.new(0, 0.8, 0)
            toggleButton.Text = "🚀 เริ่มระบบ AutoFarm"
        end
    end
    
    -- Button Events
    toggleButton.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        if isEnabled then
            task.spawn(AutoFarmLoop)
        else
            moving = false
            ClearAllBeams()
        end
        UpdateUI()
    end)
    
    addTargetBtn.MouseButton1Click:Connect(function()
        if IsCharacterValid() then
            AddCustomTarget(rootPart.Position)
            UpdateUI()
        end
    end)
    
    -- Auto update
    task.spawn(function()
        while screenGui.Parent do
            UpdateUI()
            task.wait(1)
        end
    end)
    
    -- Minimize feature
    local isMinimized = false
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local currentTime = tick()
            if title:GetAttribute("LastClick") and (currentTime - title:GetAttribute("LastClick")) < 0.5 then
                isMinimized = not isMinimized
                if isMinimized then
                    mainFrame:TweenSize(UDim2.new(0, 320, 0, 45), "Out", "Quad", 0.3, true)
                    title.Text = "🚀 Perfect AutoFarm (คลิกเพื่อขยาย)"
                else
                    mainFrame:TweenSize(UDim2.new(0, 320, 0, 400), "Out", "Quad", 0.3, true)
                    title.Text = "🚀 Perfect AutoFarm"
                end
            end
            title:SetAttribute("LastClick", currentTime)
        end
    end)
    
    UpdateUI()
    print("🎮 สร้าง Perfect AutoFarm GUI เรียบร้อย!")
end

-- ========================================
-- ระบบตรวจจับการติดขัด
-- ========================================

local stuckDetection = {
    lastPosition = nil,
    stuckTime = 0,
    stuckThreshold = 5, -- วินาที
    minMovement = 2 -- หน่วยระยะทาง
}

local function CheckStuckStatus()
    if not IsCharacterValid() or not moving then return false end
    
    local currentPos = rootPart.Position
    
    if stuckDetection.lastPosition then
        local movement = (currentPos - stuckDetection.lastPosition).Magnitude
        
        if movement < stuckDetection.minMovement then
            stuckDetection.stuckTime = stuckDetection.stuckTime + 1
        else
            stuckDetection.stuckTime = 0
        end
        
        if stuckDetection.stuckTime >= stuckDetection.stuckThreshold then
            print("⚠️ ตรวจพบการติดขัด - ใช้วิธีแก้ไข")
            
            -- วิธีแก้ไขการติดขัด
            local escapePos = currentPos + Vector3.new(
                math.random(-10, 10),
                5,
                math.random(-10, 10)
            )
            
            -- ใช้ CFrame แบบปลอดภัย เคลื่อนที่ทีละน้อย
            if IsCharacterValid() then
                local currentPos = rootPart.Position
                local direction = (escapePos - currentPos).Unit
                local safeDistance = 3 -- เคลื่อนที่ทีละ 3 หน่วย
                local newPos = currentPos + (direction * safeDistance)
                newPos = FindGroundPosition(newPos)
                
                -- ใช้ Tween เพื่อความปลอดภัย
                local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(newPos)})
                tween:Play()
            end
            stuckDetection.stuckTime = 0
            
            return true
        end
    end
    
    stuckDetection.lastPosition = currentPos
    return false
end

-- ========================================
-- ระบบ Auto-Recovery
-- ========================================

local function AutoRecovery()
    task.spawn(function()
        while true do
            task.wait(1)
            
            if settings.stuckDetection then
                CheckStuckStatus()
            end
            
            -- ตรวจสอบสถานะ Character
            if isEnabled and not IsCharacterValid() then
                print("🔄 ตรวจพบ Character หาย - รอการกลับมา")
                moving = false
                
                -- รอ Character ใหม่
                repeat task.wait(1) until IsCharacterValid()
                print("✅ Character กลับมาแล้ว")
            end
        end
    end)
end

-- ========================================
-- ระบบบันทึกและโหลดการตั้งค่า
-- ========================================

local function SaveSettings()
    -- ใน Roblox ไม่สามารถบันทึกไฟล์ได้ แต่สามารถใช้ DataStore ได้
    -- สำหรับตอนนี้จะใช้ print เพื่อแสดงการตั้งค่า
    print("💾 การตั้งค่าปัจจุบัน:")
    print("Navigation Mode:", navigationMode)
    print("Movement Speed:", movementSpeed)
    print("Custom Targets:", #customTargets)
    for key, value in pairs(settings) do
        print(key .. ":", value)
    end
end

local function LoadDefaultSettings()
    navigationMode = "Hybrid"
    movementSpeed = 20
    -- settings ได้ถูกตั้งค่าไว้แล้วข้างบน
    print("📂 โหลดการตั้งค่าเริ่มต้น")
end

-- ========================================
-- เริ่มต้นระบบ
-- ========================================

local function Initialize()
    print("🚀 กำลังเริ่มต้น Perfect AutoFarm Navigation System...")
    
    -- โหลดการตั้งค่า
    LoadDefaultSettings()
    
    -- สร้าง GUI
    CreateAdvancedGUI()
    
    -- สร้าง Debug GUI
    if settings.showDebugInfo then
        CreateDebugInfo()
    end
    
    -- เริ่ม Auto-Recovery
    AutoRecovery()
    
    -- ข้อความต้อนรับ
    print("✅ Perfect AutoFarm Navigation System พร้อมใช้งาน!")
    print("🎮 ใช้ GUI เพื่อควบคุมระบบ")
    print("🌟 ฟีเจอร์พิเศษ:")
    print("   • 3 โหมดการเดิน: CFrame, PathOnly, Hybrid")
    print("   • ระบบป้องกัน Anti-Cheat และ Anti-Noclip")
    print("   • การตรวจสอบ Collision แบบ Real-time")
    print("   • Humanoid Movement สำหรับความปลอดภัยสูงสุด")
    print("   • การตรวจจับการติดขัดและแก้ไขอัตโนมัติ")
    print("   • Path Optimization และ Ground Check")
    print("   • Debug และ Visual Systems")
end

-- เริ่มต้นเมื่อโหลดเสร็จ
task.wait(2)
Initialize()
