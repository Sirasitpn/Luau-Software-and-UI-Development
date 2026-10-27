local GameManager = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
--local PetManager = require(SharedModules:WaitForChild("PetManager"))
local JumpEvent = require(script.Parent:WaitForChild("JumpEvent"))
local ItemData = require(ReplicatedStorage.SharedModules.ItemData) 
local StatCalculator = require(game.ReplicatedStorage.SharedModules.StatCalculator)
local gameConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GameConfig"))
local AVAILABLE_BAR_HEIGHTS = gameConfig.AVAILABLE_BAR_HEIGHTS
--  THE TRAINING DICTIONARY
local TrainingData = gameConfig.TrainingData
local TRAIN_COOLDOWN = 0.1

local RemoteFolder = ReplicatedStorage:WaitForChild("Remotes")
local function CreateRemote(name)
	local remote = RemoteFolder:FindFirstChild(name) or Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = RemoteFolder
	return remote
end

local Events = {
	Train = CreateRemote("TrainJumpPower"),
	CircleResult = CreateRemote("CircleMinigameResult"),
	ShopAction = CreateRemote("ShopAction"),
	EquipPet = CreateRemote("EquipPet"),
	EquipAccessory = CreateRemote("EquipAccessory"),
	EquipTrail = CreateRemote("EquipTrail"),

	-- 🚀 ADD THIS LINE:
	FlowStateResult = CreateRemote("FlowStateResult"),
	DevAddCoins = CreateRemote("DevAddCoins"),
	StopTraining = CreateRemote("StopTraining"),
	NotifyPowerGain = CreateRemote("NotifyPowerGain")
	
}

function GameManager.Init()
	-- 1. DATA SETUP (Only called once per player now)
	Players.PlayerAdded:Connect(function(player)
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = 0
		coins.Parent = leaderstats

		player:SetAttribute("JumpPower", 10)
		player:SetAttribute("BarHeightIndex", 1) 
		player:SetAttribute("HighestCleared", 0)
		player:SetAttribute("Coins", 0)
		player:SetAttribute("LastTrainTime", 0)
		player:SetAttribute("TempFlowMultiplier", 1)
		player:SetAttribute("CircleMultiplier", 1)
	end)

	-- 2. JUMP PAD ACTIVATION (Bulletproofed)
	local function setupJumpPad(starter)
		-- 1. Create the ProximityPrompt dynamically
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Start Jump"
		prompt.ObjectText = "Jump Pad"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.1 -- How long they need to hold E (in seconds)
		prompt.RequiresLineOfSight = false -- Good for floor pads so the camera angle doesn't block it
		prompt.Parent = starter

		-- 2. Connect the prompt trigger
		-- Triggered automatically passes the 'player' who pressed E
		prompt.Triggered:Connect(function(player)
			local character = player.Character

			if character and character:FindFirstChild("Humanoid") and not character:GetAttribute("IsJumping") then
				local curveStarts = CollectionService:GetTagged("CurveStart")
				local curveCorners = CollectionService:GetTagged("CurveCorner")

				if #curveStarts > 0 and #curveCorners > 0 then
					local jump = JumpEvent.new(player, character)
					jump:Start(curveCorners[1], curveStarts[1].CFrame)
				else
					warn("⚠️ [MATH ERROR] Cannot start jump: Missing tags in workspace!")
				end
			end
		end)
	end

	for _, starter in ipairs(CollectionService:GetTagged("JumpStarter")) do setupJumpPad(starter) end
	CollectionService:GetInstanceAddedSignal("JumpStarter"):Connect(setupJumpPad)


	local function GetPetMultiplier(player)
		local equippedName = player:GetAttribute("EquippedPet")
		if not equippedName then return 1.0 end

		-- Look for the pet in your ItemData rarities
		for _, pet in ipairs(ItemData.PetRarity) do
			if pet.Name == equippedName then
				return pet.Multiplier -- Returns 1.2, 2.0, or 10.0
			end
		end
		return 1.0
	end
	
	


	-- 3. REMOTES
	-- Inside GameManager.Init()[cite: 1]
	local MultiplierService = require(SharedModules.MultiplierService)

	Events.Train.OnServerEvent:Connect(function(player)
		-- 1. COOLDOWN CHECK
		local lastTime = player:GetAttribute("LastTrainTime") or 0
		if os.clock() - lastTime < TRAIN_COOLDOWN then return end

		player:SetAttribute("LastTrainTime", os.clock())

		-- 2. CALCULATE MULTIPLIERS
		-- This pulls from your StatCalculator for both Pet and Flow State
		local totalMulti = StatCalculator.GetMultiplier(player, "PowerMultiplier")
		local baseGain = 100
		local finalGain = baseGain * totalMulti

		-- 3. APPLY POWER GAIN
		local currentPower = player:GetAttribute("JumpPower") or 10
		player:SetAttribute("JumpPower", currentPower + finalGain)

		-- 5. NOTIFY CLIENT (For the Popup UI)
		-- This fires the remote we created to show the +Amount on the screen
		local notifyRemote = ReplicatedStorage.Remotes:FindFirstChild("NotifyPowerGain")
		if notifyRemote then
			notifyRemote:FireClient(player, finalGain)
		end
	end)

	-- Inside GameManager
	Events.FlowStateResult.OnServerEvent:Connect(function(player, multiplier)
		if type(multiplier) == "number" then 
			player:SetAttribute("TempFlowMultiplier", multiplier) 

			-- Match the text to the multipliers you set in the controller
			local resultText = "x1 Power"
			if multiplier >= 1.5 then
				resultText = "x1.5 POWER!!"
			elseif multiplier >= 1.2 then
				resultText = "x1.2 POWER!"
			end

			-- This tells your UIManager to show the floating "PERFECT" or "GOOD" text
			Events.FlowStateResult:FireClient(player, resultText)
		end
	end)

	Events.CircleResult.OnServerEvent:Connect(function(player, finalMultiplier)
		-- Print EXACTLY what arrived before any if-statements check it
		print("📡 SERVER HEARD REMOTE FROM:", player.Name, "| Data:", finalMultiplier, "| Type:", type(finalMultiplier))

		if type(finalMultiplier) == "number" then 
			player:SetAttribute("CircleMultiplier", finalMultiplier)
			print("✅ " .. player.Name .. " successfully saved multiplier: " .. finalMultiplier .. "x")
		else
			warn("❌ WARNING: The server received the remote, but the multiplier was not a number!")
		end
		
	end)
	
	Events.DevAddCoins.OnServerEvent:Connect(function(player, amount)
		local totalMulti = StatCalculator.GetMultiplier(player, "CoinMultiplier")
		if type(amount) == "number" then
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Coins") then
				leaderstats.Coins.Value += amount *totalMulti
				player:SetAttribute("Coins", leaderstats.Coins.Value)
			end
		end
	end)
