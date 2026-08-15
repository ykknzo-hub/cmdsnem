-- NEMESIS SHADERS UI (Fixed) - Matches AntiVCB style
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TargetGui = (typeof(gethui) == "function" and gethui()) or PlayerGui

local existing = TargetGui:FindFirstChild("NemesisShadersGui")
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

local OPEN_SIZE        = UDim2.new(0, 280, 0, 480)
local COLLAPSED_HEIGHT = 48
local TWEEN_INFO       = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN      = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SAVE_FILE        = "NemesisShaders.json"

--------------------------------------------------------------------------------
-- LOGO SETTINGS (same as AntiVCB)
--------------------------------------------------------------------------------
local LOGO_PATH          = "whitelogo.png"
local LOGO_DOWNLOAD_URL  = "https://i.ibb.co/SwGkMS5h/whitelogo.png" -- ← paste a direct PNG link here
local FALLBACK_LOGO         = "rbxassetid://107541043103322"

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

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = r or UDim.new(0, 12)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.Stroke
	s.Thickness = thick or 1
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
		tween(btn, {BackgroundColor3 = THEME.ButtonHover, BackgroundTransparency = 0.1}, HOVER_TWEEN)
		tween(btnStroke, {Color = THEME.Accent, Transparency = 0}, HOVER_TWEEN)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {
			BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle,
			BackgroundTransparency = props.BackgroundTransparency or 0.25
		}, HOVER_TWEEN)
		tween(btnStroke, {Color = THEME.Stroke, Transparency = 0.3}, HOVER_TWEEN)
	end)
	return btn
end

--------------------------------------------------------------------------------
-- SAVE / LOAD
--------------------------------------------------------------------------------
local defaults = {
	active = false,
	removeTextures = false,
	brightness = 2,
	contrast = 0.1,
	saturation = 0.1,
	exposure = 0,
	bloom = 0.4,
	blur = 0,
	tintR = 255,
	tintG = 255,
	tintB = 255,
}

local settings = table.clone(defaults)

local function saveSettings()
	pcall(function()
		writefile(SAVE_FILE, HttpService:JSONEncode(settings))
	end)
end

local function loadSettings()
	pcall(function()
		if isfile(SAVE_FILE) then
			local data = HttpService:JSONDecode(readfile(SAVE_FILE))
			for k, v in pairs(data) do
				settings[k] = v
			end
		end
	end)
end

loadSettings()

--------------------------------------------------------------------------------
-- EFFECTS
--------------------------------------------------------------------------------
local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "NemesisCC"
colorCorrection.Parent = Lighting

local bloomEffect = Instance.new("BloomEffect")
bloomEffect.Name = "NemesisBloom"
bloomEffect.Parent = Lighting

local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "NemesisBlur"
blurEffect.Parent = Lighting

local originalSky = Lighting:FindFirstChildOfClass("Sky")
local originalSkyClone = originalSky and originalSky:Clone() or nil

local function applyShaders()
	if not settings.active then
		colorCorrection.Enabled = false
		bloomEffect.Enabled = false
		blurEffect.Enabled = false
		return
	end

	colorCorrection.Enabled = true
	bloomEffect.Enabled = true
	blurEffect.Enabled = true

	colorCorrection.Brightness = settings.brightness - 2
	colorCorrection.Contrast = settings.contrast
	colorCorrection.Saturation = settings.saturation
	colorCorrection.TintColor = Color3.fromRGB(settings.tintR, settings.tintG, settings.tintB)

	Lighting.ExposureCompensation = settings.exposure
	bloomEffect.Intensity = settings.bloom
	blurEffect.Size = settings.blur
end

applyShaders()

--------------------------------------------------------------------------------
-- REMOVE TEXTURES
--------------------------------------------------------------------------------
local originalMaterials = {}

local function setRemoveTextures(enabled)
	if enabled then
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				if not originalMaterials[v] then
					originalMaterials[v] = v.Material
				end
				v.Material = Enum.Material.SmoothPlastic
			elseif v:IsA("Texture") or v:IsA("Decal") then
				v.Transparency = 1
			end
		end
	else
		for part, mat in pairs(originalMaterials) do
			if part and part.Parent then
				part.Material = mat
			end
		end
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("Texture") or v:IsA("Decal") then
				v.Transparency = 0
			end
		end
		originalMaterials = {}
	end
end

if settings.removeTextures then
	setRemoveTextures(true)
