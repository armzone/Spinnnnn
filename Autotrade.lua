-- Navigation System V2 - Locked Destination LocalScript
-- วางไฟล์นี้ใน StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ตัวแปรสำหรับระบบนำทาง
local isNavigating = false
local targetPosition = Vector3.new(1167, 305, -592) -- ล็อคพิกัดเป้าหมาย
local currentSpeed = 25
local connection = nil
local lastTime = 0

-- สร้าง GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NavigationV2GUI"
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 180)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Corner รูปแบบมุมโค้ง
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Navigation V2 - Auto Destination"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Locked Position Display
local positionLabel = Instance.new("TextLabel")
positionLabel.Name = "PositionLabel"
positionLabel.Size = UDim2.new(1, -20, 0, 25)
positionLabel.Position = UDim2.new(0, 10, 0, 35)
positionLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
positionLabel.BorderSizePixel = 0
positionLabel.Text = "🎯 Destination: 1167, 305, -592"
positionLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
positionLabel.TextScaled = true
positionLabel.Font = Enum.Font.SourceSansBold
positionLabel.TextXAlignment = Enum.TextXAlignment.Center
positionLabel.Parent = mainFrame

local positionCorner = Instance.new("UICorner")
positionCorner.CornerRadius = UDim.new(0, 4)
positionCorner.Parent = positionLabel

-- Speed Control
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(1, -20, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 70)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 25"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = mainFrame

local speedSlider = Instance.new("TextButton")
speedSlider.Name = "SpeedSlider"
speedSlider.Size = UDim2.new(1, -20, 0, 20)
speedSlider.Position = UDim2.new(0, 10, 0, 95)
speedSlider.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
speedSlider.BorderSizePixel = 0
speedSlider.Text = ""
speedSlider.Parent = mainFrame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 4)
sliderCorner.Parent = speedSlider

local sliderFill = Instance.new("Frame")
sliderFill.Name = "Fill"
sliderFill.Size = UDim2.new(0.44, 0, 1, 0) -- (25-5)/(50-5) = 0.44
sliderFill.Position = UDim2.new(0, 0, 0, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = speedSlider

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 4)
fillCorner.Parent = sliderFill

-- Start/Stop Buttons
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(0.45, 0, 0, 30)
startButton.Position = UDim2.new(0, 10, 0, 125)
startButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
startButton.BorderSizePixel = 0
startButton.Text = "🚀 GO!"
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextScaled = true
startButton.Font = Enum.Font.SourceSansBold
startButton.Parent = mainFrame

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 4)
startCorner.Parent = startButton

local stopButton = Instance.new("TextButton")
stopButton.Name = "StopButton"
stopButton.Size = UDim2.new(0.45, 0, 0, 30)
stopButton.Position = UDim2.new(0.55, 0, 0, 125)
stopButton.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
stopButton.BorderSizePixel = 0
stopButton.Text = "❌ STOP"
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextScaled = true
stopButton.Font = Enum.Font.SourceSansBold
stopButton.Parent = mainFrame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 4)
stopCorner.Parent = stopButton

-- ฟังก์ชันสำหรับ Speed Slider (รองรับมือถือ)
local function updateSlider(input)
    local sliderPosition = speedSlider.AbsolutePosition
    local sliderSize = speedSlider.AbsoluteSize
    local inputX = input.Position.X
    local relativeX = math.clamp((inputX - sliderPosition.X) / sliderSize.X, 0, 1)
    
    currentSpeed = math.floor(5 + (relativeX * 45)) -- 5 to 50
    speedLabel.Text = "Speed: " .. currentSpeed
    sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
end

local dragging = false

-- รองรับทั้ง PC และมือถือ
speedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        updateSlider(input)
    end
end)

speedSlider.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)

-- ฟังก์ชันสำหรับ Raycast
local function raycastGround(position)
    local character = player.Character
    if not character then return position.Y end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(position, Vector3.new(0, -100, 0), raycastParams)
    if raycastResult then
        return raycastResult.Position.Y + 5 -- สูงกว่าพื้น 5 studs
    end
    return position.Y
