local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("RemoteFunctions")
local changeView = remotes:WaitForChild("ChangeView")

changeView.OnClientInvoke = function(player: Player): boolean
	if not player or player.Parent ~= Players then return false end
	
	local character = player.Character or player.CharacterAdded:Wait()
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	Camera.CameraSubject = humanoid
	return true
end