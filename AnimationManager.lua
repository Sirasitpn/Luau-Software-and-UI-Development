local AnimationManager = {}
AnimationManager.LoadedAnimations = {}

-- Your Animation IDs
local ANIM_IDS = {
	Run = "rbxassetid://112098894408103",
	RunStraight =  "rbxassetid://112803169464868",
	RunCurve =  "rbxassetid://117212060698176",
	Takeoff = "rbxassetid://94606200651287",
	PeakArch = "rbxassetid://74684743266429"
}

-- ADD THIS: The exact lengths of your animations (in seconds)
AnimationManager.Lengths = {
	RunStraight = 3.23/0.75, 
	RunCurve = 0.79/0.75,    
	TakeoffWindup = 0.3 
}

function AnimationManager.Warmup(character)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	for name, id in pairs(ANIM_IDS) do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local track = animator:LoadAnimation(anim)

		-- ACTION priority ensures it overrides the default walk
		track.Priority = Enum.AnimationPriority.Action 
		if name:find("Run") then track.Looped = true end

		AnimationManager.LoadedAnimations[name] = track
	end
	print("✅ [ANIM] All animations warmed up!")
end

function AnimationManager.Play(animName, speedMultiplier)
	local track = AnimationManager.LoadedAnimations[animName]

	if not track then
		warn("⚠️ [ANIM] Track not found in cache: " .. tostring(animName))
		return 
	end

	-- 1. START NEW TRACK WITH FADE
	-- 0.15s fade-in creates a smooth overlap
	track:Play(0.15) 
	if speedMultiplier then track:AdjustSpeed(speedMultiplier) end
	print("▶️ [ANIM] Playing: " .. animName)

	-- 2. STOP OTHERS WITH FADE
	for name, otherTrack in pairs(AnimationManager.LoadedAnimations) do
		if name ~= animName and otherTrack.IsPlaying then
			-- 0.3s fade-out bridges the gap[cite: 5]
			otherTrack:Stop(0.3) 
		end
	end
end

function AnimationManager.StopAll()
	for _, track in pairs(AnimationManager.LoadedAnimations) do
		track:Stop(0.2)
	end
	print("⏹️ [ANIM] Stopped All")
end

return AnimationManager



