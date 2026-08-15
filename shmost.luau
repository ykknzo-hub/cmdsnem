-- NEMESIS Server Browser (All servers + ping + join)
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local pg = LocalPlayer:WaitForChild("PlayerGui")

local existing = pg:FindFirstChild("ShmostGui")
if existing then existing:Destroy() end

--------------------------------------------------------------------------------
-- THEME
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
	Success      = Color3.fromRGB(80, 200, 120),
}

local OPEN_SIZE        = UDim2.new(0, 340, 0, 420)
local COLLAPSED_HEIGHT = 48
local MIN_SIZE         = Vector2.new(280, 220)
local MAX_SIZE         = Vector2.new(520, 560)
local TWEEN_INFO       = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local HOVER_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--------------------------------------------------------------------------------
-- LOGO
--------------------------------------------------------------------------------
local LOGO_PATH         = "whitelogo.png"
local LOGO_DOWNLOAD_URL = "https://i.ibb.co/SwGkMS5h/whitelogo.png"
local FALLBACK_LOGO     = "rbxassetid://107541043103322"

local function getLogoImage()
	if typeof(getcustomasset) == "function" then
		if isfile and isfile(LOGO_PATH) then
			local ok, asset = pcall(getcustomasset, LOGO_PATH)
			if ok and asset then return asset end
		end
		if LOGO_DOWNLOAD_URL ~= "" and (not isfile or not isfile(LOGO_PATH)) then
			local ok, data = pcall(function() return game:HttpGet(LOGO_DOWNLOAD_URL) end)
			if ok and type(data) == "string" and #data > 200 then
				pcall(writefile, LOGO_PATH, data)
				if isfile and isfile(LOGO_PATH) then
					local ok2, asset = pcall(getcustomasset, LOGO_PATH)
					if ok2 and asset then return asset end
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
	btn.Size = props.Size or UDim2.new(0, 24, 0, 24)
	btn.BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle
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
		tween(btn, { BackgroundColor3 = props.BackgroundColor3 or THEME.ButtonIdle, BackgroundTransparency = 0.25 }, HOVER_TWEEN_INFO)
		tween(btnStroke, { Color = THEME.Stroke, Transparency = 0.3 }, HOVER_TWEEN_INFO)
	end)
	return btn
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ShmostGui"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = pg

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = OPEN_SIZE
frame.Position = UDim2.new(0.5, -170, 0.5, -210)
frame.BackgroundColor3 = THEME.Background
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui
corner(frame, UDim.new(0, 16))
local frameStroke = stroke(frame, THEME.Stroke, 1.2)
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
title.Size = UDim2.new(0, 200, 0, 22)
title.Position = UDim2.new(0, 46, 0.5, -11)
title.Text = "NEMESIS ServerHopper"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = THEME.TextPrimary
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = makeButton(titleBar, { Text = "–", Size = UDim2.new(0, 24, 0, 24) })
minBtn.Position = UDim2.new(1, -58, 0, 12)

local closeBtn = makeButton(titleBar, { Text = "×", Size = UDim2.new(0, 24, 0, 24) })
closeBtn.Position = UDim2.new(1, -30, 0, 12)
closeBtn.TextSize = 16

local divider = Instance.new("Frame")
divider.BackgroundColor3 = THEME.Stroke
divider.BorderSizePixel = 0
divider.Size = UDim2.new(1, -24, 0, 1)
divider.Position = UDim2.new(0, 12, 0, 48)
divider.Parent = frame

-- Top controls
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, -24, 0, 36)
topBar.Position = UDim2.new(0, 12, 0, 56)
topBar.BackgroundTransparency = 1
topBar.Parent = frame

local RefreshBtn = makeButton(topBar, {
	Text = "Refresh Servers",
	Size = UDim2.new(1, 0, 0, 32),
})

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -24, 0, 18)
StatusText.Position = UDim2.new(0, 12, 0, 96)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Press Refresh to load servers."
StatusText.TextColor3 = THEME.TextMuted
StatusText.TextSize = 11
StatusText.Font = Enum.Font.Gotham
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = frame

-- Server list
local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Position = UDim2.new(0, 12, 0, 118)
content.Size = UDim2.new(1, -24, 1, -130)
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = THEME.Accent
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = content

