-- NEMESIS FRIEND TAGS (No chat messages) - Matches AntiVCB style
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TargetGui = (typeof(gethui) == "function" and gethui()) or PlayerGui

local existing = TargetGui:FindFirstChild("NemesisFriendTagsGui")
if existing then existing:Destroy() end

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------
local RANK_TEXT = "FRIEND"
local GRAD_A = Color3.fromRGB(220, 40, 40)
local GRAD_B = Color3.fromRGB(255, 120, 120)
local TAG_WIDTH = 180
local TAG_HEIGHT = 50
local TAG_OFFSET = Vector3.new(0, 1.7, 0)
local ZOOMOUT_SIZE = UDim2.new(0, 40, 0, 40)
local ZOOMOUT_DISTANCE = 60
local TP_SOUND_ID = 135640489101126

local LOGO_FILE = "friendlogo.png"
local LOGO_URL = "https://i.ibb.co/HTRrV9cK/friendlogo.png"

local function ensureImage(file, url)
	pcall(function()
		if not isfile(file) then
			writefile(file, game:HttpGet(url))
		end
	end)
end

local function loadImage(file, url)
	ensureImage(file, url)
	local ok, result = pcall(function()
		return getcustomasset(file)
	end)
	return (ok and result) or ""
end

local logoImage = loadImage(LOGO_FILE, LOGO_URL)

--------------------------------------------------------------------------------
-- THEME (exact same as AntiVCB)
--------------------------------------------------------------------------------
local THEME = {
	Background   = Color3.fromRGB(15, 15, 15),
	Panel        = Color3.fromRGB(25, 25, 25),
	Accent       = Color3.fromRGB(255, 255, 255),
	Stroke       = Color3.fromRGB(80, 80, 80),
	TextPrimary  = Color3.fromRGB(255, 255, 255),
	TextMuted    = Color3.fromRGB(200, 200, 200),
	ButtonIdle   = Color3.fromRGB(30, 30, 30),
	ButtonHover  = Color3.fromRGB(50, 50, 50),
	Danger       = Color3.fromRGB(255, 255, 255),
	Success      = Color3.fromRGB(255, 255, 255),
}

local OPEN_SIZE        = UDim2.new(0, 240, 0, 155)
local COLLAPSED_HEIGHT = 48
local TWEEN_INFO       = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--------------------------------------------------------------------------------
-- LOGO SETTINGS (same as AntiVCB for the main UI logo)
--------------------------------------------------------------------------------
local UI_LOGO_PATH          = "whitelogo.png"
local UI_LOGO_DOWNLOAD_URL  = "https://i.ibb.co/SwGkMS5h/whitelogo.png" -- ← paste a direct PNG link here
local FALLBACK_LOGO         = "rbxassetid://107541043103322"

local function getLogoImage()
	if typeof(getcustomasset) == "function" then
		if isfile and isfile(UI_LOGO_PATH) then
			local ok, asset = pcall(getcustomasset, UI_LOGO_PATH)
			if ok and asset then
				return asset
			end
		end

		if UI_LOGO_DOWNLOAD_URL ~= "" and (not isfile or not isfile(UI_LOGO_PATH)) then
			local ok, data = pcall(function()
				return game:HttpGet(UI_LOGO_DOWNLOAD_URL)
			end)
			if ok and type(data) == "string" and #data > 200 then
				pcall(writefile, UI_LOGO_PATH, data)
				if isfile and isfile(UI_LOGO_PATH) then
					local ok2, asset = pcall(getcustomasset, UI_LOGO_PATH)
					if ok2 and asset then
						return asset
					end
				end
			end
		end
	end
	return FALLBACK_LOGO
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
local function tween(instance, props, info)
	local t = TweenService:Create(instance, info or TWEEN_INFO, props)
	t:Play()
	return t
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 12)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.Stroke
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function makeButton(parent, props)
	local btn = Instance.new("TextButton")
	btn.Size = props.Size or UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle
	btn.BackgroundTransparency = props.BackgroundTransparency or 0.25
	btn.AutoButtonColor = false
	btn.Text = props.Text or ""
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = props.TextSize or 12
	btn.TextColor3 = props.TextColor3 or THEME.TextPrimary
	btn.Parent = parent
	corner(btn, UDim.new(0, 8))
	local btnStroke = stroke(btn, THEME.Stroke, 1)
	btnStroke.Transparency = 0.3

	btn.MouseEnter:Connect(function()
		if not btn:GetAttribute("Locked") then
			tween(btn, { BackgroundColor3 = THEME.ButtonHover, BackgroundTransparency = 0.1 }, HOVER_TWEEN_INFO)
			tween(btnStroke, { Color = THEME.Accent, Transparency = 0 }, HOVER_TWEEN_INFO)
		end
	end)
	btn.MouseLeave:Connect(function()
		if not btn:GetAttribute("Locked") then
			tween(btn, {
				BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle,
				BackgroundTransparency = props.BackgroundTransparency or 0.25
			}, HOVER_TWEEN_INFO)
			tween(btnStroke, { Color = THEME.Stroke, Transparency = 0.3 }, HOVER_TWEEN_INFO)
		end
	end)

	return btn, btnStroke
