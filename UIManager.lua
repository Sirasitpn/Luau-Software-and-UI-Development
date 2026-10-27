local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Events = {
	Train = ReplicatedStorage.Remotes:WaitForChild("TrainJumpPower"),
	ChangeBar = ReplicatedStorage.Remotes:WaitForChild("ChangeBarHeight"),
	SetHighest = ReplicatedStorage.Remotes:WaitForChild("SetHighestBar"),
	TestPB = ReplicatedStorage.Remotes:WaitForChild("TestPBBar") -- NEW REMOTE
}

local AVAILABLE_BAR_HEIGHTS = {8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 35, 40, 45, 50}

-- =========================================================
-- [CLASS: UI MANAGER]
-- =========================================================
local UIManager = {}
UIManager.__index = UIManager

function UIManager.new()
	local self = setmetatable({}, UIManager)
	self.activeTweens = {}
	self.Screen = Instance.new("ScreenGui")
	self.Screen.Name = "FlowUI"
	self.Screen.ResetOnSpawn = false
	self.Screen.Parent = PlayerGui

	self:BuildLeftHUD()
	self:BuildRightHUD()
	self:BuildMenu()
	self:BuildPopups() -- ✅ ADD THIS LINE HERE
	self:SetupConnections()

	return self
end

function UIManager:CreateLabel(parent, text, yOffset, color)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 35)
	lbl.Position = UDim2.new(0, 0, 0, yOffset)
	lbl.BackgroundColor3 = color
	lbl.Text = text
	lbl.TextColor3 = Color3.new(1,1,1)
	if color == Color3.fromRGB(255, 200, 0) then lbl.TextColor3 = Color3.new(0,0,0) end
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 16
	lbl.Parent = parent
	return lbl
end

function UIManager:BuildLeftHUD()
	self.LeftFrame = Instance.new("Frame")
	self.LeftFrame.Size = UDim2.new(0, 150, 0, 250)
	self.LeftFrame.Position = UDim2.new(0, 20, 0.5, -125)
	self.LeftFrame.BackgroundTransparency = 1
	self.LeftFrame.Parent = self.Screen

	-- NEW: Inventory Button
	self.BtnInventory = Instance.new("TextButton")
	self.BtnInventory.Size = UDim2.new(1, 0, 0, 40)
	self.BtnInventory.Position = UDim2.new(0, 0, 0, 0)
	self.BtnInventory.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
	self.BtnInventory.Text = "Inventory"
	self.BtnInventory.TextColor3 = Color3.new(1, 1, 1)
	self.BtnInventory.Font = Enum.Font.GothamBold
	self.BtnInventory.TextSize = 16
	self.BtnInventory.Parent = self.LeftFrame

	self.BtnOpenMenu = Instance.new("TextButton")
	self.BtnOpenMenu.Size = UDim2.new(1, 0, 0, 40)
	self.BtnOpenMenu.Position = UDim2.new(0, 0, 0, 50)
	self.BtnOpenMenu.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	self.BtnOpenMenu.Text = "Settings Menu"
	self.BtnOpenMenu.TextColor3 = Color3.new(1, 1, 1)
	self.BtnOpenMenu.Font = Enum.Font.GothamBold
	self.BtnOpenMenu.TextSize = 16
	self.BtnOpenMenu.Parent = self.LeftFrame

	-- NEW: Dev Coins Button
	self.BtnFreeCoins = Instance.new("TextButton")
	self.BtnFreeCoins.Size = UDim2.new(1, 0, 0, 40)
	self.BtnFreeCoins.Position = UDim2.new(0, 0, 0, 100)
	self.BtnFreeCoins.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	self.BtnFreeCoins.Text = "+1000 Coins (Dev)"
	self.BtnFreeCoins.TextColor3 = Color3.new(0, 0, 0)
	self.BtnFreeCoins.Font = Enum.Font.GothamBlack
	self.BtnFreeCoins.TextSize = 14
	self.BtnFreeCoins.Parent = self.LeftFrame