--------------------------------------------------------------------------------
-- RESIZE + WINDOW CONTROLS
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
	local t = tween(frame, { Size = UDim2.new(0, frame.Size.X.Offset, 0, 0), BackgroundTransparency = 1 })
	t.Completed:Connect(function() gui:Destroy() end)
end)

local minimized = false
local expandedSize = OPEN_SIZE
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		expandedSize = frame.Size
		content.Visible = false
		divider.Visible = false
		topBar.Visible = false
		StatusText.Visible = false
		resizeHandle.Visible = false
		tween(frame, { Size = UDim2.new(expandedSize.X.Scale, expandedSize.X.Offset, 0, COLLAPSED_HEIGHT) })
		minBtn.Text = "+"
	else
		tween(frame, { Size = expandedSize })
		task.delay(TWEEN_INFO.Time, function()
			content.Visible = true
			divider.Visible = true
			topBar.Visible = true
			StatusText.Visible = true
			resizeHandle.Visible = true
		end)
		minBtn.Text = "–"
	end
end)

-- Drag
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
	local delta = input.Position - dragStart
	frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and input == dragInput then updateDrag(input) end
end)

-- Resize
local resizing, resizeInput, resizeStart, sizeStart
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
			if input.UserInputState == Enum.UserInputState.End then resizing = false end
		end)
	end
end)
resizeCursor.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		resizeInput = input
	end
end)
UIS.InputChanged:Connect(function(input)
	if resizing and input == resizeInput then updateResize(input) end
end)

--------------------------------------------------------------------------------
-- SERVER FETCH + LIST
--------------------------------------------------------------------------------
local isLoading = false
local maxServerPages = 8

-- Roblox does not give country per public server. Show placeholder.
local function regionLabel(server)
	-- Some rare payloads may include region-like fields; usually nil
	local r = server.region or server.location or server.country
	if type(r) == "string" and r ~= "" then
		return r
	end
	return "—"
end

local function clearList()
	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function createServerRow(server, index)
	local playing = server.playing or 0
	local maxP = server.maxPlayers or Players.MaxPlayers
	local ping = server.ping
	local pingText = (typeof(ping) == "number") and (math.floor(ping) .. " ms") or "N/A"
	local region = regionLabel(server)

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 52)
	row.BackgroundColor3 = THEME.Panel
	row.BackgroundTransparency = 0.15
	row.BorderSizePixel = 0
	row.LayoutOrder = index
	row.Parent = content
	corner(row, UDim.new(0, 10))
	stroke(row, THEME.Stroke, 1).Transparency = 0.4

	-- Flag / region placeholder
	local flagLbl = Instance.new("TextLabel")
	flagLbl.Size = UDim2.new(0, 36, 1, 0)
	flagLbl.Position = UDim2.new(0, 8, 0, 0)
	flagLbl.BackgroundTransparency = 1
	flagLbl.Text = "🌐"
	flagLbl.TextSize = 16
	flagLbl.Font = Enum.Font.Gotham
	flagLbl.TextColor3 = THEME.TextPrimary
	flagLbl.Parent = row

	local regionLbl = Instance.new("TextLabel")
	regionLbl.Size = UDim2.new(0, 40, 0, 14)
	regionLbl.Position = UDim2.new(0, 6, 1, -16)
	regionLbl.BackgroundTransparency = 1
	regionLbl.Text = region
	regionLbl.TextSize = 9
	regionLbl.Font = Enum.Font.Gotham
	regionLbl.TextColor3 = THEME.TextMuted
	regionLbl.TextXAlignment = Enum.TextXAlignment.Center
	regionLbl.Parent = row

	-- Players
	local playersLbl = Instance.new("TextLabel")
	playersLbl.Size = UDim2.new(0, 90, 0, 18)
	playersLbl.Position = UDim2.new(0, 50, 0, 8)
	playersLbl.BackgroundTransparency = 1
	playersLbl.Text = playing .. " / " .. maxP .. " players"
	playersLbl.Font = Enum.Font.GothamBold
	playersLbl.TextSize = 12
	playersLbl.TextColor3 = THEME.TextPrimary
	playersLbl.TextXAlignment = Enum.TextXAlignment.Left
	playersLbl.Parent = row

	-- Ping
	local pingLbl = Instance.new("TextLabel")
	pingLbl.Size = UDim2.new(0, 90, 0, 16)
	pingLbl.Position = UDim2.new(0, 50, 0, 28)
	pingLbl.BackgroundTransparency = 1
	pingLbl.Text = "Ping: " .. pingText
	pingLbl.Font = Enum.Font.Gotham
	pingLbl.TextSize = 11
	pingLbl.TextColor3 = THEME.TextMuted
	pingLbl.TextXAlignment = Enum.TextXAlignment.Left
	pingLbl.Parent = row

	-- Job id short
	local idLbl = Instance.new("TextLabel")
	idLbl.Size = UDim2.new(0, 100, 0, 14)
	idLbl.Position = UDim2.new(0, 150, 0, 30)
	idLbl.BackgroundTransparency = 1
	idLbl.Text = string.sub(tostring(server.id or ""), 1, 8) .. "..."
	idLbl.Font = Enum.Font.Gotham
	idLbl.TextSize = 10
	idLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
	idLbl.TextXAlignment = Enum.TextXAlignment.Left
	idLbl.Parent = row

	-- Join
	local joinBtn = makeButton(row, {
		Text = "Join",
		Size = UDim2.new(0, 64, 0, 28),
		TextColor3 = THEME.Success,
	})
	joinBtn.Position = UDim2.new(1, -74, 0.5, -14)

	joinBtn.MouseButton1Click:Connect(function()
		if not server.id then return end
		StatusText.Text = "Joining server (" .. playing .. " players)..."
		StatusText.TextColor3 = THEME.TextPrimary
		joinBtn.Text = "..."
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
		end)
	end)
