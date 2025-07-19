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
local firebaseUrl = "https://jobid-1e3dc-default-rtdb.asia-southeast1.firebasedatabase.app/roblox_servers.json"

local killedByPlayerCount = 0
local maxPlayerKills = 1
local alreadyTeleported = false

-- ⏰ ตัวแปรสำหรับระบบการเปลี่ยนเซิร์ฟแบบจับเวลา
local autoSwitchInterval = 20 * 60 -- 20 นาที (1200 วินาที)
local serverStartTime = tick()
local lastSwitchTime = serverStartTime

print("📌 สคริปต์เริ่มทำงาน")
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
    mainFrame.Size = UDim2.new(0, 300, 0, 80)
    mainFrame.Position = UDim2.new(0.5, -150, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- เพิ่ม UICorner ให้ Frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- เพิ่มเงาให้ Frame
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, -3, 0, -3)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.ZIndex = mainFrame.ZIndex - 1
    shadow.Parent = mainFrame
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 15)
    shadowCorner.Parent = shadow
    
    -- สร้าง TextLabel สำหรับหัวข้อ
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Position = UDim2.new(0, 0, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🔄 Server Auto Switch"
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
    
    -- เพิ่มเอฟเฟกต์เรืองแสง
    local function addGlowEffect(textLabel)
        -- สร้างเงาเรืองแสงหลายชั้น
        for i = 1, 3 do
            local glowLabel = textLabel:Clone()
            glowLabel.Name = "GlowEffect" .. i
            glowLabel.TextTransparency = 0.7 - (i * 0.2)
            glowLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
            glowLabel.TextSize = textLabel.TextSize + (i * 2)
            glowLabel.ZIndex = textLabel.ZIndex - i
            glowLabel.Parent = textLabel.Parent
        end
    end
    
    addGlowEffect(timerLabel)
    
    return timerLabel, titleLabel
end

-- สร้าง UI
local timerLabel, titleLabel = createTimerUI()

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
                -- สีแดงเมื่อเหลือน้อยกว่า 1 นาที
                timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                titleLabel.Text = "⚠️ Server Switch Soon!"
                titleLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
            elseif remaining <= 300 then
                -- สีเหลืองเมื่อเหลือน้อยกว่า 5 นาที
                timerLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                titleLabel.Text = "⏰ Server Auto Switch"
                titleLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
            else
                -- สีฟ้าปกติ
                timerLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                titleLabel.Text = "🔄 Server Auto Switch"
                titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
            end
        else
            timerLabel.Text = "00:00"
            timerLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            titleLabel.Text = "🚀 Switching Server..."
            titleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
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

-- ✅ ฟัง Event เมื่อล้มเหลวในการ Teleport (เช่น Error 773)
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

-- ✅ ตรวจว่า DeathMessage มีชื่อของผู้เล่นอื่น (รวมถึงชื่อเป็นเลขล้วน)
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

-- ✅ ดึงข้อมูลจาก Firebase และสุ่ม JobId
local function getRandomJobId()
    print("🌐 กำลังดึง JobId จาก Firebase...")
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(firebaseUrl))
    end)

    if success and response then
        local serverList = {}
        for _, serverData in pairs(response) do
            if serverData.id and serverData.id ~= game.JobId then
                table.insert(serverList, serverData.id)
                print("✅ พบ JobId: " .. serverData.id)
            end
        end
        if #serverList > 0 then
            print("🔁 สุ่ม JobId ใหม่จากทั้งหมด: " .. #serverList)
            return serverList[math.random(1, #serverList)]
        else
            warn("⚠️ ไม่มีเซิร์ฟอื่นที่ต่างจากปัจจุบัน")
        end
    else
        warn("❌ ดึงข้อมูล Firebase ไม่สำเร็จ: " .. tostring(response))
    end
    return nil
end

-- ✅ ฟังก์ชันเทเลพอร์ตซ้ำจนกว่าจะสำเร็จ (รอ Event ตัดสินผล)
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
                print("✅ ส่งคำสั่ง Teleport แล้ว (แต่ยังไม่ถือว่าสำเร็จ)")
                -- 🔁 ตรวจทุก 5 วินาที ถ้ายังอยู่ในเซิร์ฟ แปลว่า teleport fail
                local checkTime = 0
                while checkTime < 10 do
                    if alreadyTeleported then break end
                    task.wait(1)
                    checkTime += 1
                end

                -- ถ้ายังอยู่ → ลองใหม่
                print("⚠️ ยังไม่ออกจากเซิร์ฟเวอร์เดิม ลอง teleport ใหม่")
            end
        else
            print("⚠️ ไม่มี JobId ให้เทเลพอร์ต ลองใหม่อีกครั้งใน 3 วิ")
            task.wait(3)
        end
    end
end

-- ✅ ลูปตรวจจับ GUI DeathMessage อย่างปลอดภัยและต่อเนื่อง
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
                    print("✅ ไม่พบชื่อผู้เล่นอื่นในข้อความ (ไม่ถูกนับ)")
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

        if currentPlayers > 15 then
            print("⚠️ ผู้เล่นเกิน 10 คน กำลังสุ่มเซิร์ฟใหม่...")
            teleportToNewServer("ผู้เล่นเกิน 10 คน")
            break
        else
            print("✅ ยังอยู่ในเซิร์ฟที่เหมาะสม")
        end
        wait(checkInterval)
    end
end)

-- ⏰ ลูปใหม่: ตรวจสอบเวลาและเปลี่ยนเซิร์ฟอัตโนมัติทุกๆ 20 นาที
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

-- ✅ แสดงสถานะเริ่มต้น
print("🎯 ระบบทำงาน:")
print("   - เปลี่ยนเซิร์ฟเมื่อถูกผู้เล่นฆ่าเกิน " .. maxPlayerKills .. " ครั้ง")
print("   - เปลี่ยนเซิร์ฟเมื่อผู้เล่นเกิน 10 คน")
print("   - เปลี่ยนเซิร์ฟอัตโนมัติทุกๆ 20 นาที")
print("🎨 UI Timer แสดงอยู่ด้านบนหน้าจอแล้ว!")
printTimeStatus()

-- เริ่มอัพเดต UI ทันที
updateTimerUI()
