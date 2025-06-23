-- ========================================
-- Perfect AutoFarm Navigation System (แก้ไขแล้ว)
-- ใช้ CFrame Movement + Advanced Pathfinding
-- ========================================

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Player และ Character
local player = Players.LocalPlayer
if not player then
    error("ไม่พบ LocalPlayer")
end

-- รอ Character
local char = player.Character or player.CharacterAdded:Wait()
local rootPart = char:WaitForChild("HumanoidRootPart", 10)
local humanoid = char:WaitForChild("Humanoid", 10)

if not rootPart or not humanoid then
    error("ไม่พบ Character Parts")
end

-- ========================================
-- การตั้งค่าระบบ
-- ========================================

-- ตัวแปรหลัก
local moving = false
local isEnabled = false
local navigationMode = "Hybrid" -- CFrame, PathOnly, Hybrid
local movementSpeed = 8 -- ความเร็วเริ่มต้นที่ปลอดภัย

-- การตั้งค่าขั้นสูง
local settings = {
    -- การเคลื่อนไหว
    smoothMovement = true,
    useHumanoidMovement = true,
    adaptiveSpeed = true,
    obstacleDetection = true,
    safeMovement = true,
    collisionCheck = true,
    
    -- Pathfinding
    useSmartPathing = true,
    pathOptimization = true,
    dynamicRecalculation = true,
    
    -- การหลีกเลี่ยง
    playerAvoidance = true,
    obstacleAvoidance = true,
    stuckDetection = true,
    groundCheck = true,
    
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
local customTargets = {}

-- ========================================
-- ระบบจัดการ Character
-- ========================================

local function IsCharacterValid()
    return char and char.Parent and rootPart and rootPart.Parent and humanoid and humanoid.Health > 0
end

local function OnCharacterAdded(newChar)
    char = newChar
    rootPart = char:WaitForChild("HumanoidRootPart", 10)
    humanoid = char:WaitForChild("Humanoid", 10)
    moving = false
    print("🔄 Character ใหม่โหลดแล้ว")
end

player.CharacterAdded:Connect(OnCharacterAdded)

-- ========================================
-- ระบบ Visual
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
    if not settings.showPath then return end
    
    local success, result = pcall(function()
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
    end)
    
    return success and result or nil
end

-- ========================================
-- ระบบตรวจสอบความปลอดภัย
-- ========================================

local function FindGroundPosition(position)
    if not settings.groundCheck then return position end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {char}
    
    local startPos = position + Vector3.new(0, 50, 0)
    local direction = Vector3.new(0, -100, 0)
    
    local success, raycastResult = pcall(function()
        return Workspace:Raycast(startPos, direction, raycastParams)
    end)
    
    if success and raycastResult then
        return raycastResult.Position + Vector3.new(0, 3, 0)
    end
    
    return position
end

local function CheckCollisionPath(startPos, endPos)
    if not settings.collisionCheck then return true end
    
    local direction = endPos - startPos
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {char}
    
    local success, result = pcall(function()
        return Workspace:Raycast(startPos, direction, raycastParams)
    end)
    
    return not (success and result)
end

-- ========================================
-- ระบบ Movement
-- ========================================

local function HumanoidMovement(targetPosition, callback)
    if not IsCharacterValid() then
        if callback then callback(false) end
        return false
    end
    
    humanoid.WalkSpeed = math.min(movementSpeed, 16)
    humanoid:MoveTo(targetPosition)
    
    local startTime = tick()
    local timeout = 30
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not IsCharacterValid() then
            connection:Disconnect()
            if callback then callback(false) end
            return
        end
        
        local distance = (rootPart.Position - targetPosition).Magnitude
        
        if distance < 4 then
            connection:Disconnect()
            if callback then callback(true) end
        elseif tick() - startTime > timeout then
            connection:Disconnect()
            if callback then callback(false) end
        end
    end)
    
    return true
end

local function CFrameMovement(targetPosition, callback)
    if not IsCharacterValid() then
        if callback then callback(false) end
        return false
    end
    
    targetPosition = FindGroundPosition(targetPosition)
    
    if not CheckCollisionPath(rootPart.Position, targetPosition) then
        return HumanoidMovement(targetPosition, callback)
    end
    
    local startPos = rootPart.Position
    local distance = (targetPosition - startPos).Magnitude
    
    if distance < 2 then
        if callback then callback(true) end
        return true
    end
    
    local duration = distance / movementSpeed
    local startTime = tick()
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not IsCharacterValid() then
            connection:Disconnect()
            if callback then callback(false) end
            return
        end
        
        local elapsed = tick() - startTime
        local progress = math.min(elapsed / duration, 1)
        
        local currentPos = startPos:Lerp(targetPosition, progress)
        currentPos = FindGroundPosition(currentPos)
        
        local lookDirection = (targetPosition - currentPos).Unit
        if lookDirection.Magnitude > 0 then
            rootPart.CFrame = CFrame.lookAt(currentPos, currentPos + lookDirection)
        else
            rootPart.CFrame = CFrame.new(currentPos)
        end
        
        if progress >= 1 then
            connection:Disconnect()
            if callback then callback(true) end
        end
    end)
    
    return true
