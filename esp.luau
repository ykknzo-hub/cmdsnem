-- NEMESIS ESP (Outline Only + Shorter UI)
-- Matches AntiVCB style + Minimize button
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local TargetGui = (typeof(gethui) == "function" and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

local existing = TargetGui:FindFirstChild("NemesisESPGui")
if existing then existing:Destroy() end

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
}

local OPEN_SIZE = UDim2.new(0, 260, 0, 160)
local COLLAPSED_HEIGHT = 48
local TWEEN_INFO = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--------------------------------------------------------------------------------
-- LOGO SETTINGS (same as AntiVCB)
--------------------------------------------------------------------------------
local LOGO_PATH          = "whitelogo.png"
local LOGO_DOWNLOAD_URL  = "https://i.ibb.co/SwGkMS5h/whitelogo.png" -- ← paste a direct PNG link here
local FALLBACK_LOGO      = "rbxassetid://107541043103322"

local function getLogoImage()
	if typeof(getcustomasset) == "function" then
		if isfile and isfile(LOGO_PATH) then
			local ok, asset = pcall(getcustomasset, LOGO_PATH)
			if ok and asset then
				return asset
			end
		end

		if LOGO_DOWNLOAD_URL ~= "" and (not isfile or not isfile(LOGO_PATH)) then
			local ok, data = pcall(function()
				return game:HttpGet(LOGO_DOWNLOAD_URL)
			end)
			if ok and type(data) == "string" and #data > 200 then
				pcall(writefile, LOGO_PATH, data)
				if isfile and isfile(LOGO_PATH) then
					local ok2, asset = pcall(getcustomasset, LOGO_PATH)
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
local function tween(inst, props, info)
	TweenService:Create(inst, info or TWEEN_INFO, props):Play()
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = r or UDim.new(0, 12)
	c.Parent = parent
end

local function stroke(parent, color, t)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.Stroke
	s.Thickness = t or 1
	s.Parent = parent
	return s
end

local function makeButton(parent, props)
	local btn = Instance.new("TextButton")
	btn.Size = props.Size or UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle
	btn.BackgroundTransparency = 0.25
	btn.AutoButtonColor = false
	btn.Text = props.Text or ""
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = props.TextSize or 12
	btn.TextColor3 = props.TextColor3 or THEME.TextPrimary
	btn.Parent = parent
	corner(btn, UDim.new(0, 8))
	local s = stroke(btn)
	s.Transparency = 0.3

	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundTransparency = 0.1, BackgroundColor3 = THEME.ButtonHover}, HOVER_TWEEN_INFO)
		tween(s, {Color = THEME.Accent, Transparency = 0}, HOVER_TWEEN_INFO)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundTransparency = 0.25, BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle}, HOVER_TWEEN_INFO)
		tween(s, {Color = THEME.Stroke, Transparency = 0.3}, HOVER_TWEEN_INFO)
	end)
	return btn
end

--------------------------------------------------------------------------------
-- ESP
--------------------------------------------------------------------------------
local ESP_ENABLED = false
local ESP_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_OBJECTS = {}

local function clearESP()
	for player, highlight in pairs(ESP_OBJECTS) do
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
	end
	table.clear(ESP_OBJECTS)
end

local function createESP(player)
	if player == LocalPlayer then return end
	if ESP_OBJECTS[player] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "NemesisESP"
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = ESP_COLOR
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = nil
	highlight.Parent = TargetGui

	ESP_OBJECTS[player] = highlight
end

local function updateESP()
	if not ESP_ENABLED then
		clearESP()
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end

		if not ESP_OBJECTS[player] then
			createESP(player)
		end

		local highlight = ESP_OBJECTS[player]
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if char and hum and hum.Health > 0 then
			highlight.Adornee = char
			highlight.OutlineColor = ESP_COLOR
		else
			highlight.Adornee = nil
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	if ESP_OBJECTS[player] then
		ESP_OBJECTS[player]:Destroy()
		ESP_OBJECTS[player] = nil
	end
end)

RunService.RenderStepped:Connect(updateESP)

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisESPGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGui

local frame = Instance.new("Frame")
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -130, 0.5, -80)
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

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundTransparency = 1
titleBar.Parent = frame

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(0, 26, 0, 26)
logo.Position = UDim2.new(0, 12, 0.5, -13)
logo.BackgroundTransparency = 1
logo.Image = getLogoImage()
logo.ScaleType = Enum.ScaleType.Fit
logo.Parent = titleBar
corner(logo, UDim.new(0, 8))

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 120, 0, 18)
title.Position = UDim2.new(0, 46, 0.5, -9)
title.BackgroundTransparency = 1
title.Text = "NEMESIS ESP"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = THEME.TextPrimary
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Minimize button
local minBtn = makeButton(titleBar, {
	Text = "–",
	Size = UDim2.new(0, 24, 0, 24),
	TextColor3 = THEME.TextPrimary
})
minBtn.Position = UDim2.new(1, -58, 0.5, -12)

