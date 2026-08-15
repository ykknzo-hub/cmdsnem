-- NEMESIS-STYLE UI - SLIDERS PANEL (Xeno Max Compatibility)
-- Matches AntiVCB style
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safely determine where to parent the UI without triggering executor blocks
local TargetGuiService = (typeof(gethui) == "function" and gethui()) or PlayerGui

-- Prevent duplicate UI instances
local existing = TargetGuiService:FindFirstChild("NemesisSlidersGui")
if existing then existing:Destroy() end

--------------------------------------------------------------------------------
-- UI THEME & CONFIGURATION (exact same as AntiVCB)
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

local OPEN_SIZE        = UDim2.new(0, 260, 0, 320)
local COLLAPSED_HEIGHT = 48
local TWEEN_INFO       = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
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
-- HELPER FUNCTIONS FOR UI STYLING
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
		tween(btn, { BackgroundColor3 = THEME.ButtonHover, BackgroundTransparency = 0.1 }, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Accent, Transparency = 0 }, HOVER_TWEEN_INFO)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle, BackgroundTransparency = props.BackgroundTransparency or 0.25 }, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Stroke, Transparency = 0.3 }, HOVER_TWEEN_INFO)
	end)

	return btn
end

--------------------------------------------------------------------------------
-- MAIN UI CONSTRUCTION
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisSlidersGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGuiService

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -130, 0.5, -160)
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
title.Size = UDim2.new(0, 150, 0, 22)
title.Position = UDim2.new(0, 46, 0.5, -11)
title.Text = "NEMESIS Sliders"
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

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 12, 0, 58)
content.Size = UDim2.new(1, -24, 1, -70)
content.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 10)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = content

--------------------------------------------------------------------------------
-- SLIDER BUILDER
--------------------------------------------------------------------------------
local function createSlider(labelText, minV, maxV, defV, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundColor3 = THEME.ButtonIdle
	row.BackgroundTransparency = 0.25
	row.Parent = content
	corner(row, UDim.new(0, 10))
	stroke(row, THEME.Stroke, 1).Transparency = 0.3

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.5, 0, 0, 18)
	label.Position = UDim2.new(0, 12, 0, 6)
	label.Text = labelText
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = THEME.TextMuted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Size = UDim2.new(0.3, 0, 0, 18)
	valLbl.Position = UDim2.new(0.45, 0, 0, 6)
	valLbl.Text = tostring(defV)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 12
	valLbl.TextColor3 = THEME.Accent
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = row

	local resetBtn = makeButton(row, {
		Text = "reset",
		Size = UDim2.new(0, 40, 0, 18),
		TextSize = 10,
		BackgroundTransparency = 0.15,
	})
	resetBtn.Position = UDim2.new(1, -52, 0, 6)

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -24, 0, 6)
	track.Position = UDim2.new(0, 12, 0, 32)
	track.BackgroundColor3 = THEME.Stroke
	track.BorderSizePixel = 0
	track.Parent = row
	corner(track, UDim.new(1, 0))

	local pct = (defV - minV) / (maxV - minV)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(pct, 0, 1, 0)
	fill.BackgroundColor3 = THEME.Accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, UDim.new(1, 0))

	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.new(0, 14, 0, 14)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = UDim2.new(pct, 0, 0.5, 0)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 4
	thumb.Parent = track
	corner(thumb, UDim.new(1, 0))
	stroke(thumb, THEME.Accent, 2)

	local sliding = false

	local function setValue(v)
		local r = math.clamp((v - minV) / (maxV - minV), 0, 1)
		fill.Size = UDim2.new(r, 0, 1, 0)
		thumb.Position = UDim2.new(r, 0, 0.5, 0)
		valLbl.Text = tostring(v)
		callback(v)
	end

	local function update(ix)
		local tp = track.AbsolutePosition.X
		local ts = track.AbsoluteSize.X
		local r = math.clamp((ix - tp) / ts, 0, 1)
		local v = math.floor(minV + (maxV - minV) * r + 0.5)
		setValue(v)
	end

	resetBtn.MouseButton1Click:Connect(function()
		setValue(defV)
	end)

	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = true
			update(i.Position.X)
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
	thumb.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			update(i.Position.X)
		end
	end)
end

--------------------------------------------------------------------------------
-- TOGGLE BUILDER
--------------------------------------------------------------------------------
local function createToggleRow(labelText, initialState, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = THEME.ButtonIdle
	row.BackgroundTransparency = 0.25
	row.Parent = content
	corner(row, UDim.new(0, 10))
	stroke(row, THEME.Stroke, 1).Transparency = 0.3

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.6, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Text = labelText
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = THEME.TextMuted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0, 40, 0, 20)
	bg.Position = UDim2.new(1, -52, 0.5, -10)
	bg.BackgroundColor3 = initialState and THEME.Accent or THEME.Stroke
	bg.BorderSizePixel = 0
	bg.Parent = row
	corner(bg, UDim.new(1, 0))

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 14, 0, 14)
	circle.Position = initialState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	circle.BorderSizePixel = 0
	circle.Parent = bg
	corner(circle, UDim.new(1, 0))

	local on = initialState
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = row

	btn.MouseButton1Click:Connect(function()
		on = not on
		if on then
			tween(bg, { BackgroundColor3 = THEME.Accent })
			circle:TweenPosition(UDim2.new(1, -17, 0.5, -7), "Out", "Quad", 0.15, true)
		else
			tween(bg, { BackgroundColor3 = THEME.Stroke })
			circle:TweenPosition(UDim2.new(0, 3, 0.5, -7), "Out", "Quad", 0.15, true)
		end
		callback(on)
	end)
end

--------------------------------------------------------------------------------
-- BUILD CONTROLS
--------------------------------------------------------------------------------
createSlider("Walk Speed", 0, 500, 16, function(v)
	local c = LocalPlayer.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if h then h.WalkSpeed = v end
end)

createSlider("Jump Power", 0, 350, 50, function(v)
	local c = LocalPlayer.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if h then
		if h.UseJumpPower then
			h.JumpPower = v
		else
			h.JumpHeight = v
		end
	end
end)

createSlider("Field of View", 1, 120, 70, function(v)
	Camera.FieldOfView = v
end)

local origZoom
createToggleRow("Infinite Zoom", false, function(on)
	if on then
		origZoom = LocalPlayer.CameraMaxZoomDistance
		LocalPlayer.CameraMaxZoomDistance = 999999
		LocalPlayer.CameraMinZoomDistance = 0
	else
		LocalPlayer.CameraMaxZoomDistance = origZoom or 128
		LocalPlayer.CameraMinZoomDistance = 0.5
	end
end)

--------------------------------------------------------------------------------
-- WINDOW CONTROLS
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
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
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingWindow = false
	end
end)