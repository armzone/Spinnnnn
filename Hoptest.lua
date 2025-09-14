-- 🎮 Auto Server Hopper - ใช้กับเซิร์ฟเวอร์ Python Monitor (มี Delay หลังโดนฆ่า)
-- 🔧 การตั้งค่าที่สามารถปรับได้ขณะทำงาน
if game.PlaceId ~= 104715542330896 then
    warn("❌ ไม่ใช่แมพที่กำหนด สคริปต์จะไม่ทำงาน")
    return
end

-- 🌟 ตัวแปรที่สามารถปรับได้ผ่าน _G (เปลี่ยนได้ขณะทำงาน)
_G.ServerHopperConfig = _G.ServerHopperConfig or {
    -- ⏰ เวลาการเปลี่ยนเซิร์ฟอัตโนมัติ (นาที)
    autoSwitchMinutes = 60,
    
    -- 💀 จำนวนครั้งที่ถูกผู้เล่นฆ่าก่อนเปลี่ยนเซิร์ฟ
    maxPlayerKills = 1,
    
    -- ⏱️ เวลารอหลังโดนฆ่าก่อนย้ายเซิร์ฟ (วินาที)
    killDelaySeconds = 15,
    
    -- 👥 จำนวนผู้เล่นสูงสุดในเซิร์ฟ
    maxPlayersInServer = 16,
    
    -- ⏱️ ช่วงเวลาตรวจสอบผู้เล่น (วินาที)
    playerCheckInterval = 30,
    
    -- ⏱️ ช่วงเวลาทดสอบการเชื่อมต่อ Python Server (วินาที)
    connectionTestInterval = 120,
    
    -- 🌐 URL ของเซิร์ฟเวอร์ Python Monitor
    monitorServerUrl = "http://185.84.160.178/api/roblox-servers",
    
    -- 🎨 การแสดงผล UI
    showUI = true,
    
    -- 📊 การแสดงผลใน Console
    verboseLogging = false
}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local placeId = game.PlaceId
local killedByPlayerCount = 0
local alreadyTeleported = false
local killDelayActive = false -- ตัวแปรสำหรับเช็ค delay หลังโดนฆ่า

-- ⏰ ตัวแปรสำหรับระบบการเปลี่ยนเซิร์ฟแบบจับเวลา
local serverStartTime = tick()
local lastSwitchTime = serverStartTime

-- 🎯 UI Elements
local timerLabel, titleLabel, statusLabel, mainFrame, killDelayLabel

print("📌 สคริปต์เริ่มทำงาน (ใช้เซิร์ฟเวอร์ Python Monitor)")
print("🔧 การตั้งค่าปัจจุบัน:")
print("   ⏰ เปลี่ยนเซิร์ฟอัตโนมัติทุกๆ: " .. _G.ServerHopperConfig.autoSwitchMinutes .. " นาที")
print("   💀 เปลี่ยนเซิร์ฟเมื่อถูกฆ่า: " .. _G.ServerHopperConfig.maxPlayerKills .. " ครั้ง")
print("   ⏱️ รอหลังโดนฆ่า: " .. _G.ServerHopperConfig.killDelaySeconds .. " วินาที")
print("   👥 เปลี่ยนเซิร์ฟเมื่อผู้เล่นเกิน: " .. _G.ServerHopperConfig.maxPlayersInServer .. " คน")
print("🌐 Monitor URL: " .. _G.ServerHopperConfig.monitorServerUrl)
print("")
print("💡 วิธีเปลี่ยนการตั้งค่าขณะทำงาน:")
print("   _G.ServerHopperConfig.autoSwitchMinutes = 30  -- เปลี่ยนเป็น 30 นาที")
print("   _G.ServerHopperConfig.maxPlayerKills = 3      -- เปลี่ยนเป็น 3 ครั้ง")
print("   _G.ServerHopperConfig.killDelaySeconds = 20   -- รอ 20 วินาทีหลังโดนฆ่า")
print("   _G.ServerHopperConfig.maxPlayersInServer = 10 -- เปลี่ยนเป็น 10 คน")
print("   _G.ServerHopperConfig.showUI = false          -- ซ่อน UI")