end

-- ========================================
-- ระบบ Pathfinding
-- ========================================

local function CreatePath(startPos, endPos)
    local pathfindingParams = {
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 50,
        AgentCanClimb = true,
        AgentMaxSlope = 89,
        WaypointSpacing = 8
    }
    
    local success, path = pcall(function()
        local newPath = PathfindingService:CreatePath(pathfindingParams)
        newPath:ComputeAsync(startPos, endPos)
        return newPath
    end)
    
    if success and path.Status == Enum.PathStatus.Success then
        return path
    end
    
    return nil
end

local function OptimizePath(waypoints)
    if not settings.pathOptimization or #waypoints < 3 then
        return waypoints
    end
    
    local optimized = {waypoints[1]}
    
    for i = 2, #waypoints - 1 do
        local prevPoint = optimized[#optimized].Position
        local nextPoint = waypoints[i + 1].Position
        
        if not CheckCollisionPath(prevPoint, nextPoint) then
            table.insert(optimized, waypoints[i])
        end
    end
    
    table.insert(optimized, waypoints[#waypoints])
    return optimized
end

-- ========================================
-- ระบบ Navigation หลัก
-- ========================================

local function NavigateToPosition(targetPos)
    if not targetPos or not IsCharacterValid() then return false end
    
    moving = true
    local startPos = rootPart.Position
    
    -- Mode: CFrame Only
    if navigationMode == "CFrame" then
        CreateBeam(startPos, targetPos, Color3.new(0, 1, 1), 0.8)
        
        local success = false
        CFrameMovement(targetPos, function(result)
            success = result
            moving = false
        end)
        
        -- รอให้เสร็จ
        while moving do
            task.wait(0.1)
        end
        
        return success
        
    -- Mode: Pathfinding + Movement
    else
        local path = CreatePath(startPos, targetPos)
        if not path then
            if navigationMode == "Hybrid" then
                -- Fallback to CFrame
                navigationMode = "CFrame"
                local result = NavigateToPosition(targetPos)
                navigationMode = "Hybrid"
                return result
            else
                moving = false
                return false
            end
        end
        
        local waypoints = OptimizePath(path:GetWaypoints())
        
        -- วาดเส้นทาง
        for i = 1, #waypoints - 1 do
            local color = waypoints[i].Action == Enum.PathWaypointAction.Jump and Color3.new(1, 1, 0) or Color3.new(0, 1, 0)
            CreateBeam(waypoints[i].Position, waypoints[i + 1].Position, color, 0.6)
        end
        
        -- เดินตาม waypoints
        for i, wp in ipairs(waypoints) do
            if not IsCharacterValid() or not isEnabled then
                moving = false
                return false
            end
            
            local moveComplete = false
            
            if settings.useHumanoidMovement then
                HumanoidMovement(wp.Position, function(result)
                    moveComplete = true
                end)
            else
                CFrameMovement(wp.Position, function(result)
                    moveComplete = true
                end)
            end
            
            -- รอให้เคลื่อนที่เสร็จ
            local timeout = tick() + 15
            while not moveComplete and tick() < timeout do
                task.wait(0.1)
            end
            
            if wp.Action == Enum.PathWaypointAction.Jump and humanoid then
                humanoid.Jump = true
                task.wait(0.5)
            end
        end
        
        moving = false
        return true
    end
end

-- ========================================
-- ระบบ Target Management
-- ========================================

local function GetNextTarget()
    local allTargets = {}
    
    for _, pos in ipairs(targetPositions) do
        table.insert(allTargets, pos)
    end
    for _, pos in ipairs(customTargets) do
        table.insert(allTargets, pos)
    end
    
    if #allTargets == 0 then return nil end
    
    local target = allTargets[currentTargetIndex]
    currentTargetIndex = currentTargetIndex % #allTargets + 1
    
    return target
end

local function AddCustomTarget(position)
    table.insert(customTargets, position)
    print("➕ เพิ่มตำแหน่งใหม่: " .. tostring(position))
end

-- ========================================
-- AutoFarm Loop
-- ========================================

local function AutoFarmLoop()
    print("🤖 เริ่มระบบ AutoFarm")
    
    while isEnabled do
        if not IsCharacterValid() then
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
            print("✅ ถึงเป้าหมายแล้ว")
            task.wait(3)
        else
            print("❌ ไม่สามารถไปถึงเป้าหมาย")
            task.wait(5)
        end
        
        task.wait(0.5)
    end
    
    print("🛑 หยุดระบบ AutoFarm")
end

-- ========================================
-- GUI System
-- ========================================

local function CreateGUI()
    -- ตรวจสอบและลบ GUI เก่า
    local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("AutoFarmGUI")
    if oldGui then
        oldGui:Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFarmGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 450)
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
    local modeButtons = {}
    
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
        
        modeButtons[mode] = modeBtn
        
        modeBtn.MouseButton1Click:Connect(function()
            navigationMode = mode
            for modeName, btn in pairs(modeButtons) do
                btn.BackgroundColor3 = modeName == mode and Color3.new(0, 0.8, 0) or Color3.new(0.3, 0.3, 0.3)
            end
        end)
    end
    yOffset = yOffset + 35
    
    -- Speed Control
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(1, -20, 0, 20)
    speedLabel.Position = UDim2.new(0, 10, 0, yOffset)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Text = string.format("⚡ ความเร็ว: %.1f", movementSpeed)
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
    sliderFill.Size = UDim2.new((movementSpeed - 3) / 17, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.new(0, 0.8, 1)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = sliderFill
    
    -- Slider interaction
    local sliderDragging = false
    local function updateSpeed(input)
        local relativeX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        movementSpeed = math.floor((relativeX * 17 + 3) * 10) / 10
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        speedLabel.Text = string.format("⚡ ความเร็ว: %.1f", movementSpeed)
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = true
            updateSpeed(input)
        end
    end)
    
    yOffset = yOffset + 20
    
    -- Settings Toggles
    local settingsToggles = {
        {key = "useHumanoidMovement", label = "🚶 Humanoid Movement"},
        {key = "collisionCheck", label = "🔍 ตรวจสอบ Collision"},
        {key = "safeMovement", label = "🛡️ Safe Movement"},
        {key = "groundCheck", label = "🌍 ตรวจสอบพื้น"},
        {key = "showPath", label = "🌈 แสดงเส้นทาง"},
        {key = "pathOptimization", label = "🔧 ปรับปรุงเส้นทาง"}
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
            
            if setting.key == "showPath" and not settings[setting.key] then
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
    
    -- Draggable
    local frameDragging = false
    local dragStart = nil
    local startPos = nil
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            frameDragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    -- Global Input Events
    UserInputService.InputChanged:Connect(function(input)
        if frameDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        elseif sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSpeed(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            frameDragging = false
            sliderDragging = false
        end
    end)
    
    return screenGui
end

-- ========================================
-- ระบบ Keybind
-- ========================================

local keybindEnabled = true
local toggleKey = Enum.KeyCode.F

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if keybindEnabled and input.KeyCode == toggleKey then
        isEnabled = not isEnabled
        if isEnabled then
            task.spawn(AutoFarmLoop)
        else
            moving = false
            ClearAllBeams()
        end
        print(isEnabled and "🟢 AutoFarm เปิด" or "🔴 AutoFarm ปิด")
    end
end)

-- ========================================
-- เริ่มต้นระบบ
-- ========================================

-- สร้าง GUI
CreateGUI()

-- แสดงคำแนะนำ
print([[
========================================
🚀 Perfect AutoFarm Navigation System
========================================
📌 วิธีใช้:
- กด F เพื่อเปิด/ปิดระบบ
- ใช้ GUI เพื่อปรับตั้งค่า
- เพิ่มตำแหน่งได้ด้วยปุ่ม "เพิ่มตำแหน่งปัจจุบัน"

🧭 โหมดการเดิน:
- CFrame: เดินตรงไปยังเป้าหมาย (เร็วแต่อาจติดสิ่งกีดขวาง)
- PathOnly: ใช้ Pathfinding อย่างเดียว (ช้าแต่หลบสิ่งกีดขวาง)
- Hybrid: ผสมผสานทั้งสองวิธี (แนะนำ)

⚡ ความเร็ว: ปรับได้ 3-20
🛡️ ระบบป้องกัน: ตรวจสอบการชน, หาพื้น, หลบสิ่งกีดขวาง

✨ พัฒนาโดย: Perfect AutoFarm Team
========================================
]])

-- ตรวจสอบว่ามีตำแหน่งเป้าหมายหรือไม่
if #targetPositions == 0 then
    warn("⚠️ คำเตือน: ยังไม่มีตำแหน่งเป้าหมาย กรุณาเพิ่มตำแหน่งด้วยปุ่ม 'เพิ่มตำแหน่งปัจจุบัน'")
end
