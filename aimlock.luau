-- Combined NEMESIS Template UI + AIMLOCK Script
-- Matches AntiVCB style
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local pg = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicate UI instances
local existing = pg:FindFirstChild("AimlockGui")
if existing then existing:Destroy() end

--------------------------------------------------------------------------------
-- UI THEME & SIZING CONFIGURATION (exact same as AntiVCB)
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
	ToggleOn     = Color3.fromRGB(255, 255, 255),
	ToggleOff    = Color3.fromRGB(80, 80, 80),
}

local OPEN_SIZE        = UDim2.new(0, 280, 0, 520)
local COLLAPSED_HEIGHT = 48
local MIN_SIZE         = Vector2.new(240, 200)
local MAX_SIZE         = Vector2.new(500, 600)
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
	btn.Size = props.Size or UDim2.new(0, 24, 0, 24)
	btn.BackgroundColor3 = THEME.ButtonIdle
	btn.BackgroundTransparency = 0.25
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
		tween(btn, { BackgroundColor3 = THEME.ButtonIdle, BackgroundTransparency = 0.25 }, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Stroke, Transparency = 0.3 }, HOVER_TWEEN_INFO)
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, { Size = btn.Size - UDim2.new(0, 2, 0, 2) }, HOVER_TWEEN_INFO)
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, { Size = props.Size or UDim2.new(0, 24, 0, 24) }, HOVER_TWEEN_INFO)
	end)

	return btn
end

local function makeToggle(parent, label, defaultState, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 36)
	container.BackgroundColor3 = THEME.ButtonIdle
	container.BackgroundTransparency = 0.25
	container.Parent = parent
	corner(container, UDim.new(0, 10))
	stroke(container, THEME.Stroke, 1).Transparency = 0.3

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(0.6, 0, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.Text = label
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextColor3 = THEME.TextMuted
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = container

	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 40, 0, 20)
	toggleBg.Position = UDim2.new(1, -52, 0.5, -10)
	toggleBg.BackgroundColor3 = defaultState and THEME.ToggleOn or THEME.ToggleOff
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	corner(toggleBg, UDim.new(1, 0))

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = defaultState and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = toggleBg
	corner(knob, UDim.new(1, 0))

	local state = defaultState
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = ""
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.Parent = toggleBg

	toggleBtn.MouseButton1Click:Connect(function()
		state = not state
		tween(toggleBg, { BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff })
		tween(knob, { Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) })
		if callback then callback(state) end
	end)

	return container, function() return state end
end

--------------------------------------------------------------------------------
-- UI CONSTRUCTION
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AimlockGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -140, 0.5, -260)
frame.BackgroundColor3 = THEME.Background
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui
corner(frame, UDim.new(0, 16))
local frameStroke = stroke(frame, THEME.Stroke, 1.2)
frameStroke.LineJoinMode = Enum.LineJoinMode.Round
frameStroke.Transparency = 0.15

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
logo.BackgroundTransparency = 1
logo.Size = UDim2.new(0, 26, 0, 26)
logo.Position = UDim2.new(0, 12, 0.5, -13)
logo.Image = getLogoImage()
logo.ScaleType = Enum.ScaleType.Fit
logo.Parent = titleBar
corner(logo, UDim.new(0, 8))

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(0, 150, 0, 22)
title.Position = UDim2.new(0, 46, 0.5, -11)
title.Text = "NEMESIS Aimlock"
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

local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Position = UDim2.new(0, 12, 0, 58)
content.Size = UDim2.new(1, -24, 1, -70)
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = THEME.Accent
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = content

--------------------------------------------------------------------------------
-- AIMLOCK CONFIGURATION & LOGIC
--------------------------------------------------------------------------------
local aimlockConfig = {
	Enabled = false,
	TargetPlayer = nil,
	Smoothness = 0.5,
	Sensitivity = 1.0,
	VisibleOnly = true,
	TargetTeam = false,
	Keybind = Enum.KeyCode.E,
	ToggleKeybind = Enum.KeyCode.T,
	FOVRadius = 150,
	ShowFOV = true,
	FOVColor = Color3.fromRGB(255, 255, 255),
	FOVTransparency = 0.5,
	FOVThickness = 2,
	FOVFilled = false,
	TargetPartMode = "Head",
}

