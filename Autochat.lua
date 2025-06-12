local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- อ้างอิงถึง Event ที่ใช้ส่งข้อความแชท
local chatEvent = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")

-- Table เก็บข้อความที่พิมพ์บ่อยใน Blox Fruits
local commonMessages = {
    "ใครมี Hack Tool ขายบ้าง?",
    "หาคนช่วยเปิด Airdrop ที่ชายหาด",
    "ใครมีบ้านให้เช่าแถว Safe Zone?",
    "ขอทีมบุก ATM หลังร้าน The Butcher’s Cut",
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

-- ฟังก์ชันสำหรับส่งข้อความในแชท
local function sendChatMessage(message)
    if chatEvent then
        chatEvent:FireServer(message, "All")
    else
        warn("Chat event not found!")
    end
end

-- ฟังก์ชันสุ่มข้อความจาก Table
local function getRandomMessage()
    local randomIndex = math.random(1, #commonMessages)
    return commonMessages[randomIndex]
end

-- ส่งข้อความทุก ๆ 5 นาที (300 วินาที)
while true do
    local randomMessage = getRandomMessage()
    sendChatMessage(randomMessage)
    wait(300) -- รอ 5 นาทีก่อนส่งข้อความครั้งถัดไป
end
