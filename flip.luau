-- NEMESIS-STYLE UI - FLIP INTEGRATION (Xeno Max Compatibility)
-- Matches AntiVCB style
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Safely determine where to parent the UI without triggering executor blocks
local TargetGuiService = (typeof(gethui) == "function" and gethui()) or PlayerGui

-- Prevent duplicate UI instances
local existing = TargetGuiService:FindFirstChild("NemesisFlipGui")
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

local OPEN_SIZE        = UDim2.new(0, 260, 0, 300)
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
gui.Name = "NemesisFlipGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGuiService

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -130, 0.5, -150)
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
title.Size = UDim2.new(0, 140, 0, 22)
title.Position = UDim2.new(0, 46, 0.5, -11)
title.Text = "NEMESIS Flip"
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

local frontflipBtn = makeButton(content, { Text = "Frontflip", Size = UDim2.new(1, 0, 0, 34) })
frontflipBtn.Position = UDim2.new(0, 0, 0, 4)

local backflipBtn = makeButton(content, { Text = "Backflip", Size = UDim2.new(1, 0, 0, 34) })
backflipBtn.Position = UDim2.new(0, 0, 0, 44)

local function createKeybindRow(yPos, labelText)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.Position = UDim2.new(0, 0, 0, yPos)
	row.BackgroundColor3 = THEME.ButtonIdle
	row.BackgroundTransparency = 0.25
	row.Parent = content
	corner(row, UDim.new(0, 10))
	stroke(row, THEME.Stroke, 1).Transparency = 0.3

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Text = labelText
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = THEME.TextMuted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bindBtn = makeButton(row, { Text = "None", Size = UDim2.new(0, 58, 0, 24) })
	bindBtn.Position = UDim2.new(1, -68, 0.5, -12)
	bindBtn.BackgroundColor3 = THEME.Panel
	bindBtn.TextSize = 11

	return bindBtn
end

local frontflipBindBtn = createKeybindRow(86, "Frontflip Key")
local backflipBindBtn = createKeybindRow(128, "Backflip Key")

--------------------------------------------------------------------------------
-- SLIDER CONSTRUCTION
--------------------------------------------------------------------------------
local flipDistance = 0 
local maxDistance = 50

local sliderContainer = Instance.new("Frame")
sliderContainer.Size = UDim2.new(1, 0, 0, 50)
sliderContainer.Position = UDim2.new(0, 0, 0, 170)
sliderContainer.BackgroundColor3 = THEME.ButtonIdle
sliderContainer.BackgroundTransparency = 0.25
sliderContainer.Parent = content
corner(sliderContainer, UDim.new(0, 10))
stroke(sliderContainer, THEME.Stroke, 1).Transparency = 0.3

local sliderLabel = Instance.new("TextLabel")
sliderLabel.BackgroundTransparency = 1
sliderLabel.Size = UDim2.new(1, -24, 0, 18)
sliderLabel.Position = UDim2.new(0, 12, 0, 6)
sliderLabel.Text = "Distance: " .. flipDistance
sliderLabel.Font = Enum.Font.GothamBold
sliderLabel.TextSize = 12
sliderLabel.TextColor3 = THEME.TextMuted
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Parent = sliderContainer

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, -24, 0, 8)
sliderBg.Position = UDim2.new(0, 12, 0, 30)
sliderBg.BackgroundColor3 = THEME.Stroke
sliderBg.Parent = sliderContainer
corner(sliderBg, UDim.new(1, 0))

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = THEME.Accent
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
corner(sliderFill, UDim.new(1, 0))

local sliderHitbox = Instance.new("TextButton")
sliderHitbox.Size = UDim2.new(1, 0, 1, 10)
sliderHitbox.Position = UDim2.new(0, 0, 0.5, -5)
sliderHitbox.BackgroundTransparency = 1
sliderHitbox.Text = ""
sliderHitbox.Parent = sliderBg

local draggingSlider = false

local function updateSlider(input)
	local clampedX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
	local percentage = clampedX / sliderBg.AbsoluteSize.X
	
	sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
	flipDistance = math.floor(percentage * maxDistance)
	sliderLabel.Text = "Distance: " .. flipDistance
end

sliderHitbox.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
		updateSlider(input)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateSlider(input)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = false
	end
end)

--------------------------------------------------------------------------------
-- FLIP LOGIC
--------------------------------------------------------------------------------
local FlipCooldown = false
local frontflipKey = nil
local backflipKey = nil
local bindingBtn = nil

local function PerformFlip(isBackflip)
	if FlipCooldown then return end
	FlipCooldown = true
	local character = Players.LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	
	if not hrp or not humanoid then
		FlipCooldown = false
		return
	end

	humanoid.PlatformStand = true
	
	local duration = 0.45
	local steps = 50
	local startCFrame = hrp.CFrame
	local forwardVector = startCFrame.LookVector
	local upVector = Vector3.new(0, 1, 0)
	local dirMultiplier = isBackflip and -1 or 1

	task.spawn(function()
		local startTime = tick()
		for i = 1, steps do
			local t = i / steps
			local height = 4 * (t - t ^ 2) * 10
			
			local nextPos = startCFrame.Position + forwardVector * (flipDistance * t * dirMultiplier) + upVector * height
			
			local angle = i * (360 / steps)
			if not isBackflip then angle = -angle end
			local rotation = startCFrame.Rotation * CFrame.Angles(math.rad(angle), 0, 0)

			hrp.CFrame = CFrame.new(nextPos) * rotation
			
			local elapsedTime = tick() - startTime
			local expectedTime = (duration / steps) * i
			local waitTime = expectedTime - elapsedTime
			if waitTime > 0 then task.wait(waitTime) end
		end

		hrp.CFrame = CFrame.new(startCFrame.Position + forwardVector * (flipDistance * dirMultiplier)) * startCFrame.Rotation
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		
		task.wait(0.25)
		FlipCooldown = false
	end)
end

frontflipBtn.MouseButton1Click:Connect(function() PerformFlip(false) end)
backflipBtn.MouseButton1Click:Connect(function() PerformFlip(true) end)

local function handleBindClick(btn, type)
	if bindingBtn then return end
	bindingBtn = btn
	btn.Text = "..."
end

frontflipBindBtn.MouseButton1Click:Connect(function() handleBindClick(frontflipBindBtn, "Front") end)
backflipBindBtn.MouseButton1Click:Connect(function() handleBindClick(backflipBindBtn, "Back") end)

UserInputService.InputBegan:Connect(function(input, busy)
	if bindingBtn then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				bindingBtn.Text = "None"
				if bindingBtn == frontflipBindBtn then frontflipKey = nil else backflipKey = nil end
			else
				local keyName = input.KeyCode.Name
				bindingBtn.Text = keyName
				if bindingBtn == frontflipBindBtn then frontflipKey = input.KeyCode else backflipKey = input.KeyCode end
			end
			bindingBtn = nil
		end
		return
	end

	if not busy and input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == frontflipKey then
			PerformFlip(false)
		elseif input.KeyCode == backflipKey then
			PerformFlip(true)
		end
	end
end)

--------------------------------------------------------------------------------
-- DRAGGING & WINDOW CONTROLS
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