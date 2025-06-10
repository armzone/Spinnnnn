local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local placeId = game.PlaceId
local checkInterval = 30 -- ระยะเวลาตรวจสอบ (วินาที)
local firebaseUrl = "https://jobid-1e3dc-default-rtdb.asia-southeast1.firebasedatabase.app/roblox_servers.json"

local killedByPlayerCount = 0 -- นับจำนวนครั้งที่ถูกผู้เล่นฆ่า
local maxPlayerKills = 2 -- จำนวนครั้งสูงสุดที่ถูกผู้เล่นฆ่าก่อนจะเทเลพอร์ต

-- ✅ ดึงข้อมูลจาก Firebase และสุ่ม JobId
local function getRandomJobId()
    local success, response = pcall(function()
        -- พยายามดึงข้อมูล JSON จาก URL
        return HttpService:JSONDecode(game:HttpGet(firebaseUrl))
    end)

    if success and response then
        local serverList = {}
        for _, serverData in pairs(response) do
            -- ตรวจสอบว่ามี JobId และไม่ใช่เซิร์ฟเวอร์ปัจจุบัน
            if serverData.id and serverData.id ~= game.JobId then
                table.insert(serverList, serverData.id)
            end
        end
        if #serverList > 0 then
            -- ถ้ามีเซิร์ฟเวอร์อื่นในรายการ ให้สุ่ม JobId
            return serverList[math.random(1, #serverList)]
        end
    end

    warn("❌ ไม่สามารถดึงข้อมูล JobId จาก Firebase ได้ หรือไม่มีเซิร์ฟเวอร์อื่น")
    return nil
end

-- ✅ ฟังก์ชันเทเลพอร์ต
local function teleportToNewServer()
    local jobId = getRandomJobId()
    if jobId then
        print("🚀 กำลังเทเลพอร์ตไป JobId: " .. jobId)
        -- เทเลพอร์ตผู้เล่นไปยัง PlaceId และ JobId ที่กำหนด
        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
    else
        print("❌ ไม่มีเซิร์ฟเวอร์ว่างสำหรับเทเลพอร์ต")
    end
end

-- ✅ ฟังก์ชันตรวจจับข้อความ DeathMessage ที่มี ชื่อผู้เล่น
local function setupDeathDetection()
    -- รอ DeathScreen GUI โหลด ซึ่งเป็นที่แสดงข้อความการตาย
    local guiPath = player:WaitForChild("PlayerGui"):WaitForChild("DeathScreen"):WaitForChild("DeathScreenHolder"):WaitForChild("Frame"):WaitForChild("DeathMessage")
    
    local function checkIfKilledByPlayer(text)
        -- สร้างรูปแบบการค้นหาชื่อผู้เล่นในข้อความ DeathMessage
        local pattern = "<b><i>" .. player.Name .. "</i></b>"
        return text:find(pattern)
    end

    -- ตรวจจับการเปลี่ยนแปลงของข้อความ DeathMessage
    guiPath:GetPropertyChangedSignal("Text"):Connect(function()
        local newText = guiPath.Text
        print("🔁 ตรวจพบการเปลี่ยนแปลงข้อความ! ข้อความใหม่: " .. newText)
        
        if checkIfKilledByPlayer(newText) then
            killedByPlayerCount += 1
            print("💀 ถูกผู้เล่นฆ่า (รวม " .. killedByPlayerCount .. " ครั้ง)")

            if killedByPlayerCount >= maxPlayerKills then
                print("⚠️ ถูกผู้เล่นฆ่าเกิน " .. maxPlayerKills .. " ครั้ง กำลังหาเซิร์ฟเวอร์ใหม่...")
                teleportToNewServer()
                -- รีเซ็ตจำนวนครั้งที่ถูกฆ่าหลังพยายามเทเลพอร์ต เพื่อให้เริ่มนับใหม่ในเซิร์ฟเวอร์ถัดไป
                killedByPlayerCount = 0 
            end
        else
            print("✅ ไม่ใช่ข้อความจากการถูกผู้เล่นฆ่า (ไม่ถูกนับ)")
        end
    end)
end

-- ✅ รอ GUI และเริ่มตรวจจับ
task.spawn(function()
    local success, err = pcall(setupDeathDetection)
    if not success then
        warn("❌ เกิดข้อผิดพลาดใน setupDeathDetection: " .. tostring(err))
    end
end)

-- ✅ ลูปตรวจสอบจำนวนผู้เล่นในเซิร์ฟ
while true do
    local currentPlayers = #Players:GetPlayers()
    print("👥 จำนวนผู้เล่นในเซิร์ฟเวอร์: " .. currentPlayers)

    if currentPlayers > 10 then
        print("⚠️ ผู้เล่นเกิน 10 คน กำลังสุ่มเซิร์ฟเวอร์ใหม่...")
        teleportToNewServer()
        -- ไม่มี 'break' ตรงนี้ เพื่อให้ลูปยังคงทำงานต่อไปและตรวจสอบจำนวนผู้เล่นในเซิร์ฟเวอร์ใหม่
    else
        print("✅ ยังอยู่ในเซิร์ฟเวอร์ที่มีผู้เล่นน้อย")
    end
    wait(checkInterval) -- รอตามช่วงเวลาที่กำหนดก่อนตรวจสอบอีกครั้ง
end
