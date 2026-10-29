local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaySound = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PlaySound")
local SFXFolder = SoundService:WaitForChild("SFX")

local COOLDOWN = 0.1
local MAX_PENALTY = 2.5
local lastFired = {}

PlaySound.OnServerEvent:Connect(function(player, sound, parent)
	local now = os.clock()
	if lastFired[player] and lastFired[player].time and now - lastFired[player].time < COOLDOWN then
		if not lastFired[player].count then return end
		lastFired[player].time += math.clamp(COOLDOWN*2^(lastFired[player].count), COOLDOWN, MAX_PENALTY)
		--print(math.clamp(COOLDOWN*2^(lastFired[player].count), COOLDOWN, MAX_PENALTY))
		lastFired[player].count += 1
		return 
	end
	if not lastFired[player] then lastFired[player] = {} end
	lastFired[player].time = now
	lastFired[player].count = 0
	
	if typeof(sound) ~= "Instance" or not sound:IsA("Sound") then return end
	if not sound:IsDescendantOf(SFXFolder) then return end
	if not parent then return end
	if parent ~= nil and (typeof(parent) ~= "Instance" or not parent:IsDescendantOf(workspace)) then return end

	for _, plr in Players:GetPlayers() do
		if plr ~= player then
			PlaySound:FireClient(plr, player, sound, parent)
		end
	end
end)