end

function UIManager:BuildRightHUD()
	-- NEW: Right Container for Stats and Train
	self.RightFrame = Instance.new("Frame")
	self.RightFrame.Size = UDim2.new(0, 220, 0, 350)
	self.RightFrame.Position = UDim2.new(1, -240, 0.5, -175)
	self.RightFrame.BackgroundTransparency = 1
	self.RightFrame.Parent = self.Screen

	-- MOVED STATS HERE
	self.LblCoins = self:CreateLabel(self.RightFrame, "Coins: 0", 0, Color3.fromRGB(255, 200, 0))
	self.LblHighest = self:CreateLabel(self.RightFrame, "Highest Cleared: 0", 40, Color3.fromRGB(80, 40, 100))
	self.LblPower = self:CreateLabel(self.RightFrame, "Power: 10 (8.0h)", 80, Color3.fromRGB(40, 80, 120))
	self.LblBar = self:CreateLabel(self.RightFrame, "Bar Height: 8", 120, Color3.fromRGB(120, 40, 40))

	self.BtnTrain = Instance.new("TextButton")
	self.BtnTrain.Size = UDim2.new(0, 150, 0, 150)
	self.BtnTrain.Position = UDim2.new(1, -150, 0, 170)
	self.BtnTrain.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	self.BtnTrain.Text = "TRAIN\n(Click)"
	self.BtnTrain.TextColor3 = Color3.new(1, 1, 1)
	self.BtnTrain.Font = Enum.Font.GothamBlack
	self.BtnTrain.TextSize = 28
	self.BtnTrain.Parent = self.RightFrame

	self.BtnTrain.MouseButton1Down:Connect(function()
		self.BtnTrain.Size = UDim2.new(0, 140, 0, 140)
		self.BtnTrain.Position = UDim2.new(1, -145, 0, 175)
	end)
	self.BtnTrain.MouseButton1Up:Connect(function()
		self.BtnTrain.Size = UDim2.new(0, 150, 0, 150)
		self.BtnTrain.Position = UDim2.new(1, -150, 0, 170)
	end)
end