-- 🎨 สร้าง UI แสดงเวลานับถอยหลัง
local function createTimerUI()
    if not _G.ServerHopperConfig.showUI then return end
    
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- ลบ UI เก่าถ้ามี
    local existingUI = playerGui:FindFirstChild("ServerTimerUI")
    if existingUI then existingUI:Destroy() end
    
    -- สร้าง ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ServerTimerUI"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    
    -- สร้าง Frame หลัก (เพิ่มขนาดสำหรับ Kill Delay)
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "TimerFrame"
    mainFrame.Size = UDim2.new(0, 380, 0, 140) -- เพิ่มความสูง
    mainFrame.Position = UDim2.new(0.5, -190, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- เพิ่ม UICorner ให้ Frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- สร้าง TextLabel สำหรับหัวข้อ
    titleLabel = Instance.new("TextLabel")
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
    timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, 0, 0, 35)
    timerLabel.Position = UDim2.new(0, 0, 0, 30)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = _G.ServerHopperConfig.autoSwitchMinutes .. ":00"
    timerLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    timerLabel.TextSize = 24
    timerLabel.TextStrokeTransparency = 0
    timerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Parent = mainFrame
    
    -- สร้าง TextLabel สำหรับ Kill Delay Countdown
    killDelayLabel = Instance.new("TextLabel")
    killDelayLabel.Name = "KillDelayLabel"
    killDelayLabel.Size = UDim2.new(1, 0, 0, 20)
    killDelayLabel.Position = UDim2.new(0, 0, 0, 65)
    killDelayLabel.BackgroundTransparency = 1
    killDelayLabel.Text = ""
    killDelayLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
    killDelayLabel.TextSize = 12
    killDelayLabel.TextStrokeTransparency = 0
    killDelayLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    killDelayLabel.Font = Enum.Font.GothamBold
    killDelayLabel.Parent = mainFrame
    
    -- สร้าง TextLabel สำหรับสถานะการเชื่อมต่อ
    statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 0, 90)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "🔗 กำลังเชื่อมต่อ..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 12
    statusLabel.TextStrokeTransparency = 0
    statusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = mainFrame
    
    -- สร้าง TextLabel สำหรับการตั้งค่า
    local configLabel = Instance.new("TextLabel")
    configLabel.Name = "ConfigLabel"
    configLabel.Size = UDim2.new(1, 0, 0, 20)
    configLabel.Position = UDim2.new(0, 0, 0, 115)
    configLabel.BackgroundTransparency = 1
    configLabel.Text = "⚙️ เปลี่ยนเซิร์ฟ: " .. _G.ServerHopperConfig.autoSwitchMinutes .. "นาที | ฆ่า: " .. _G.ServerHopperConfig.maxPlayerKills .. "ครั้ง | รอ: " .. _G.ServerHopperConfig.killDelaySeconds .. "วิ | คน: " .. _G.ServerHopperConfig.maxPlayersInServer
    configLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    configLabel.TextSize = 10
    configLabel.TextStrokeTransparency = 0
    configLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    configLabel.Font = Enum.Font.Gotham
    configLabel.Parent = mainFrame
    
    return timerLabel, titleLabel, statusLabel, configLabel, killDelayLabel
end

-- ✅ ฟังก์ชันแสดงเวลาที่เหลือ
local function getTimeRemaining()
    local autoSwitchInterval = _G.ServerHopperConfig.autoSwitchMinutes * 60 -- แปลงเป็นวินาที
    local elapsed = tick() - lastSwitchTime
    local remaining = autoSwitchInterval - elapsed
    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    return minutes, seconds, remaining
end

