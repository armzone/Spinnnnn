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
        -- ใช้ DisplayName ก่อน ถ้าไม่มีก็ใช้ Name (สำหรับชื่อที่แสดงในเกม)
        local playerDisplayName = player.DisplayName or player.Name
        
        -- ตรวจสอบว่า 'เรา' คือเหยื่อ (ระบุโดย "You", "คุณ", หรือชื่อผู้เล่นของเรา)
        local victimIsPresent = text:find("You", 1, true) or text:find("คุณ", 1, true) or text:find(playerDisplayName, 1, true)

        if not victimIsPresent then
            return false -- ไม่ใช่ข้อความการตายที่เกี่ยวกับเรา
        end

        -- พยายามดึงชื่อที่อยู่ระหว่างแท็ก <b><i>...</i></b> ซึ่งมักจะเป็นชื่อผู้ฆ่า
        local killerNameInTags = text:match("<b><i>(.-)</i></b>")

        if killerNameInTags then
            -- ตรวจสอบว่าชื่อที่ดึงมาได้ไม่ใช่ชื่อผู้เล่นของเราเอง (ยืนยันว่าถูกฆ่าโดยผู้เล่นอื่น)
            if killerNameInTags ~= playerDisplayName and killerNameInTags ~= player.Name then
                -- ตรวจสอบวลีทั่วไปที่บ่งบอกถึงการถูกฆ่า (จากภาพที่ให้มา)
                local killedByPhrases = {
                    "killed by",
                    "slain by",
                    "ถูกฆ่าโดย", -- Thai for "was killed by"
                    "สังหารโดย", -- Thai for "slain by"
                    "turned you into", -- "turned you into free real estate"
                    "got clapped by", -- "You just got clapped by"
                    "confirmed by",   -- "Your skill issue has been confirmed by"
                    "taken down by",
                    "caused your death", -- เช่น "X caused your death"
                }
                
                for _, phrase in ipairs(killedByPhrases) do
                    -- ตรวจสอบว่ามีวลีที่บ่งบอกถึงการถูกฆ่าอยู่ในข้อความหรือไม่
                    if text:find(phrase, 1, true) then
                        return true -- ถ้าพบ แสดงว่าถูกฆ่าโดยผู้เล่นคนอื่น
                    end
                end
            end
        end
        
        return false -- ไม่ตรงตามเงื่อนไขการถูกฆ่าโดยผู้เล่น
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
