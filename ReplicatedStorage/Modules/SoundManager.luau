local FADE_TIME = 3

local SoundManager = {}

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SFXFolder = SoundService:WaitForChild("SFX")
local MusicFolder = SoundService:WaitForChild("Music")
local PlaySound = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PlaySound")

local Signal = require(ReplicatedStorage.Modules.Signal)
SoundManager.TrackFinished = Signal.new()

SoundManager.SFX = {}
SoundManager.Music = {}

local function fade(sound, duration, volume)
	local tweenInfo = TweenInfo.new(duration)
	local tween = TweenService:Create(sound, tweenInfo, {Volume = volume})
	
	tween:Play()
	return tween
end

local function loadSoundEffects(current, path)
	for _, object in current:GetChildren() do
		if object:IsA("Folder") then
			path[object.Name] = {}
			loadSoundEffects(object, path[object.Name])
		elseif object:IsA("SoundGroup") then
			local sounds = {}

			for _, sound in object:GetChildren() do
				if sound:IsA("Sound") then
					table.insert(sounds, sound)
					sound.SoundGroup = SFXFolder
				end
			end

			path[object.Name] = sounds
		elseif object:IsA("Sound") then
			path[object.Name] = object
			object.SoundGroup = SFXFolder
		end
	end
end

local function loadMusic(current)
	for _, object in current:GetChildren() do
		if object:IsA("Folder") then
			loadMusic(object)
		elseif object:IsA("Sound") and object.Name ~= "MainMenuMusic" then
			table.insert(SoundManager.Music, object)
			object.SoundGroup = MusicFolder
		end
	end
end

loadSoundEffects(SFXFolder, SoundManager.SFX)
loadMusic(MusicFolder)

local playingFolder = Instance.new("Folder")
playingFolder.Name = "Playing"
playingFolder.Parent = SoundService

function SoundManager.PlaySFX(sound, parent)
	if not parent then 
		local character = game:GetService("Players").LocalPlayer.Character
		if not character then return end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		parent = hrp
	end

	if type(sound) ~= "table" then
		sound:Play()
		PlaySound:FireServer(sound, parent) 
		return
	end
	
	if #sound == 0 then return end
	
	local index = math.random(1, #sound)
	local s = sound[index]
	s:Play()
	PlaySound:FireServer(s, parent)
end

function SoundManager.PlayMusic(music: Sound, volume: number?, looped: boolean?)
	if not MusicFolder:IsAncestorOf(music) then return end
	music = music or SoundManager.Music[math.random(1, #SoundManager.Music)]
	
	playingFolder:ClearAllChildren()
	
	local newMusic = music:Clone()
	newMusic.Parent = playingFolder
	newMusic.Looped = looped or false
	newMusic.Volume = 0
	
	
	if not newMusic.IsLoaded then
		newMusic.Loaded:Wait()
	end
	
	local finished = false
	local function finish()
		if finished then return end
		finished = true
		SoundManager.TrackFinished:Fire()
		if newMusic.Parent then
			newMusic:Destroy()
		end
	end

	newMusic.Ended:Once(finish)
	newMusic.Destroying:Once(finish)

	newMusic:Play()
	fade(newMusic, FADE_TIME, volume or music.Volume)

	local remaining = newMusic.TimeLength - newMusic.TimePosition - FADE_TIME
	task.delay(math.max(remaining, 0), function()
		if finished then return end
		fade(newMusic, FADE_TIME, 0).Completed:Once(finish)
	end)

	return newMusic
end

local playingBackground = false
local playingThread = nil

function SoundManager.StartBackgroundMusic(volume: number?)
	if playingBackground then return end
	playingBackground = true
	
	if playingThread then
		task.cancel(playingThread)
	end
	
	playingThread = task.spawn(function()
		local lastPlayed = nil
		local tracks = #SoundManager.Music
		if tracks == 0 then 
			playingBackground = false
			return 
		end
		
		while true do
			local nextMusic = SoundManager.Music[math.random(1,tracks)]
			while nextMusic == lastPlayed and tracks > 1 do
				nextMusic = SoundManager.Music[math.random(1,tracks)]
			end
			lastPlayed = nextMusic
			
			local music = SoundManager.PlayMusic(nextMusic, volume, false)
			
			if not music then
				task.wait(1)
				continue
			end
			
			local finishedTrack = SoundManager.TrackFinished:Wait()
		end
	end)
end

function SoundManager.StopBackgroundMusic()
	playingBackground = false
	if playingThread then task.cancel(playingThread) end
	playingFolder:ClearAllChildren()
end

return SoundManager