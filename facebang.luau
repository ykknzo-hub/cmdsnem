-- NEMESIS FACEBANG - Perfect Zero Delay Stick (Matches AntiVCB style)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TargetGui = (typeof(gethui) == "function" and gethui()) or PlayerGui

local existing = TargetGui:FindFirstChild("NemesisFacengGui")
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

local OPEN_SIZE        = UDim2.new(0, 280, 0, 400)
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
-- HELPERS
--------------------------------------------------------------------------------
local function tween(inst, props, info)
	local t = TweenService:Create(inst, info or TWEEN_INFO, props)
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
		tween(btn, {BackgroundColor3 = THEME.ButtonHover, BackgroundTransparency = 0.1}, HOVER_TWEEN_INFO)
		tween(btnStroke, {Color = THEME.Accent, Transparency = 0}, HOVER_TWEEN_INFO)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {
			BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle,
			BackgroundTransparency = props.BackgroundTransparency or 0.25
		}, HOVER_TWEEN_INFO)
		tween(btnStroke, {Color = THEME.Stroke, Transparency = 0.3}, HOVER_TWEEN_INFO)
	end)
	return btn
end

--------------------------------------------------------------------------------
-- CORE (Perfect Stick)
--------------------------------------------------------------------------------
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local targetHead = nil
local targetPlayer = nil

local FOLLOW_DISTANCE = -0.7
local HEIGHT_OFFSET = 0.8
local THRUST_DISTANCE = 1.9
local THRUST_SPEED = 10

getgenv().faceactive = false
local keybind = Enum.KeyCode.Z

local thrustTime = 0
local bound = false

local function disableAllAnimations(char)
	if not char then return end
	local animate = char:FindFirstChild("Animate")
	if animate then animate.Disabled = true end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
			t:Stop()
			t:Destroy()
		end
		hum.PlatformStand = true
		hum.AutoRotate = false
		hum:ChangeState(Enum.HumanoidStateType.Physics)
	end
	workspace.Gravity = 0
end

local function enableAllAnimations(char)
	if not char then return end
	local animate = char:FindFirstChild("Animate")
	if animate then animate.Disabled = false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
		hum.AutoRotate = true
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	workspace.Gravity = 192.2
end

local function findNearestPlayer()
	if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
		local h = targetPlayer.Character.Head
		if h:IsDescendantOf(workspace) then return h end
	end
	local nearest, shortest = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			local head = plr.Character:FindFirstChild("Head")
			if hum and hum.Health > 0 and head then
				local d = (HumanoidRootPart.Position - head.Position).Magnitude
				if d < shortest then
					shortest = d
					nearest = head
					targetPlayer = plr
				end
			end
		end
	end
	return nearest
end

local function updateStick(dt)
	if not getgenv().faceactive then return end

	if not targetHead or not targetHead:IsDescendantOf(workspace) then
		targetHead = findNearestPlayer()
		if not targetHead then return end
	end

	local hrp = HumanoidRootPart
	if not hrp or not hrp.Parent then return end

	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.Velocity = Vector3.zero
		hrp.RotVelocity = Vector3.zero
	end)

	thrustTime = thrustTime + (dt or 0.016) * THRUST_SPEED
	local thrust = math.sin(thrustTime) * THRUST_DISTANCE

	hrp.CFrame = targetHead.CFrame
		* CFrame.new(0, HEIGHT_OFFSET, FOLLOW_DISTANCE - thrust)
		* CFrame.Angles(0, math.rad(180), 0)
end

local function startFaceBang()
	if bound then return end
	bound = true
	thrustTime = 0

	RunService:BindToRenderStep("NemesisFaceBang", Enum.RenderPriority.Camera.Value - 1, updateStick)

	RunService.Heartbeat:Connect(function()
		if getgenv().faceactive then
			updateStick(0)
		end
	end)
end

local function stopFaceBang()
	if bound then
		pcall(function()
			RunService:UnbindFromRenderStep("NemesisFaceBang")
		end)
		bound = false
	end
	enableAllAnimations(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
	Character = newChar
	HumanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
	if getgenv().faceactive then
		disableAllAnimations(newChar)
		targetHead = findNearestPlayer()
	end
end)

RunService.Heartbeat:Connect(function()
	if getgenv().faceactive and LocalPlayer.Character then
		local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
				t:Stop()
			end
			hum.PlatformStand = true
			hum:ChangeState(Enum.HumanoidStateType.Physics)
		end
	end
end)

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisFacengGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -140, 0.5, -200)
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
title.Text = "NEMESIS Facebang"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = THEME.TextPrimary
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = makeButton(titleBar, {Text = "–", Size = UDim2.new(0, 24, 0, 24)})
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
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 12, 0, 58)
content.Size = UDim2.new(1, -24, 1, -70)
content.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = content

