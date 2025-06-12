local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local placeId = game.PlaceId
local checkInterval = 30
local firebaseUrl = "https://jobid-1e3dc-default-rtdb.asia-southeast1.firebasedatabase.app/roblox_servers.json"

local killedByPlayerCount = 0
local maxPlayerKills = 2
local alreadyTeleported = false

print("📌 สคริปต์เริ่มทำงาน")

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

local function teleportToNewServer()
    if alreadyTeleported then
        print("⚠️ ห้ามเทเลพอร์ตซ้ำ")
        return
    end
    alreadyTeleported = true
    local jobId = getRandomJobId()
    if jobId then
        print("🚀 เทเลพอร์ตไป JobId: " .. jobId)
        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
    else
        print("❌ ไม่มีเซิร์ฟว่างสำหรับเทเลพอร์ต")
    end
end

-- ✅ ตรวจว่าข้อความชื่อว่าเป็นเลขล้วนหรือไม่
local function isNumericName(name)
    return name:match("^%d+$") ~= nil
end

-- ✅ ตรวจว่า DeathMessage มีชื่อของผู้เล่นอื่นในเซิร์ฟ (รวมชื่อเลขล้วน)
local function checkIfKilledByOtherPlayer(text)
    print("🔎 กำลังตรวจสอบข้อความ: " .. text)
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local nameLower = otherPlayer.Name:lower()
            local displayLower = otherPlayer.DisplayName:lower()
            local textLower = text:lower()

            if textLower:find(nameLower) or textLower:find(displayLower) then
                print("💥 พบชื่อผู้เล่นในข้อความ")
                return true, otherPlayer.Name
            end
        end
    end

    -- ✅ เพิ่มตรวจสอบชื่อเป็นเลขล้วนจาก DeathMessage
    local numericName = text:match("by%s+(%d+)")
    if numericName and isNumericName(numericName) then
        print("💥 พบชื่อเป็นตัวเลขล้วน:", numericName)
        return true, numericName
    end

    print("❌ ไม่มีชื่อผู้เล่นในข้อความ")
    return false
end

-- ✅ รอ GUI และเริ่มตรวจจับ
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
            print("📋 ประเภทของ deathMessage:", deathMessage.ClassName)

            deathMessage:GetPropertyChangedSignal("Text"):Connect(function()
                local newText = deathMessage.Text
                print("🔁 ตรวจพบข้อความใหม่: " .. newText)

                local killed, killerName = checkIfKilledByOtherPlayer(newText)
                if killed then
                    killedByPlayerCount += 1
                    print("💀 ถูกผู้เล่นฆ่าโดย: " .. killerName .. " (รวม " .. killedByPlayerCount .. " ครั้ง)")

                    if killedByPlayerCount >= maxPlayerKills then
                        print("⚠️ ถูกผู้เล่นฆ่าเกิน 2 ครั้ง กำลังหาเซิร์ฟใหม่...")
                        teleportToNewServer()
                    end
                else
                    print("✅ ไม่พบชื่อผู้เล่นอื่นในข้อความ (ไม่ถูกนับ)")
                end
            end)

            return
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

        if currentPlayers > 10 then
            print("⚠️ ผู้เล่นเกิน 10 คน กำลังสุ่มเซิร์ฟใหม่...")
            teleportToNewServer()
            break
        else
            print("✅ ยังอยู่ในเซิร์ฟที่เหมาะสม")
        end
        wait(checkInterval)
    end
end)
