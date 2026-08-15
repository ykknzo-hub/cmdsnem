-- Combined NEMESIS Template UI + Airwalk Script (Flat & Non-Neon)
-- Matches AntiVCB style
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Prevent duplicate UI instances
local existing = CoreGui:FindFirstChild("TemplateAirwalkGui") or PlayerGui:FindFirstChild("TemplateAirwalkGui")
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
	StatusOn     = Color3.fromRGB(255, 255, 255),
	StatusOff    = Color3.fromRGB(160, 160, 160),
}

local OPEN_SIZE        = UDim2.new(0, 280, 0, 300)
local COLLAPSED_HEIGHT = 48
local MIN_SIZE         = Vector2.new(240, 200)
local MAX_SIZE         = Vector2.new(500, 480)
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
	btn.Size = props.Size or UDim2.new(1, 0, 0, 32)
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
	btn.MouseButton1Down:Connect(function()
		tween(btn, { Size = btn.Size - UDim2.new(0, 2, 0, 2) }, HOVER_TWEEN_INFO)
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, { Size = props.Size or UDim2.new(1, 0, 0, 32) }, HOVER_TWEEN_INFO)
	end)

	return btn
end

--------------------------------------------------------------------------------
-- UI CONSTRUCTION
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "TemplateAirwalkGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -140, 0.5, -150)
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
title.Size = UDim2.new(0, 160, 0, 22)
title.Position = UDim2.new(0, 46, 0.5, -11)
title.Text = "NEMESIS WalkOnAir"
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
-- AIRWALK UI CONTROLS
--------------------------------------------------------------------------------
local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, 0, 0, 22)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Airwalk: Enabled"
StatusText.TextColor3 = THEME.StatusOn
StatusText.TextSize = 13
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = content

local toggleButton = makeButton(content, { Text = "Toggle Airwalk: ON", Size = UDim2.new(1, 0, 0, 34) })

local elevationRow = Instance.new("Frame")
elevationRow.Name = "ElevationRow"
elevationRow.Size = UDim2.new(1, 0, 0, 34)
elevationRow.BackgroundTransparency = 1
elevationRow.Parent = content

local upButton = makeButton(elevationRow, { Text = "▲ Move Up", Size = UDim2.new(0.48, 0, 1, 0) })
upButton.Position = UDim2.new(0, 0, 0, 0)

local downButton = makeButton(elevationRow, { Text = "▼ Move Down", Size = UDim2.new(0.48, 0, 1, 0) })
downButton.Position = UDim2.new(0.52, 0, 0, 0)

local actionRow = Instance.new("Frame")
actionRow.Name = "ActionRow"
actionRow.Size = UDim2.new(1, 0, 0, 34)
actionRow.BackgroundTransparency = 1
actionRow.Parent = content

local resetButton = makeButton(actionRow, { Text = "Catch Player (Reset)", Size = UDim2.new(0.48, 0, 1, 0) })
resetButton.Position = UDim2.new(0, 0, 0, 0)

local visibilityButton = makeButton(actionRow, { Text = "Visibility: Off", Size = UDim2.new(0.48, 0, 1, 0) })
visibilityButton.Position = UDim2.new(0.52, 0, 0, 0)

--------------------------------------------------------------------------------
-- RESIZE HANDLE & WINDOW CONTROLS
--------------------------------------------------------------------------------
local resizeHandle = Instance.new("Frame")
resizeHandle.Name = "ResizeHandle"
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.Position = UDim2.new(1, -4, 1, -4)
resizeHandle.Size = UDim2.new(0, 18, 0, 18)
resizeHandle.BackgroundTransparency = 1
resizeHandle.ZIndex = 5
resizeHandle.Parent = frame

for i = 0, 2 do
	for j = 0, i do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 3, 0, 3)
		dot.BackgroundColor3 = THEME.Stroke
		dot.BackgroundTransparency = 0.2
		dot.BorderSizePixel = 0
		dot.AnchorPoint = Vector2.new(1, 1)
		dot.Position = UDim2.new(1, -5 - (i * 5), 1, -5 - (j * 5))
		dot.Parent = resizeHandle
		corner(dot, UDim.new(1, 0))
	end
end

local resizeCursor = Instance.new("TextButton")
resizeCursor.BackgroundTransparency = 1
resizeCursor.Text = ""
resizeCursor.Size = UDim2.new(1, 0, 1, 0)
resizeCursor.AutoButtonColor = false
resizeCursor.Parent = resizeHandle

closeBtn.MouseButton1Click:Connect(function()
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
		resizeHandle.Visible = false
		tween(frame, { Size = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT) })
		minBtn.Text = "+"
	else
		tween(frame, { Size = expandedSize })
		task.delay(TWEEN_INFO.Time, function()
			content.Visible = true
			divider.Visible = true
			resizeHandle.Visible = true
		end)
		minBtn.Text = "–"
	end
end)

-- Window Dragging
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

