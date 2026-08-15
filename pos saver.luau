-- NEMESIS-STYLE UI - POSITION SAVER (Xeno Max Compatibility) + Persistent Save
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
local existing = TargetGuiService:FindFirstChild("NemesisPositionSaverGui")
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
	Danger       = Color3.fromRGB(255, 255, 255),
}

local OPEN_SIZE        = UDim2.new(0, 280, 0, 340)
local COLLAPSED_HEIGHT = 48
local TWEEN_INFO       = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SAVE_FILE = "NemesisPositions.txt"

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
		tween(btn, {
			BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle,
			BackgroundTransparency = props.BackgroundTransparency or 0.25
		}, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Stroke, Transparency = 0.3 }, HOVER_TWEEN_INFO)
	end)

	return btn
end

--------------------------------------------------------------------------------
-- PERSISTENT DATA
--------------------------------------------------------------------------------
local savedPositions = {} -- {name: {x, y, z}}

local function saveToFile()
	if not writefile then return end
	local lines = {}
	for name, pos in pairs(savedPositions) do
		table.insert(lines, string.format("%s|%.4f|%.4f|%.4f", name, pos.x, pos.y, pos.z))
	end
	writefile(SAVE_FILE, table.concat(lines, "\n"))
end

local function loadFromFile()
	if not (isfile and readfile) then return end
	if not isfile(SAVE_FILE) then return end

	local content = readfile(SAVE_FILE)
	for line in content:gmatch("[^\r\n]+") do
		local name, x, y, z = line:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
		if name and x and y and z then
			savedPositions[name] = {
				x = tonumber(x),
				y = tonumber(y),
				z = tonumber(z)
			}
		end
	end
end

loadFromFile()

--------------------------------------------------------------------------------
-- MAIN UI CONSTRUCTION
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "NemesisPositionSaverGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.Parent = TargetGuiService

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -140, 0.5, -170)
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
title.Size = UDim2.new(0, 160, 0, 22)
title.Position = UDim2.new(0, 46, 0.5, -11)
title.Text = "NEMESIS PositionSaver"
title.Font = Enum.Font.GothamBold
title.TextSize = 13
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

-- Tab buttons
local tabContainer = Instance.new("Frame")
tabContainer.BackgroundTransparency = 1
tabContainer.Size = UDim2.new(1, -24, 0, 30)
tabContainer.Position = UDim2.new(0, 12, 0, 58)
tabContainer.Parent = frame

local tab1Btn = makeButton(tabContainer, {
	Text = "Save",
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundColor3 = THEME.Accent,
	BackgroundTransparency = 0,
	TextColor3 = Color3.fromRGB(15, 15, 15),
})
tab1Btn.Position = UDim2.new(0, 0, 0, 0)

local tab2Btn = makeButton(tabContainer, {
	Text = "Load",
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundTransparency = 0.25,
})
tab2Btn.Position = UDim2.new(0.5, 4, 0, 0)

-- Content area
local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 12, 0, 96)
content.Size = UDim2.new(1, -24, 1, -108)
content.Parent = frame

--------------------------------------------------------------------------------
-- SAVE PANEL
--------------------------------------------------------------------------------
local savePanel = Instance.new("Frame")
savePanel.Name = "SavePanel"
savePanel.Size = UDim2.new(1, 0, 1, 0)
savePanel.BackgroundTransparency = 1
savePanel.Parent = content
savePanel.Visible = true

local saveLayout = Instance.new("UIListLayout")
saveLayout.Padding = UDim.new(0, 10)
saveLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
saveLayout.Parent = savePanel

-- Current position card
local currentPosCard = Instance.new("Frame")
currentPosCard.Size = UDim2.new(1, 0, 0, 52)
currentPosCard.BackgroundColor3 = THEME.ButtonIdle
currentPosCard.BackgroundTransparency = 0.25
currentPosCard.Parent = savePanel
corner(currentPosCard, UDim.new(0, 10))
stroke(currentPosCard, THEME.Stroke, 1).Transparency = 0.3

