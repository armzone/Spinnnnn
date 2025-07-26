-- 🎮 Auto Server Hopper - ใช้กับเซิร์ฟเวอร์ Python Monitor
if game.PlaceId ~= 104715542330896 then
    warn("❌ ไม่ใช่แมพที่กำหนด สคริปต์จะไม่ทำงาน")
    return
end

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local placeId = game.PlaceId
local checkInterval = 30

-- 🌐 URL ของเซิร์ฟเวอร์ Python Monitor (แก้ไข IP ให้ตรงกับเครื่องที่รัน Python)
local monitorServerUrl = "http://185.84.161.87/api/roblox-servers"  -- 🔁 เปลี่ยน IP ให้ตรงกับเครื่องคุณ
-- local monitorServerUrl = "http://localhost:5000/api/roblox-servers"  -- ใช้บรรทัดนี้ถ้ารันบนเครื่องเดียวกัน

local killedByPlayerCount = 0
local maxPlayerKills = 1
local alreadyTeleported = false

-- ⏰ ตัวแปรสำหรับระบบการเปลี่ยนเซิร์ฟแบบจับเวลา
local autoSwitchInterval = 20 * 60 -- 20 นาที (1200 วินาที)
local serverStartTime = tick()
local lastSwitchTime = serverStartTime

print("📌 สคริปต์เริ่มทำงาน (ใช้เซิร์ฟเวอร์ Python Monitor)")
print("🌐 Monitor URL: " .. monitorServerUrl)
print("⏰ จะเปลี่ยนเซิร์ฟเวอร์อัตโนมัติทุกๆ 20 นาที")

-- 🎨 สร้าง UI แสดงเวลานับถอยหลัง
local function createTimerUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- สร้าง ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ServerTimerUI"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    
    -- สร้าง Frame หลัก
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "TimerFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 100)
    mainFrame.Position = UDim2.new(0.5, -175, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- เพิ่ม UICorner ให้ Frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- สร้าง TextLabel สำหรับหัวข้อ
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 0, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔄 Python Monitor Connection"
    titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
    titleLabel.TextSize = 14
    titleLabel.TextStrokeTransparency = 0
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame
    
    -- สร้าง TextLabel สำหรับเวลานับถอยหลัง
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, 0, 0, 40)
    timerLabel.Position = UDim2.new(0, 0, 0, 30)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "20:00"
    timerLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    timerLabel.TextSize = 28
    timerLabel.TextStrokeTransparency = 0
    timerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Parent = mainFrame
    
    -- สร้าง TextLabel สำหรับสถานะการเชื่อมต่อ
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 0, 75)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🔗 กำลังเชื่อมต่อ..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 12
    statusLabel.TextStrokeTransparency = 0
    statusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = mainFrame
    
    return timerLabel, titleLabel, statusLabel
end

-- สร้าง UI
local timerLabel, titleLabel, statusLabel = createTimerUI()

-- ✅ ฟังก์ชันแสดงเวลาที่เหลือ
local function getTimeRemaining()
    local elapsed = tick() - lastSwitchTime
    local remaining = autoSwitchInterval - elapsed
    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    return minutes, seconds, remaining
end

-- ✅ ฟังก์ชันอัพเดต UI เวลา
local function updateTimerUI()
    if timerLabel then
        local minutes, seconds, remaining = getTimeRemaining()
        if remaining > 0 then
            timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
            
            -- เปลี่ยนสีตามเวลาที่เหลือ
            if remaining <= 60 then
                timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                titleLabel.Text = "⚠️ Server Switch Soon!"
            elseif remaining <= 300 then
                timerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                titleLabel.Text = "⏰ Python Monitor Active"
            else
                timerLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                titleLabel.Text = "🔄 Python Monitor Connection"
            end
        else
            timerLabel.Text = "00:00"
            timerLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            titleLabel.Text = "🚀 Switching Server..."
        end
    end
end

-- ✅ ฟังก์ชันอัพเดตสถานะการเชื่อมต่อ
local function updateConnectionStatus(status, serverCount)
    if statusLabel then
        if status == "connected" then
            statusLabel.Text = "✅ เชื่อมต่อสำเร็จ | เซิร์ฟเวอร์: " .. (serverCount or 0)
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        elseif status == "error" then
            statusLabel.Text = "❌ เชื่อมต่อล้มเหลว | ลองใหม่..."
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            statusLabel.Text = "🔗 กำลังเชื่อมต่อ..."
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

-- ✅ ฟังก์ชันแสดงสถานะเวลา (สำหรับ console)
local function printTimeStatus()
    local minutes, seconds, remaining = getTimeRemaining()
    if remaining > 0 then
        print("⏰ เวลาที่เหลือก่อนเปลี่ยนเซิร์ฟ: " .. minutes .. " นาที " .. seconds .. " วินาที")
    else
        print("⏰ ถึงเวลาเปลี่ยนเซิร์ฟแล้ว!")
    end
end