-- Window Resizing
local resizing = false
local resizeInput, resizeStart, sizeStart

local function updateResize(input)
	local delta = input.Position - resizeStart
	local newWidth = math.clamp(sizeStart.X.Offset + delta.X, MIN_SIZE.X, MAX_SIZE.X)
	local newHeight = math.clamp(sizeStart.Y.Offset + delta.Y, MIN_SIZE.Y, MAX_SIZE.Y)

	frame.Size = UDim2.new(sizeStart.X.Scale, newWidth, sizeStart.Y.Scale, newHeight)
	expandedSize = frame.Size
end

resizeCursor.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		resizeStart = input.Position
		sizeStart = frame.Size

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				resizing = false
			end
		end)
	end
end)

resizeCursor.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		resizeInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if resizing and input == resizeInput then
		updateResize(input)
	end
end)

--------------------------------------------------------------------------------
-- AIRWALK CORE LOGIC (FLAT & NON-NEON)
--------------------------------------------------------------------------------
local function createBaseplate()
	local baseplate = Instance.new("Part")
	baseplate.Name = "InvisibleBaseplate"
	baseplate.Size = Vector3.new(math.huge, 0.1, math.huge)
	baseplate.Position = Vector3.new(0, 0, 0)
	baseplate.Transparency = 1
	baseplate.Anchored = true
	baseplate.CanCollide = true
	baseplate.Material = Enum.Material.SmoothPlastic
	baseplate.Color = Color3.fromRGB(70, 200, 255)
	baseplate.Parent = workspace
	return baseplate
end

local baseplate = createBaseplate()

local airwalking = true
local isVisible = false
local isMovingUp = false
local isMovingDown = false

local function resetBaseplate()
	local character = LocalPlayer.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			baseplate.Position = Vector3.new(
				humanoidRootPart.Position.X,
				baseplate.Position.Y,
				humanoidRootPart.Position.Z
			)
		end
	end
end

local function saveFallingPlayer()
	local character = LocalPlayer.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			baseplate.Position = Vector3.new(
				humanoidRootPart.Position.X,
				humanoidRootPart.Position.Y - 5,
				humanoidRootPart.Position.Z
			)
		end
	end
end

local function toggleVisibility()
	isVisible = not isVisible
	baseplate.Transparency = isVisible and 0.3 or 1
	baseplate.Material = Enum.Material.SmoothPlastic
	
	if isVisible then
		visibilityButton.Text = "Visibility: On"
	else
		visibilityButton.Text = "Visibility: Off"
	end
end

local function toggleAirwalk()
	airwalking = not airwalking
	if airwalking then
		toggleButton.Text = "Toggle Airwalk: ON"
		StatusText.Text = "Airwalk: Enabled"
		StatusText.TextColor3 = THEME.StatusOn
		if not baseplate:IsDescendantOf(workspace) then
			baseplate = createBaseplate()
		end
	else
		toggleButton.Text = "Toggle Airwalk: OFF"
		StatusText.Text = "Airwalk: Disabled"
		StatusText.TextColor3 = THEME.StatusOff
		baseplate:Destroy()
	end
end

-- Continuous movement
RunService.Heartbeat:Connect(function()
	if isMovingUp and baseplate and baseplate.Parent then
		baseplate.Position = baseplate.Position + Vector3.new(0, 0.5, 0)
	elseif isMovingDown and baseplate and baseplate.Parent then
		baseplate.Position = baseplate.Position - Vector3.new(0, 0.5, 0)
	end
end)

-- UI Button bindings
toggleButton.MouseButton1Click:Connect(toggleAirwalk)
resetButton.MouseButton1Click:Connect(saveFallingPlayer)
visibilityButton.MouseButton1Click:Connect(toggleVisibility)

-- Movement triggers
upButton.MouseButton1Down:Connect(function() isMovingUp = true end)
upButton.MouseButton1Up:Connect(function() isMovingUp = false end)
upButton.MouseLeave:Connect(function() isMovingUp = false end)

downButton.MouseButton1Down:Connect(function() isMovingDown = true end)
downButton.MouseButton1Up:Connect(function() isMovingDown = false end)
downButton.MouseLeave:Connect(function() isMovingDown = false end)

-- Smooth platform following
RunService.Heartbeat:Connect(function()
	local character = LocalPlayer.Character
	if character and airwalking and baseplate and baseplate.Parent then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			baseplate.Position = Vector3.new(
				humanoidRootPart.Position.X,
				baseplate.Position.Y,
				humanoidRootPart.Position.Z
			)
		end
	end
end)

-- Initialization
resetBaseplate()

LocalPlayer.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	resetBaseplate()
end)

--------------------------------------------------------------------------------
-- INITIALIZATION & ANIMATION OPENING
--------------------------------------------------------------------------------
frame.Size = UDim2.new(0, 280, 0, 0)
tween(frame, { Size = OPEN_SIZE })