-- ✅ ฟังก์ชันอัพเดต Kill Delay UI
local function updateKillDelayUI(remainingSeconds)
    if not _G.ServerHopperConfig.showUI or not killDelayLabel then return end
    
    if remainingSeconds > 0 then
        killDelayLabel.Text = "💀 กำลังรอย้ายเซิร์ฟ: " .. remainingSeconds .. " วินาที..."
        killDelayLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        killDelayLabel.Text = ""
    end
end

-- ✅ ฟังก์ชันอัพเดต UI เวลา
local function updateTimerUI()
    if not _G.ServerHopperConfig.showUI or not timerLabel then return end
    
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
    
    -- อัพเดตข้อมูลการตั้งค่า
    local configLabel = mainFrame and mainFrame:FindFirstChild("ConfigLabel")
    if configLabel then
        configLabel.Text = "⚙️ เปลี่ยนเซิร์ฟ: " .. _G.ServerHopperConfig.autoSwitchMinutes .. "นาที | ฆ่า: " .. _G.ServerHopperConfig.maxPlayerKills .. "ครั้ง | รอ: " .. _G.ServerHopperConfig.killDelaySeconds .. "วิ | คน: " .. _G.ServerHopperConfig.maxPlayersInServer
    end
end

-- ✅ ฟังก์ชันอัพเดตสถานะการเชื่อมต่อ
local function updateConnectionStatus(status, serverCount)
    if not _G.ServerHopperConfig.showUI or not statusLabel then return end
    
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

-- ✅ ฟังก์ชันแสดงสถานะเวลา (สำหรับ console)
local function printTimeStatus()
    if not _G.ServerHopperConfig.verboseLogging then return end
    
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
    if _G.ServerHopperConfig.verboseLogging then
        print("🔎 กำลังตรวจสอบข้อความ: " .. text)
    end
    local textLower = text:lower()

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local nameLower = otherPlayer.Name:lower()
            local displayLower = otherPlayer.DisplayName:lower()
            if textLower:find(nameLower) or textLower:find(displayLower) then
                if _G.ServerHopperConfig.verboseLogging then
                    print("💥 พบชื่อผู้เล่นในข้อความ:", otherPlayer.Name)
                end
                return true, otherPlayer.Name
            end
        end
    end

    for word in string.gmatch(text, "[^%s%-]+") do
        local cleanedWord = word:gsub("[^%d]", "")
        if isNumericName(cleanedWord) and #cleanedWord >= 6 then
            if _G.ServerHopperConfig.verboseLogging then
                print("💥 พบชื่อเป็นตัวเลขล้วน:", cleanedWord)
            end
            return true, cleanedWord
        end
    end

    if _G.ServerHopperConfig.verboseLogging then
        print("❌ ไม่มีชื่อผู้เล่นในข้อความ")
    end
    return false
end