local camera = workspace.CurrentCamera
local renderConnection = nil
local targetListUpdated = false

local function getAimCenter()
	local mouse = LocalPlayer:GetMouse()
	return Vector2.new(mouse.X, mouse.Y)
end

-- FOV Circle Setup
local fovCircle = nil
local function createFOVCircle()
	if fovCircle then pcall(function() fovCircle:Remove() end) end
	if not aimlockConfig.ShowFOV then return end
	if typeof(Drawing) == "userdata" or Drawing then
		fovCircle = Drawing.new("Circle")
		fovCircle.Visible = true
		fovCircle.Position = getAimCenter()
		fovCircle.Radius = aimlockConfig.FOVRadius
		fovCircle.Color = aimlockConfig.FOVColor
		fovCircle.Transparency = aimlockConfig.FOVTransparency
		fovCircle.Thickness = aimlockConfig.FOVThickness
		fovCircle.Filled = aimlockConfig.FOVFilled
	end
end

local function updateFOVCircle()
	if not aimlockConfig.ShowFOV or not fovCircle then return end
	if fovCircle then
		fovCircle.Position = getAimCenter()
		fovCircle.Radius = aimlockConfig.FOVRadius
		fovCircle.Color = aimlockConfig.FOVColor
		fovCircle.Transparency = aimlockConfig.FOVTransparency
		fovCircle.Thickness = aimlockConfig.FOVThickness
		fovCircle.Filled = aimlockConfig.FOVFilled
	end
end

-- Status Display
local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, 0, 0, 22)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Status: Inactive"
StatusText.TextColor3 = Color3.fromRGB(160, 160, 160)
StatusText.TextSize = 12
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = content

-- Create Toggles
local toggleEnabled, getToggleEnabled = makeToggle(content, "Enable Aimlock", false, function(state)
	aimlockConfig.Enabled = state
	if state then
		tween(StatusText, { TextColor3 = THEME.Accent })
		StatusText.Text = "Status: Active (no target)"
		startAimlock()
	else
		StatusText.Text = "Status: Inactive"
		tween(StatusText, { TextColor3 = Color3.fromRGB(160, 160, 160) })
		stopAimlock()
	end
end)

local toggleVisibleOnly, getToggleVisibleOnly = makeToggle(content, "Visible Only", true, function(state)
	aimlockConfig.VisibleOnly = state
end)

local toggleTeamCheck, getToggleTeamCheck = makeToggle(content, "Ignore Team", false, function(state)
	aimlockConfig.TargetTeam = state
end)

-- Sensitivity Slider
local sensitivityContainer = Instance.new("Frame")
sensitivityContainer.Size = UDim2.new(1, 0, 0, 36)
sensitivityContainer.BackgroundColor3 = THEME.ButtonIdle
sensitivityContainer.BackgroundTransparency = 0.25
sensitivityContainer.Parent = content
corner(sensitivityContainer, UDim.new(0, 10))
stroke(sensitivityContainer, THEME.Stroke, 1).Transparency = 0.3

local sensitivityLabel = Instance.new("TextLabel")
sensitivityLabel.BackgroundTransparency = 1
sensitivityLabel.Size = UDim2.new(0.5, 0, 0, 16)
sensitivityLabel.Position = UDim2.new(0, 12, 0, 4)
sensitivityLabel.Text = "Smoothness: 0.50x"
sensitivityLabel.Font = Enum.Font.GothamBold
sensitivityLabel.TextSize = 11
sensitivityLabel.TextColor3 = THEME.TextMuted
sensitivityLabel.TextXAlignment = Enum.TextXAlignment.Left
sensitivityLabel.Parent = sensitivityContainer