local currentPosLabel = Instance.new("TextLabel")
currentPosLabel.Size = UDim2.new(1, -20, 1, 0)
currentPosLabel.Position = UDim2.new(0, 10, 0, 0)
currentPosLabel.BackgroundTransparency = 1
currentPosLabel.Text = "X: 0.0\nY: 0.0\nZ: 0.0"
currentPosLabel.TextColor3 = THEME.TextMuted
currentPosLabel.TextSize = 12
currentPosLabel.Font = Enum.Font.Gotham
currentPosLabel.TextXAlignment = Enum.TextXAlignment.Left
currentPosLabel.TextYAlignment = Enum.TextYAlignment.Center
currentPosLabel.Parent = currentPosCard

-- Name input
local nameInput = Instance.new("TextBox")
nameInput.Size = UDim2.new(1, 0, 0, 34)
nameInput.BackgroundColor3 = THEME.ButtonIdle
nameInput.BackgroundTransparency = 0.25
nameInput.BorderSizePixel = 0
nameInput.PlaceholderColor3 = THEME.TextMuted
nameInput.PlaceholderText = "Position name..."
nameInput.Text = ""
nameInput.TextColor3 = THEME.TextPrimary
nameInput.TextSize = 12
nameInput.Font = Enum.Font.Gotham
nameInput.ClearTextOnFocus = false
nameInput.Parent = savePanel
corner(nameInput, UDim.new(0, 10))
stroke(nameInput, THEME.Stroke, 1).Transparency = 0.3

-- Save button
local saveBtn = makeButton(savePanel, {
	Text = "Save Position",
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = THEME.Accent,
	BackgroundTransparency = 0,
	TextColor3 = Color3.fromRGB(15, 15, 15),
	TextSize = 13,
})

--------------------------------------------------------------------------------
-- LOAD PANEL
--------------------------------------------------------------------------------
local loadPanel = Instance.new("Frame")
loadPanel.Name = "LoadPanel"
loadPanel.Size = UDim2.new(1, 0, 1, 0)
loadPanel.BackgroundTransparency = 1
loadPanel.Parent = content
loadPanel.Visible = false

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = THEME.Accent
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = loadPanel

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 8)
scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
scrollLayout.Parent = scrollFrame

--------------------------------------------------------------------------------
-- CORE FUNCTIONS
--------------------------------------------------------------------------------
local function getCurrentPosition()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local pos = char.HumanoidRootPart.Position
		return { x = pos.X, y = pos.Y, z = pos.Z }
	end
	return { x = 0, y = 0, z = 0 }
end

local function updateCurrentPosLabel()
	local pos = getCurrentPosition()
	currentPosLabel.Text = string.format("X: %.1f\nY: %.1f\nZ: %.1f", pos.x, pos.y, pos.z)
end

local function teleportToPosition(posData)
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(posData.x, posData.y, posData.z))
	end
end

