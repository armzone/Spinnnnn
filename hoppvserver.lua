-- =============================================
-- Reserved Server Manager + File Save System
-- ใช้ได้เฉพาะใน Exploit ที่มี writefile, readfile, setclipboard
-- =============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- ========== MD5, HMAC, Base64 (ไม่เปลี่ยนแปลง) ==========
local md5 = {}
local hmac = {}
local base64 = {}

do
	do
		local T = {
			0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
			0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
			0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
			0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
			0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
			0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
			0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
			0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
			0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
			0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
			0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
			0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
			0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
			0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
			0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
			0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
		}

		local function add(a, b)
			local lsw = bit32.band(a, 0xFFFF) + bit32.band(b, 0xFFFF)
			local msw = bit32.rshift(a, 16) + bit32.rshift(b, 16) + bit32.rshift(lsw, 16)
			return bit32.bor(bit32.lshift(msw, 16), bit32.band(lsw, 0xFFFF))
		end

		local function rol(x, n)
			return bit32.bor(bit32.lshift(x, n), bit32.rshift(x, 32 - n))
		end

		local function F(x, y, z)
			return bit32.bor(bit32.band(x, y), bit32.band(bit32.bnot(x), z))
		end
		local function G(x, y, z)
			return bit32.bor(bit32.band(x, z), bit32.band(y, bit32.bnot(z)))
		end
		local function H(x, y, z)
			return bit32.bxor(x, bit32.bxor(y, z))
		end
		local function I(x, y, z)
			return bit32.bxor(y, bit32.bor(x, bit32.bnot(z)))
		end

		function md5.sum(message)
			local a, b, c, d = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476

			local message_len = #message
			local padded_message = message .. "\128"
			while #padded_message % 64 ~= 56 do
				padded_message = padded_message .. "\0"
			end

			local len_bytes = ""
			local len_bits = message_len * 8
			for i = 0, 7 do
				len_bytes = len_bytes .. string.char(bit32.band(bit32.rshift(len_bits, i * 8), 0xFF))
			end
			padded_message = padded_message .. len_bytes

			for i = 1, #padded_message, 64 do
				local chunk = padded_message:sub(i, i + 63)
				local X = {}
				for j = 0, 15 do
					local b1, b2, b3, b4 = chunk:byte(j * 4 + 1, j * 4 + 4)
					X[j] = bit32.bor(b1, bit32.lshift(b2, 8), bit32.lshift(b3, 16), bit32.lshift(b4, 24))
				end

				local aa, bb, cc, dd = a, b, c, d

				local s = { 7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21 }

				for j = 0, 63 do
					local f, k, shift_index
					if j < 16 then
						f = F(b, c, d)
						k = j
						shift_index = j % 4
					elseif j < 32 then
						f = G(b, c, d)
						k = (1 + 5 * j) % 16
						shift_index = 4 + (j % 4)
					elseif j < 48 then
						f = H(b, c, d)
						k = (5 + 3 * j) % 16
						shift_index = 8 + (j % 4)
					else
						f = I(b, c, d)
						k = (7 * j) % 16
						shift_index = 12 + (j % 4)
					end

					local temp = add(a, f)
					temp = add(temp, X[k])
					temp = add(temp, T[j + 1])
					temp = rol(temp, s[shift_index + 1])

					local new_b = add(b, temp)
					a, b, c, d = d, new_b, b, c
				end

				a = add(a, aa)
				b = add(b, bb)
				c = add(c, cc)
				d = add(d, dd)
			end

			local function to_le_hex(n)
				local s = ""
				for i = 0, 3 do
					s = s .. string.char(bit32.band(bit32.rshift(n, i * 8), 0xFF))
				end
				return s
			end

			return to_le_hex(a) .. to_le_hex(b) .. to_le_hex(c) .. to_le_hex(d)
		end
	end

	do
		function hmac.new(key, msg, hash_func)
			if #key > 64 then
				key = hash_func(key)
			end

			local o_key_pad = ""
			local i_key_pad = ""
			for i = 1, 64 do
				local byte = (i <= #key and string.byte(key, i)) or 0
				o_key_pad = o_key_pad .. string.char(bit32.bxor(byte, 0x5C))
				i_key_pad = i_key_pad .. string.char(bit32.bxor(byte, 0x36))
			end

			return hash_func(o_key_pad .. hash_func(i_key_pad .. msg))
		end
	end

	do
		local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

		function base64.encode(data)
			return (
				(data:gsub(".", function(x)
					local r, b_val = "", x:byte()
					for i = 8, 1, -1 do
						r = r .. (b_val % 2 ^ i - b_val % 2 ^ (i - 1) > 0 and "1" or "0")
					end
					return r
				end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
					if #x < 6 then
						return ""
					end
					local c = 0
					for i = 1, 6 do
						c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
					end
					return b:sub(c + 1, c + 1)
				end) .. ({ "", "==", "=" })[#data % 3 + 1]
			)
		end
	end
end

-- ========== GenerateReservedServerCode ==========
local function GenerateReservedServerCode(placeId)
	local uuid = {}
	for i = 1, 16 do
		uuid[i] = math.random(0, 255)
	end

	uuid[7] = bit32.bor(bit32.band(uuid[7], 0x0F), 0x40)
	uuid[9] = bit32.bor(bit32.band(uuid[9], 0x3F), 0x80)

	local firstBytes = ""
	for i = 1, 16 do
		firstBytes = firstBytes .. string.char(uuid[i])
	end

	local gameCode = string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", table.unpack(uuid))

	local placeIdBytes = ""
	local pIdRec = placeId
	for _ = 1, 8 do
		placeIdBytes = placeIdBytes .. string.char(pIdRec % 256)
		pIdRec = math.floor(pIdRec / 256)
	end

	local content = firstBytes .. placeIdBytes

	local SUPERDUPERSECRETROBLOXKEYTHATTHEYDIDNTCHANGEEVERSINCEFOREVER = "e4Yn8ckbCJtw2sv7qmbg"
	local signature = hmac.new(SUPERDUPERSECRETROBLOXKEYTHATTHEYDIDNTCHANGEEVERSINCEFOREVER, content, md5.sum)

	local accessCodeBytes = signature .. content

	local accessCode = base64.encode(accessCodeBytes)
	accessCode = accessCode:gsub("+", "-"):gsub("/", "_")

	local pdding = 0
	accessCode, _ = accessCode:gsub("=", function()
		pdding = pdding + 1
		return ""
	end)

	accessCode = accessCode .. tostring(pdding)

	return accessCode, gameCode
end

-- ========== ระบบไฟล์ (เฉพาะ Exploit) ==========
local ACCESS_CODE_FILE = "reserved_server_code.txt"

local function saveAccessCodeToFile(code)
    if writefile then
        writefile(ACCESS_CODE_FILE, code)
        print("💾 บันทึก Access Code ลงไฟล์:", code)
    else
        warn("⚠️ writefile ไม่พร้อมใช้งาน")
    end
end

local function loadAccessCodeFromFile()
    if readfile and isfile and isfile(ACCESS_CODE_FILE) then
        local content = readfile(ACCESS_CODE_FILE)
        if content and content ~= "" then
            return content
        end
    end
    return nil
end

-- ========== UI ==========
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerCodeUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 350)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 20, 0, 15)
title.BackgroundTransparency = 1
title.Text = "Reserved Server Manager"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 11
title.Parent = mainFrame

-- TextBox
local accessCodeBox = Instance.new("TextBox")
accessCodeBox.Name = "AccessCodeBox"
accessCodeBox.Size = UDim2.new(1, -40, 0, 45)
accessCodeBox.Position = UDim2.new(0, 20, 0, 70)
accessCodeBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
accessCodeBox.BorderSizePixel = 0
accessCodeBox.Text = ""
accessCodeBox.PlaceholderText = "กรอก Access Code ที่นี่..."
accessCodeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
accessCodeBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
accessCodeBox.TextSize = 14
accessCodeBox.Font = Enum.Font.Gotham
accessCodeBox.ClearTextOnFocus = false
accessCodeBox.ZIndex = 11
accessCodeBox.Parent = mainFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 8)
boxCorner.Parent = accessCodeBox

