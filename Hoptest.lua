wait(30)

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local checkInterval = 60 -- ตรวจสอบทุก 60 วิ
local firebaseUrl = "https://jobid-1e3dc-default-rtdb.asia-southeast1.firebasedatabase.app/roblox_servers.json"

local deathCount = 0
local maxDeaths = 3
local alreadyNotified = false

-- 🔁 ดึงข้อมูลจาก Firebase และสุ่ม JobId
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

-- 🚀 ฟังก์ชันเทเลพอร์ต
local function teleportToNewServer()
	local jobId = getRandomJobId()
	if jobId then
		print("🚀 เทเลพอร์ตไป JobId: " .. jobId)
		TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
	else
		print("❌ ไม่มีเซิร์ฟว่างสำหรับเทเลพอร์ต")
	end
end

-- ☠️ ตรวจสอบ GUI การตาย
task.spawn(function()
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("DeathScreen")
	local deathMsg = gui:WaitForChild("DeathScreenHolder"):WaitForChild("Frame"):WaitForChild("Frame"):WaitForChild("DeathMessage")

	while true do
		task.wait(0.5)
		if deathMsg.Visible and not alreadyNotified then
			local msg = deathMsg.Text
			local killerName = string.match(msg, "^(.-) killed you")

			deathCount += 1
			if killerName then
				print("☠️ คุณถูกฆ่าโดยผู้เล่นชื่อ:", killerName)
			else
				print("☠️ คุณตายแล้ว (ไม่ทราบชื่อผู้ฆ่า)")
			end

			print("📛 จำนวนการตายสะสม:", deathCount)

			if deathCount >= maxDeaths then
				print("⚠️ ตายเกิน 3 ครั้ง กำลังย้ายเซิร์ฟเวอร์...")
				teleportToNewServer()
				break
			end

			alreadyNotified = true
		elseif not deathMsg.Visible then
			alreadyNotified = false
		end
	end
end)

-- 👥 ลูปตรวจสอบจำนวนผู้เล่นในเซิร์ฟ
task.spawn(function()
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
end)
