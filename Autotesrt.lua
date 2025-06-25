-- DirtBike Navigation System LocalScript
-- วางไฟล์นี้ใน StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ตัวแปรสำหรับระบบนำทาง
local isNavigating = false
local targetPosition = nil
local currentSpeed = 25
local connection = nil
local lastTime = 0
local currentVehicle = nil

-- สร้าง GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DirtBikeNavigationGUI"
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 250)
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
title.Text = "DirtBike Navigation"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Vehicle Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 35)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Not in vehicle"
statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSans
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

-- Vector3 Input
local positionLabel = Instance.new("TextLabel")
positionLabel.Name = "PositionLabel"
positionLabel.Size = UDim2.new(1, -20, 0, 20)
positionLabel.Position = UDim2.new(0, 10, 0, 65)
positionLabel.BackgroundTransparency = 1
positionLabel.Text = "Target Position (X, Y, Z):"
positionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
positionLabel.TextScaled = true
positionLabel.Font = Enum.Font.SourceSans
positionLabel.TextXAlignment = Enum.TextXAlignment.Left
positionLabel.Parent = mainFrame

local positionInput = Instance.new("TextBox")
positionInput.Name = "PositionInput"
positionInput.Size = UDim2.new(1, -20, 0, 25)
positionInput.Position = UDim2.new(0, 10, 0, 90)
positionInput.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
positionInput.BorderSizePixel = 0
positionInput.Text = "0, 0, 0"
positionInput.TextColor3 = Color3.fromRGB(255, 255, 255)
positionInput.TextScaled = true
positionInput.Font = Enum.Font.SourceSans
positionInput.Parent = mainFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 4)
inputCorner.Parent = positionInput

-- Speed Control
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(1, -20, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 125)
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
speedSlider.Position = UDim2.new(0, 10, 0, 150)
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
startButton.Position = UDim2.new(0, 10, 0, 180)
startButton.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
startButton.BorderSizePixel = 0
startButton.Text = "Start"
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
stopButton.Position = UDim2.new(0.55, 0, 0, 180)
stopButton.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
stopButton.BorderSizePixel = 0
stopButton.Text = "Stop"
stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
stopButton.TextScaled = true
stopButton.Font = Enum.Font.SourceSansBold
stopButton.Parent = mainFrame

local stopCorner = Instance.new("UICorner")
stopCorner.CornerRadius = UDim.new(0, 4)
stopCorner.Parent = stopButton

-- Reset Button
local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(1, -20, 0, 25)
resetButton.Position = UDim2.new(0, 10, 1, -35)
resetButton.BackgroundColor3 = Color3.fromRGB(255, 149, 0)
resetButton.BorderSizePixel = 0
resetButton.Text = "Reset GUI"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.TextScaled = true
resetButton.Font = Enum.Font.SourceSansBold
resetButton.Parent = mainFrame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 4)
resetCorner.Parent = resetButton

-- ฟังก์ชันสำหรับ Speed Slider
local function updateSlider(input)
    local sliderPosition = speedSlider.AbsolutePosition
    local sliderSize = speedSlider.AbsoluteSize
    local mouseX = input.Position.X
    local relativeX = math.clamp((mouseX - sliderPosition.X) / sliderSize.X, 0, 1)
    
    currentSpeed = math.floor(5 + (relativeX * 45)) -- 5 to 50
    speedLabel.Text = "Speed: " .. currentSpeed
    sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
end

local dragging = false
speedSlider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        updateSlider(input)
    end
end)

speedSlider.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSlider(input)
    end
end)

-- ฟังก์ชันตรวจสอบรถ
local function findDirtBike()
    local character = player.Character
    if not character then return nil end
    
    -- ตรวจสอบว่าผู้เล่นนั่งใน VehicleSeat หรือไม่
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or not humanoid.SeatPart then return nil end
    
    local seat = humanoid.SeatPart
    if seat.Name ~= "DriverSeat" then return nil end
    
    -- หา DirtBike Model
    local vehicle = seat.Parent
    if vehicle.Name ~= "DirtBike" then return nil end
    
    -- ตรวจสอบว่ามี Chassis หรือไม่
    local chassis = vehicle:FindFirstChild("Chassis")
    if not chassis then return nil end
    
    return {
        model = vehicle,
        chassis = chassis,
        driverSeat = seat
    }