-- สร้างปุ่ม
local function createButton(name, text, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, -40, 0, 48)
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 15
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.ZIndex = 11
	button.Parent = mainFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = button
	
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(
			math.min(color.R * 255 + 20, 255),
			math.min(color.G * 255 + 20, 255),
			math.min(color.B * 255 + 20, 255)
		)}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
	end)
	
	return button
end

local btn1 = createButton("CreateButton", "🚀 สร้างเซิฟเวอร์ใหม่และ Teleport", UDim2.new(0, 20, 0, 135), Color3.fromRGB(88, 101, 242))
local btn2 = createButton("CopyButton", "📋 คัดลอก Access Code ปัจจุบัน", UDim2.new(0, 20, 0, 195), Color3.fromRGB(87, 242, 135))
local btn3 = createButton("JoinButton", "🎯 เข้าร่วมเซิฟเวอร์", UDim2.new(0, 20, 0, 255), Color3.fromRGB(254, 231, 92))

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -40, 0, 25)
statusLabel.Position = UDim2.new(0, 20, 1, -40)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "พร้อมใช้งาน"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.ZIndex = 11
statusLabel.Parent = mainFrame

local function showStatus(text, color)
	statusLabel.Text = text
	statusLabel.TextColor3 = color
	task.spawn(function()
		task.wait(3)
		if statusLabel.Text == text then
			statusLabel.Text = "พร้อมใช้งาน"
			statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end)