local sensitivitySlider = Instance.new("Frame")
sensitivitySlider.Size = UDim2.new(1, -24, 0, 6)
sensitivitySlider.Position = UDim2.new(0, 12, 0, 24)
sensitivitySlider.BackgroundColor3 = THEME.Stroke
sensitivitySlider.BorderSizePixel = 0
sensitivitySlider.Parent = sensitivityContainer
corner(sensitivitySlider, UDim.new(1, 0))

local sensitivityFill = Instance.new("Frame")
sensitivityFill.Size = UDim2.new(0.5, 0, 1, 0)
sensitivityFill.BackgroundColor3 = THEME.Accent
sensitivityFill.BorderSizePixel = 0
sensitivityFill.Parent = sensitivitySlider
corner(sensitivityFill, UDim.new(1, 0))

local sensitivityButton = Instance.new("TextButton")
sensitivityButton.BackgroundColor3 = THEME.Accent
sensitivityButton.BorderSizePixel = 0
sensitivityButton.Text = ""
sensitivityButton.Size = UDim2.new(0, 12, 1, 6)
sensitivityButton.Position = UDim2.new(0.5, -6, 0.5, -3)
sensitivityButton.AutoButtonColor = false
sensitivityButton.Parent = sensitivitySlider
corner(sensitivityButton, UDim.new(1, 0))

local isDragging = false
sensitivityButton.MouseButton1Down:Connect(function()
	isDragging = true
	local mouse = LocalPlayer:GetMouse()
	while isDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		local relX = math.clamp((mouse.X - sensitivitySlider.AbsolutePosition.X) / sensitivitySlider.AbsoluteSize.X, 0, 1)
		aimlockConfig.Smoothness = math.round(relX * 100) / 100
		sensitivityFill.Size = UDim2.new(relX, 0, 1, 0)
		sensitivityButton.Position = UDim2.new(relX, -6, 0.5, -3)
		sensitivityLabel.Text = "Smoothness: " .. string.format("%.2f", aimlockConfig.Smoothness) .. "x"
		task.wait()
	end
	isDragging = false
end)

-- FOV Radius Slider
local fovContainer = Instance.new("Frame")
fovContainer.Size = UDim2.new(1, 0, 0, 36)
fovContainer.BackgroundColor3 = THEME.ButtonIdle
fovContainer.BackgroundTransparency = 0.25
fovContainer.Parent = content
corner(fovContainer, UDim.new(0, 10))
stroke(fovContainer, THEME.Stroke, 1).Transparency = 0.3

local fovLabel = Instance.new("TextLabel")
fovLabel.BackgroundTransparency = 1
fovLabel.Size = UDim2.new(0.5, 0, 0, 16)
fovLabel.Position = UDim2.new(0, 12, 0, 4)
fovLabel.Text = "FOV Radius: 150"
fovLabel.Font = Enum.Font.GothamBold
fovLabel.TextSize = 11
fovLabel.TextColor3 = THEME.TextMuted
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Parent = fovContainer

local fovSlider = Instance.new("Frame")
fovSlider.Size = UDim2.new(1, -24, 0, 6)
fovSlider.Position = UDim2.new(0, 12, 0, 24)
fovSlider.BackgroundColor3 = THEME.Stroke
fovSlider.BorderSizePixel = 0
fovSlider.Parent = fovContainer
corner(fovSlider, UDim.new(1, 0))

local fovFill = Instance.new("Frame")
fovFill.Size = UDim2.new(0.25, 0, 1, 0)
fovFill.BackgroundColor3 = THEME.Accent
fovFill.BorderSizePixel = 0
fovFill.Parent = fovSlider
corner(fovFill, UDim.new(1, 0))

local fovButton = Instance.new("TextButton")
fovButton.BackgroundColor3 = THEME.Accent
fovButton.BorderSizePixel = 0
fovButton.Text = ""
fovButton.Size = UDim2.new(0, 12, 1, 6)
fovButton.Position = UDim2.new(0.25, -6, 0.5, -3)
fovButton.AutoButtonColor = false
fovButton.Parent = fovSlider
corner(fovButton, UDim.new(1, 0))

