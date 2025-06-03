wait(30)
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local checkInterval = 60
local firebaseUrl = "https://jobid-1e3dc-default-rtdb.asia-southeast1.firebasedatabase.app/roblox_servers.json"

local killedByPlayerCount = 0
local maxPlayerKills = 2

-- ดึงข้อมูลจาก Firebase และสุ่ม JobId
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

-- ฟังก์ชันเทเลพอร์ต
local function teleportToNewServer()
    local jobId = getRandomJobId()
    if jobId then
        print("🚀 เทเลพอร์ตไป JobId: " .. jobId)
        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
    else
        print("❌ ไม่มีเซิร์ฟว่างสำหรับเทเลพอร์ต")
    end
end

-- นับการถูก "ผู้เล่น" ฆ่า
player.CharacterAdded:Connect(function()
    local humanoid = player.Character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            local killerTag = humanoid:FindFirstChild("creator")
            if killerTag and killerTag.Value and killerTag.Value:IsA("Player") then
                local killerName = killerTag.Value.Name
                killedByPlayerCount += 1
                print("💀 ถูกผู้เล่นฆ่าโดย: " .. killerName .. " (รวม " .. killedByPlayerCount .. " ครั้ง)")
                if killedByPlayerCount >= maxPlayerKills then
                    print("⚠️ ถูกผู้เล่นฆ่าเกิน 2 ครั้ง กำลังหาเซิร์ฟใหม่...")
                    teleportToNewServer()
                end
            else
                print("💀 ตายโดยไม่ใช่ผู้เล่น (ไม่ถูกนับ)")
            end
        end)
    end
end)

-- ลูปตรวจสอบจำนวนผู้เล่นในเซิร์ฟ
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
