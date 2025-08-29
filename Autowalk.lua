-- ========================================
-- CFrame Path Movement v1.4 - Enhanced Error Handling
-- แก้ไข nil value errors และเพิ่มการตรวจสอบที่แข็งแกร่งกว่า
-- ========================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ฟังก์ชันรอ service ที่ปลอดภัยกว่า
local function waitForService(serviceName, timeout)
    timeout = timeout or 10
    local service = nil
    local attempts = 0
    
    repeat
        local success, result = pcall(function()
            return game:GetService(serviceName)
        end)
        if success and result then
            service = result
            break
        end
        attempts = attempts + 1
        task.wait(0.1)
    until attempts >= (timeout * 10)
    
    return service
end

-- โหลด services ด้วยการตรวจสอบ
local PhysicsService = waitForService("PhysicsService", 5)
local PathfindingService = waitForService("PathfindingService", 5)
local UserInputService = waitForService("UserInputService", 5)

if not PhysicsService then
    warn("⚠️ ไม่สามารถโหลด PhysicsService")
end
if not PathfindingService then
    error("❌ ไม่สามารถโหลด PathfindingService - จำเป็นสำหรับการทำงาน")
    return
end
if not UserInputService then
    warn("⚠️ ไม่สามารถโหลด UserInputService - GUI อาจไม่ทำงานปกติ")
end

local player = Players.LocalPlayer
if not player then
    error("❌ ไม่พบ LocalPlayer")
    return
end

-- รอ Character และ components ที่จำเป็น
local char = player.Character
if not char then
    print("🔄 รอ Character...")
    char = player.CharacterAdded:Wait()
end

local humanoid = char:WaitForChild("Humanoid", 10)
local rootPart = char:WaitForChild("HumanoidRootPart", 10)

if not humanoid or not rootPart then
    error("❌ ไม่พบ Humanoid หรือ HumanoidRootPart")
    return
end

-- เป้าหมาย
local TARGET = Vector3.new(1224.875, 255.192, -559.237)

-- ตัวแปร
local isEnabled, moving = false, false
local speed = 8 -- studs/s
local activeBeams = {}

-- แกนมาตรฐาน
local Y_AXIS = Vector3.new(0,1,0)
local Z_AXIS = Vector3.new(0,0,1)

local AGENT_RADIUS = 2.5

-- โหมดการเลี่ยงสิ่งกีดขวาง
local avoidanceMode = "up"
local UP_STEP_HEIGHT = 2.5
local UP_MAX_HEIGHT = 10
local OVER_FORWARD = 3.5

-- สถานะ vault และ slide
local isVaulting = false
local vaultConn = nil
local isSliding = false
local slideSign = 1
local slideUntil = 0

-- ค่าชดเชยความสูง
local BASE_OFFSET = (humanoid.HipHeight or 2) + (rootPart.Size.Y/2)
local extraHover = 0.5

-- Utility clamp function
local clamp = math.clamp or function(x, a, b)
    if x < a then return a elseif x > b then return b else return x end
end

local function IsCharacterValid()
    return char and char.Parent and rootPart and rootPart.Parent and humanoid and humanoid.Parent
end

-- อัพเดท Character เมื่อ respawn
player.CharacterAdded:Connect(function(newChar)
    char = newChar
    humanoid = char:WaitForChild("Humanoid", 10)
    rootPart = char:WaitForChild("HumanoidRootPart", 10)
    moving = false
    isEnabled = false
    
    if humanoid and rootPart then
        BASE_OFFSET = (humanoid.HipHeight or 2) + (rootPart.Size.Y/2)
        print("✅ Character ใหม่พร้อมใช้งาน")
    else
        warn("⚠️ Character ใหม่มีปัญหา")
    end
end)

local function ClearOldBeams()
    for _, obj in ipairs(activeBeams) do
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
        end
    end
    activeBeams = {}
end

