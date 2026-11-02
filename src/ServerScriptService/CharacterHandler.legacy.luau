local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local StartGameEvent = Remotes:WaitForChild("StartGameEvent")

Players.CharacterAutoLoads = false

StartGameEvent.OnServerEvent:Connect(function(player: Player)
	if not player or player.Parent ~= Players then return end
	
	player:LoadCharacterAsync()	
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	
	player.ReplicationFocus = nil
end)