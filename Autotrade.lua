-- Auto Farm System V3 LocalScript
-- วางไฟล์นี้ใน StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ตัวแปรสำหรับระบบ Auto Farm
local isRunning = false
local currentStep = 1
local targetWithdraw = 140000
local currentSpeed = 35
local connection = nil
local lastTime = 0
local navigationConnection = nil

-- พิกัดสำคัญ
local ATM_POSITION = Vector3.new(1255.526123046875, 255.31919718251953, -558.7059936523438)
local FINAL_DESTINATION = Vector3.new(1167, 305, -592)

-- ขั้นตอนการทำงาน
local STEPS = {
    [1] = "Going to ATM...",
    [2] = "Withdrawing money...",
    [3] = "Going to destination...",
    [4] = "Waiting for respawn..."
}

-- สร้าง GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmV3GUI"
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 300)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
title.Text = "🤖 Auto Farm System V3"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

-- Money Status
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Size = UDim2.new(1, -20, 0, 25)
moneyLabel.Position = UDim2.new(0, 10, 0, 45)
moneyLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
moneyLabel.BorderSizePixel = 0
moneyLabel.Text = "💰 Hand Money: $0"
moneyLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
moneyLabel.TextScaled = true
moneyLabel.Font = Enum.Font.SourceSansBold
moneyLabel.Parent = mainFrame

local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 5)
moneyCorner.Parent = moneyLabel

-- Bank Balance Status
local bankLabel = Instance.new("TextLabel")
bankLabel.Name = "BankLabel"
bankLabel.Size = UDim2.new(1, -20, 0, 25)
bankLabel.Position = UDim2.new(0, 10, 0, 75)
bankLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
bankLabel.BorderSizePixel = 0
bankLabel.Text = "🏦 Bank Balance: $0"
bankLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
bankLabel.TextScaled = true
bankLabel.Font = Enum.Font.SourceSansBold
bankLabel.Parent = mainFrame

local bankCorner = Instance.new("UICorner")
bankCorner.CornerRadius = UDim.new(0, 5)
bankCorner.Parent = bankLabel

-- Withdraw Amount
local withdrawLabel = Instance.new("TextLabel")
withdrawLabel.Name = "WithdrawLabel"
withdrawLabel.Size = UDim2.new(0.4, 0, 0, 20)
withdrawLabel.Position = UDim2.new(0, 10, 0, 110)
withdrawLabel.BackgroundTransparency = 1
withdrawLabel.Text = "Withdraw Amount:"
withdrawLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
withdrawLabel.TextScaled = true
withdrawLabel.Font = Enum.Font.SourceSans
withdrawLabel.TextXAlignment = Enum.TextXAlignment.Left
withdrawLabel.Parent = mainFrame

local withdrawInput = Instance.new("TextBox")
withdrawInput.Name = "WithdrawInput"
withdrawInput.Size = UDim2.new(0.5, 0, 0, 25)
withdrawInput.Position = UDim2.new(0.5, 0, 0, 107)
withdrawInput.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
withdrawInput.BorderSizePixel = 0
withdrawInput.Text = "140000"
withdrawInput.TextColor3 = Color3.fromRGB(255, 255, 255)
withdrawInput.TextScaled = true
withdrawInput.Font = Enum.Font.SourceSans
withdrawInput.Parent = mainFrame

local withdrawCorner = Instance.new("UICorner")
withdrawCorner.CornerRadius = UDim.new(0, 4)
withdrawCorner.Parent = withdrawInput

-- Speed Control
local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(1, -20, 0, 20)
speedLabel.Position = UDim2.new(0, 10, 0, 140)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 35"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = mainFrame

local speedSlider = Instance.new("TextButton")
speedSlider.Name = "SpeedSlider"
speedSlider.Size = UDim2.new(1, -20, 0, 20)
speedSlider.Position = UDim2.new(0, 10, 0, 165)
speedSlider.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
speedSlider.BorderSizePixel = 0
speedSlider.Text = ""
speedSlider.Parent = mainFrame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(0, 4)
sliderCorner.Parent = speedSlider

local sliderFill = Instance.new("Frame")
sliderFill.Name = "Fill"
sliderFill.Size = UDim2.new(0.66, 0, 1, 0) -- (35-5)/(50-5) = 0.66
sliderFill.Position = UDim2.new(0, 0, 0, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = speedSlider

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 4)
fillCorner.Parent = sliderFill

-- Status Display
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 195)
statusLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
statusLabel.BorderSizePixel = 0
statusLabel.Text = "⏸️ Ready to start"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 5)
statusCorner.Parent = statusLabel