-- ✅ ฟัง Event เมื่อล้มเหลวในการ Teleport
TeleportService.TeleportInitFailed:Connect(function(failedPlayer, teleportResult, errorMessage)
    if failedPlayer == player and not alreadyTeleported then
        warn("❌ TeleportInitFailed:", teleportResult, errorMessage)
        task.delay(2, function()
            teleportToNewServer("TeleportInitFailed")
        end)
    end
end)

-- ✅ ตรวจว่า string เป็นตัวเลขล้วน
local function isNumericName(name)
    return name:match("^%d+$") ~= nil
end

-- ✅ ตรวจว่า DeathMessage มีชื่อของผู้เล่นอื่น
local function checkIfKilledByOtherPlayer(text)
    print("🔎 กำลังตรวจสอบข้อความ: " .. text)
    local textLower = text:lower()

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local nameLower = otherPlayer.Name:lower()
            local displayLower = otherPlayer.DisplayName:lower()
            if textLower:find(nameLower) or textLower:find(displayLower) then
                print("💥 พบชื่อผู้เล่นในข้อความ:", otherPlayer.Name)
                return true, otherPlayer.Name
            end
        end
    end

    for word in string.gmatch(text, "[^%s%-]+") do
        local cleanedWord = word:gsub("[^%d]", "")
        if isNumericName(cleanedWord) and #cleanedWord >= 6 then
            print("💥 พบชื่อเป็นตัวเลขล้วน:", cleanedWord)
            return true, cleanedWord
        end
    end

    print("❌ ไม่มีชื่อผู้เล่นในข้อความ")
    return false
end