function UIManager:BuildMenu()
	self.Menu = Instance.new("Frame")
	self.Menu.Size = UDim2.new(0, 320, 0, 290)
	self.Menu.Position = UDim2.new(0.5, -160, 0.5, -145)
	self.Menu.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	self.Menu.Visible = false
	self.Menu.Parent = self.Screen

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "SET BAR HEIGHT"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 20
	title.Parent = self.Menu

	-- Cycle Controls (Symmetrical Layout)
	self.BtnPrev = Instance.new("TextButton")
	self.BtnPrev.Size = UDim2.new(0, 50, 0, 50)
	self.BtnPrev.Position = UDim2.new(0.15, 0, 0.2, 0)
	self.BtnPrev.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	self.BtnPrev.Text = "<"
	self.BtnPrev.TextColor3 = Color3.new(1, 1, 1)
	self.BtnPrev.TextSize = 24
	self.BtnPrev.Font = Enum.Font.GothamBold
	self.BtnPrev.Parent = self.Menu

	self.LblMenuCurrentBar = Instance.new("TextLabel")
	self.LblMenuCurrentBar.Size = UDim2.new(0.4, 0, 0, 50)
	self.LblMenuCurrentBar.Position = UDim2.new(0.3, 0, 0.2, 0)
	self.LblMenuCurrentBar.BackgroundTransparency = 1
	self.LblMenuCurrentBar.Text = "8"
	self.LblMenuCurrentBar.TextColor3 = Color3.new(1, 1, 1)
	self.LblMenuCurrentBar.TextSize = 28
	self.LblMenuCurrentBar.Font = Enum.Font.GothamBlack
	self.LblMenuCurrentBar.Parent = self.Menu

	self.BtnNext = Instance.new("TextButton")
	self.BtnNext.Size = UDim2.new(0, 50, 0, 50)
	self.BtnNext.Position = UDim2.new(0.85, -50, 0.2, 0)
	self.BtnNext.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	self.BtnNext.Text = ">"
	self.BtnNext.TextColor3 = Color3.new(1, 1, 1)
	self.BtnNext.TextSize = 24
	self.BtnNext.Font = Enum.Font.GothamBold
	self.BtnNext.Parent = self.Menu

	-- Action Buttons Stacked Below
	self.BtnSetHighest = Instance.new("TextButton")
	self.BtnSetHighest.Size = UDim2.new(0.8, 0, 0, 35)
	self.BtnSetHighest.Position = UDim2.new(0.1, 0, 0.45, 0)
	self.BtnSetHighest.BackgroundColor3 = Color3.fromRGB(80, 40, 100)
	self.BtnSetHighest.Text = "Set to Highest Cleared"
	self.BtnSetHighest.TextColor3 = Color3.new(1, 1, 1)
	self.BtnSetHighest.Font = Enum.Font.GothamBold
	self.BtnSetHighest.TextSize = 14
	self.BtnSetHighest.Parent = self.Menu

	self.BtnTestPB = Instance.new("TextButton")
	self.BtnTestPB.Size = UDim2.new(0.8, 0, 0, 45)
	self.BtnTestPB.Position = UDim2.new(0.1, 0, 0.61, 0)
	self.BtnTestPB.BackgroundColor3 = Color3.fromRGB(220, 150, 0)
	self.BtnTestPB.Text = "Attempt Next PB (+1)"
	self.BtnTestPB.TextColor3 = Color3.new(0, 0, 0)
	self.BtnTestPB.Font = Enum.Font.GothamBlack
	self.BtnTestPB.TextSize = 16
	self.BtnTestPB.Parent = self.Menu

	self.BtnClose = Instance.new("TextButton")
	self.BtnClose.Size = UDim2.new(0.8, 0, 0, 30)
	self.BtnClose.Position = UDim2.new(0.1, 0, 0.82, 0)
	self.BtnClose.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	self.BtnClose.Text = "Close"
	self.BtnClose.TextColor3 = Color3.new(1, 1, 1)
	self.BtnClose.Font = Enum.Font.GothamBold
	self.BtnClose.Parent = self.Menu
end

-- Paste this right ABOVE function UIManager:CalculateHeight(power)