end

local function playTpSound()
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(TP_SOUND_ID)
	s.Volume = 1
	s.Parent = SoundService
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- FRIENDS + TAG SYSTEM
--------------------------------------------------------------------------------
local ACTIVE = false
local friendIds = {}
local taggedByUs = {}

local function hasExistingTag(userId)
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return false end
	local tag = pg:FindFirstChild("NEMESISTag_" .. userId)
	if tag and not taggedByUs[userId] then
		return true
	end
	return false
end

local function destroyOurTag(userId)
	if not taggedByUs[userId] then return end
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return end
	local t = pg:FindFirstChild("NEMESISTag_" .. userId)
	if t then t:Destroy() end
	taggedByUs[userId] = nil
end

local function buildFriendTag(plr)
	if not plr or plr == LocalPlayer then return end
	if not friendIds[plr.UserId] then return end
	if not ACTIVE then return end
	if hasExistingTag(plr.UserId) then return end

	local char = plr.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not head or not hrp then return end

	destroyOurTag(plr.UserId)
	taggedByUs[plr.UserId] = true

	local pg = LocalPlayer:WaitForChild("PlayerGui")

	local bb = Instance.new("BillboardGui")
	bb.Name = "NEMESISTag_" .. plr.UserId
	bb.Size = UDim2.new(0, TAG_WIDTH, 0, TAG_HEIGHT)
	bb.StudsOffset = TAG_OFFSET
	bb.AlwaysOnTop = true
	bb.MaxDistance = math.huge
	bb.Adornee = head
	bb.Active = true
	bb.Parent = pg

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.ZIndex = 20
	btn.Parent = bb
	btn.MouseButton1Click:Connect(function()
		local myChar = LocalPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if myHRP and hrp and hrp.Parent then
			playTpSound()
			myHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
		end
	end)

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
	bg.BackgroundTransparency = 0.12
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true
	bg.Parent = bb
	corner(bg, UDim.new(0, 14))

	local bgGrad = Instance.new("UIGradient")
	bgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, GRAD_A),
		ColorSequenceKeypoint.new(1, GRAD_B),
	})
	bgGrad.Rotation = 135
	bgGrad.Parent = bg

	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 255, 255)
	st.Thickness = 1.5
	st.Transparency = 0.4
	st.Parent = bg

	local stGrad = Instance.new("UIGradient")
	stGrad.Color = ColorSequence.new(GRAD_A, GRAD_B)
	stGrad.Parent = st

	local IMG_W = math.floor(TAG_HEIGHT * 0.8)
	local IMG_PAD = 6

	local logoHolder = Instance.new("Frame")
	logoHolder.Size = UDim2.new(0, IMG_W, 0, IMG_W)
	logoHolder.Position = UDim2.new(0, IMG_PAD, 0.5, -IMG_W / 2)
	logoHolder.BackgroundTransparency = 1
	logoHolder.ClipsDescendants = true
	logoHolder.ZIndex = 4
	logoHolder.Parent = bg
	corner(logoHolder, UDim.new(1, 0))

	local logoImg = Instance.new("ImageLabel")
	logoImg.Size = UDim2.new(1, 0, 1, 0)
	logoImg.BackgroundTransparency = 1
	logoImg.Image = logoImage
	logoImg.ScaleType = Enum.ScaleType.Fit
	logoImg.ZIndex = 5
	logoImg.Parent = logoHolder
	corner(logoImg, UDim.new(1, 0))

	local TEXT_OFFSET = IMG_PAD + IMG_W + 7

	local rank = Instance.new("TextLabel")
	rank.Size = UDim2.new(1, -(TEXT_OFFSET + 8), 0, math.floor(TAG_HEIGHT * 0.38))
	rank.Position = UDim2.new(0, TEXT_OFFSET, 0, math.floor(TAG_HEIGHT * 0.15))
	rank.BackgroundTransparency = 1
	rank.Text = RANK_TEXT
	rank.Font = Enum.Font.LuckiestGuy
	rank.TextScaled = true
	rank.TextColor3 = Color3.fromRGB(255, 255, 255)
	rank.TextXAlignment = Enum.TextXAlignment.Left
	rank.TextStrokeTransparency = 0.5
	rank.ZIndex = 5
	rank.Parent = bg

	local rankGrad = Instance.new("UIGradient")
	rankGrad.Color = ColorSequence.new(GRAD_A, GRAD_B)
	rankGrad.Parent = rank

	local user = Instance.new("TextLabel")
	user.Size = UDim2.new(1, -(TEXT_OFFSET + 8), 0, math.floor(TAG_HEIGHT * 0.26))
	user.Position = UDim2.new(0, TEXT_OFFSET, 0.55, 0)
	user.BackgroundTransparency = 1
	user.Text = "@" .. plr.Name
	user.Font = Enum.Font.Gotham
	user.TextScaled = true
	user.TextColor3 = Color3.fromRGB(255, 255, 255)
	user.TextXAlignment = Enum.TextXAlignment.Left
	user.TextStrokeTransparency = 0.85
	user.ZIndex = 5
	user.Parent = bg

	local isZoomed = false
	local t0 = tick()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not bb or not bb.Parent then
			conn:Disconnect()
			return
		end

		local c = plr.Character
		local h = c and c:FindFirstChild("Head")
		if h then
			bb.Adornee = h
		end

		local t = tick() - t0
		bb.StudsOffset = TAG_OFFSET + Vector3.new(0, math.sin(t * 1.4) * 0.08, 0)

		local cam = workspace.CurrentCamera
		if cam and h then
			local dist = (cam.CFrame.Position - h.Position).Magnitude
			if dist > ZOOMOUT_DISTANCE and not isZoomed then
				isZoomed = true
				TweenService:Create(bb, TweenInfo.new(0.12), {Size = ZOOMOUT_SIZE}):Play()
				TweenService:Create(logoHolder, TweenInfo.new(0.12), {
					Position = UDim2.new(0.5, -20, 0.5, -20),
					Size = UDim2.new(0, 40, 0, 40),
				}):Play()
				rank.Visible = false
				user.Visible = false
			elseif dist <= ZOOMOUT_DISTANCE and isZoomed then
				isZoomed = false
				TweenService:Create(bb, TweenInfo.new(0.12), {Size = UDim2.new(0, TAG_WIDTH, 0, TAG_HEIGHT)}):Play()
				TweenService:Create(logoHolder, TweenInfo.new(0.12), {
					Position = UDim2.new(0, IMG_PAD, 0.5, -IMG_W / 2),
					Size = UDim2.new(0, IMG_W, 0, IMG_W),
				}):Play()
				rank.Visible = true
				user.Visible = true
			end
		end
	end)
