local SoundManager = {}

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SFXFolder = SoundService:WaitForChild("SFX")
local MusicFolder = SoundService:WaitForChild("Music")
local PlaySound = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PlaySound")

SoundManager.SFX = {}

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

loadSoundEffects(SFXFolder, SoundManager.SFX)

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

function SoundManager.PlayMusic(musicName, volume, playbackSpeed)
	local sound = MusicFolder:FindFirstChild(musicName, true)
	if not sound or not sound:IsA("Sound") then
		warn("SoundManager: Music '" .. musicName .. "' not found")
		return
	end

	sound = sound:Clone()
	sound.Parent = SoundService
	sound.Looped = true
	sound.Volume = volume or sound.Volume
	sound.PlaybackSpeed = playbackSpeed or sound.PlaybackSpeed
	sound:Play()

	return sound
end

return SoundManager