local isFovDragging = false
fovButton.MouseButton1Down:Connect(function()
	isFovDragging = true
	local mouse = LocalPlayer:GetMouse()
	while isFovDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		local relX = math.clamp((mouse.X - fovSlider.AbsolutePosition.X) / fovSlider.AbsoluteSize.X, 0, 1)
		aimlockConfig.FOVRadius = math.round(50 + relX * 400)
		fovFill.Size = UDim2.new(relX, 0, 1, 0)
		fovButton.Position = UDim2.new(relX, -6, 0.5, -3)
		fovLabel.Text = "FOV Radius: " .. aimlockConfig.FOVRadius
		task.wait()
	end
	isFovDragging = false
end)

-- FOV Display Toggle
local toggleFOV, getToggleFOV = makeToggle(content, "Show FOV Circle", true, function(state)
	aimlockConfig.ShowFOV = state
	if aimlockConfig.Enabled then
		if state then
			createFOVCircle()
		else
			if fovCircle then
				pcall(function() fovCircle:Remove() end)
				fovCircle = nil
			end
		end
	end
end)

-- FOV Transparency Slider
local fovTransContainer = Instance.new("Frame")
fovTransContainer.Size = UDim2.new(1, 0, 0, 36)
fovTransContainer.BackgroundColor3 = THEME.ButtonIdle
fovTransContainer.BackgroundTransparency = 0.25
fovTransContainer.Parent = content
corner(fovTransContainer, UDim.new(0, 10))
stroke(fovTransContainer, THEME.Stroke, 1).Transparency = 0.3

local fovTransLabel = Instance.new("TextLabel")
fovTransLabel.BackgroundTransparency = 1
fovTransLabel.Size = UDim2.new(0.5, 0, 0, 16)
fovTransLabel.Position = UDim2.new(0, 12, 0, 4)
fovTransLabel.Text = "Transparency: 0.50"
fovTransLabel.Font = Enum.Font.GothamBold
fovTransLabel.TextSize = 11
fovTransLabel.TextColor3 = THEME.TextMuted
fovTransLabel.TextXAlignment = Enum.TextXAlignment.Left
fovTransLabel.Parent = fovTransContainer

local fovTransSlider = Instance.new("Frame")
fovTransSlider.Size = UDim2.new(1, -24, 0, 6)
fovTransSlider.Position = UDim2.new(0, 12, 0, 24)
fovTransSlider.BackgroundColor3 = THEME.Stroke
fovTransSlider.BorderSizePixel = 0
fovTransSlider.Parent = fovTransContainer
corner(fovTransSlider, UDim.new(1, 0))

local fovTransFill = Instance.new("Frame")
fovTransFill.Size = UDim2.new(0.5, 0, 1, 0)
fovTransFill.BackgroundColor3 = THEME.Accent
fovTransFill.BorderSizePixel = 0
fovTransFill.Parent = fovTransSlider
corner(fovTransFill, UDim.new(1, 0))

local fovTransButton = Instance.new("TextButton")
fovTransButton.BackgroundColor3 = THEME.Accent
fovTransButton.BorderSizePixel = 0
fovTransButton.Text = ""
fovTransButton.Size = UDim2.new(0, 12, 1, 6)
fovTransButton.Position = UDim2.new(0.5, -6, 0.5, -3)
fovTransButton.AutoButtonColor = false
fovTransButton.Parent = fovTransSlider
corner(fovTransButton, UDim.new(1, 0))

local isTransDragging = false
fovTransButton.MouseButton1Down:Connect(function()
	isTransDragging = true
	local mouse = LocalPlayer:GetMouse()
	while isTransDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		local relX = math.clamp((mouse.X - fovTransSlider.AbsolutePosition.X) / fovTransSlider.AbsoluteSize.X, 0, 1)
		aimlockConfig.FOVTransparency = math.round(relX * 100) / 100
		fovTransFill.Size = UDim2.new(relX, 0, 1, 0)
		fovTransButton.Position = UDim2.new(relX, -6, 0.5, -3)
		fovTransLabel.Text = "Transparency: " .. string.format("%.2f", aimlockConfig.FOVTransparency)
		task.wait()
	end
	isTransDragging = false
end)

