local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Datastore.DataManager)
local playerStore = DataManager.playerDataStore
local killsLeaderboardStore = DataManager.killsLeaderboard

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FeedEvent = ReplicatedStorage.RemoteEvents.FeedEvent
local Ragdoll = require(ReplicatedStorage.Modules.Ragdoll)

local tracker = {}
local streaks = {}

local CREDIT_WINDOW = 60
local RESPAWN_DELAY = 3

local function getNoobId(noob)
	local model = noob and noob.Model
	return model:GetAttribute("UniqueId") or "noob"
end

local function getEntityId(entity, isNoob)
	if isNoob then return getNoobId(entity) end
	return entity.UserId
end

local KillHandler = {}

function KillHandler.RegisterAttacker(attacker, victim, damage, attackerIsNoob, victimIsNoob)
	if not attacker or not victim or attacker == victim then return false end

	local victimId = victimIsNoob and getNoobId(victim) or victim.UserId
	local victimEntry = tracker[victimId]
	if not victimEntry then
		victimEntry = {}
		tracker[victimId] = victimEntry
	end

	local attackerId = getEntityId(attacker, attackerIsNoob)
	local attackInfo = victimEntry[attackerId]
	if not attackInfo then
		attackInfo = {Damage = 0, Time = 0, Entity = attacker, IsNoob = attackerIsNoob}
		victimEntry[attackerId] = attackInfo
	end

	attackInfo.Damage += damage
	attackInfo.Time = os.clock()
	return true
end

function KillHandler.AwardKill(victim, victimIsNoob)
	if not victim then return false end

	local victimId = victimIsNoob and getNoobId(victim) or victim.UserId
	local tracking = tracker[victimId]
	tracker[victimId] = nil
	
	if not victimIsNoob then
		streaks[victim.UserId] = 0
		playerStore:IncrementSession(victim, "Deaths", 1)
	end

	if not tracking then
		local character = victimIsNoob and victim or victim.Character
		return Ragdoll.Play(character)
	end

	local now = os.clock()
	local killer, mostDamage, ltime = nil, 0, 0
	local killerIsNoob = false
	
	for _, info in pairs(tracking) do
		if now - info.Time > CREDIT_WINDOW then continue end
		if info.IsNoob then
			if not info.Entity or not info.Entity.Model then continue end
		else
			if info.Entity.Parent ~= Players then continue end
		end
		if info.Damage < mostDamage then continue end
		if info.Damage == mostDamage and ltime < info.Time then continue end
		
		killer = info.Entity
		killerIsNoob = info.IsNoob
		mostDamage = info.Damage
		ltime = info.Time
	end

	if not killer then
		local character = victimIsNoob and victim or victim.Character
		return Ragdoll.Play(character)
	end

	local victimCharacter = victimIsNoob and victim or victim.Character
	local killerCharacter = killerIsNoob and killer.Model or killer.Character
	
	Ragdoll.Play(victimCharacter, killerCharacter and killerCharacter:FindFirstChild("HumanoidRootPart") and killerCharacter.HumanoidRootPart.CFrame.LookVector)
	
	if not killerIsNoob then
		local killerStreak = streaks[killer.UserId] or 0
		killerStreak += 1
		streaks[killer.UserId] = killerStreak
		
		local success = playerStore:IncrementSession(killer, "Kills", 1)
		if not success then return false end
		
		FeedEvent:FireAllClients(killer, victim, mostDamage, killerStreak)

		local data = playerStore:Get(killer)
		local lifetimeKills = data and data.Kills
		if lifetimeKills then killsLeaderboardStore:UpdateLeaderboard(killer, lifetimeKills) end
	else
		FeedEvent:FireAllClients(killer, victim, mostDamage, 0)
	end

	return true
end

function KillHandler.ProcessDamage(attacker: Player, targetHumanoid: Humanoid, damage: number, victimIsNoob: boolean?)
	if not attacker or not targetHumanoid or targetHumanoid.Health <= 0 or damage <= 0 then return end
	targetHumanoid:TakeDamage(damage)
	KillHandler.RegisterAttacker(attacker, targetHumanoid.Parent, damage, false, victimIsNoob)
end

function KillHandler.ProcessNoobDamage(noob, targetHumanoid, damage)
	if not noob or not targetHumanoid or targetHumanoid.Health <= 0 or damage <= 0 then return end
	local victim = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	if not victim then return end
	targetHumanoid:TakeDamage(damage)
	KillHandler.RegisterAttacker(noob, victim, damage, true, false)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		if not humanoid then return end
		humanoid.BreakJointsOnDeath = false
		humanoid.Died:Once(function()
			KillHandler.AwardKill(player, false)
			if player and player.Parent == Players then
				task.delay(RESPAWN_DELAY, function() player:LoadCharacterAsync() end)
			end
		end)
	end)
end

local function onPlayerRemoving(player)
	KillHandler.AwardKill(player, false)
	tracker[player.UserId] = nil
	for _, tracking in pairs(tracker) do tracking[player.UserId] = nil end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do 
	task.spawn(onPlayerAdded, player)
end

return KillHandler