end

-- ฟังก์ชันอัพเดทสถานะ
local function updateVehicleStatus()
    local vehicle = findDirtBike()
    if vehicle then
        currentVehicle = vehicle
        statusLabel.Text = "Status: In DirtBike ✓"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        currentVehicle = nil
        statusLabel.Text = "Status: Not in DirtBike"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        -- หยุดการนำทางถ้าไม่ได้อยู่ในรถ
        if isNavigating then
            stopNavigation()
        end
    end
end

-- ฟังก์ชันสำหรับ Raycast
local function raycastGround(position)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {currentVehicle.model}
    
    local raycastResult = workspace:Raycast(position, Vector3.new(0, -100, 0), raycastParams)
    if raycastResult then
        return raycastResult.Position.Y + 5 -- สูงกว่าพื้น 5 studs
    end
    return position.Y
end

local function raycastObstacle(from, to)
    local direction = (to - from).Unit * 15 -- ตรวจสอบ 15 studs ข้างหน้า (เพิ่มจาก 10)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {currentVehicle.model}
    
    local raycastResult = workspace:Raycast(from, direction, raycastParams)
    return raycastResult
end

-- ฟังก์ชันหลักสำหรับการนำทาง
local function navigateToPosition(deltaTime)
    if not currentVehicle then
        stopNavigation()
        return
    end
    
    local chassis = currentVehicle.chassis
    local currentPosition = chassis.Position
    
    -- คำนวณทิศทางและระยะทาง
    local direction = (targetPosition - currentPosition)
    local distance = direction.Magnitude
    
    -- ถ้าถึงจุดหมายแล้ว
    if distance < 5 then -- เพิ่มระยะหยุดสำหรับรถ
        isNavigating = false
        if connection then
            connection:Disconnect()
            connection = nil
        end
        return
    end
    
    -- ปรับทิศทางให้เป็น Unit Vector
    direction = direction.Unit
    
    -- ตรวจสอบสิ่งกีดขวาง
    local obstacleHit = raycastObstacle(currentPosition, currentPosition + direction * 15)
    
    local nextPosition = currentPosition + direction * (currentSpeed * deltaTime)
    
    -- ถ้าเจอสิ่งกีดขวาง
    if obstacleHit then
        local obstacleHeight = obstacleHit.Position.Y
        local vehicleHeight = currentPosition.Y
        
        -- ถ้าสิ่งกีดขวางสูงไม่เกิน 20 studs (รถมอเตอร์ไซค์กระโดดได้!)
        if (obstacleHeight - vehicleHeight) < 20 then
            -- กระโดดข้ามสิ่งกีดขวาง
            nextPosition = Vector3.new(nextPosition.X, obstacleHeight + 8, nextPosition.Z) -- เพิ่มความสูงเป็น 8
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
        chassis.CFrame = CFrame.lookAt(nextPosition, lookAtPosition)
    else
        chassis.CFrame = CFrame.new(nextPosition)
    end
end

-- ฟังก์ชันเริ่มการนำทาง
local function startNavigation()
    if not currentVehicle then
        warn("Please sit in DirtBike first!")
        return
    end
    
    if isNavigating then return end
    
    -- แปลง input เป็น Vector3
    local inputText = positionInput.Text
    local x, y, z = inputText:match("([^,]+),([^,]+),([^,]+)")
    
    if not x or not y or not z then
        warn("Invalid position format. Use: X, Y, Z")
        return
    end
    
    targetPosition = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
    isNavigating = true
    lastTime = tick()
    
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
end

-- ฟังก์ชันรีเซ็ต GUI
local function resetGUI()
    stopNavigation()
    screenGui:Destroy()
    
    wait(0.1)
    
    local success, errorMessage = pcall(function()
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui.Name == "DirtBikeNavigationGUI" then
                gui:Destroy()
            end
        end
    end)
    
    warn("DirtBike Navigation GUI Reset! Please run the script again.")
end

-- อัพเดทสถานะรถทุก 0.5 วินาที
spawn(function()
    while screenGui.Parent do
        updateVehicleStatus()
        wait(0.5)
    end
end)

-- เชื่อม Events
startButton.MouseButton1Click:Connect(startNavigation)
stopButton.MouseButton1Click:Connect(stopNavigation)
resetButton.MouseButton1Click:Connect(resetGUI)