-- FOV Thickness Slider
local fovThickContainer = Instance.new("Frame")
fovThickContainer.Size = UDim2.new(1, 0, 0, 36)
fovThickContainer.BackgroundColor3 = THEME.ButtonIdle
fovThickContainer.BackgroundTransparency = 0.25
fovThickContainer.Parent = content
corner(fovThickContainer, UDim.new(0, 10))
stroke(fovThickContainer, THEME.Stroke, 1).Transparency = 0.3

local fovThickLabel = Instance.new("TextLabel")
fovThickLabel.BackgroundTransparency = 1
fovThickLabel.Size = UDim2.new(0.5, 0, 0, 16)
fovThickLabel.Position = UDim2.new(0, 12, 0, 4)
fovThickLabel.Text = "Thickness: 2"
fovThickLabel.Font = Enum.Font.GothamBold
fovThickLabel.TextSize = 11
fovThickLabel.TextColor3 = THEME.TextMuted
fovThickLabel.TextXAlignment = Enum.TextXAlignment.Left
fovThickLabel.Parent = fovThickContainer

local fovThickSlider = Instance.new("Frame")
fovThickSlider.Size = UDim2.new(1, -24, 0, 6)
fovThickSlider.Position = UDim2.new(0, 12, 0, 24)
fovThickSlider.BackgroundColor3 = THEME.Stroke
fovThickSlider.BorderSizePixel = 0
fovThickSlider.Parent = fovThickContainer
corner(fovThickSlider, UDim.new(1, 0))

local fovThickFill = Instance.new("Frame")
fovThickFill.Size = UDim2.new(0.25, 0, 1, 0)
fovThickFill.BackgroundColor3 = THEME.Accent
fovThickFill.BorderSizePixel = 0
fovThickFill.Parent = fovThickSlider
corner(fovThickFill, UDim.new(1, 0))

local fovThickButton = Instance.new("TextButton")
fovThickButton.BackgroundColor3 = THEME.Accent
fovThickButton.BorderSizePixel = 0
fovThickButton.Text = ""
fovThickButton.Size = UDim2.new(0, 12, 1, 6)
fovThickButton.Position = UDim2.new(0.25, -6, 0.5, -3)
fovThickButton.AutoButtonColor = false
fovThickButton.Parent = fovThickSlider
corner(fovThickButton, UDim.new(1, 0))

local isThickDragging = false
fovThickButton.MouseButton1Down:Connect(function()
	isThickDragging = true
	local mouse = LocalPlayer:GetMouse()
	while isThickDragging and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		local relX = math.clamp((mouse.X - fovThickSlider.AbsolutePosition.X) / fovThickSlider.AbsoluteSize.X, 0, 1)
		aimlockConfig.FOVThickness = math.max(1, math.round(relX * 8))
		fovThickFill.Size = UDim2.new(relX, 0, 1, 0)
		fovThickButton.Position = UDim2.new(relX, -6, 0.5, -3)
		fovThickLabel.Text = "Thickness: " .. aimlockConfig.FOVThickness
		task.wait()
	end
	isThickDragging = false
end)

-- FOV Color Picker
local colorOptions = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(255, 165, 0),
	Color3.fromRGB(255, 0, 255),
	Color3.fromRGB(0, 255, 255),
}

local colorIndex = 1
local fovColorContainer = Instance.new("Frame")
fovColorContainer.Size = UDim2.new(1, 0, 0, 36)
fovColorContainer.BackgroundColor3 = THEME.ButtonIdle
fovColorContainer.BackgroundTransparency = 0.25
fovColorContainer.Parent = content
corner(fovColorContainer, UDim.new(0, 10))
stroke(fovColorContainer, THEME.Stroke, 1).Transparency = 0.3