end

local function GetAllServers()
	local allServers = {}
	local cursor = ""
	local pageCount = 0
	local maxRetryAttempts = 3

	repeat
		local success, result = false, nil
		local retryAttempt = 0

		repeat
			retryAttempt = retryAttempt + 1
			success, result = pcall(function()
				local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
				if cursor ~= "" then
					url = url .. "&cursor=" .. cursor
				end
				return HttpService:JSONDecode(game:HttpGet(url))
			end)
			if not success then
				task.wait(retryAttempt * 0.4)
			end
		until success or retryAttempt >= maxRetryAttempts

		if success and result and result.data then
			for _, server in ipairs(result.data) do
				if server.id and server.id ~= game.JobId then
					table.insert(allServers, server)
				end
			end
			cursor = result.nextPageCursor or ""
			pageCount = pageCount + 1
			StatusText.Text = "Loading servers... page " .. pageCount
		else
			cursor = ""
		end
	until cursor == "" or pageCount >= maxServerPages

	return allServers
end

local function RefreshServers()
	if isLoading then return end
	isLoading = true
	RefreshBtn.Text = "Loading..."
	StatusText.Text = "Fetching servers..."
	StatusText.TextColor3 = THEME.TextMuted
	clearList()

	task.spawn(function()
		local servers = GetAllServers()

		-- Sort: highest players first, then lower ping
		table.sort(servers, function(a, b)
			local pa, pb = a.playing or 0, b.playing or 0
			if pa ~= pb then return pa > pb end
			local pina = (typeof(a.ping) == "number") and a.ping or 9999
			local pinb = (typeof(b.ping) == "number") and b.ping or 9999
			return pina < pinb
		end)

		clearList()
		for i, server in ipairs(servers) do
			createServerRow(server, i)
		end

		StatusText.Text = #servers .. " servers found (region not provided by Roblox API)"
		StatusText.TextColor3 = THEME.TextMuted
		RefreshBtn.Text = "Refresh Servers"
		isLoading = false
	end)
end

RefreshBtn.MouseButton1Click:Connect(RefreshServers)

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult)
	if player == LocalPlayer then
		StatusText.Text = "Join failed: " .. tostring(teleportResult)
		StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end)

--------------------------------------------------------------------------------
-- OPEN ANIMATION
--------------------------------------------------------------------------------
frame.Size = UDim2.new(0, OPEN_SIZE.X.Offset, 0, 0)
tween(frame, { Size = OPEN_SIZE })