end

--------------------------------------------------------------------------------
-- SKYBOXES
--------------------------------------------------------------------------------
local skyboxes = {
	{ name = "None (Default)", id = nil },
	{
		name = "Pink Sunset",
		SkyboxBk = "rbxassetid://271042516",
		SkyboxDn = "rbxassetid://271077243",
		SkyboxFt = "rbxassetid://271042556",
		SkyboxLf = "rbxassetid://271042310",
		SkyboxRt = "rbxassetid://271042467",
		SkyboxUp = "rbxassetid://271077958",
	},
	{
		name = "Deep Space",
		SkyboxBk = "rbxassetid://159454299",
		SkyboxDn = "rbxassetid://159454296",
		SkyboxFt = "rbxassetid://159454293",
		SkyboxLf = "rbxassetid://159454286",
		SkyboxRt = "rbxassetid://159454300",
		SkyboxUp = "rbxassetid://159454288",
	},
	{
		name = "Cloudy Day",
		SkyboxBk = "rbxassetid://600830446",
		SkyboxDn = "rbxassetid://600831635",
		SkyboxFt = "rbxassetid://600832720",
		SkyboxLf = "rbxassetid://600833862",
		SkyboxRt = "rbxassetid://600835177",
		SkyboxUp = "rbxassetid://600837955",
	},
	{
		name = "Aurora",
		SkyboxBk = "rbxassetid://12064107",
		SkyboxDn = "rbxassetid://12064152",
		SkyboxFt = "rbxassetid://12064121",
		SkyboxLf = "rbxassetid://12063984",
		SkyboxRt = "rbxassetid://12064115",
		SkyboxUp = "rbxassetid://12064131",
	},
}

local function applySkybox(data)
	for _, v in ipairs(Lighting:GetChildren()) do
		if v:IsA("Sky") then
			v:Destroy()
		end
	end

	if data.name == "None (Default)" then
		if originalSkyClone then
			originalSkyClone:Clone().Parent = Lighting
		end
		return
	end

	local sky = Instance.new("Sky")
	sky.Name = "NemesisSky"
	sky.SkyboxBk = data.SkyboxBk
	sky.SkyboxDn = data.SkyboxDn
	sky.SkyboxFt = data.SkyboxFt
	sky.SkyboxLf = data.SkyboxLf
	sky.SkyboxRt = data.SkyboxRt
	sky.SkyboxUp = data.SkyboxUp
	sky.Parent = Lighting
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisShadersGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -140, 0.5, -240)
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
title.Text = "NEMESIS Shaders"
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

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.BackgroundTransparency = 1
tabBar.Size = UDim2.new(1, -24, 0, 32)
tabBar.Position = UDim2.new(0, 12, 0, 58)
tabBar.Parent = frame

local customTab = makeButton(tabBar, {
	Text = "Custom",
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundTransparency = 0.1,
})
customTab.Position = UDim2.new(0, 0, 0, 0)

local presetsTab = makeButton(tabBar, {
	Text = "Presets",
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundTransparency = 0.25,
})
presetsTab.Position = UDim2.new(0.5, 4, 0, 0)

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 12, 0, 98)
content.Size = UDim2.new(1, -24, 1, -110)
content.ClipsDescendants = true
content.Parent = frame

local customPage = Instance.new("ScrollingFrame")
customPage.Size = UDim2.new(1, 0, 1, 0)
customPage.BackgroundTransparency = 1
customPage.BorderSizePixel = 0
customPage.ScrollBarThickness = 3
customPage.ScrollBarImageColor3 = THEME.Accent
customPage.CanvasSize = UDim2.new(0, 0, 0, 0)
customPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
customPage.Visible = true
customPage.Parent = content

local customLayout = Instance.new("UIListLayout")
customLayout.Padding = UDim.new(0, 8)
customLayout.Parent = customPage

local presetsPage = Instance.new("ScrollingFrame")
presetsPage.Size = UDim2.new(1, 0, 1, 0)
presetsPage.BackgroundTransparency = 1
presetsPage.BorderSizePixel = 0
presetsPage.ScrollBarThickness = 3
presetsPage.ScrollBarImageColor3 = THEME.Accent
presetsPage.CanvasSize = UDim2.new(0, 0, 0, 0)
presetsPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
presetsPage.Visible = false
presetsPage.Parent = content