local function ShowPath(waypoints)
    ClearOldBeams()
    if not waypoints or #waypoints < 2 then return end
    
    for i = 1, #waypoints - 1 do
        local success, error = pcall(function()
            local fromPos, toPos = waypoints[i].Position, waypoints[i+1].Position
            local color = waypoints[i].Action == Enum.PathWaypointAction.Jump and Color3.new(1,1,0) or Color3.new(0,1,0)

            local att0, att1 = Instance.new("Attachment"), Instance.new("Attachment")
            att0.Parent, att1.Parent = Workspace.Terrain, Workspace.Terrain
            att0.WorldPosition, att1.WorldPosition = fromPos, toPos

            local beam = Instance.new("Beam")
            beam.Attachment0, beam.Attachment1 = att0, att1
            beam.Width0, beam.Width1 = 0.5, 0.5
            beam.Color = ColorSequence.new(color)
            beam.FaceCamera = true
            beam.Transparency = NumberSequence.new(0.3)
            beam.LightEmission = 0.8
            beam.Parent = att0

            table.insert(activeBeams, att0)
            table.insert(activeBeams, att1)
            table.insert(activeBeams, beam)
        end)
        
        if not success then
            warn("⚠️ ไม่สามารถสร้าง beam:", error)
        end
    end
end

local function FindGroundPosition(position)
    local success, result = pcall(function()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {char}
        params.IgnoreWater = true
        
        -- ตั้งค่า CollisionGroup อย่างปลอดภัย
        if PhysicsService and rootPart then
            pcall(function()
                params.CollisionGroup = PhysicsService:GetCollisionGroupName(rootPart.CollisionGroupId)
            end)
        end

        local rayResult = Workspace:Raycast(position + Vector3.new(0,10,0), Vector3.new(0,-50,0), params)
        if rayResult then
            return rayResult.Position + Vector3.new(0, BASE_OFFSET + extraHover, 0)
        end
        return position + Vector3.new(0, BASE_OFFSET + extraHover, 0)
    end)
    
    if success then
        return result
    else
        -- fallback ถ้า raycast ไม่ทำงาน
        return position + Vector3.new(0, BASE_OFFSET + extraHover, 0)
    end
end

local function IsForwardBlocked(fromPos, dirXZ, dist)
    local success, blocked, hitResult = pcall(function()
        local forward = dirXZ.Magnitude > 0 and dirXZ.Unit or Z_AXIS
        local right = forward:Cross(Y_AXIS).Unit

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {char}
        params.IgnoreWater = true
        
        if PhysicsService and rootPart then
            pcall(function()
                params.CollisionGroup = PhysicsService:GetCollisionGroupName(rootPart.CollisionGroupId)
            end)
        end

        local heights = {2, 4}
        for _,h in ipairs(heights) do
            for _,side in ipairs({-1,0,1}) do
                local lateral = right * AGENT_RADIUS * 0.9 * side
                local origin = fromPos + Vector3.new(0, h, 0) + lateral
                local rayResult = Workspace:Raycast(origin, forward * dist, params)
                if rayResult then 
                    return true, rayResult 
                end
            end
        end
        return false, nil
    end)
    
    if success then
        return blocked, hitResult
    else
        return false, nil -- ถ้า error ให้ถือว่าไม่มีสิ่งกีดขวาง
    end
end

local function StartVault(dirXZ, height, forwardDist)
    if isVaulting or not IsCharacterValid() then return false end
    
    isVaulting = true
    local startPos = rootPart.Position
    local fwd = dirXZ.Magnitude > 0 and dirXZ.Unit or Z_AXIS
    local dur = clamp(0.28 + forwardDist/12, 0.28, 0.7)
    local t = 0

    if vaultConn then
        vaultConn:Disconnect()
    end
    
    vaultConn = RunService.Heartbeat:Connect(function(dt)
        if not IsCharacterValid() or not isEnabled then
            if vaultConn then vaultConn:Disconnect() end
            isVaulting = false
            return
        end
        
        t = math.min(1, t + dt/dur)
        local arcY = height * math.sin(math.pi * t)
        local p = startPos + fwd * (forwardDist * t) + Vector3.new(0, arcY, 0)
        
        local success = pcall(function()
            rootPart.CFrame = CFrame.lookAt(p, p + fwd, Y_AXIS)
        end)
        
        if not success then
            if vaultConn then vaultConn:Disconnect() end
            isVaulting = false
            return
        end
        
        if t >= 1 then
            local land = FindGroundPosition(p)
            pcall(function()
                rootPart.CFrame = CFrame.lookAt(land, land + fwd, Y_AXIS)
            end)
            if vaultConn then vaultConn:Disconnect() end
            isVaulting = false
        end
    end)
    
    if humanoid then
        pcall(function()
            humanoid.Jump = true
        end)
    end
    return true
end