end


--

local Players = game:GetService("Players")
-- (Assuming ReplicatedStorage and ItemData are defined at the top of your script!)

-- Logic to make the pet follow behind and to the right
local function MakePetFollow(player, petName)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	-- Remove existing follower if one exists
	local oldPet = workspace:FindFirstChild(player.Name .. "_Pet")
	if oldPet then oldPet:Destroy() end

	-- Create the Pet Part
	local pet = Instance.new("Part")
	pet.Name = player.Name .. "_Pet"
	pet.Size = Vector3.new(1.5, 1.5, 1.5)
	pet.CanCollide = false
	pet.Anchored = true

	-- Assign the color from ItemData
	for _, data in ipairs(ItemData.PetRarity) do
		if data.Name == petName then
			pet.Color = data.Color
			break
		end
	end
	pet.Parent = workspace

	-- 🚀 FIX 1: Destroy the pet when the player dies
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			if pet then pet:Destroy() end
		end)
	end

	-- Movement Loop
	task.spawn(function()
		while pet.Parent and char.Parent do
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				-- Goal: 3 studs back (+Z) and 3 studs right (+X)
				local goalCF = root.CFrame * CFrame.new(3, 1, 3)
				pet.CFrame = pet.CFrame:Lerp(goalCF, 0.1)
			end
			task.wait()
		end
	end)
end

-- Listen for the Equip Remote (Needs to be in ReplicatedStorage.Remotes)
ReplicatedStorage.Remotes.EquipPet.OnServerEvent:Connect(function(player, petName)
	local owned = player:GetAttribute("OwnedPets") or ""
	if string.find(owned, petName) then
		player:SetAttribute("EquippedPet", petName)
		MakePetFollow(player, petName)
	end
end)



-- 🚀 FIX 2: Automatically give the pet back when they respawn!
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)

		-- Give the Roblox engine a split second to build the new body
		task.wait(0.2)

		-- Check if they had a pet equipped before they died
		local equippedPetName = player:GetAttribute("EquippedPet") 
		if equippedPetName and equippedPetName ~= "" then
			MakePetFollow(player, equippedPetName)
		end

	end)
end)

