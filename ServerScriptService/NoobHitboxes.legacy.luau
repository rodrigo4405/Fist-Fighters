local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CombatEvent")
local Ragdoll = require(ReplicatedStorage.Modules.Ragdoll)
local KillHandler = require(ServerScriptService.KillHandler)

local noobFolder = Workspace:WaitForChild("Noobs", 10)

local BLOCK_MULTIPLIER = 0.3
local PARRY_MULTIPLIER = 0

local function isNoob(model: Model): boolean
	if not model then return false end
	return model:IsDescendantOf(noobFolder)
end

local noobHumanoids = {}

local function trackNoobHumanoid(humanoid, model)
	if noobHumanoids[humanoid] then return end
	noobHumanoids[humanoid] = model
	humanoid.Died:Once(function()
		noobHumanoids[humanoid] = nil
		KillHandler.AwardKill(model, true)
	end)
end

CombatEvent.OnServerEvent:Connect(function(player, targetList, damage, attackSide)
	if type(damage) ~= "number" or damage < 0 or not math.isfinite(damage) then return end
	if not player or not player:IsA("Player") or player.Parent ~= Players then return end

	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid or humanoid.Health <= 0 then return end

	for _, targetModel in ipairs(targetList) do
		if targetModel and targetModel:IsA("Model") and isNoob(targetModel) then
			local targetHumanoid = targetModel:FindFirstChildWhichIsA("Humanoid")

			if targetHumanoid and targetHumanoid.Health > 0 then
				trackNoobHumanoid(targetHumanoid, targetModel)

				local targetState = targetModel:GetAttribute("CombatState")
				local finalDamage = damage

				if targetState == "Block" then
					finalDamage = math.round(damage * BLOCK_MULTIPLIER)
				elseif targetState == "Parry" then
					finalDamage = 0
				end

				if finalDamage > 0 then
					KillHandler.ProcessDamage(player, targetHumanoid, finalDamage, true)
				end

				CombatEvent:FireClient(player, targetState == "Parry", attackSide)

				if targetHumanoid.Health <= 0 then
					Ragdoll.Play(targetModel, rootPart.CFrame.LookVector)
				end
			end
		end
	end
end)

task.spawn(function()
	task.wait(1)
	for _, model in ipairs(noobFolder:GetChildren()) do
		if model:IsA("Model") then
			local humanoid = model:FindFirstChildWhichIsA("Humanoid")
			if humanoid then trackNoobHumanoid(humanoid, model) end
		end
	end
end)
