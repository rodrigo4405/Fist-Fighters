local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ForceFieldEvent = ReplicatedStorage.RemoteEvents.ForceFieldEvent

ForceFieldEvent.OnServerEvent:Connect(function(player, switch)
	local character = player.Character or player.CharacterAdded:Wait()
	if not character then return end
	
	if switch then
		local forceField = Instance.new("ForceField")
		forceField.Parent = character
	else
		local forceField = character:FindFirstChildWhichIsA("ForceField")
		if forceField then forceField:Destroy() end
	end
end)