-- Start/Stop Button
local startButton = Instance.new("TextButton")
startButton.Name = "StartButton"
startButton.Size = UDim2.new(1, -20, 0, 40)
startButton.Position = UDim2.new(0, 10, 0, 230)
startButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
startButton.BorderSizePixel = 0
startButton.Text = "🚀 START AUTO FARM"
startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
startButton.TextScaled = true
startButton.Font = Enum.Font.SourceSansBold
startButton.Parent = mainFrame

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 8)
startCorner.Parent = startButton

-- Reset Button
local resetButton = Instance.new("TextButton")
resetButton.Name = "ResetButton"
resetButton.Size = UDim2.new(1, -20, 0, 25)
resetButton.Position = UDim2.new(0, 10, 1, -35)
resetButton.BackgroundColor3 = Color3.fromRGB(255, 149, 0)
resetButton.BorderSizePixel = 0
resetButton.Text = "🔄 RESET"
resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
resetButton.TextScaled = true
resetButton.Font = Enum.Font.SourceSansBold
resetButton.Parent = mainFrame

local resetCorner = Instance.new("UICorner")
resetCorner.CornerRadius = UDim.new(0, 4)
resetCorner.Parent = resetButton

-- ปรับขนาด Frame ให้พอดีกับ element ใหม่
mainFrame.Size = UDim2.new(0, 350, 0, 330)

-- ฟังก์ชันสำหรับ Speed Slider
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

-- ฟังก์ชันอัพเดทยอดเงิน
local function updateMoney()
    local handMoney = 0
    local bankMoney = 0
    
    -- อ่านเงินในมือ (Hand Money)
    local success1, currentMoney = pcall(function()
        local topRightHud = playerGui:FindFirstChild("TopRightHud")
        if topRightHud then
            local holder = topRightHud:FindFirstChild("Holder")
            if holder then
                local frame = holder:FindFirstChild("Frame")
                if frame and frame:FindFirstChild("Folder") then
                    local moneyTextLabel = frame.Folder:FindFirstChild("MoneyTextLabel")
                    if moneyTextLabel then
                        local moneyText = moneyTextLabel.Text
                        local cleanText = moneyText:gsub("[%$,]", "")
                        return tonumber(cleanText) or 0
                    end
                end
            end
        end
        return 0
    end)
    
    -- อ่านเงินในธนาคาร (Bank Balance)
    local success2, bankBalance = pcall(function()
        -- หาเงินในธนาคารจาก GUI Options
        local optionsGui = playerGui:FindFirstChild("Options")
        if optionsGui then
            local uiListLayout = optionsGui:FindFirstChild("UIListLayout")
            if uiListLayout then
                local title = optionsGui:FindFirstChild("Title")
                if title then
                    local bankLabel = title:FindFirstChild("7511") -- หา TextLabel ที่แสดง Bank Balance
                    if bankLabel and bankLabel.Text then
                        local bankText = bankLabel.Text
                        -- แปลง "Bank Balance: $200" เป็น 200
                        local cleanBankText = bankText:gsub("Bank Balance: %$", ""):gsub(",", "")
                        return tonumber(cleanBankText) or 0
                    end
                end
            end
        end
        return 0
    end)
    
    if success1 then
        handMoney = currentMoney
        moneyLabel.Text = "💰 Hand Money: $" .. string.format("%,d", handMoney)
    else
        moneyLabel.Text = "💰 Hand Money: Error reading"
    end
    
    if success2 then
        bankMoney = bankBalance
        bankLabel.Text = "🏦 Bank Balance: $" .. string.format("%,d", bankMoney)
    else
        bankLabel.Text = "🏦 Bank Balance: Error reading"
    end
    
    return handMoney, bankMoney
end

-- ฟังก์ชันสำหรับ Raycast
local function raycastGround(position)
    local character = player.Character
    if not character then return position.Y end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(position, Vector3.new(0, -100, 0), raycastParams)
    if raycastResult then
        return raycastResult.Position.Y + 5
    end
    return position.Y
end

local function raycastObstacle(from, to)
    local character = player.Character
    if not character then return nil end
    
    local direction = (to - from).Unit * 10
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    
    local raycastResult = workspace:Raycast(from, direction, raycastParams)
    return raycastResult
end

-- ฟังก์ชันนำทาง
local function navigateToPosition(targetPos, deltaTime)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local humanoidRootPart = character.HumanoidRootPart
    local currentPosition = humanoidRootPart.Position
    
    local direction = (targetPos - currentPosition)
    local distance = direction.Magnitude
    
    -- ถ้าถึงจุดหมายแล้ว
    if distance < 5 then
        return true -- ถึงแล้ว
    end
    
    direction = direction.Unit
    local obstacleHit = raycastObstacle(currentPosition, currentPosition + direction * 10)
    local nextPosition = currentPosition + direction * (currentSpeed * deltaTime)
    
    if obstacleHit then
        local obstacleHeight = obstacleHit.Position.Y
        local characterHeight = currentPosition.Y
        
        if (obstacleHeight - characterHeight) < 20 then
            nextPosition = Vector3.new(nextPosition.X, obstacleHeight + 5, nextPosition.Z)
        else
            return false -- ไม่สามารถผ่านได้
        end
    else
        local groundY = raycastGround(nextPosition)
        nextPosition = Vector3.new(nextPosition.X, groundY, nextPosition.Z)
    end
    
    local lookDirection = (targetPos - nextPosition)
    if lookDirection.Magnitude > 0 then
        lookDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
        local lookAtPosition = nextPosition + lookDirection
        humanoidRootPart.CFrame = CFrame.lookAt(nextPosition, lookAtPosition)
    else
        humanoidRootPart.CFrame = CFrame.new(nextPosition)
    end
    
    return false -- ยังไม่ถึง
