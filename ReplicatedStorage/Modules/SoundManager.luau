local SoundManager = {}

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SFXFolder = SoundService:WaitForChild("SFX")
local MusicFolder = SoundService:WaitForChild("Music")
local PlaySound = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PlaySound")

SoundManager.SFX = {}
SoundManager.Music = {} 

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
				end
			end

			path[object.Name] = sounds
		elseif object:IsA("Sound") then
			path[object.Name] = object
		end
	end
end

local function loadMusic(current)
	for _, object in current:GetChildren() do
		if object:IsA("Folder") then
			loadMusic(object)
		elseif object:IsA("Sound") and object.Name ~= "MainMenuMusic" then
			table.insert(SoundManager.Music, object)
		end
	end
end

loadSoundEffects(SFXFolder, SoundManager.SFX)
loadMusic(MusicFolder)

local playingFolder = Instance.new("Folder")
playingFolder.Name = "Playing"
playingFolder.Parent = SoundService

function SoundManager.PlaySFX(sound, parent)
	if type(sound) ~= "table" then
		sound:Play()
		PlaySound:FireServer(sound, parent) 
		return
	end
	
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
	newMusic.Looped = looped
	newMusic.Volume = volume or music.Volume
	newMusic:Play()
	
	newMusic.Ended:Once(function()
		newMusic:Destroy()
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
			
			music.Destroying:Wait()
		end
	end)
end

function SoundManager.StopBackgroundMusic()
	playingBackground = false
	if playingThread then task.cancel(playingThread) end
	playingFolder:ClearAllChildren()
end

return SoundManager