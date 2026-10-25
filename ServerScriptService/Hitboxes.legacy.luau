local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local KillHandler = require(ServerScriptService:WaitForChild("KillHandler"))

local CombatEvent = ReplicatedStorage.RemoteEvents.CombatEvent
local BlockStrengthEvent = ReplicatedStorage.RemoteEvents.BlockStrengthEvent

CombatEvent.OnServerEvent:Connect(function(player, targetList, damage)
	if not player or not player:IsA("Player") or player.Parent ~= Players then return end
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	for _, targetModel in ipairs(targetList) do
		if targetModel and targetModel:IsA("Model") then
			local targetHumanoid = targetModel:FindFirstChildWhichIsA("Humanoid")

			if targetHumanoid and targetHumanoid.Health > 0 then
				local targetState = targetModel:GetAttribute("CombatState")
				
				if targetState == "Block" then
					local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
					if targetPlayer then
						BlockStrengthEvent:FireClient(targetPlayer, {humanoid = humanoid, character = character}, math.round(damage * 0.7))
					end

					damage = math.round(damage * 0.3)
					
				elseif targetState == "Parry" then
					CombatEvent:FireClient(player, "Stunned", true)
					
					task.delay(1, function()
						CombatEvent:FireClient(player, "Stunned", false)
					end)

					continue
				end
				
				KillHandler.ProcessDamage(player, targetHumanoid, damage)
			end
		end
	end
end)