end

-- ========== ปุ่มที่ 1: สร้าง + บันทึกไฟล์ ==========
btn1.MouseButton1Click:Connect(function()
    local success, result = pcall(function()
        local accessCode, gameCode = GenerateReservedServerCode(game.PlaceId)
        
        -- 🔥 บันทึกลงไฟล์
        saveAccessCodeToFile(accessCode)
        
        -- ส่งไปยังเซิร์ฟเวอร์
        game.RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(game.PlaceId, "", accessCode)
        
        print("✅ สร้างเซิร์ฟเวอร์ใหม่:", accessCode)
        return true
    end)
    
    if success then
        showStatus("✓ สร้างและบันทึกเรียบร้อย!", Color3.fromRGB(87, 242, 135))
    else
        showStatus("✗ สร้างไม่สำเร็จ", Color3.fromRGB(237, 66, 69))
        warn("Error:", result)
    end
end)

-- ========== ปุ่มที่ 2: คัดลอกจากไฟล์ ==========
btn2.MouseButton1Click:Connect(function()
    local savedCode = loadAccessCodeFromFile()
    if savedCode then
        if setclipboard then
            setclipboard(savedCode)
            showStatus("✓ คัดลอกจากไฟล์แล้ว!", Color3.fromRGB(87, 242, 135))
        else
            accessCodeBox.Text = savedCode
            showStatus("📋 ดูโค้ดในช่องกรอก", Color3.fromRGB(254, 231, 92))
        end
    else
        showStatus("✗ ไม่พบไฟล์บันทึก", Color3.fromRGB(237, 66, 69))
    end
end)

-- ========== ปุ่มที่ 3: เข้าร่วมจากช่องกรอก ==========
btn3.MouseButton1Click:Connect(function()
    local inputCode = accessCodeBox.Text
    if inputCode == "" then
        showStatus("✗ กรุณากรอก Access Code", Color3.fromRGB(237, 66, 69))
        return
    end
    

    local success, err = pcall(function()
        game.RobloxReplicatedStorage.ContactListIrisInviteTeleport:FireServer(game.PlaceId, "", inputCode)
    end)
		if success then
        showStatus("✓ กำลังเข้าร่วม...", Color3.fromRGB(87, 242, 135))
    else
        showStatus("✗ เข้าร่วมไม่ได้", Color3.fromRGB(237, 66, 69))
        warn("Error:", err)
    end
end)

-- ========== โหลดไฟล์อัตโนมัติเมื่อเปิด UI ==========
spawn(function()
    local saved = loadAccessCodeFromFile()
    if saved then
        accessCodeBox.Text = saved
        print("📂 โหลด Access Code จากไฟล์:", saved)
    end
end)

-- ========== Draggable UI ==========
local dragging = false
local dragStart
local startPos

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

print("✅ Reserved Server Manager + File System โหลดเรียบร้อย!")