-- Equip Accessory Logic
Events.EquipAccessory.OnServerEvent:Connect(function(player, accessoryName)
	-- Check if they actually own it (Security check)
	local owned = player:GetAttribute("OwnedAccessories") or ""

	if string.find(owned, accessoryName) then
		-- Update the attribute! This automatically tells the UI to turn the button dark!
		player:SetAttribute("EquippedAccessory", accessoryName)
		print(player.Name .. " equipped Accessory: " .. accessoryName)

		-- (Later, you can add code here to physically attach the accessory to the player's character)
	end
end)

-- Equip Trail Logic
Events.EquipTrail.OnServerEvent:Connect(function(player, trailName)
	local owned = player:GetAttribute("OwnedTrails") or ""

	if string.find(owned, trailName) then
		player:SetAttribute("EquippedTrail", trailName)
		print(player.Name .. " equipped Trail: " .. trailName)

		-- (Later, you can add code here to physically attach the trail to the player's character)
	end
end)
-- Add this to the top of GameManager if you haven't already:
-- local ItemData = require(ReplicatedStorage.SharedModules.ItemData)

Events.ShopAction.OnServerEvent:Connect(function(player, itemName, category)
	local categoryTable = ItemData[category]
	if not categoryTable then return end

	-- 1. Find the item and its price
	local itemInfo = nil
	for _, item in ipairs(categoryTable) do
		if item.Name == itemName then
			itemInfo = item
			break
		end
	end

	-- 2. Validate and Purchase
	local coins = player:GetAttribute("Coins") or 0
	if itemInfo and coins >= itemInfo.Price then

		-- Check if they already own it to prevent double-buying
		local attributeName = "Owned" .. category -- e.g., "OwnedPets" or "OwnedAccessories"
		local currentOwned = player:GetAttribute(attributeName) or ""

		if string.find(currentOwned, itemName) then
			-- Optional: Tell the client they already own it
			return 
		end

		-- Take the coins
		player:SetAttribute("Coins", coins - itemInfo.Price)

		-- Give the item (Adds it to their comma-separated string)
		player:SetAttribute(attributeName, currentOwned .. itemName .. ",")

		print(player.Name .. " securely bought " .. itemName)
	else
		warn(player.Name .. " tried to buy " .. itemName .. " but couldn't!")
	end
end)

-- ==========================================
-- AFK TRAINING ZONE LOGIC
-- ==========================================
local BASE_AFK_POWER = 5 

local function SetupTrainingZone(zonePart)
	local partAnimType = zonePart:GetAttribute("AnimationType") or "BWSquat"
	local partMultiplier = TrainingData[partAnimType] or 1.0

	-- 1. Create the ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Start Training"
	prompt.ObjectText = "Training Zone"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.2
	prompt.RequiresLineOfSight = false
	prompt.Parent = zonePart

	-- 2. Handle the Interaction
	prompt.Triggered:Connect(function(player)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if player and hrp and not player:GetAttribute("IsTraining") then

			-- Start Training
			player:SetAttribute("CurrentTrainingAnim", partAnimType)
			player:SetAttribute("IsTraining", true)

			-- Lock them in place & hide the prompt so no one else clicks it
			hrp.CFrame = CFrame.new(zonePart.Position.X, 3, zonePart.Position.Z) * zonePart.CFrame.Rotation
			hrp.Anchored = true 
			prompt.Enabled = false

			-- Start the AFK Loop
			task.spawn(function()

				-- This loop runs until the player hits the "Stop" button and changes the attribute
				while player:GetAttribute("IsTraining") do
					task.wait(0.5)
					if not player.Character then break end 

					local currentPower = player:GetAttribute("JumpPower") or 10
					local itemMultiplier = StatCalculator.GetMultiplier(player, "PowerMultiplier") or 1
					local finalGain = (BASE_AFK_POWER * partMultiplier) * itemMultiplier

					player:SetAttribute("JumpPower", currentPower + finalGain)
					Events.NotifyPowerGain:FireClient(player, finalGain)
				end

				-- 🚀 THE FIX: The loop just finished (they stopped training). Turn the prompt back on!
				prompt.Enabled = true
			end)
		end
	end)
end

-- Connect all parts tagged with "TrainingZone"
for _, zone in ipairs(CollectionService:GetTagged("TrainingZone")) do
	SetupTrainingZone(zone)
end

-- Handle the Stop Button from the UI
Events.StopTraining.OnServerEvent:Connect(function(player)
	if player:GetAttribute("IsTraining") then

		-- Setting this to false instantly breaks the loop above!
		player:SetAttribute("IsTraining", false)
		player:SetAttribute("CurrentTrainingAnim", nil)

		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = false
			hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -5) -- Bumps them off the pad
		end
	end	
end)

local function GenerateBars()
	-- 1. Find the template we hid in ServerStorage
	local template = ServerStorage:FindFirstChild("BarTemplate")

	if not template then
		warn("❌ Could not find 'BarTemplate' in ServerStorage!")
		return
	end

	-- 2. Create a clean Folder in Workspace to hold all the bars
	local barFolder = Instance.new("Folder")
	barFolder.Name = "GeneratedJumpBars"
	barFolder.Parent = workspace

	-- 3. Save the exact X and Z coordinates of your template
	local baseX = template.Position.X
	local baseZ = template.Position.Z

	-- 4. Loop through the table and spawn them!
	for _, height in ipairs(AVAILABLE_BAR_HEIGHTS) do
		local newBar = template:Clone()

		-- Keep the X and Z exactly the same, but change the Y to match the table!
		newBar.Position = Vector3.new(baseX, height, baseZ)

		-- Optional: You can put a SurfaceGui or TextLabel inside the template, 
		-- and the script can even auto-name the visual text for you!
		newBar.Name = "Bar_" .. height

		-- Put it in the folder so your Workspace stays clean
		newBar.Parent = barFolder 
	end

	print("✅ Successfully generated " .. #AVAILABLE_BAR_HEIGHTS .. " bars!")
end

GenerateBars()
return GameManager