function UIManager:BuildPopups()
	-- ==========================================
	-- COIN POPUP UI
	-- ==========================================
	self.PopupContainer = Instance.new("Frame")
	self.PopupContainer.Size = UDim2.new(0, 400, 0, 100)
	self.PopupContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
	self.PopupContainer.AnchorPoint = Vector2.new(0.5, 0.5) 
	self.PopupContainer.BackgroundTransparency = 1
	self.PopupContainer.Visible = false
	self.PopupContainer.Parent = self.Screen 

	self.PopupText = Instance.new("TextLabel")
	self.PopupText.Size = UDim2.new(1, 0, 1, 0)
	self.PopupText.BackgroundTransparency = 1
	self.PopupText.Text = "+1000 COINS!"
	self.PopupText.TextColor3 = Color3.fromRGB(255, 215, 0) 
	self.PopupText.Font = Enum.Font.GothamBlack
	self.PopupText.TextScaled = true
	self.PopupText.TextStrokeColor3 = Color3.fromRGB(150, 100, 0) 
	self.PopupText.TextStrokeTransparency = 0 
	self.PopupText.Parent = self.PopupContainer
	
	-- ==========================================
	-- CLEAR / FAIL RESULT UI
	-- ==========================================
	self.ResultContainer = Instance.new("Frame")
	self.ResultContainer.Size = UDim2.new(0, 400, 0, 100)
	self.ResultContainer.Position = UDim2.new(0.5, 0, 0.3, 0) -- Sits above the coins
	self.ResultContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	self.ResultContainer.BackgroundTransparency = 1
	self.ResultContainer.Visible = false
	self.ResultContainer.Parent = self.Screen

	self.ResultText = Instance.new("TextLabel")
	self.ResultText.Size = UDim2.new(1, 0, 1, 0)
	self.ResultText.BackgroundTransparency = 1
	self.ResultText.Text = ""
	self.ResultText.Font = Enum.Font.GothamBlack
	self.ResultText.TextScaled = true
	self.ResultText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	self.ResultText.TextStrokeTransparency = 0
	self.ResultText.Parent = self.ResultContainer
	
	-- ==========================================
	-- FLOW STATE MINIGAME UI
	-- ==========================================
	self.FlowContainer = Instance.new("Frame")
	
	self.FlowContainer.Size = UDim2.new(0, 300, 0, 80)
	self.FlowContainer.Position = UDim2.new(0.7, 0, math.random(45,60)/100, 0) -- Use the shifted position here
	self.FlowContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	self.FlowContainer.BackgroundTransparency = 1
	self.FlowContainer.Visible = false
	self.FlowContainer.Parent = self.Screen

	-- 2. Create the Text and parent it to that container
	self.FlowText = Instance.new("TextLabel")
	self.FlowText.Size = UDim2.new(1, 0, 1, 0)
	self.FlowText.BackgroundTransparency = 1
	self.FlowText.Text = "PERFECT!"
	self.FlowText.Font = Enum.Font.GothamBlack
	self.FlowText.TextScaled = true
	self.FlowText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	self.FlowText.TextStrokeTransparency = 0
	self.FlowText.Parent = self.FlowContainer

	-- 3. Create the Result Container (Cleared/Failed)
	self.ResultContainer = Instance.new("Frame")
	self.ResultContainer.Size = UDim2.new(0, 400, 0, 100)
	self.ResultContainer.Position = UDim2.new(0.5, 0, 0.3, 0)
	self.ResultContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	self.ResultContainer.BackgroundTransparency = 1
	self.ResultContainer.Visible = false
	self.ResultContainer.Parent = self.Screen

	self.ResultText = Instance.new("TextLabel")
	self.ResultText.Size = UDim2.new(1, 0, 1, 0)
	self.ResultText.BackgroundTransparency = 1
	self.ResultText.Font = Enum.Font.GothamBlack
	self.ResultText.TextScaled = true
	self.ResultText.Parent = self.ResultContainer
end


function UIManager:UpdatePetInventory()
	local invGui = PlayerGui:FindFirstChild("InventoryGui")
	local pages = invGui and invGui.MainFrame:FindFirstChild("Pages")
	local petsPage = pages and pages:FindFirstChild("PetsPage")
	if not petsPage then return end

	-- Clear current display
	for _, child in ipairs(petsPage:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	-- Split the attribute string into an array
	local ownedString = Player:GetAttribute("OwnedPets") or ""
	local ownedArray = string.split(ownedString, ",")

	for _, petName in ipairs(ownedArray) do
		if petName == "" then continue end

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 110, 0, 110)
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		btn.Text = petName -- "Pet name as the icon"
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextWrapped = true
		btn.Parent = petsPage

		-- Equip on click
		btn.MouseButton1Click:Connect(function()
			ReplicatedStorage.Remotes.EquipPet:FireServer(petName)
		end)
	end
end

