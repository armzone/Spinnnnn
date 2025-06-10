--[[
    Service Definitions
    Initializes required Roblox services for the script to function.
]]
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

--[[
    Configuration Variables
    - placeId: The ID of the current game place.
    - firebaseUrl: The URL to your Firebase Realtime Database.
    - killedByPlayerCount: Counter for how many times the player has been killed by another player.
    - maxPlayerKills: The number of player kills to trigger a server hop.
    - maxPlayersInServer: The maximum number of players allowed before triggering a server hop.
    - checkInterval: How often (in seconds) to check the player count.
]]
local placeId = game.PlaceId
local firebaseUrl = "https://jobid-1e3dc-default-rtdb.asia-southeast1.firebasedatabase.app/roblox_servers.json"
local killedByPlayerCount = 0
local maxPlayerKills = 2
local maxPlayersInServer = 10
local checkInterval = 30
local isTeleporting = false

--[[
    @function getRandomJobId
    @description Fetches server list from Firebase and returns a random JobId from a different server.
    @return (string | nil) A random JobId or nil if fetching fails or no other servers are available.
]]
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

--[[
    @function teleportToNewServer
    @description Initiates teleportation to a new server instance, ensuring it only runs once.
]]
local function teleportToNewServer()
    if isTeleporting then return end -- ป้องกันการเรียกเทเลพอร์ตซ้ำซ้อน
    isTeleporting = true

    local jobId = getRandomJobId()
    if jobId then
        print("🚀 กำลังเทเลพอร์ตไป JobId: " .. jobId)
        TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
    else
        print("❌ ไม่มีเซิร์ฟเวอร์ว่างสำหรับเทเลพอร์ต")
        isTeleporting = false -- รีเซ็ตถ้าหาเซิร์ฟไม่เจอ
    end
end

--[[
    @function setupDeathDetection
    @description Sets up a listener to detect when the local player is killed by another player.
    If the kill count is reached, it triggers an immediate teleport.
]]
local function setupDeathDetection()
    local guiPath = player:WaitForChild("PlayerGui"):WaitForChild("DeathScreen"):WaitForChild("DeathScreenHolder"):WaitForChild("Frame"):WaitForChild("DeathMessage")
    
    local function checkIfKilledByPlayer(text)
        local pattern = "<b><i>" .. player.Name .. "</i></b>"
        return text:find(pattern)
    end

    guiPath:GetPropertyChangedSignal("Text"):Connect(function()
        if isTeleporting then return end -- ถ้ากำลังจะเทเลพอร์ตแล้ว ไม่ต้องทำอะไรต่อ
        
        local newText = guiPath.Text
        print("🔁 ตรวจพบการเปลี่ยนแปลง Text! ข้อความใหม่: " .. newText)
        
        if checkIfKilledByPlayer(newText) then
            killedByPlayerCount += 1
            print("💀 ถูกผู้เล่นฆ่า (รวม " .. killedByPlayerCount .. " ครั้ง)")

            if killedByPlayerCount >= maxPlayerKills then
                print("⚠️ ถูกผู้เล่นฆ่าครบ " .. maxPlayerKills .. " ครั้ง! กำลังเทเลพอร์ตทันที...")
                teleportToNewServer()
            end
        else
            print("✅ การตายนี้ไม่ได้เกิดจากผู้เล่นอื่น")
        end
    end)
end

--[[
    Script Initialization
    - Spawns the death detection in a new thread.
    - Starts the main loop for checking player count.
]]
task.spawn(setupDeathDetection)
print("✅ สคริปต์ตรวจจับการตายเริ่มทำงานแล้ว")

while task.wait(checkInterval) do
    if isTeleporting then 
        break -- หยุดลูปถ้ามีการเทเลพอร์ตเกิดขึ้นแล้ว (ไม่ว่าจะจากเหตุผลใด)
    end
    
    local currentPlayers = #Players:GetPlayers()
    print("👥 จำนวนผู้เล่นในเซิร์ฟ: " .. currentPlayers .. "/" .. maxPlayersInServer)

    if currentPlayers > maxPlayersInServer then
        print("⚠️ ผู้เล่นเกิน " .. maxPlayersInServer .. " คน กำลังหาเซิร์ฟใหม่...")
        teleportToNewServer()
        break -- ออกจากลูปหลังจากสั่งเทเลพอร์ต
    else
        print("✅ จำนวนผู้เล่นยังอยู่ในเกณฑ์ที่กำหนด")
    end
end