local fovColorLabel = Instance.new("TextLabel")
fovColorLabel.BackgroundTransparency = 1
fovColorLabel.Size = UDim2.new(0.6, 0, 1, 0)
fovColorLabel.Position = UDim2.new(0, 12, 0, 0)
fovColorLabel.Text = "Circle Color"
fovColorLabel.Font = Enum.Font.GothamBold
fovColorLabel.TextSize = 12
fovColorLabel.TextColor3 = THEME.TextMuted
fovColorLabel.TextXAlignment = Enum.TextXAlignment.Left
fovColorLabel.Parent = fovColorContainer

local fovColorBtn = Instance.new("TextButton")
fovColorBtn.Size = UDim2.new(0, 48, 0, 20)
fovColorBtn.Position = UDim2.new(1, -60, 0.5, -10)
fovColorBtn.BackgroundColor3 = aimlockConfig.FOVColor
fovColorBtn.Text = "✓"
fovColorBtn.Font = Enum.Font.GothamBold
fovColorBtn.TextSize = 12
fovColorBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
fovColorBtn.BorderSizePixel = 0
fovColorBtn.AutoButtonColor = false
fovColorBtn.Parent = fovColorContainer
corner(fovColorBtn, UDim.new(0, 6))

fovColorBtn.MouseButton1Click:Connect(function()
	colorIndex = colorIndex % #colorOptions + 1
	aimlockConfig.FOVColor = colorOptions[colorIndex]
	fovColorBtn.BackgroundColor3 = aimlockConfig.FOVColor
end)

-- FOV Filled Toggle
local toggleFOVFilled, getToggleFOVFilled = makeToggle(content, "Filled Circle", false, function(state)
	aimlockConfig.FOVFilled = state
end)

-- Target Part Selector
local targetPartContainer = Instance.new("Frame")
targetPartContainer.Size = UDim2.new(1, 0, 0, 36)
targetPartContainer.BackgroundColor3 = THEME.ButtonIdle
targetPartContainer.BackgroundTransparency = 0.25
targetPartContainer.Parent = content
corner(targetPartContainer, UDim.new(0, 10))
stroke(targetPartContainer, THEME.Stroke, 1).Transparency = 0.3

local targetPartLabel = Instance.new("TextLabel")
targetPartLabel.BackgroundTransparency = 1
targetPartLabel.Size = UDim2.new(0.6, 0, 1, 0)
targetPartLabel.Position = UDim2.new(0, 12, 0, 0)
targetPartLabel.Text = "Target Part"
targetPartLabel.Font = Enum.Font.GothamBold
targetPartLabel.TextSize = 12
targetPartLabel.TextColor3 = THEME.TextMuted
targetPartLabel.TextXAlignment = Enum.TextXAlignment.Left
targetPartLabel.Parent = targetPartContainer

local targetPartButton = makeButton(targetPartContainer, { Text = aimlockConfig.TargetPartMode, Size = UDim2.new(0, 64, 0, 24) })
targetPartButton.Position = UDim2.new(1, -76, 0.5, -12)

targetPartButton.MouseButton1Click:Connect(function()
	if aimlockConfig.TargetPartMode == "Head" then
		aimlockConfig.TargetPartMode = "Torso"
		targetPartButton.Text = "Torso"
	else
		aimlockConfig.TargetPartMode = "Head"
		targetPartButton.Text = "Head"
	end
end)

-- Keybind
local keybindContainer = Instance.new("Frame")
keybindContainer.Size = UDim2.new(1, 0, 0, 36)
keybindContainer.BackgroundColor3 = THEME.ButtonIdle
keybindContainer.BackgroundTransparency = 0.25
keybindContainer.Parent = content
corner(keybindContainer, UDim.new(0, 10))
stroke(keybindContainer, THEME.Stroke, 1).Transparency = 0.3

