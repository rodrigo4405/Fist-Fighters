local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationManager = {}

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local animator = nil
local cachedTracks = {}

local function setupAnimator(character)
	table.clear(cachedTracks)

	local humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
end

if character then
	setupAnimator(character)
end

player.CharacterAdded:Connect(function(character: Model)
	setupAnimator(character)
end)

function AnimationManager.WarmUp(animation)
	if not animator then return end
	if cachedTracks[animation] then return end

	local track = animator:LoadAnimation(animation)
	cachedTracks[animation] = track
end

function AnimationManager.PlayAnimation(animation: Animation, priority: Enum.AnimationPriority, weight: number?, speed: number?, looped: boolean?): AnimationTrack
	if not animator then return nil end

	if not cachedTracks[animation] then
		cachedTracks[animation] = animator:LoadAnimation(animation)
	end

	local track = cachedTracks[animation]

	if track.IsPlaying then return track end

	speed = speed or 1
	weight = weight or 1

	if looped ~= nil then
		track.Looped = looped
	end
	
	track.Priority = priority
	track:Play(0.2, weight, speed)
	return track
end

function AnimationManager.StopAnimation(animation: Animation)
	local track = cachedTracks[animation]
	
	if track then
		if track.IsPlaying then
			track:Stop(0.2)
		end
	end
end

return AnimationManager