local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaySound = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PlaySound")
local SFXFolder = SoundService:WaitForChild("SFX")

local COOLDOWN = 0.05
local lastFired = {}

Players.PlayerRemoving:Connect(function(plr)
	lastFired[plr] = nil
end)

PlaySound.OnServerEvent:Connect(function(player, sound, parent)
	local now = os.clock()
	if lastFired[player] and now - lastFired[player] < COOLDOWN then return end
	lastFired[player] = now
	
	if typeof(sound) ~= "Instance" or not sound:IsA("Sound") then return end
	if not sound:IsDescendantOf(SFXFolder) then return end
	if parent ~= nil and (typeof(parent) ~= "Instance" or not parent:IsDescendantOf(workspace)) then return end

	for _, plr in Players:GetPlayers() do
		if plr ~= player then
			PlaySound:FireClient(plr, player, sound, parent)
		end
	end
end)