local keybindLabel = Instance.new("TextLabel")
keybindLabel.BackgroundTransparency = 1
keybindLabel.Size = UDim2.new(0.6, 0, 1, 0)
keybindLabel.Position = UDim2.new(0, 12, 0, 0)
keybindLabel.Text = "Toggle Keybind"
keybindLabel.Font = Enum.Font.GothamBold
keybindLabel.TextSize = 12
keybindLabel.TextColor3 = THEME.TextMuted
keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindLabel.Parent = keybindContainer

local keybindButton = makeButton(keybindContainer, { Text = aimlockConfig.ToggleKeybind.Name, Size = UDim2.new(0, 50, 0, 24) })
keybindButton.Position = UDim2.new(1, -62, 0.5, -12)

local awaitingKeybind = false
keybindButton.MouseButton1Click:Connect(function()
	if awaitingKeybind then return end
	awaitingKeybind = true
	keybindButton.Text = "..."

	local connection
	connection = UIS.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			aimlockConfig.ToggleKeybind = input.KeyCode
			keybindButton.Text = input.KeyCode.Name
			connection:Disconnect()
			awaitingKeybind = false
		end
	end)

	task.wait(5)
	if awaitingKeybind then
		awaitingKeybind = false
		keybindButton.Text = aimlockConfig.ToggleKeybind.Name
		connection:Disconnect()
	end
end)

-- Info Text
local infoText = Instance.new("TextLabel")
infoText.Name = "InfoText"
infoText.Size = UDim2.new(1, 0, 0, 48)
infoText.BackgroundTransparency = 1
infoText.Text = "Press " .. aimlockConfig.ToggleKeybind.Name .. " to toggle aimlock.\nPress E to cycle targets.\nAim at enemies to lock on."
infoText.TextColor3 = THEME.TextMuted
infoText.TextSize = 11
infoText.Font = Enum.Font.Gotham
infoText.TextWrapped = true
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.Parent = content

--------------------------------------------------------------------------------
-- AIMLOCK CORE FUNCTIONS
--------------------------------------------------------------------------------
local function getTargetPart(player)
	if not player or not player.Character then return nil end
	local char = player.Character
	if aimlockConfig.TargetPartMode == "Torso" then
		return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
	end
	return char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
end

local function isPlayerVisible(targetPlayer)
	if not targetPlayer or not targetPlayer.Character then return false end
	local targetChar = targetPlayer.Character
	local targetPart = getTargetPart(targetPlayer)
	if not targetPart then return false end

	local camera = workspace.CurrentCamera
	local rayOrigin = camera.CFrame.Position
	local rayDirection = (targetPart.Position - rayOrigin).Unit

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

	local result = workspace:Raycast(rayOrigin, rayDirection * 500, raycastParams)
	if result then
		return result.Instance:IsDescendantOf(targetChar)
	end
	return true
end

local function isEnemy(player)
	if player == LocalPlayer then return false end
	local targetPart = getTargetPart(player)
	if not player.Character or not targetPart then return false end

	if not aimlockConfig.TargetTeam then
		if player.Team ~= nil and LocalPlayer.Team ~= nil and player.Team == LocalPlayer.Team then
			return false
		end
	end

	if aimlockConfig.VisibleOnly and not isPlayerVisible(player) then
		return false
	end

	return true
end

local function getClosestEnemy()
	local closest = nil
	local closestScore = math.huge
	local center = getAimCenter()

	for _, player in pairs(Players:GetPlayers()) do
		if isEnemy(player) then
			local targetPart = getTargetPart(player)
			if targetPart then
				local partPos = targetPart.Position
				local screenPos, onScreen = camera:WorldToScreenPoint(partPos)

				if onScreen then
					local screenVector = Vector2.new(screenPos.X, screenPos.Y)
					local distToCenter = (screenVector - center).Magnitude

					if distToCenter <= aimlockConfig.FOVRadius then
						local distance = (partPos - camera.CFrame.Position).Magnitude
						local score = distToCenter + (distance * 0.1)

						if score < closestScore then
							closestScore = score
							closest = player
						end
					end
				end
			end
		end
	end

	return closest
end

