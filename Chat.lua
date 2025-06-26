-- ต้องใช้เป็น LocalScript เท่านั้น!
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- Table เก็บข้อความ
local commonMessages = {
    "ใครมี Hack Tool ขายบ้าง?",
    "หาคนช่วยเปิด Airdrop ที่ชายหาด",
    "ใครมีบ้านให้เช่าแถว Safe Zone?",
    "ขอทีมบุก ATM หลังร้าน The Butcher's Cut",
    "ใครมี Blood Bag ขายไหม? ต้องการด่วน!",
    "หาคนช่วยฟาร์มเงินจากงาน Burger Place",
    "ใครมีอาวุธระดับสูงให้แลกบ้าง?",
    "ขอเข้าร่วม Crew ที่เน้น PvP",
    "ใครรู้วิธีปลดล็อกอาวุธลับบ้าง?",
    "หาคนช่วยป้องกันฐานจากการโจมตี",
    "ใครมีข้อมูลเกี่ยวกับการ Hack ATM บ้าง?",
    "ขอทีมช่วยปล้นร้านค้าในเมือง",
    "ใครมีรถเร็วให้เช่าบ้าง?",
    "หาคนช่วยเก็บของจาก Airdrop",
    "ใครมีข้อมูลเกี่ยวกับ Safehouse บ้าง?",
    "ขอทีมช่วยทำภารกิจลับ",
    "ใครมีเงินสดแลกเป็นของได้บ้าง?",
    "หาคนช่วยป้องกัน Airdrop จากศัตรู",
    "ใครมีข้อมูลเกี่ยวกับการฟาร์มเงินเร็ว ๆ บ้าง?",
    "ขอเข้าร่วม Crew ที่มีประสบการณ์"
}

-- ฟังก์ชันส่งข้อความ (รองรับทั้งระบบเก่าและใหม่)
local function sendChatMessage(message)
    local success = false
    
    -- ลองใช้ TextChatService ก่อน (ระบบใหม่)
    if TextChatService then
        pcall(function()
            local textChannel = TextChatService.TextChannels.RBXGeneral
            if textChannel then
                textChannel:SendAsync(message)
                success = true
                print("ส่งข้อความสำเร็จ (TextChatService): " .. message)
            end
        end)
    end
    
    -- ถ้าไม่สำเร็จ ลองใช้ระบบเก่า
    if not success then
        pcall(function()
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents then
                local sayMessageRequest = chatEvents:FindFirstChild("SayMessageRequest")
                if sayMessageRequest then
                    sayMessageRequest:FireServer(message, "All")
                    success = true
                    print("ส่งข้อความสำเร็จ (Legacy): " .. message)
                end
            end
        end)
    end
    
    if not success then
        warn("ไม่สามารถส่งข้อความได้: " .. message)
    end
end

-- ฟังก์ชันสุ่มข้อความ
local function getRandomMessage()
    local randomIndex = math.random(1, #commonMessages)
    return commonMessages[randomIndex]
end

-- รอให้เกมโหลดเสร็จ
if not player.Character then
    player.CharacterAdded:Wait()
end

wait(5) -- รอเพิ่มให้แน่ใจว่าทุกอย่างโหลดแล้ว

print("เริ่มระบบส่งข้อความอัตโนมัติ...")

-- ใช้ spawn เพื่อไม่ให้ค้างระบบ
spawn(function()
    while true do
        -- ตรวจสอบว่าผู้เล่นยังอยู่ในเกม
        if player and player.Parent then
            local randomMessage = getRandomMessage()
            sendChatMessage(randomMessage)
        else
            warn("ผู้เล่นไม่อยู่ในเกม หยุดการส่งข้อความ")
            break
        end
        
        -- รอ 5 นาที (300 วินาที) พร้อมเพิ่มความสุ่ม ±30 วินาที
        local waitTime = 300 + math.random(-30, 30)
        wait(waitTime)
    end
end)