function UIManager:CreatePowerPopup(amount)
	local TweenService = game:GetService("TweenService")

	-- 1. Create the Label
	local popup = Instance.new("TextLabel")
	popup.Name = "PowerPopup"
	-- Randomize start position slightly so they don't stack perfectly
	local randomX = math.random(20, 70) / 100 
	local randomY = math.random(10, 40) / 100
	popup.Position = UDim2.new(randomX, 0, 0.5, 0) 
	popup.Size = UDim2.new(0, 200, 0, 50)
	popup.BackgroundTransparency = 1
	popup.Text = "+" .. string.format("%.1f", amount) .. " POWER"
	popup.TextColor3 = Color3.fromRGB(0, 255, 100) -- Green for gain
	popup.Font = Enum.Font.GothamBlack
	popup.TextScaled = true
	popup.ZIndex = 10
	popup.Parent = self.Screen

	-- 2. Animation: Float Up and Fade Out
	local goalPos = popup.Position - UDim2.new(0, 0, randomY, 0) 
	local info = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	local moveTween = TweenService:Create(popup, info, {
		Position = goalPos
	})

	moveTween:Play()

	task.wait(1)
	
	local info2 = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	local moveTween2 = TweenService:Create(popup, info2, {
		Position = goalPos- UDim2.new(0, 0,math.random(5, 10) / 100, 0) ,
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})

	moveTween2:Play()

	-- 3. Cleanup
	moveTween2.Completed:Connect(function()
		popup:Destroy()
	end)
end

function UIManager:CalculateHeight(power)
	return 8 + math.pow(power / 10, 0.8)
end

-- Helper function to add commas to large numbers (e.g., 1,000,000)
local function FormatNumber(value)
	local str = tostring(value)
	return str:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function UIManager:UpdateVisuals()
	local power = Player:GetAttribute("JumpPower") or 10
	local highest = Player:GetAttribute("HighestCleared") or 0
	local barIndex = Player:GetAttribute("BarHeightIndex") or 1

	-- FIX: Check leaderstats first, then fall back to Attributes
	local coins = 0
	local leaderstats = Player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Coins") then
		coins = leaderstats.Coins.Value
	else
		coins = Player:GetAttribute("Coins") or 0
	end

	local heightStuds = self:CalculateHeight(power)
	local currentBarHeight = AVAILABLE_BAR_HEIGHTS[barIndex] or 8
	local formattedHeight = string.format("%.1f", heightStuds)

	-- Update UI with formatted coin count
	self.LblCoins.Text = "Coins: " .. FormatNumber(coins)
	self.LblHighest.Text = "Highest Cleared: " .. highest
	self.LblPower.Text = "Power: " .. power .. " (" .. formattedHeight .. "h)"
	self.LblBar.Text = "Bar Height: " .. currentBarHeight
	self.LblMenuCurrentBar.Text = tostring(currentBarHeight)
end

