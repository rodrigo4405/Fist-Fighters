local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ApplyAttributeRE = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ApplyAttribute")

ApplyAttributeRE.OnServerEvent:Connect(function(player, stateType, state)
	if not player or player.Parent ~= game:GetService("Players") then return end
	assert(stateType == "Movement" or stateType == "Combat")
	
	local character = player.Character
	if not character then return end
	
	character:SetAttribute(stateType .. "State", state)
end)