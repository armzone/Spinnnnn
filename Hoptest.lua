local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local placeId = game.PlaceId
local checkInterval = 30
local firebaseUrl = "https://jobid-1e3dc-default-rtdb.asia-southeast1.firebasedatabase.app/roblox_servers.json"

local killedByPlayerCount = 0
local maxPlayerKills = 2

-- ✅ ดึงข้อมูลจาก Firebase และสุ่ม JobId
local function getRandomJobId()
    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(firebaseUrl))
    end)

    if success and response then
        local serverList = {}
        for _, serverData in pairs(response) do
            if serverData.id and serverData.id ~= game.JobId then
                table.insert(serverList, serverData.id)
            end
        end
        if #serverList > 0 then
            return serverList[math.random(1, #serverList)]
        end
    end

    warn("❌ ไม่สามารถดึงข้อมูล JobId จาก Firebase ได้ หรือไม่มีเซิร์ฟอื่น")
    return nil
end

-- ✅ ฟังก์ชันเทเลพอร์ต
local function teleportToNewServer()
    local jobId = getRandomJobId()
    if jobId then
        print("🚀 เทเลพอร์ตไป JobId: " .. jobId)
        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
    else
        print("❌ ไม่มีเซิร์ฟว่างสำหรับเทเลพอร์ต")
    end
end

-- ✅ ฟังก์ชันตรวจจับข้อความ DeathMessage ที่มี <b><i>ชื่อผู้เล่น</i></b>
local function setupDeathDetection()
    local guiPath = player:WaitForChild("PlayerGui"):WaitForChild("DeathScreen"):WaitForChild("DeathScreenHolder"):WaitForChild("Frame"):WaitForChild("DeathMessage")
    
    local function checkIfKilledByPlayer(text)
        local pattern = "<b><i>" .. player.Name .. "</i></b>"
        return text:find(pattern)
    end

    guiPath:GetPropertyChangedSignal("Text"):Connect(function()
        local newText = guiPath.Text
        print("🔁 ตรวจพบการเปลี่ยนแปลง Text! ข้อความใหม่: " .. newText)
        
        if checkIfKilledByPlayer(newText) then
            killedByPlayerCount += 1
            print("💀 ถูกผู้เล่นฆ่า (รวม " .. killedByPlayerCount .. " ครั้ง)")

            if killedByPlayerCount >= maxPlayerKills then
                print("⚠️ ถูกผู้เล่นฆ่าเกิน 2 ครั้ง กำลังหาเซิร์ฟใหม่...")
                teleportToNewServer()
            end
        else
            print("✅ ไม่ใช่ข้อความจากผู้เล่น (ไม่ถูกนับ)")
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
    print("👥 จำนวนผู้เล่นในเซิร์ฟ: " .. currentPlayers)

    if currentPlayers > 10 then
        print("⚠️ ผู้เล่นเกิน 10 คน กำลังสุ่มเซิร์ฟใหม่...")
        teleportToNewServer()
        break
    else
        print("✅ ยังอยู่ในเซิร์ฟที่มีผู้เล่นน้อย")
    end
    wait(checkInterval)
end