local function NudgeUpOver(currentPos, dirXZ)
    local fwd = dirXZ.Magnitude > 0 and dirXZ.Unit or Z_AXIS

    local success, result = pcall(function()
        local upParams = RaycastParams.new()
        upParams.FilterType = Enum.RaycastFilterType.Blacklist
        upParams.FilterDescendantsInstances = {char}
        upParams.IgnoreWater = true
        
        if PhysicsService and rootPart then
            pcall(function()
                upParams.CollisionGroup = PhysicsService:GetCollisionGroupName(rootPart.CollisionGroupId)
            end)
        end

        for h = UP_STEP_HEIGHT, UP_MAX_HEIGHT, UP_STEP_HEIGHT do
            local hitUp = Workspace:Raycast(currentPos + Vector3.new(0, 0.1, 0), Vector3.new(0, h, 0), upParams)
            if not hitUp then
                local elevated = currentPos + Vector3.new(0, h, 0)
                local clearAhead = not IsForwardBlocked(elevated, fwd, OVER_FORWARD + AGENT_RADIUS)
                if clearAhead then
                    return StartVault(dirXZ, h, OVER_FORWARD + AGENT_RADIUS*0.7)
                end
            end
        end
        return false
    end)
    
    return success and result or false
end

-- คำนวณเส้นทาง
local function ComputePath(startPos, endPos)
    local success, waypoints = pcall(function()
        local path = PathfindingService:CreatePath({
            AgentRadius = AGENT_RADIUS,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentJumpHeight = 12,
            AgentMaxSlope = 35,
            WaypointSpacing = 6
        })
        
        path:ComputeAsync(startPos, endPos)
        
        if path.Status == Enum.PathStatus.Success then
            local raw = path:GetWaypoints()
            local processedWaypoints = {}
            
            for _, wp in ipairs(raw) do
                table.insert(processedWaypoints, { 
                    Position = FindGroundPosition(wp.Position), 
                    Action = wp.Action 
                })
            end
            return processedWaypoints
        end
        return nil
    end)
    
    if success then
        return waypoints
    else
        warn("❌ เกิดข้อผิดพลาดในการคำนวณเส้นทาง")
        return nil
    end
end