-- 🌐 ดึงข้อมูลจากเซิร์ฟเวอร์ Python Monitor และสุ่ม JobId
local function getRandomJobId()
    print("🌐 กำลังดึง JobId จากเซิร์ฟเวอร์ Python Monitor...")
    updateConnectionStatus("connecting")
    
    local success, response = pcall(function()
        return game:HttpGet(monitorServerUrl)
    end)

    if success and response then
        local serverData = HttpService:JSONDecode(response)
        local serverList = {}
        
        for _, serverInfo in pairs(serverData) do
            if serverInfo.id and serverInfo.id ~= game.JobId then
                table.insert(serverList, serverInfo.id)
                print("✅ พบ JobId: " .. serverInfo.id .. " (ผู้เล่น: " .. serverInfo.playing .. "/" .. serverInfo.maxPlayers .. ", Ping: " .. serverInfo.ping .. ")")
            end
        end
        
        if #serverList > 0 then
            updateConnectionStatus("connected", #serverList)
            print("🔁 สุ่ม JobId ใหม่จากทั้งหมด: " .. #serverList)
            return serverList[math.random(1, #serverList)]
        else
            updateConnectionStatus("error")
            warn("⚠️ ไม่มีเซิร์ฟอื่นที่ต่างจากปัจจุบัน")
        end
    else
        updateConnectionStatus("error")
        warn("❌ ดึงข้อมูลจากเซิร์ฟเวอร์ Python ไม่สำเร็จ: " .. tostring(response))
        warn("💡 ตรวจสอบว่าเซิร์ฟเวอร์ Python ทำงานอยู่และ URL ถูกต้อง")
    end
    return nil
end

-- ✅ ฟังก์ชันเทเลพอร์ตซ้ำจนกว่าจะสำเร็จ
function teleportToNewServer(reason)
    if alreadyTeleported then
        print("⚠️ ห้ามเทเลพอร์ตซ้ำ")
        return
    end

    print("🚀 เริ่มกระบวนการเปลี่ยนเซิร์ฟ เหตุผล: " .. (reason or "ไม่ระบุ"))
    
    local attempt = 0

    while not alreadyTeleported do
        attempt += 1
        local jobId = getRandomJobId()

        if jobId then
            print("🚀 [ครั้งที่ " .. attempt .. "] พยายาม teleport ไป JobId: " .. jobId)

            local success, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
            end)

            if not success then
                print("❌ pcall ล้มเหลว:", err)
                task.wait(2)
            else
                print("✅ ส่งคำสั่ง Teleport แล้ว")
                local checkTime = 0
                while checkTime < 10 do
                    if alreadyTeleported then break end
                    task.wait(1)
                    checkTime += 1
                end
                print("⚠️ ยังไม่ออกจากเซิร์ฟเวอร์เดิม ลอง teleport ใหม่")
            end
        else
            print("⚠️ ไม่มี JobId ให้เทเลพอร์ต ลองใหม่อีกครั้งใน 3 วิ")
            task.wait(3)
        end
    end
end

-- ✅ ลูปตรวจจับ GUI DeathMessage
task.spawn(function()
    while not alreadyTeleported do
        local success, err = pcall(function()
            local guiPath = player:WaitForChild("PlayerGui"):FindFirstChild("DeathScreen")
            if not guiPath then error("DeathScreen ยังไม่พบ") end

            local holder = guiPath:FindFirstChild("DeathScreenHolder")
            if not holder then error("DeathScreenHolder ยังไม่พบ") end

            local frame1 = holder:FindFirstChild("Frame")
            if not frame1 then error("Frame ชั้นที่ 1 ยังไม่พบ") end

            local frame2 = frame1:FindFirstChild("Frame") or frame1
            local deathMessage = frame2:FindFirstChild("DeathMessage")
            if not deathMessage then error("DeathMessage ยังไม่พบ") end

            print("✅ พบ DeathMessage:", deathMessage)

            deathMessage:GetPropertyChangedSignal("Text"):Connect(function()
                local newText = deathMessage.Text
                print("🔁 ตรวจพบข้อความใหม่: " .. newText)

                local killed, killerName = checkIfKilledByOtherPlayer(newText)
                if killed then
                    killedByPlayerCount += 1
                    print("💀 ถูกผู้เล่นฆ่าโดย: " .. killerName .. " (รวม " .. killedByPlayerCount .. " ครั้ง)")

                    if killedByPlayerCount >= maxPlayerKills then
                        print("⚠️ ถูกผู้เล่นฆ่าเกิน " .. maxPlayerKills .. " ครั้ง กำลังหาเซิร์ฟใหม่...")
                        teleportToNewServer("ถูกผู้เล่นฆ่าเกินกำหนด")
                    end
                else
                    print("✅ ไม่พบชื่อผู้เล่นอื่นในข้อความ")
                end
            end)
        end)

        if not success then
            warn("❌ ยังหา GUI ไม่เจอ: " .. tostring(err))
            task.wait(5)
        else
            break
        end
    end
end)

-- ✅ ลูปตรวจสอบจำนวนผู้เล่นในเซิร์ฟ
task.spawn(function()
    print("📊 เริ่มลูปตรวจสอบจำนวนผู้เล่น")
    while not alreadyTeleported do
        local currentPlayers = #Players:GetPlayers()
        print("👥 จำนวนผู้เล่นในเซิร์ฟ: " .. currentPlayers)

        if currentPlayers > 20 then
            print("⚠️ ผู้เล่นเกิน 20 คน กำลังสุ่มเซิร์ฟใหม่...")
            teleportToNewServer("ผู้เล่นเกิน 20 คน")
            break
        else
            print("✅ ยังอยู่ในเซิร์ฟที่เหมาะสม")
        end
        wait(checkInterval)
    end
end)

-- ⏰ ลูปตรวจสอบเวลาและเปลี่ยนเซิร์ฟอัตโนมัติ
task.spawn(function()
    print("⏰ เริ่มระบบการเปลี่ยนเซิร์ฟแบบจับเวลา")
    
    while not alreadyTeleported do
        local minutes, seconds, remaining = getTimeRemaining()
        
        -- อัพเดต UI ทุกวินาที
        updateTimerUI()
        
        -- แสดงเวลาที่เหลือทุก 5 นาที
        if remaining > 0 and (remaining % 300 == 0 or remaining <= 60) then
            printTimeStatus()
        end
        
        -- ถ้าเวลาหมดแล้ว ให้เปลี่ยนเซิร์ฟ
        if remaining <= 0 then
            print("⏰ ครบ 20 นาทีแล้ว! กำลังเปลี่ยนเซิร์ฟเวอร์...")
            teleportToNewServer("ครบเวลา 20 นาทีตามกำหนด")
            break
        end
        
        task.wait(1) -- ตรวจทุกวินาที
    end
end)

-- ⏰ ลูปทดสอบการเชื่อมต่อเซิร์ฟเวอร์ Python
task.spawn(function()
    print("🔗 เริ่มทดสอบการเชื่อมต่อเซิร์ฟเวอร์ Python")
    while not alreadyTeleported do
        -- ทดสอบการเชื่อมต่อทุก 2 นาที
        task.wait(120)
        
        local success, response = pcall(function()
            return game:HttpGet(monitorServerUrl)
        end)
        
        if success and response then
            local serverData = HttpService:JSONDecode(response)
            local serverCount = 0
            for _ in pairs(serverData) do
                serverCount = serverCount + 1
            end
            updateConnectionStatus("connected", serverCount)
            print("🔗 การเชื่อมต่อเซิร์ฟเวอร์ Python ปกติ (" .. serverCount .. " เซิร์ฟเวอร์)")
        else
            updateConnectionStatus("error")
            warn("⚠️ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ Python ได้")
        end
    end
end)

-- ✅ แสดงสถานะเริ่มต้น
print("🎯 ระบบทำงาน:")
print("   - เปลี่ยนเซิร์ฟเมื่อถูกผู้เล่นฆ่าเกิน " .. maxPlayerKills .. " ครั้ง")
print("   - เปลี่ยนเซิร์ฟเมื่อผู้เล่นเกิน 20 คน")
print("   - เปลี่ยนเซิร์ฟอัตโนมัติทุกๆ 20 นาที")
print("   - ดึงข้อมูลเซิร์ฟเวอร์จาก Python Monitor")
print("🎨 UI Timer แสดงอยู่ด้านบนหน้าจอแล้ว!")
print("🌐 Monitor Server: " .. monitorServerUrl)
printTimeStatus()

-- เริ่มอัพเดต UI และทดสอบการเชื่อมต่อทันที
updateTimerUI()
task.spawn(function()
    task.wait(2)
    getRandomJobId() -- ทดสอบการเชื่อมต่อครั้งแรก
end)