local function aimAtTarget(target)
	if not target or not target.Character then return end
	local targetPart = getTargetPart(target)
	if not targetPart then return end

	local currentCFrame = camera.CFrame
	local targetPosition = targetPart.Position + (targetPart.AssemblyLinearVelocity * 0.1)

	if aimlockConfig.TargetPartMode == "Torso" then
		targetPosition = targetPosition + Vector3.new(0, 0.25, 0)
	end

	local targetCFrame = CFrame.new(currentCFrame.Position, targetPosition)
	local alpha = aimlockConfig.Smoothness * 0.15
	alpha = math.clamp(alpha, 0.05, 0.15)

	camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
end

local function updateAutoTarget()
	local nearest = getClosestEnemy()

	if nearest then
		aimlockConfig.TargetPlayer = nearest
		StatusText.Text = "Status: Locked on " .. nearest.DisplayName
		tween(StatusText, { TextColor3 = THEME.Accent })
		return
	end

	if aimlockConfig.TargetPlayer and aimlockConfig.TargetPlayer.Parent then
		local targetPart = getTargetPart(aimlockConfig.TargetPlayer)
		if targetPart then
			local partPos = targetPart.Position
			local screenPos, onScreen = camera:WorldToScreenPoint(partPos)

			if onScreen then
				local center = getAimCenter()
				local distToCenter = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
				if distToCenter <= aimlockConfig.FOVRadius then
					return
				end
			end
		end
	end

	aimlockConfig.TargetPlayer = nil
	StatusText.Text = "Status: Active (no target)"
	tween(StatusText, {TextColor3 = THEME.Accent})
end

function startAimlock()
	if renderConnection then renderConnection:Disconnect() end
	createFOVCircle()

	renderConnection = RunService.RenderStepped:Connect(function()
		if not aimlockConfig.Enabled then return end
		updateFOVCircle()
		updateAutoTarget()

		if aimlockConfig.TargetPlayer and aimlockConfig.TargetPlayer.Parent then
			aimAtTarget(aimlockConfig.TargetPlayer)
		else
			aimlockConfig.TargetPlayer = nil
		end
	end)
end

function stopAimlock()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if fovCircle then
		pcall(function() fovCircle:Remove() end)
		fovCircle = nil
	end
end

-- Keybind to cycle targets
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == aimlockConfig.ToggleKeybind then
		aimlockConfig.Enabled = not aimlockConfig.Enabled
		if aimlockConfig.Enabled then
			tween(StatusText, {TextColor3 = THEME.Accent})
			StatusText.Text = "Status: Active (no target)"
			startAimlock()
		else
			StatusText.Text = "Status: Inactive"
			tween(StatusText, {TextColor3 = Color3.fromRGB(160, 160, 160)})
			stopAimlock()
		end
	end

	if input.KeyCode == aimlockConfig.Keybind and aimlockConfig.Enabled then
		local closest = getClosestEnemy()
		if closest then
			aimlockConfig.TargetPlayer = closest
			StatusText.Text = "Status: Locked on " .. closest.DisplayName
			tween(StatusText, {TextColor3 = THEME.Accent})
		else
			aimlockConfig.TargetPlayer = nil
			StatusText.Text = "Status: Active (no target)"
			tween(StatusText, {TextColor3 = THEME.Accent})
		end
	end
end)

--------------------------------------------------------------------------------
-- WINDOW CONTROLS
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	aimlockConfig.Enabled = false
	stopAimlock()
	if fovCircle then
		pcall(function() fovCircle:Remove() end)
		fovCircle = nil
	end
	local t = tween(frame, { Size = UDim2.new(0, 280, 0, 0), BackgroundTransparency = 1 })
	t.Completed:Connect(function()
		gui:Destroy()
	end)
end)

local minimized = false
local expandedSize = OPEN_SIZE
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		expandedSize = frame.Size
		content.Visible = false
		divider.Visible = false
		tween(frame, { Size = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT) })
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
local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	frame.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		updateDrag(input)
	end
end)

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
frame.Size = UDim2.new(0, 280, 0, 0)
tween(frame, { Size = OPEN_SIZE })