local function MoveAlongPath(waypoints)
    if not waypoints or #waypoints == 0 then
        warn("❌ ไม่มี waypoints")
        return
    end
    
    moving = true
    local idx = 1
    local blockedTimer = 0
    local lastXZ = nil
    local noProgress = 0

    local function BeginSlide(dirXZ)
        local fwd = (dirXZ.Magnitude > 0) and dirXZ.Unit or Z_AXIS
        local right = fwd:Cross(Y_AXIS).Unit
        local rightClear = not IsForwardBlocked(rootPart.Position + right * AGENT_RADIUS * 0.8, fwd, 2.0)
        local leftClear = not IsForwardBlocked(rootPart.Position - right * AGENT_RADIUS * 0.8, fwd, 2.0)
        
        if rightClear and not leftClear then
            slideSign = 1
        elseif leftClear and not rightClear then
            slideSign = -1
        else
            slideSign = (math.random() < 0.5) and 1 or -1
        end
        
        isSliding = true
        slideUntil = os.clock() + 0.7
    end

    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        if not IsCharacterValid() or not isEnabled or not moving or idx > #waypoints then
            conn:Disconnect()
            if idx > #waypoints then
                moving = false
                print("✅ ถึงเป้าหมายแล้ว!")
            end
            return
        end
        
        if isVaulting then return end

        local wp = waypoints[idx].Position
        local flatDir = Vector3.new(wp.X - rootPart.Position.X, 0, wp.Z - rootPart.Position.Z)
        local horizDist = flatDir.Magnitude
        local step = math.max(0.05, speed * dt)

        -- ติดตามความคืบหน้า
        local curXZ = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
        if lastXZ then
            local moved = (curXZ - lastXZ).Magnitude
            if moved < step * 0.2 then
                noProgress = noProgress + dt
            else
                noProgress = 0
            end
        end
        lastXZ = curXZ

        if isSliding then
            local fwd = (flatDir.Magnitude > 0) and flatDir.Unit or Z_AXIS
            local right = fwd:Cross(Y_AXIS).Unit
            local lateral = right * slideSign
            local sideBlocked = IsForwardBlocked(rootPart.Position, lateral, math.min(speed * dt * 0.6 + 0.6, 2.0))
            
            if sideBlocked then
                slideSign = -slideSign
            else
                local stepLen = math.max(0.05, speed * dt * 0.6)
                local newPos = rootPart.Position + lateral * stepLen
                local safePos = FindGroundPosition(newPos)
                pcall(function()
                    rootPart.CFrame = CFrame.lookAt(safePos, safePos + fwd, Y_AXIS)
                end)
            end
            
            if os.clock() > slideUntil or not IsForwardBlocked(rootPart.Position, flatDir, 1.5) then
                isSliding = false
            end
            return
        end

        if waypoints[idx].Action == Enum.PathWaypointAction.Jump and horizDist < 3.5 and humanoid then
            pcall(function()
                humanoid.Jump = true
            end)
        end

        if horizDist <= 0.6 then
            idx = idx + 1
            if idx > #waypoints then
                moving = false
                conn:Disconnect()
                print("✅ ถึงเป้าหมายแล้ว!")
                return
            end
        else
            local blocked = IsForwardBlocked(rootPart.Position, flatDir, math.min(step + 1.5, 6))
            
            if (not blocked) and noProgress > 0.35 then
                blocked = true
            end

            if blocked then
                if avoidanceMode == "up" or avoidanceMode == "auto" then
                    local did = NudgeUpOver(rootPart.Position, flatDir)
                    if did then 
                        blockedTimer = 0
                        noProgress = 0
                        return 
                    end
                end
                
                if avoidanceMode == "side" or avoidanceMode == "auto" then
                    BeginSlide(flatDir)
                    blockedTimer = 0
                    noProgress = 0
                    return
                end
                
                blockedTimer = blockedTimer + dt
                if blockedTimer > 1.2 then
                    local newWps = ComputePath(rootPart.Position, TARGET)
                    if newWps then
                        waypoints = newWps
                        idx = 1
                        ShowPath(waypoints)
                        blockedTimer = 0
                        noProgress = 0
                    end
                end
                return
            end

            blockedTimer = 0
            local moveVec = flatDir.Unit * math.min(step, horizDist)
            local targetXZ = Vector3.new(
                rootPart.Position.X + moveVec.X,
                rootPart.Position.Y,
                rootPart.Position.Z + moveVec.Z
            )
            local safePos = FindGroundPosition(targetXZ)
            local look = (flatDir.Magnitude > 0) and flatDir.Unit or Z_AXIS
            
            pcall(function()
                rootPart.CFrame = CFrame.lookAt(safePos, safePos + Vector3.new(look.X, 0, look.Z), Y_AXIS)
            end)
        end
    end)
end

local function StartPathMovement()
    if not IsCharacterValid() then
        warn("❌ Character ไม่พร้อม")
        return
    end
    
    print("🧭 คำนวณเส้นทาง...")
    local waypoints = ComputePath(rootPart.Position, TARGET)
    if waypoints then
        ShowPath(waypoints)
        MoveAlongPath(waypoints)
    else
        warn("❌ ไม่สามารถหาเส้นทางได้")
        moving = false
        isEnabled = false
    end
end