function UIManager:SetupConnections()

		-- 1. DEFINE SHARED VARIABLES AT THE VERY TOP
	local activeTweens = {} 
	local resultFadeOut = nil
	local TweenService = game:GetService("TweenService")

		-- ... the rest of your button connections follow below ...
	self.BtnOpenMenu.MouseButton1Click:Connect(function() self.Menu.Visible = not self.Menu.Visible end)
	self.BtnClose.MouseButton1Click:Connect(function() self.Menu.Visible = false end)

	self.BtnTrain.MouseButton1Click:Connect(function() Events.Train:FireServer() end)
	self.BtnPrev.MouseButton1Click:Connect(function() Events.ChangeBar:FireServer(-1) end)
	self.BtnNext.MouseButton1Click:Connect(function() Events.ChangeBar:FireServer(1) end)

	self.BtnSetHighest.MouseButton1Click:Connect(function() Events.SetHighest:FireServer() end)
	self.BtnTestPB.MouseButton1Click:Connect(function() Events.TestPB:FireServer() end)

	-- Listeners for attributes
	Player:GetAttributeChangedSignal("JumpPower"):Connect(function() self:UpdateVisuals() end)
	Player:GetAttributeChangedSignal("HighestCleared"):Connect(function() self:UpdateVisuals() end)
	Player:GetAttributeChangedSignal("BarHeightIndex"):Connect(function() self:UpdateVisuals() end)
	Player:GetAttributeChangedSignal("Coins"):Connect(function() self:UpdateVisuals() end)
	

	-- Inventory Hookup
	-- Inventory Hookup (Debug Version)
	
	-- ==========================================
	-- INVENTORY TABS LOGIC
	-- ==========================================f
	self.BtnInventory.MouseButton1Click:Connect(function()
		-- 1. Check if the ScreenGui exists
		local invGui = PlayerGui:FindFirstChild("InventoryGui")
		if not invGui then
			warn("❌ ERROR: Could not find 'InventoryGui'. Did you name it correctly in StarterGui?")
			return
		end
	

		-- 2. Check if the MainFrame exists
		local mainFrame = invGui:FindFirstChild("MainFrame")
		if not mainFrame then
			warn("❌ ERROR: Found InventoryGui, but could not find 'MainFrame' inside it!")
			return
		end

		-- 3. If both exist, force it to show!
		invGui.Enabled = true -- Make sure the ScreenGui itself is turned on
		mainFrame.Visible = not mainFrame.Visible
		print("✅ Inventory Visibility changed to: ", mainFrame.Visible)
	end)
	

	
	local invGui = PlayerGui:WaitForChild("InventoryGui")
	local mainFrame = invGui:WaitForChild("MainFrame")
	local sidebar = mainFrame:WaitForChild("Sidebar")
	local pages = mainFrame:WaitForChild("Pages")
	local pageTitle = mainFrame:WaitForChild("PageTitle") -- The new header!

	-- Automatically set the starting page (Pets)
	local startPage = pages:FindFirstChild("PetsPage")
	if startPage then startPage.Visible = true end
	pageTitle.Text = "Pets"

	for _, button in ipairs(sidebar:GetChildren()) do
		if button:IsA("TextButton") then

			-- 1. Auto-rename the button text to match its Explorer name
			button.Text = button.Name

			-- 2. Setup the click behavior
			button.MouseButton1Click:Connect(function()
				-- Hide all pages
				for _, page in ipairs(pages:GetChildren()) do
					if page:IsA("Frame") or page:IsA("ScrollingFrame") then
						page.Visible = false
					end
				end

				-- Find the target page
				local targetPageName = button.Name .. "Page"
				local targetPage = pages:FindFirstChild(targetPageName)

				if targetPage then
					targetPage.Visible = true
					-- Update the big header text to match the tab we just clicked!
					pageTitle.Text = button.Name
				else
					warn("❌ Clicked " .. button.Name .. " but couldn't find a page named " .. targetPageName)
				end
			end)

		end
	end
	
	
	-- ==========================================
	-- CLOSE BUTTON LOGIC
	-- ==========================================
	local btnCloseInv = mainFrame:WaitForChild("BtnClose")

	btnCloseInv.MouseButton1Click:Connect(function()
		-- Simply hide the MainFrame when clicked!
		mainFrame.Visible = false
	end)




	-- ✅ PASTE THE ANIMATION LOGIC HERE:
	-- ==========================================
	-- COIN POPUP ANIMATION LOGIC
	-- ==========================================
	local TweenService = game:GetService("TweenService")
	local notifyRemote = ReplicatedStorage.Remotes:WaitForChild("NotifyCoinGain")
	local currentFadeOut = nil

	notifyRemote.OnClientEvent:Connect(function(coinAmount)
		self.PopupText.Text = "+" .. tostring(coinAmount) .. " COINS!"
		self.PopupContainer.Visible = true
		self.PopupContainer.Position = UDim2.new(0.5, 0, 0.45, 0)
		self.PopupText.TextTransparency = 0
		self.PopupText.TextStrokeTransparency = 0

		if currentFadeOut then currentFadeOut:Cancel() end

		local floatInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local floatTween = TweenService:Create(self.PopupContainer, floatInfo, {
			Position = UDim2.new(0.5, 0, 0.35, 0) 
		})
		floatTween:Play()

		task.delay(1.5, function()
			local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
			currentFadeOut = TweenService:Create(self.PopupText, fadeInfo, {
				TextTransparency = 1,
				TextStrokeTransparency = 1
			})
			currentFadeOut:Play()

			currentFadeOut.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					self.PopupContainer.Visible = false
				end
			end)
		end)
	end)
	

	-- ==========================================
	-- JUMP STATE LOGIC (PEAK & LANDING)
	-- ==========================================
	Player:GetAttributeChangedSignal("JumpState"):Connect(function()
		local state = Player:GetAttribute("JumpState")

		-- 1. TRIGGERED AT THE PEAK
		if state == "PeakClear" or state == "PeakClearPerfect" or state == "PeakFail" then
			print("🚨 DEBUG: Peak hit! Clearing " .. #activeTweens .. " tweens.")

			-- Stop and clear the pulsing/wobbling "PERFECT!" text
			for _, tween in ipairs(activeTweens) do
				if tween then tween:Cancel() end
			end
			activeTweens = {} 

			self.FlowContainer.Visible = false 

			-- SHOW THE SUCCESS/FAIL TEXT
			self.ResultContainer.Visible = true
			self.ResultContainer.Position = UDim2.new(0.5, 0, 0.3, 0)
			self.ResultText.TextTransparency = 0
			self.ResultText.TextStrokeTransparency = 0

			if state == "PeakClearPerfect" then
				self.ResultText.Text = "PERFECT CLEAR!"
				self.ResultText.TextColor3 = Color3.fromRGB(255, 150, 0) 
			elseif state == "PeakClear" then
				self.ResultText.Text = "CLEARED!"
				self.ResultText.TextColor3 = Color3.fromRGB(50, 255, 50) 
			elseif state == "PeakFail" then
				self.ResultText.Text = "FAILED!"
				self.ResultText.TextColor3 = Color3.fromRGB(255, 50, 50) 
			end

			-- "Pop" the result text upward
			TweenService:Create(self.ResultContainer, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {
				Position = UDim2.new(0.5, 0, 0.25, 0)
			}):Play()

			if resultFadeOut then resultFadeOut:Cancel() end
		end

		-- 2. TRIGGERED ON LANDING
		if state == "Landed" then
			if self.ResultContainer.Visible then
				resultFadeOut = TweenService:Create(self.ResultText, TweenInfo.new(0.5), {
					TextTransparency = 1,
					TextStrokeTransparency = 1
				})
				resultFadeOut:Play()

				resultFadeOut.Completed:Connect(function(playbackState)
					if playbackState == Enum.PlaybackState.Completed then
						self.ResultContainer.Visible = false
					end
				end)
			end
		end
	end)
	
	-- ==========================================
	-- SHOW FLOW STATE RESULT LOGIC
	-- ==========================================
	-- Change "FlowStateResult" to "CircleMinigameResult" if that is what your RemoteEvent is named!
	-- ==========================================
	-- DEBUG: SHOW FLOW STATE RESULT LOGIC
	-- ==========================================
	-- ⚠️ CHANGE THE NAME IN QUOTES TO MATCH YOUR EXACT REMOTE IN EXPLORER!
	-- ==========================================
	-- FLOW STATE RESULT LOGIC (BindableEvent)
	-- ==========================================
	-- Inside UIManager:SetupConnections()
	

	-- ==========================================
	-- JUICY FLOW STATE RESULT LOGIC
	-- ==========================================
	local flowRemote = ReplicatedStorage.Remotes:WaitForChild("FlowStateResult")

	-- We store the tweens here so we can stop them when the text is hidden
	

	flowRemote.OnClientEvent:Connect(function(resultType)
		-- 1. Setup Initial State
		self.FlowContainer.Visible = true
		self.FlowText.Text = tostring(resultType)
		self.FlowText.Rotation = -5 -- Start tilted slightly left
		self.FlowText.Size = UDim2.new(0.8, 0, 0.8, 0) -- Start small for the "pop"

		-- Color Logic
		if resultType == "x1.5 POWER!!" then
			self.FlowText.TextColor3 = Color3.fromRGB(0, 255, 100)
		elseif resultType == "x1.2 POWER!" then
			self.FlowText.TextColor3 = Color3.fromRGB(255, 200, 0)
		else
			self.FlowText.TextColor3 = Color3.fromRGB(255, 50, 50)
		end

		-- 2. THE "POP" (Initial appearance)
		local popTween = TweenService:Create(self.FlowText, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.new(1.2, 0, 1.2, 0)
		})
		popTween:Play()

		-- 3. THE "PULSE" (Bigger and Smaller)
		local pulseInfo = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local pulseTween = TweenService:Create(self.FlowText, pulseInfo, {
			Size = UDim2.new(1, 0, 1, 0) -- Pulses between 1.2 and 1.0
		})
		pulseTween:Play()

		-- 4. THE "WOBBLE" (Rotating right and left)
		local wobbleInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local wobbleTween = TweenService:Create(self.FlowText, wobbleInfo, {
			Rotation = 5 -- Tilts from -5 to 5 degrees
		})
		wobbleTween:Play()

		-- Store them so we can stop them later
		table.insert(activeTweens, pulseTween)
		table.insert(activeTweens, wobbleTween)
	end)
	
	
	-- Dev Coins Hookup
	self.BtnFreeCoins.MouseButton1Click:Connect(function() 
		local devEvent = ReplicatedStorage.Remotes:FindFirstChild("DevAddCoins")
		if devEvent then devEvent:FireServer(1000) end

		-- Instead of firing a remote, we just trigger the UI logic directly!
		-- This is why it failed before.
		flowRemote:FireServer(1.2) -- This tells the server to give you the 1.2x boost AND trigger the UI
	end)
	
	
	function UIManager:UpdatePetInventory()
		local invGui = PlayerGui:FindFirstChild("InventoryGui")
		local pages = invGui and invGui.MainFrame:FindFirstChild("Pages")
		local petsPage = pages and pages:FindFirstChild("PetsPage")
		if not petsPage then return end

		-- Clear current buttons
		for _, child in ipairs(petsPage:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end

		-- Get owned pets string and split it
		local ownedString = Player:GetAttribute("OwnedPets") or ""
		local ownedArray = string.split(ownedString, ",")

		for _, petName in ipairs(ownedArray) do
			if petName == "" then continue end

			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 110, 0, 110)
			btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			btn.Text = petName -- Uses name as the icon[cite: 1]
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Font = Enum.Font.FredokaOne
			btn.TextScaled = true
			btn.Parent = petsPage

			btn.MouseButton1Click:Connect(function()
				ReplicatedStorage.Remotes.EquipPet:FireServer(petName)
			end)
		end
	end
	-- Inside SetupConnections()
	Player:GetAttributeChangedSignal("OwnedPets"):Connect(function()
		self:UpdatePetInventory()
	end)

	-- Also refresh when the Inventory button is clicked
	self.BtnInventory.MouseButton1Click:Connect(function()
		self:UpdatePetInventory()
	end)
	
	-- Inside UIManager:SetupConnections()
	local notifyPowerRemote = ReplicatedStorage.Remotes:WaitForChild("NotifyPowerGain")

	notifyPowerRemote.OnClientEvent:Connect(function(amount)
		self:CreatePowerPopup(amount)
	end)
	
	
	
	

	-- FIX: Listener for leaderstats (in case you don't use attributes for coins)
	task.spawn(function()
		local stats = Player:WaitForChild("leaderstats", 5)
		if stats then
			local c = stats:WaitForChild("Coins", 5)
			if c then
				c:GetPropertyChangedSignal("Value"):Connect(function() self:UpdateVisuals() end)
			end
		end
	end)

	task.wait(0.5)
	self:UpdateVisuals()
end

local MainUI = UIManager.new()