end

local function clearOurTags()
	for userId in pairs(taggedByUs) do
		destroyOurTag(userId)
	end
	table.clear(taggedByUs)
end

local function refreshFriendTags()
	if not ACTIVE then
		clearOurTags()
		return
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if friendIds[plr.UserId] and not taggedByUs[plr.UserId] and not hasExistingTag(plr.UserId) then
			buildFriendTag(plr)
		end
	end
end

local function loadFriends()
	table.clear(friendIds)
	local ok, pages = pcall(function()
		return Players:GetFriendsAsync(LocalPlayer.UserId)
	end)
	if not ok or not pages then return end

	while true do
		local pageOk, items = pcall(function()
			return pages:GetCurrentPage()
		end)
		if pageOk and items then
			for _, item in ipairs(items) do
				local id = item.Id or item.VisitorId or item.UserId
				if id then
					friendIds[id] = true
				end
			end
		end
		if pages.IsFinished then break end
		local advOk = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not advOk then break end
	end
end

loadFriends()

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(1)
		if ACTIVE and friendIds[plr.UserId] and not hasExistingTag(plr.UserId) then
			buildFriendTag(plr)
		end
	end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer then
		plr.CharacterAdded:Connect(function()
			task.wait(1)
			if ACTIVE and friendIds[plr.UserId] and not hasExistingTag(plr.UserId) then
				buildFriendTag(plr)
			end
		end)
	end
end

Players.PlayerRemoving:Connect(function(plr)
	destroyOurTag(plr.UserId)
end)

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisFriendTagsGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -120, 0.5, -77)
frame.BackgroundColor3 = THEME.Background
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui
corner(frame, UDim.new(0, 16))
stroke(frame, THEME.Stroke, 1.2)

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
	ColorSequenceKeypoint.new(1, THEME.Background),
})
gradient.Rotation = 90
gradient.Parent = frame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.BackgroundTransparency = 1
titleBar.Size = UDim2.new(1, 0, 0, 48)
titleBar.Parent = frame