local presetsLayout = Instance.new("UIListLayout")
presetsLayout.Padding = UDim.new(0, 6)
presetsLayout.Parent = presetsPage

local function switchPage(page)
	customPage.Visible = page == "custom"
	presetsPage.Visible = page == "presets"
	customTab.BackgroundTransparency = page == "custom" and 0.1 or 0.25
	presetsTab.BackgroundTransparency = page == "presets" and 0.1 or 0.25
end

customTab.MouseButton1Click:Connect(function() switchPage("custom") end)
presetsTab.MouseButton1Click:Connect(function() switchPage("presets") end)

--------------------------------------------------------------------------------
-- TOGGLE BUILDER
--------------------------------------------------------------------------------
local function createToggle(parent, labelText, initial, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 36)
	row.BackgroundColor3 = THEME.ButtonIdle
	row.BackgroundTransparency = 0.25
	row.Parent = parent
	corner(row, UDim.new(0, 10))
	stroke(row, THEME.Stroke, 1).Transparency = 0.3

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.65, 0, 1, 0)
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
	bg.BackgroundColor3 = initial and THEME.Accent or THEME.Stroke
	bg.BorderSizePixel = 0
	bg.Parent = row
	corner(bg, UDim.new(1, 0))

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 14, 0, 14)
	circle.Position = initial and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	circle.BorderSizePixel = 0
	circle.Parent = bg
	corner(circle, UDim.new(1, 0))

	local on = initial
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

createToggle(customPage, "Active", settings.active, function(v)
	settings.active = v
	applyShaders()
	saveSettings()
end)

createToggle(customPage, "Remove Textures", settings.removeTextures, function(v)
	settings.removeTextures = v
	setRemoveTextures(v)
	saveSettings()
end)

--------------------------------------------------------------------------------
-- SLIDERS
--------------------------------------------------------------------------------
local function createSlider(parent, labelText, minV, maxV, defV, decimals, key)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 50)
	row.BackgroundColor3 = THEME.ButtonIdle
	row.BackgroundTransparency = 0.25
	row.Parent = parent
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
	local current = settings[key] or defV

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Size = UDim2.new(0.3, 0, 0, 18)
	valLbl.Position = UDim2.new(0.45, 0, 0, 6)
	valLbl.Text = string.format(fmt, current)
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

	local pct = (current - minV) / (maxV - minV)
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
		settings[key] = v
		applyShaders()
		saveSettings()
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

createSlider(customPage, "Brightness", 0, 5, defaults.brightness, 1, "brightness")
createSlider(customPage, "Contrast", -1, 1, defaults.contrast, 2, "contrast")
createSlider(customPage, "Saturation", -1, 1, defaults.saturation, 2, "saturation")
createSlider(customPage, "Exposure", -3, 3, defaults.exposure, 1, "exposure")
createSlider(customPage, "Bloom", 0, 2, defaults.bloom, 2, "bloom")
createSlider(customPage, "Blur", 0, 24, defaults.blur, 0, "blur")
createSlider(customPage, "Tint R", 0, 255, defaults.tintR, 0, "tintR")
createSlider(customPage, "Tint G", 0, 255, defaults.tintG, 0, "tintG")
createSlider(customPage, "Tint B", 0, 255, defaults.tintB, 0, "tintB")

--------------------------------------------------------------------------------
-- PRESETS
--------------------------------------------------------------------------------
for _, data in ipairs(skyboxes) do
	local btn = makeButton(presetsPage, {
		Text = data.name,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 0.2,
	})
	btn.MouseButton1Click:Connect(function()
		applySkybox(data)
	end)
end

--------------------------------------------------------------------------------
-- WINDOW CONTROLS
--------------------------------------------------------------------------------
closeBtn.MouseButton1Click:Connect(function()
	settings.active = false
	settings.removeTextures = false

	colorCorrection.Enabled = false
	bloomEffect.Enabled = false
	blurEffect.Enabled = false

	setRemoveTextures(false)

	saveSettings()
	gui:Destroy()
end)

local minimized = false
local expandedSize = OPEN_SIZE
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		expandedSize = frame.Size
		content.Visible = false
		tabBar.Visible = false
		divider.Visible = false
		tween(frame, {Size = UDim2.new(0, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT)})
		minBtn.Text = "+"
	else
		tween(frame, {Size = expandedSize})
		task.delay(0.22, function()
			content.Visible = true
			tabBar.Visible = true
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