local function refreshLoadPanel()
	for _, child in pairs(scrollFrame:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local positions = {}
	for name, pos in pairs(savedPositions) do
		table.insert(positions, { name = name, data = pos })
	end

	if #positions == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 40)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No positions saved"
		emptyLabel.TextColor3 = THEME.TextMuted
		emptyLabel.TextSize = 12
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.Parent = scrollFrame
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 40)
		return
	end

	for _, item in pairs(positions) do
		local itemCard = Instance.new("Frame")
		itemCard.Size = UDim2.new(1, 0, 0, 54)
		itemCard.BackgroundColor3 = THEME.ButtonIdle
		itemCard.BackgroundTransparency = 0.25
		itemCard.Parent = scrollFrame
		corner(itemCard, UDim.new(0, 10))
		stroke(itemCard, THEME.Stroke, 1).Transparency = 0.3

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -80, 0, 18)
		nameLbl.Position = UDim2.new(0, 12, 0, 8)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = item.name
		nameLbl.TextColor3 = THEME.TextPrimary
		nameLbl.TextSize = 12
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Parent = itemCard

		local coordsLbl = Instance.new("TextLabel")
		coordsLbl.Size = UDim2.new(1, -24, 0, 16)
		coordsLbl.Position = UDim2.new(0, 12, 0, 28)
		coordsLbl.BackgroundTransparency = 1
		coordsLbl.Text = string.format("X:%.1f  Y:%.1f  Z:%.1f", item.data.x, item.data.y, item.data.z)
		coordsLbl.TextColor3 = THEME.TextMuted
		coordsLbl.TextSize = 11
		coordsLbl.Font = Enum.Font.Gotham
		coordsLbl.TextXAlignment = Enum.TextXAlignment.Left
		coordsLbl.Parent = itemCard

		local tpBtn = makeButton(itemCard, {
			Text = "TP",
			Size = UDim2.new(0, 30, 0, 22),
			BackgroundColor3 = THEME.Accent,
			BackgroundTransparency = 0,
			TextColor3 = Color3.fromRGB(15, 15, 15),
			TextSize = 11,
		})
		tpBtn.Position = UDim2.new(1, -70, 0, 8)

		tpBtn.MouseButton1Click:Connect(function()
			teleportToPosition(item.data)
		end)

		local delBtn = makeButton(itemCard, {
			Text = "Del",
			Size = UDim2.new(0, 30, 0, 22),
			BackgroundColor3 = THEME.ButtonHover,
			BackgroundTransparency = 0,
			TextColor3 = THEME.TextPrimary,
			TextSize = 11,
		})
		delBtn.Position = UDim2.new(1, -36, 0, 8)

		delBtn.MouseButton1Click:Connect(function()
			savedPositions[item.name] = nil
			saveToFile()
			refreshLoadPanel()
		end)
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 12)
end

--------------------------------------------------------------------------------
-- EVENTS
--------------------------------------------------------------------------------
saveBtn.MouseButton1Click:Connect(function()
	local posName = nameInput.Text
	if posName and posName ~= "" then
		savedPositions[posName] = getCurrentPosition()
		nameInput.Text = ""
		updateCurrentPosLabel()
		saveToFile()
	end
end)

local function setActiveTab(isSave)
	if isSave then
		savePanel.Visible = true
		loadPanel.Visible = false
		tab1Btn.BackgroundColor3 = THEME.Accent
		tab1Btn.BackgroundTransparency = 0
		tab1Btn.TextColor3 = Color3.fromRGB(15, 15, 15)
		tab2Btn.BackgroundColor3 = THEME.ButtonIdle
		tab2Btn.BackgroundTransparency = 0.25
		tab2Btn.TextColor3 = THEME.TextPrimary
	else
		savePanel.Visible = false
		loadPanel.Visible = true
		tab2Btn.BackgroundColor3 = THEME.Accent
		tab2Btn.BackgroundTransparency = 0
		tab2Btn.TextColor3 = Color3.fromRGB(15, 15, 15)
		tab1Btn.BackgroundColor3 = THEME.ButtonIdle
		tab1Btn.BackgroundTransparency = 0.25
		tab1Btn.TextColor3 = THEME.TextPrimary
		refreshLoadPanel()
	end
end

tab1Btn.MouseButton1Click:Connect(function()
	setActiveTab(true)
end)

tab2Btn.MouseButton1Click:Connect(function()
	setActiveTab(false)
end)

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
		tabContainer.Visible = false
		divider.Visible = false
		tween(frame, { Size = UDim2.new(0, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT) })
		minBtn.Text = "+"
	else
		tween(frame, { Size = expandedSize })
		task.delay(TWEEN_INFO.Time, function()
			content.Visible = true
			tabContainer.Visible = true
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

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
task.wait(0.3)
updateCurrentPosLabel()

RunService.Heartbeat:Connect(function()
	if savePanel.Visible and not minimized then
		updateCurrentPosLabel()
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	updateCurrentPosLabel()
end)