-- GUI Creation (ปลอดภัยกว่า)
local function CreateGUI()
    local success, result = pcall(function()
        local playerGui = player:WaitForChild("PlayerGui", 10)
        if not playerGui then
            error("ไม่พบ PlayerGui")
        end

        -- ลบ GUI เก่าถ้ามี
        local oldGui = playerGui:FindFirstChild("CFramePathGUI")
        if oldGui then
            oldGui:Destroy()
        end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "CFramePathGUI"
        screenGui.Parent = playerGui

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0,260,0,180)
        frame.Position = UDim2.new(0,20,0,20)
        frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = screenGui

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1,0,0,30)
        title.BackgroundTransparency = 1
        title.Text = "🚶 CFrame Path v1.4"
        title.TextColor3 = Color3.new(1,1,1)
        title.Font = Enum.Font.GothamBold
        title.TextScaled = true
        title.Parent = frame

        local speedLabel = Instance.new("TextLabel")
        speedLabel.Size = UDim2.new(1,-20,0,20)
        speedLabel.Position = UDim2.new(0,10,0,40)
        speedLabel.BackgroundTransparency = 1
        speedLabel.Text = "⚡ ความเร็ว: "..speed.." studs/s"
        speedLabel.TextColor3 = Color3.new(1,1,1)
        speedLabel.Font = Enum.Font.Gotham
        speedLabel.TextSize = 14
        speedLabel.Parent = frame

        -- Speed Slider
        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(1,-20,0,8)
        sliderBg.Position = UDim2.new(0,10,0,70)
        sliderBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
        sliderBg.BorderSizePixel = 0
        sliderBg.Parent = frame

        local sliderFill = Instance.new("Frame")
        sliderFill.Size = UDim2.new((speed-4)/16,0,1,0)
        sliderFill.BackgroundColor3 = Color3.fromRGB(0,200,255)
        sliderFill.BorderSizePixel = 0
        sliderFill.Parent = sliderBg

        -- Slider Logic (ปลอดภัย)
        if UserInputService then
            local dragging = false
            sliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local size = clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                    speed = math.floor(size * 16 + 4)
                    sliderFill.Size = UDim2.new(size, 0, 1, 0)
                    speedLabel.Text = "⚡ ความเร็ว: "..speed.." studs/s"
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
        end

        -- Buttons
        local startBtn = Instance.new("TextButton")
        startBtn.Size = UDim2.new(0.48,-12,0,35)
        startBtn.Position = UDim2.new(0,10,0,95)
        startBtn.BackgroundColor3 = Color3.fromRGB(0,180,0)
        startBtn.Text = "▶️ เริ่ม"
        startBtn.TextColor3 = Color3.new(1,1,1)
        startBtn.Font = Enum.Font.GothamBold
        startBtn.BorderSizePixel = 0
        startBtn.Parent = frame

        local stopBtn = Instance.new("TextButton")
        stopBtn.Size = UDim2.new(0.48,-12,0,35)
        stopBtn.Position = UDim2.new(0.52,2,0,95)
        stopBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
        stopBtn.Text = "⏹️ หยุด"
        stopBtn.TextColor3 = Color3.new(1,1,1)
        stopBtn.Font = Enum.Font.GothamBold
        stopBtn.BorderSizePixel = 0
        stopBtn.Parent = frame

        local pauseBtn = Instance.new("TextButton")
        pauseBtn.Size = UDim2.new(1,-20,0,35)
        pauseBtn.Position = UDim2.new(0,10,0,135)
        pauseBtn.BackgroundColor3 = Color3.fromRGB(60,60,180)
        pauseBtn.Text = "⏸️ พักชั่วคราว"
        pauseBtn.TextColor3 = Color3.new(1,1,1)
        pauseBtn.Font = Enum.Font.GothamBold
        pauseBtn.BorderSizePixel = 0
        pauseBtn.Parent = frame

        -- Button Events
        startBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if not moving and not isEnabled then
                    isEnabled = true
                    task.spawn(StartPathMovement)
                end
            end)
        end)

        stopBtn.MouseButton1Click:Connect(function()
            pcall(function()
                isEnabled = false
                moving = false
                isSliding = false
                if vaultConn then vaultConn:Disconnect() end
                isVaulting = false
                ClearOldBeams()
            end)
        end)

        local paused = false
        pauseBtn.MouseButton1Click:Connect(function()
            pcall(function()
                paused = not paused
                if paused then
                    isEnabled = false
                    moving = false
                    pauseBtn.Text = "▶️ ดำเนินต่อ"
                else
                    if not moving then
                        isEnabled = true
                        pauseBtn.Text = "⏸️ พักชั่วคราว"
                        task.spawn(StartPathMovement)
                    end
                end
            end)
        end)
        
        return true
    end)
    
    if not success then
        error("❌ ไม่สามารถสร้าง GUI ได้: " .. tostring(result))
    end
end

-- Main Startup
local function Initialize()
    print("🔄 กำลังเริ่มต้นระบบ...")
    
    -- ตรวจสอบความพร้อมของ components
    if not IsCharacterValid() then
        warn("⚠️ Character ไม่พร้อม - รอสักครู่...")
        return
    end
    
    if not PathfindingService then
        error("❌ PathfindingService ไม่พร้อม")
        return
    end
    
    -- สร้าง GUI
    local success, result = pcall(CreateGUI)
    if success then
        print("✅ พร้อมใช้งาน: กดปุ่ม 'เริ่ม' เพื่อเริ่มการเดินทาง")
    else
        warn("⚠️ เกิดข้อผิดพลาดในการสร้าง GUI:", result)
    end
end

-- เริ่มต้น
Initialize()