end

-- ฟังก์ชันถอนเงิน
local function withdrawMoney(amount)
    local success, result = pcall(function()
        local remote = ReplicatedStorage.Remotes.Get
        local arguments = {
            [1] = 7,
            [2] = "transfer_funds",
            [3] = "bank",
            [4] = "hand",
            [5] = amount
        }
        return remote:InvokeServer(unpack(arguments))
    end)
    
    return success
end

-- ฟังก์ชันหลักของ Auto Farm
local function autoFarmLoop()
    if not isRunning then return end
    
    local currentTime = tick()
    local deltaTime = currentTime - lastTime
    lastTime = currentTime
    
    if currentStep == 1 then
        -- ไปยัง ATM
        statusLabel.Text = "🏃‍♂️ " .. STEPS[1]
        statusLabel.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        
        if navigateToPosition(ATM_POSITION, deltaTime) then
            currentStep = 2
            wait(1) -- รอเครื่องเสร็จ
        end
        
    elseif currentStep == 2 then
        -- ถอนเงิน
        statusLabel.Text = "💰 " .. STEPS[2]
        statusLabel.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
        
        targetWithdraw = tonumber(withdrawInput.Text) or 140000
        local handMoney, bankMoney = updateMoney()
        local needToWithdraw = math.max(0, targetWithdraw - handMoney)
        
        if needToWithdraw > 0 then
            if withdrawMoney(needToWithdraw) then
                statusLabel.Text = "✅ Withdrew $" .. string.format("%,d", needToWithdraw)
                wait(2)
            else
                statusLabel.Text = "❌ Withdrawal failed"
                wait(2)
            end
        else
            statusLabel.Text = "✅ Already have enough money"
            wait(1)
        end
        
        currentStep = 3
        
    elseif currentStep == 3 then
        -- ไปยังจุดหมาย
        statusLabel.Text = "🎯 " .. STEPS[3]
        statusLabel.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
        
        if navigateToPosition(FINAL_DESTINATION, deltaTime) then
            currentStep = 4
        end
        
    elseif currentStep == 4 then
        -- รอ respawn
        statusLabel.Text = "⏳ " .. STEPS[4]
        statusLabel.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
        
        -- ตรวจสอบว่า respawn หรือไม่
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            -- รอ respawn เสร็จ
            wait(3)
            currentStep = 1 -- เริ่มใหม่
            statusLabel.Text = "🔄 Restarting cycle..."
        end
    end
end

-- ฟังก์ชันเริ่ม/หยุด Auto Farm
local function toggleAutoFarm()
    if isRunning then
        -- หยุด
        isRunning = false
        currentStep = 1
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        startButton.Text = "🚀 START AUTO FARM"
        startButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        statusLabel.Text = "⏸️ Auto Farm stopped"
        statusLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    else
        -- เริ่ม
        isRunning = true
        lastTime = tick()
        
        connection = RunService.Heartbeat:Connect(autoFarmLoop)
        
        startButton.Text = "⏹️ STOP AUTO FARM"
        startButton.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
        statusLabel.Text = "🤖 Auto Farm started!"
        statusLabel.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    end
end

-- ฟังก์ชันรีเซ็ต
local function resetSystem()
    isRunning = false
    currentStep = 1
    
    if connection then
        connection:Disconnect()
        connection = nil
    end
    
    startButton.Text = "🚀 START AUTO FARM"
    startButton.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    statusLabel.Text = "🔄 System reset"
    statusLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
end

-- อัพเดทเงินทุก 2 วินาที
spawn(function()
    while screenGui.Parent do
        updateMoney()
        wait(2)
    end
end)

-- เชื่อม Events
startButton.MouseButton1Click:Connect(toggleAutoFarm)
resetButton.MouseButton1Click:Connect(resetSystem)

-- ตรวจจับ Character Spawn
player.CharacterAdded:Connect(function()
    wait(2) -- รอให้ character โหลดเสร็จ
    if isRunning and currentStep == 4 then
        currentStep = 1 -- เริ่มรอบใหม่
    end
end)