-- 🌐 ดึงข้อมูลจากเซิร์ฟเวอร์ Python Monitor และสุ่ม JobId
local function getRandomJobId()
    if _G.ServerHopperConfig.verboseLogging then
        print("🌐 กำลังดึง JobId จากเซิร์ฟเวอร์ Python Monitor...")
    end
    updateConnectionStatus("connecting")
    
    local success, response = pcall(function()
        return game:HttpGet(_G.ServerHopperConfig.monitorServerUrl)
    end)

    if success and response then
        local serverData = HttpService:JSONDecode(response)
        local serverList = {}
        
        for _, serverInfo in pairs(serverData) do
            if serverInfo.id and serverInfo.id ~= game.JobId then
                table.insert(serverList, serverInfo.id)
                if _G.ServerHopperConfig.verboseLogging then
                    print("✅ พบ JobId: " .. serverInfo.id .. " (ผู้เล่น: " .. serverInfo.playing .. "/" .. serverInfo.maxPlayers .. ", Ping: " .. serverInfo.ping .. ")")
                end
            end
        end
        
        if #serverList > 0 then
            updateConnectionStatus("connected", #serverList)
            if _G.ServerHopperConfig.verboseLogging then
                print("🔁 สุ่ม JobId ใหม่จากทั้งหมด: " .. #serverList)
            end
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

-- ✅ ฟังก์ชัน Kill Delay พร้อม Countdown
local function startKillDelay()
    if killDelayActive then return end -- ถ้า delay อยู่แล้วไม่ต้องเริ่มใหม่
    
    killDelayActive = true
    local remainingTime = _G.ServerHopperConfig.killDelaySeconds
    
    print("⏳ รอ " .. _G.ServerHopperConfig.killDelaySeconds .. " วินาที ก่อนย้ายเซิร์ฟเวอร์...")
    
    -- สร้าง countdown loop
    task.spawn(function()
        while remainingTime > 0 and killDelayActive do
            updateKillDelayUI(remainingTime)
            task.wait(1)
            remainingTime -= 1
        end
        
        -- หลังจากเวลาผ่านไป
        if killDelayActive then
            updateKillDelayUI(0)
            print("⏰ ครบเวลารอแล้ว! กำลังเปลี่ยนเซิร์ฟเวอร์...")
            teleportToNewServer("ถูกผู้เล่นฆ่าเกินกำหนด (หลังรอ " .. _G.ServerHopperConfig.killDelaySeconds .. " วินาที)")
            killDelayActive = false
        end
    end)
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
                if _G.ServerHopperConfig.verboseLogging then
                    print("🔁 ตรวจพบข้อความใหม่: " .. newText)
                end

                local killed, killerName = checkIfKilledByOtherPlayer(newText)
                if killed then
                    killedByPlayerCount += 1
                    print("💀 ถูกผู้เล่นฆ่าโดย: " .. killerName .. " (รวม " .. killedByPlayerCount .. " ครั้ง)")

                    if killedByPlayerCount >= _G.ServerHopperConfig.maxPlayerKills then
                        print("⚠️ ถูกผู้เล่นฆ่าเกิน " .. _G.ServerHopperConfig.maxPlayerKills .. " ครั้ง")
                        startKillDelay() -- เริ่มนับถอยหลังแทนการย้ายทันที
                    end
                else
                    if _G.ServerHopperConfig.verboseLogging then
                        print("✅ ไม่พบชื่อผู้เล่นอื่นในข้อความ")
                    end
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
    if _G.ServerHopperConfig.verboseLogging then
        print("📊 เริ่มลูปตรวจสอบจำนวนผู้เล่น")
    end
    while not alreadyTeleported do
        local currentPlayers = #Players:GetPlayers()
        if _G.ServerHopperConfig.verboseLogging then
            print("👥 จำนวนผู้เล่นในเซิร์ฟ: " .. currentPlayers)
        end

        if currentPlayers > _G.ServerHopperConfig.maxPlayersInServer then
            print("⚠️ ผู้เล่นเกิน " .. _G.ServerHopperConfig.maxPlayersInServer .. " คน กำลังสุ่มเซิร์ฟใหม่...")
            teleportToNewServer("ผู้เล่นเกิน " .. _G.ServerHopperConfig.maxPlayersInServer .. " คน")
            break
        else
            if _G.ServerHopperConfig.verboseLogging then
                print("✅ ยังอยู่ในเซิร์ฟที่เหมาะสม")
            end
        end
        wait(_G.ServerHopperConfig.playerCheckInterval)
    end
end)

-- ⏰ ลูปตรวจสอบเวลาและเปลี่ยนเซิร์ฟอัตโนมัติ
task.spawn(function()
    if _G.ServerHopperConfig.verboseLogging then
        print("⏰ เริ่มระบบการเปลี่ยนเซิร์ฟแบบจับเวลา")
    end
    
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
            print("⏰ ครบ " .. _G.ServerHopperConfig.autoSwitchMinutes .. " นาทีแล้ว! กำลังเปลี่ยนเซิร์ฟเวอร์...")
            teleportToNewServer("ครบเวลา " .. _G.ServerHopperConfig.autoSwitchMinutes .. " นาทีตามกำหนด")
            break
        end
        
        task.wait(1) -- ตรวจทุกวินาที
    end
end)

-- ⏰ ลูปทดสอบการเชื่อมต่อเซิร์ฟเวอร์ Python
task.spawn(function()
    if _G.ServerHopperConfig.verboseLogging then
        print("🔗 เริ่มทดสอบการเชื่อมต่อเซิร์ฟเวอร์ Python")
    end
    while not alreadyTeleported do
        -- ทดสอบการเชื่อมต่อตามช่วงเวลาที่กำหนด
        task.wait(_G.ServerHopperConfig.connectionTestInterval)
        
        local success, response = pcall(function()
            return game:HttpGet(_G.ServerHopperConfig.monitorServerUrl)
        end)
        
        if success and response then
            local serverData = HttpService:JSONDecode(response)
            local serverCount = 0
            for _ in pairs(serverData) do
                serverCount = serverCount + 1
            end
            updateConnectionStatus("connected", serverCount)
            if _G.ServerHopperConfig.verboseLogging then
                print("🔗 การเชื่อมต่อเซิร์ฟเวอร์ Python ปกติ (" .. serverCount .. " เซิร์ฟเวอร์)")
            end
        else
            updateConnectionStatus("error")
            warn("⚠️ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ Python ได้")
        end
    end
end)

-- 🔧 ฟังก์ชันสำหรับรีเซ็ตเวลานับถอยหลัง
_G.resetServerTimer = function()
    lastSwitchTime = tick()
    print("🔄 รีเซ็ตเวลานับถอยหลังแล้ว")
    if _G.ServerHopperConfig.showUI then
        updateTimerUI()
    end
end

-- 🔧 ฟังก์ชันสำหรับเปลี่ยนเซิร์ฟทันที
_G.switchServerNow = function()
    print("🚀 กำลังเปลี่ยนเซิร์ฟเวอร์ทันที...")
    teleportToNewServer("คำสั่งเปลี่ยนเซิร์ฟทันที")
end

-- 🔧 ฟังก์ชันสำหรับยกเลิก Kill Delay
_G.cancelKillDelay = function()
    if killDelayActive then
        killDelayActive = false
        updateKillDelayUI(0)
        print("🛑 ยกเลิกการรอหลังโดนฆ่าแล้ว")
    else
        print("⚠️ ไม่มีการรออยู่")
    end
end

-- 🔧 ฟังก์ชันสำหรับรีเซ็ตจำนวนครั้งที่โดนฆ่า
_G.resetKillCount = function()
    killedByPlayerCount = 0
    killDelayActive = false
    updateKillDelayUI(0)
    print("🔄 รีเซ็ตจำนวนครั้งที่โดนฆ่าแล้ว")
end

-- 🔧 ฟังก์ชันสำหรับแสดงการตั้งค่าปัจจุบัน
_G.showConfig = function()
    print("🔧 การตั้งค่าปัจจุบัน:")
    print("   ⏰ เปลี่ยนเซิร์ฟอัตโนมัติทุกๆ: " .. _G.ServerHopperConfig.autoSwitchMinutes .. " นาที")
    print("   💀 เปลี่ยนเซิร์ฟเมื่อถูกฆ่า: " .. _G.ServerHopperConfig.maxPlayerKills .. " ครั้ง")
    print("   ⏱️ รอหลังโดนฆ่า: " .. _G.ServerHopperConfig.killDelaySeconds .. " วินาที")
    print("   👥 เปลี่ยนเซิร์ฟเมื่อผู้เล่นเกิน: " .. _G.ServerHopperConfig.maxPlayersInServer .. " คน")
    print("   ⏱️ ตรวจสอบผู้เล่นทุกๆ: " .. _G.ServerHopperConfig.playerCheckInterval .. " วินาที")
    print("   🔗 ทดสอบการเชื่อมต่อทุกๆ: " .. _G.ServerHopperConfig.connectionTestInterval .. " วินาที")
    print("   🌐 Monitor URL: " .. _G.ServerHopperConfig.monitorServerUrl)
    print("   🎨 แสดง UI: " .. tostring(_G.ServerHopperConfig.showUI))
    print("   📊 แสดงรายละเอียด: " .. tostring(_G.ServerHopperConfig.verboseLogging))
    print("📊 สถานะปัจจุบัน:")
    print("   💀 ถูกฆ่าแล้ว: " .. killedByPlayerCount .. " ครั้ง")
    print("   ⏳ กำลังรอหลังโดนฆ่า: " .. tostring(killDelayActive))
end

-- 🔧 ฟังก์ชันสำหรับรีเฟรช UI
_G.refreshUI = function()
    if _G.ServerHopperConfig.showUI then
        createTimerUI()
        print("🎨 รีเฟรช UI แล้ว")
    else
        -- ซ่อน UI
        local playerGui = player:WaitForChild("PlayerGui")
        local existingUI = playerGui:FindFirstChild("ServerTimerUI")
        if existingUI then 
            existingUI:Destroy() 
            print("🎨 ซ่อน UI แล้ว")
        end
    end
end

-- สร้าง UI เริ่มต้น
createTimerUI()

-- ✅ แสดงสถานะเริ่มต้น
print("🎯 ระบบทำงาน:")
print("   - เปลี่ยนเซิร์ฟเมื่อถูกผู้เล่นฆ่าเกิน " .. _G.ServerHopperConfig.maxPlayerKills .. " ครั้ง (รอ " .. _G.ServerHopperConfig.killDelaySeconds .. " วินาทีก่อนย้าย)")
print("   - เปลี่ยนเซิร์ฟเมื่อผู้เล่นเกิน " .. _G.ServerHopperConfig.maxPlayersInServer .. " คน")
print("   - เปลี่ยนเซิร์ฟอัตโนมัติทุกๆ " .. _G.ServerHopperConfig.autoSwitchMinutes .. " นาที")
print("   - ดึงข้อมูลเซิร์ฟเวอร์จาก Python Monitor")
if _G.ServerHopperConfig.showUI then
    print("🎨 UI Timer แสดงอยู่ด้านบนหน้าจอแล้ว!")
end
print("🌐 Monitor Server: " .. _G.ServerHopperConfig.monitorServerUrl)
print("")
print("🔧 คำสั่งที่สามารถใช้ได้:")
print("   _G.showConfig()          -- แสดงการตั้งค่าและสถานะปัจจุบัน")
print("   _G.resetServerTimer()    -- รีเซ็ตเวลานับถอยหลัง")
print("   _G.switchServerNow()     -- เปลี่ยนเซิร์ฟเวอร์ทันที")
print("   _G.cancelKillDelay()     -- ยกเลิกการรอหลังโดนฆ่า")
print("   _G.resetKillCount()      -- รีเซ็ตจำนวนครั้งที่โดนฆ่า")
print("   _G.refreshUI()           -- รีเฟรช UI")
print("")
print("💡 ตัวอย่างการเปลี่ยนการตั้งค่า:")
print("   _G.ServerHopperConfig.autoSwitchMinutes = 30  -- เปลี่ยนเป็น 30 นาที")
print("   _G.ServerHopperConfig.maxPlayerKills = 3      -- เปลี่ยนเป็น 3 ครั้ง")
print("   _G.ServerHopperConfig.killDelaySeconds = 20   -- รอ 20 วินาทีหลังโดนฆ่า")
print("   _G.ServerHopperConfig.maxPlayersInServer = 10 -- เปลี่ยนเป็น 10 คน")
print("   _G.ServerHopperConfig.showUI = false          -- ซ่อน UI")
print("   _G.ServerHopperConfig.verboseLogging = false  -- ปิดการแสดงรายละเอียด")
print("   _G.refreshUI()  -- อัพเดต UI หลังเปลี่ยนการตั้งค่า")
printTimeStatus()

-- เริ่มอัพเดต UI และทดสอบการเชื่อมต่อทันที
updateTimerUI()
task.spawn(function()
    task.wait(2)
    getRandomJobId() -- ทดสอบการเชื่อมต่อครั้งแรก
end)