end

local function raycastObstacle(from, to)
    local character = player.Character
    if not character then return nil end
    
    local direction = (to - from).Unit * 10 -- ตรวจสอบ 10 studs ข้างหน้า
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(from, direction, raycastParams)
    return raycastResult
end

-- ฟังก์ชันหลักสำหรับการนำทาง
local function navigateToPosition(deltaTime)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local currentPosition = humanoidRootPart.Position
    
    -- คำนวณทิศทางและระยะทาง
    local direction = (targetPosition - currentPosition)
    local distance = direction.Magnitude
    
    -- ถ้าถึงจุดหมายแล้ว
    if distance < 3 then
        isNavigating = false
        if connection then
            connection:Disconnect()
            connection = nil
        end
        -- แจ้งเตือนเมื่อถึงจุดหมาย
        startButton.Text = "✅ ARRIVED!"
        startButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        wait(2)
        startButton.Text = "🚀 GO!"
        startButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
        return
    end
    
    -- อัพเดทระยะทางบน UI
    local distanceText = math.floor(distance) .. " studs away"
    positionLabel.Text = "🎯 Destination: 1167, 305, -592 (" .. distanceText .. ")"
    
    -- ปรับทิศทางให้เป็น Unit Vector
    direction = direction.Unit
    
    -- ตรวจสอบสิ่งกีดขวาง
    local obstacleHit = raycastObstacle(currentPosition, currentPosition + direction * 10)
    
    local nextPosition = currentPosition + direction * (currentSpeed * deltaTime)
    
    -- ถ้าเจอสิ่งกีดขวาง
    if obstacleHit then
        local obstacleHeight = obstacleHit.Position.Y
        local characterHeight = currentPosition.Y
        
        -- ถ้าสิ่งกีดขวางสูงไม่เกิน 20 studs
        if (obstacleHeight - characterHeight) < 20 then
            -- กระโดดข้ามสิ่งกีดขวาง
            nextPosition = Vector3.new(nextPosition.X, obstacleHeight + 5, nextPosition.Z)
        else
            -- หยุดถ้าสิ่งกีดขวางสูงเกินไป
            isNavigating = false
            if connection then
                connection:Disconnect()
                connection = nil
            end
            return
        end
    else
        -- ตรวจสอบพื้นผิว
        local groundY = raycastGround(nextPosition)
        nextPosition = Vector3.new(nextPosition.X, groundY, nextPosition.Z)
    end
    
    -- อัพเดท CFrame พร้อมทิศทางที่ถูกต้อง
    local lookDirection = (targetPosition - nextPosition)
    if lookDirection.Magnitude > 0 then
        -- ใช้เฉพาะแกน X และ Z สำหรับการหันหน้า
        lookDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
        local lookAtPosition = nextPosition + lookDirection
        humanoidRootPart.CFrame = CFrame.lookAt(nextPosition, lookAtPosition)
    else
        humanoidRootPart.CFrame = CFrame.new(nextPosition)
    end
end

-- ฟังก์ชันเริ่มการนำทาง
local function startNavigation()
    if isNavigating then return end
    
    -- ตรวจสอบว่ามีตัวละครหรือไม่
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        warn("Character not found!")
        return
    end
    
    isNavigating = true
    lastTime = tick()
    
    -- อัพเดท UI
    startButton.Text = "🏃‍♂️ GOING..."
    startButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    
    -- เริ่ม RunService connection พร้อม delta time
    connection = RunService.Heartbeat:Connect(function()
        local currentTime = tick()
        local deltaTime = currentTime - lastTime
        lastTime = currentTime
        
        navigateToPosition(deltaTime)
    end)
end

-- ฟังก์ชันหยุดการนำทาง
local function stopNavigation()
    isNavigating = false
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    -- รีเซ็ต UI
    startButton.Text = "🚀 GO!"
    startButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    positionLabel.Text = "🎯 Destination: 1167, 305, -592"
end

-- เชื่อม Events
startButton.MouseButton1Click:Connect(startNavigation)
stopButton.MouseButton1Click:Connect(stopNavigation)