--------------------------------------------------------------------------------
-- SLIDER
--------------------------------------------------------------------------------
local function createSlider(labelText, minV, maxV, defV, decimals, callback)
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

	local fmt = decimals > 0 and ("%."..decimals.."f") or "%d"

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Size = UDim2.new(0.3, 0, 0, 18)
	valLbl.Position = UDim2.new(0.45, 0, 0, 6)
	valLbl.Text = string.format(fmt, defV)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 12
	valLbl.TextColor3 = THEME.Accent
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = row

	local resetBtn = makeButton(row, {
		Text = "reset",
		Size = UDim2.new(0, 42, 0, 18),
		TextSize = 10,
		BackgroundTransparency = 0.15,
	})
	resetBtn.Position = UDim2.new(1, -54, 0, 6)

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
	stroke(thumb, THEME.Accent, 1.5)

	local sliding = false

	local function setValue(v)
		local r = math.clamp((v - minV) / (maxV - minV), 0, 1)
		fill.Size = UDim2.new(r, 0, 1, 0)
		thumb.Position = UDim2.new(r, 0, 0.5, 0)
		valLbl.Text = string.format(fmt, v)
		callback(v)
	end

	local function update(ix)
		local tp = track.AbsolutePosition.X
		local ts = track.AbsoluteSize.X
		local r = math.clamp((ix - tp) / ts, 0, 1)
		local raw = minV + (maxV - minV) * r
		local step = 10 ^ decimals
		setValue(math.floor(raw * step + 0.5) / step)
	end

	resetBtn.MouseButton1Click:Connect(function() setValue(defV) end)

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
-- TOGGLE
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

	local api = {
		setOn = function(val)
			on = val
			if on then
				tween(bg, {BackgroundColor3 = THEME.Accent})
				circle:TweenPosition(UDim2.new(1, -17, 0.5, -7), "Out", "Quad", 0.15, true)
			else
				tween(bg, {BackgroundColor3 = THEME.Stroke})
				circle:TweenPosition(UDim2.new(0, 3, 0.5, -7), "Out", "Quad", 0.15, true)
			end
		end
	}

	btn.MouseButton1Click:Connect(function()
		on = not on
		api.setOn(on)
		callback(on)
	end)

	return api
end

--------------------------------------------------------------------------------
-- KEYBIND
--------------------------------------------------------------------------------
local function createKeybindRow(labelText, defaultKey, onChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
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

	local bindBtn = makeButton(row, {
		Text = defaultKey.Name,
		Size = UDim2.new(0, 64, 0, 24),
		BackgroundColor3 = THEME.Panel,
		TextSize = 11,
	})
	bindBtn.Position = UDim2.new(1, -76, 0.5, -12)

	local listening = false
	bindBtn.MouseButton1Click:Connect(function()
		if not listening then
			listening = true
			bindBtn.Text = "..."
		end
	end)

	UserInputService.InputBegan:Connect(function(input, busy)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				bindBtn.Text = "None"
				keybind = nil
				onChange(nil)
			else
				keybind = input.KeyCode
				bindBtn.Text = input.KeyCode.Name
				onChange(input.KeyCode)
			end
			listening = false
		end
	end)
end

--------------------------------------------------------------------------------
-- BUILD CONTROLS
--------------------------------------------------------------------------------
createSlider("Distance", -3, 0, FOLLOW_DISTANCE, 1, function(v) FOLLOW_DISTANCE = v end)
createSlider("Thrust Range", 0, 5, THRUST_DISTANCE, 1, function(v) THRUST_DISTANCE = v end)
createSlider("Thrust Speed", 1, 25, THRUST_SPEED, 0, function(v) THRUST_SPEED = v end)
createSlider("Height", -2, 3, HEIGHT_OFFSET, 1, function(v) HEIGHT_OFFSET = v end)

local toggleRef = createToggleRow("Active", false, function(on)
	if on then
		targetHead = findNearestPlayer()
		if targetHead then
			getgenv().faceactive = true
			disableAllAnimations(LocalPlayer.Character)
			startFaceBang()
		else
			toggleRef.setOn(false)
		end
	else
		getgenv().faceactive = false
		targetPlayer = nil
		targetHead = nil
		stopFaceBang()
	end
end)

createKeybindRow("Keybind", keybind, function(k) keybind = k end)

--------------------------------------------------------------------------------
-- WINDOW
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	getgenv().faceactive = false
	stopFaceBang()
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
		tween(frame, {Size = UDim2.new(0, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT)})
		minBtn.Text = "+"
	else
		tween(frame, {Size = expandedSize})
		task.delay(0.22, function()
			content.Visible = true
			divider.Visible = true
		end)
		minBtn.Text = "–"
	end
end)

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

UserInputService.InputBegan:Connect(function(input, gp)
	if not gp and keybind and input.KeyCode == keybind then
		local newState = not getgenv().faceactive
		toggleRef.setOn(newState)
		if newState then
			targetHead = findNearestPlayer()
			if targetHead then
				getgenv().faceactive = true
				disableAllAnimations(LocalPlayer.Character)
				startFaceBang()
			else
				toggleRef.setOn(false)
			end
		else
			getgenv().faceactive = false
			targetPlayer = nil
			targetHead = nil
			stopFaceBang()
		end
	end
end)