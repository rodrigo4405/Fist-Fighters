local Main = script.Parent.Parent.Parent
local Permissions = require(Main:WaitForChild("Permissions"))
local Helpers = require(Main:WaitForChild("Helpers"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RE = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CombatEvent")

local ServerScriptService = game:GetService("ServerScriptService")
local KillHandler = require(ServerScriptService:WaitForChild("KillHandler"))

local connections = {}

local Ohko = {}

Ohko.Name = "Ohko"
Ohko.Aliases = {}
Ohko.Description = "Toggles ohko."
Ohko.PermissionLevel = Permissions.Ranks.Developer
Ohko.Help = ""

function Ohko.Run(player: Player, ...)
	local args = {...}

	if connections[player.UserId] then
		connections[player.UserId]:Disconnect()
		connections[player.UserId] = nil
		return true, "Ohko disabled."
	end
	
	connections[player.UserId] = RE.OnServerEvent:Connect(function(plr, targetList, damage)
		if plr ~= player then return end
		local character = player.Character
		if not character then return end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")
		if not rootPart or not humanoid or humanoid.Health <= 0 then return end

		for _, targetModel in ipairs(targetList) do
			if targetModel and targetModel:IsA("Model") then
				local targetHumanoid = targetModel:FindFirstChildWhichIsA("Humanoid")
				if targetHumanoid and targetHumanoid.Health > 0 then
					KillHandler.ProcessDamage(player, targetHumanoid, damage * 1000)
				end
			end
		end
	end)
	
	return true, "Ohko enabled."
end

return Ohko