-- Close button
local closeBtn = makeButton(titleBar, {
	Text = "×",
	Size = UDim2.new(0, 24, 0, 24),
	TextColor3 = THEME.TextPrimary
})
closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
closeBtn.TextSize = 16

local divider = Instance.new("Frame")
divider.BackgroundColor3 = THEME.Stroke
divider.BorderSizePixel = 0
divider.Size = UDim2.new(1, -24, 0, 1)
divider.Position = UDim2.new(0, 12, 0, 48)
divider.Parent = frame

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -24, 1, -60)
content.Position = UDim2.new(0, 12, 0, 54)
content.BackgroundTransparency = 1
content.Parent = frame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.Parent = content

--------------------------------------------------------------------------------
-- TOGGLE
--------------------------------------------------------------------------------
local function createToggle(text, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = THEME.ButtonIdle
	row.BackgroundTransparency = 0.25
	row.Parent = content
	corner(row, UDim.new(0, 10))
	stroke(row).Transparency = 0.3

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = THEME.TextMuted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0, 40, 0, 20)
	bg.Position = UDim2.new(1, -52, 0.5, -10)
	bg.BackgroundColor3 = default and THEME.Accent or THEME.Stroke
	bg.BorderSizePixel = 0
	bg.Parent = row
	corner(bg, UDim.new(1, 0))

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 14, 0, 14)
	circle.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	circle.BackgroundColor3 = Color3.new(1, 1, 1)
	circle.BorderSizePixel = 0
	circle.Parent = bg
	corner(circle, UDim.new(1, 0))

	local on = default
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = row

	btn.MouseButton1Click:Connect(function()
		on = not on
		if on then
			tween(bg, {BackgroundColor3 = THEME.Accent})
			circle:TweenPosition(UDim2.new(1, -17, 0.5, -7), "Out", "Quad", 0.15, true)
		else
			tween(bg, {BackgroundColor3 = THEME.Stroke})
			circle:TweenPosition(UDim2.new(0, 3, 0.5, -7), "Out", "Quad", 0.15, true)
		end
		callback(on)
	end)
end

createToggle("Enable ESP", false, function(v)
	ESP_ENABLED = v
	if not v then
		clearESP()
	end
end)

--------------------------------------------------------------------------------
-- COLOR SLIDER
--------------------------------------------------------------------------------
local colorRow = Instance.new("Frame")
colorRow.Size = UDim2.new(1, 0, 0, 56)
colorRow.BackgroundColor3 = THEME.ButtonIdle
colorRow.BackgroundTransparency = 0.25
colorRow.Parent = content
corner(colorRow, UDim.new(0, 10))
stroke(colorRow).Transparency = 0.3

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(1, -50, 0, 16)
colorLabel.Position = UDim2.new(0, 12, 0, 6)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "Outline Color"
colorLabel.Font = Enum.Font.GothamBold
colorLabel.TextSize = 12
colorLabel.TextColor3 = THEME.TextMuted
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Parent = colorRow

local preview = Instance.new("Frame")
preview.Size = UDim2.new(0, 22, 0, 14)
preview.Position = UDim2.new(1, -34, 0, 7)
preview.BackgroundColor3 = ESP_COLOR
preview.BorderSizePixel = 0
preview.Parent = colorRow
corner(preview, UDim.new(0, 5))

local track = Instance.new("Frame")
track.Size = UDim2.new(1, -24, 0, 12)
track.Position = UDim2.new(0, 12, 0, 30)
track.BorderSizePixel = 0
track.Parent = colorRow
corner(track, UDim.new(1, 0))

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
	ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
})
grad.Parent = track

local thumb = Instance.new("Frame")
thumb.Size = UDim2.new(0, 14, 0, 14)
thumb.AnchorPoint = Vector2.new(0.5, 0.5)
thumb.Position = UDim2.new(0.0, 0, 0.5, 0)
thumb.BackgroundColor3 = Color3.new(1, 1, 1)
thumb.BorderSizePixel = 0
thumb.ZIndex = 3
thumb.Parent = track
corner(thumb, UDim.new(1, 0))
stroke(thumb, Color3.new(0, 0, 0), 1)

local sliding = false

local function setHue(x)
	local r = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
	thumb.Position = UDim2.new(r, 0, 0.5, 0)
	ESP_COLOR = Color3.fromHSV(r, 1, 1)
	preview.BackgroundColor3 = ESP_COLOR
end

track.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sliding = true
		setHue(i.Position.X)
	end
end)
track.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sliding = false
	end
end)
thumb.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sliding = true
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		setHue(i.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sliding = false
	end
end)

--------------------------------------------------------------------------------
-- WINDOW CONTROLS (Minimize + Close)
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	ESP_ENABLED = false
	clearESP()
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

--------------------------------------------------------------------------------
-- DRAG
--------------------------------------------------------------------------------
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
