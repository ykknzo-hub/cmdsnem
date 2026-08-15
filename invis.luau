-- NEMESIS INVISIBLE (Camera follows you above the map) - Matches AntiVCB style
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TargetGui = (typeof(gethui) == "function" and gethui()) or LocalPlayer:WaitForChild("PlayerGui")

local existing = TargetGui:FindFirstChild("NemesisInvisGui")
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
	Danger       = Color3.fromRGB(255, 255, 255),
	Success      = Color3.fromRGB(255, 255, 255),
}

local OPEN_SIZE        = UDim2.new(0, 240, 0, 155)
local COLLAPSED_HEIGHT = 48
local TWEEN_INFO       = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--------------------------------------------------------------------------------
-- LOGO SETTINGS (same as AntiVCB)
--------------------------------------------------------------------------------
local LOGO_PATH          = "whitelogo.png"
local LOGO_DOWNLOAD_URL  = "https://i.ibb.co/SwGkMS5h/whitelogo.png" -- ← paste a direct PNG link here (e.g. Discord CDN / Imgur / raw GitHub)
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

--------------------------------------------------------------------------------
-- INVIS LOGIC
--------------------------------------------------------------------------------
local INVIS_ENABLED = false
local keybind = Enum.KeyCode.X
local savedCFrame = nil
local camPart = nil
local connection
local oldCameraSubject = nil

local UNDER_Y = -40
local CAM_HEIGHT = nil

local function getHRP()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function enableInvis()
	local hrp = getHRP()
	if not hrp then return end

	INVIS_ENABLED = true
	savedCFrame = hrp.CFrame
	CAM_HEIGHT = hrp.Position.Y

	if camPart then camPart:Destroy() end
	camPart = Instance.new("Part")
	camPart.Name = "NemesisCamProxy"
	camPart.Size = Vector3.new(1, 1, 1)
	camPart.Transparency = 1
	camPart.Anchored = true
	camPart.CanCollide = false
	camPart.CFrame = CFrame.new(hrp.Position.X, CAM_HEIGHT, hrp.Position.Z)
	camPart.Parent = workspace

	oldCameraSubject = Camera.CameraSubject
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = camPart

	hrp.CFrame = CFrame.new(hrp.Position.X, UNDER_Y, hrp.Position.Z)

	if connection then connection:Disconnect() end
	connection = RunService.Heartbeat:Connect(function()
		if not INVIS_ENABLED then return end

		local h = getHRP()
		if not h then return end

		local pos = h.Position
		h.CFrame = CFrame.new(pos.X, UNDER_Y, pos.Z) * (h.CFrame - h.CFrame.Position)

		if camPart then
			camPart.CFrame = CFrame.new(pos.X, CAM_HEIGHT, pos.Z)
		end
	end)
end

local function disableInvis()
	INVIS_ENABLED = false

	if connection then
		connection:Disconnect()
		connection = nil
	end

	if oldCameraSubject then
		Camera.CameraSubject = oldCameraSubject
	end

	local hrp = getHRP()
	
	if hrp and camPart then
		local camPos = camPart.Position
		hrp.CFrame = CFrame.new(camPos.X, camPos.Y, camPos.Z)
	elseif hrp and savedCFrame then
		hrp.CFrame = savedCFrame
	end

	if camPart then
		camPart:Destroy()
		camPart = nil
	end

	savedCFrame = nil
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisInvisGui"
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
title.Text = "NEMESIS Invisible"
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

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.Parent = content

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
label.Text = "Invisible"
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
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 1, 0)
btn.BackgroundTransparency = 1
btn.Text = ""
btn.Parent = row

local function setToggleVisual(state)
	on = state
	if on then
		tween(bg, {BackgroundColor3 = THEME.Accent}, HOVER_TWEEN_INFO)
		circle:TweenPosition(UDim2.new(1, -17, 0.5, -7), "Out", "Quad", 0.15, true)
	else
		tween(bg, {BackgroundColor3 = THEME.Stroke}, HOVER_TWEEN_INFO)
		circle:TweenPosition(UDim2.new(0, 3, 0.5, -7), "Out", "Quad", 0.15, true)
	end
end

btn.MouseButton1Click:Connect(function()
	if not on then
		setToggleVisual(true)
		enableInvis()
	else
		setToggleVisual(false)
		disableInvis()
	end
end)

--------------------------------------------------------------------------------
-- KEYBIND
--------------------------------------------------------------------------------
local keyRow = Instance.new("Frame")
keyRow.Size = UDim2.new(1, 0, 0, 36)
keyRow.BackgroundColor3 = THEME.ButtonIdle
keyRow.BackgroundTransparency = 0.25
keyRow.Parent = content
corner(keyRow, UDim.new(0, 10))
local keyStroke = stroke(keyRow, THEME.Stroke, 1)
keyStroke.Transparency = 0.3

local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(0.5, 0, 1, 0)
keyLabel.Position = UDim2.new(0, 12, 0, 0)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = "Keybind"
keyLabel.Font = Enum.Font.GothamBold
keyLabel.TextSize = 13
keyLabel.TextColor3 = THEME.TextMuted
keyLabel.TextXAlignment = Enum.TextXAlignment.Left
keyLabel.Parent = keyRow

local keyBtn = makeButton(keyRow, {
	Text = keybind.Name,
	Size = UDim2.new(0, 64, 0, 24),
})
keyBtn.Position = UDim2.new(1, -76, 0.5, -12)

local listening = false
keyBtn.MouseButton1Click:Connect(function()
	if not listening then
		listening = true
		keyBtn.Text = "..."
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if listening and input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.Escape then
			keyBtn.Text = "None"
			keybind = nil
		else
			keybind = input.KeyCode
			keyBtn.Text = input.KeyCode.Name
		end
		listening = false
		return
	end

	if not gp and keybind and input.KeyCode == keybind then
		if not on then
			setToggleVisual(true)
			enableInvis()
		else
			setToggleVisual(false)
			disableInvis()
		end
	end
end)

--------------------------------------------------------------------------------
-- WINDOW CONTROLS
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	disableInvis()
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