local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.BackgroundTransparency = 1
logo.Size = UDim2.new(0, 26, 0, 26)
logo.Position = UDim2.new(0, 12, 0.5, -13)
logo.Image = getLogoImage()
logo.ScaleType = Enum.ScaleType.Fit
logo.Parent = titleBar
corner(logo, UDim.new(0, 8))

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(0, 140, 0, 22)
title.Position = UDim2.new(0, 46, 0.5, -11)
title.Text = "NEMESIS Friend Tags"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = THEME.TextPrimary
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = makeButton(titleBar, { Text = "–", Size = UDim2.new(0, 24, 0, 24) })
minBtn.Position = UDim2.new(1, -58, 0, 12)

local closeBtn = makeButton(titleBar, {
	Text = "×",
	Size = UDim2.new(0, 24, 0, 24),
	TextColor3 = THEME.TextPrimary
})
closeBtn.Position = UDim2.new(1, -30, 0, 12)
closeBtn.TextSize = 16

local divider = Instance.new("Frame")
divider.BackgroundColor3 = THEME.Stroke
divider.BorderSizePixel = 0
divider.Size = UDim2.new(1, -24, 0, 1)
divider.Position = UDim2.new(0, 12, 0, 48)
divider.Parent = frame

-- Content
local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 12, 0, 58)
content.Size = UDim2.new(1, -24, 1, -70)
content.Parent = frame

--------------------------------------------------------------------------------
-- TOGGLE
--------------------------------------------------------------------------------
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 36)
row.BackgroundColor3 = THEME.ButtonIdle
row.BackgroundTransparency = 0.25
row.Parent = content
corner(row, UDim.new(0, 10))
local rowStroke = stroke(row, THEME.Stroke, 1)
rowStroke.Transparency = 0.3

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0.6, 0, 1, 0)
label.Position = UDim2.new(0, 12, 0, 0)
label.BackgroundTransparency = 1
label.Text = "Active"
label.Font = Enum.Font.GothamBold
label.TextSize = 13
label.TextColor3 = THEME.TextMuted
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = row

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 40, 0, 20)
bg.Position = UDim2.new(1, -52, 0.5, -10)
bg.BackgroundColor3 = THEME.Stroke
bg.BorderSizePixel = 0
bg.Parent = row
corner(bg, UDim.new(1, 0))

local circle = Instance.new("Frame")
circle.Size = UDim2.new(0, 14, 0, 14)
circle.Position = UDim2.new(0, 3, 0.5, -7)
circle.BackgroundColor3 = Color3.new(1, 1, 1)
circle.BorderSizePixel = 0
circle.Parent = bg
corner(circle, UDim.new(1, 0))

local on = false
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.Parent = row

toggleBtn.MouseButton1Click:Connect(function()
	on = not on
	ACTIVE = on
	if on then
		tween(bg, {BackgroundColor3 = THEME.Accent}, HOVER_TWEEN_INFO)
		circle:TweenPosition(UDim2.new(1, -17, 0.5, -7), "Out", "Quad", 0.15, true)
		loadFriends()
		refreshFriendTags()
	else
		tween(bg, {BackgroundColor3 = THEME.Stroke}, HOVER_TWEEN_INFO)
		circle:TweenPosition(UDim2.new(0, 3, 0.5, -7), "Out", "Quad", 0.15, true)
		clearOurTags()
	end
end)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 40)
info.Position = UDim2.new(0, 0, 0, 48)
info.BackgroundTransparency = 1
info.Text = "Added Friends get a red FRIEND tag"
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextColor3 = THEME.TextMuted
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = content

--------------------------------------------------------------------------------
-- WINDOW CONTROLS
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	ACTIVE = false
	clearOurTags()
	gui:Destroy()
end)

local minimized = false
local expandedSize = OPEN_SIZE
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		expandedSize = frame.Size
		content.Visible = false
		divider.Visible = false
		tween(frame, { Size = UDim2.new(0, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT) })
		minBtn.Text = "+"
	else
		tween(frame, { Size = expandedSize })
		task.delay(TWEEN_INFO.Time, function()
			content.Visible = true
			divider.Visible = true
		end)
		minBtn.Text = "–"
	end
end)

-- Dragging
local draggingWindow, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingWindow = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingWindow and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingWindow = false
	end
end)