local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local KillHandler = require(ServerScriptService.KillHandler)

local CombatEvent = ReplicatedStorage.RemoteEvents.CombatEvent
local BlockStrengthEvent = ReplicatedStorage.RemoteEvents.BlockStrengthEvent

local noobFolder = Workspace:WaitForChild("Noobs", 30)

local function isNoob(model: Model): boolean
	if not model then return false end
	if not noobFolder then return false end
	
	return model:IsDescendantOf(noobFolder)
end

CombatEvent.OnServerEvent:Connect(function(player, targetList, damage, attackSide)
	if type(damage) ~= "number" or damage < 0 and not math.isfinite(damage) then return end
	if not player or not player:IsA("Player") or player.Parent ~= Players then return end
	
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	for _, targetModel in ipairs(targetList) do
		if targetModel and targetModel:IsA("Model") then
			if isNoob(targetModel) then continue end
			
			local targetHumanoid = targetModel:FindFirstChildWhichIsA("Humanoid")
			if not targetHumanoid or targetHumanoid.Health <= 0 then continue end

			local targetPlayer = Players:GetPlayerFromCharacter(targetModel)
			local targetState = targetModel:GetAttribute("CombatState")
			
			if targetState == "Block" then
				if targetPlayer then
					BlockStrengthEvent:FireClient(targetPlayer, {humanoid = humanoid, character = character}, math.round(damage * 0.7))
				end
				damage = math.round(damage * 0.3)
			elseif targetState == "Parry" then
				damage = 0
			end
			
			if targetPlayer then CombatEvent:FireClient(targetPlayer, nil, attackSide) end
			CombatEvent:FireClient(player, targetState == "Parry", nil)
			KillHandler.ProcessDamage(player, targetHumanoid, damage)
		end
	end
end)
