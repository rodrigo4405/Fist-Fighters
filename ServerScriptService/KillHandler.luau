local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService:WaitForChild("Datastore"):WaitForChild("DataManager"))
local playerStore = DataManager.playerDataStore
local killsLeaderboardStore = DataManager.killsLeaderboard

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FeedEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("FeedEvent")

local tracker = {}
local streaks = {}

local CREDIT_WINDOW = 60
local RESPAWN_DELAY = 3

local function ragdoll(character, lv)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.RequiresNeck = false
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.AutoRotate = false


	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part:SetNetworkOwner(nil)
		end
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		lv = lv or -hrp.CFrame.LookVector
		hrp.AssemblyLinearVelocity = -lv * 50
		hrp.CanCollide = false
	end

	for _, joint in pairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
			local attachment0 = Instance.new("Attachment")
			attachment0.CFrame = joint.C0
			attachment0.Parent = joint.Part0

			local attachment1 = Instance.new("Attachment")
			attachment1.CFrame = joint.C1
			attachment1.Parent = joint.Part1

			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = attachment0
			socket.Attachment1 = attachment1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.Parent = joint.Parent

			joint.Enabled = false
		end
	end

	return false
end


local KillHandler = {}

function KillHandler.RegisterAttacker(attacker: Player, victim: Player, damage: number)
	if not attacker or not victim or attacker == victim then return false end

	local victimEntry = tracker[victim.UserId]
	if not victimEntry then
		victimEntry = {}
		tracker[victim.UserId] = victimEntry
	end

	local attackInfo = victimEntry[attacker.UserId]
	if not attackInfo then
		attackInfo = {Damage = 0, Time = 0, Player = attacker}
		victimEntry[attacker.UserId] = attackInfo
	end

	attackInfo.Damage += damage
	attackInfo.Time = os.clock()

	return true
end

function KillHandler.AwardKill(victim: Player)
	if not victim then return false end

	local tracking = tracker[victim.UserId]
	tracker[victim.UserId] = nil

	playerStore:IncrementSession(victim, "Deaths", 1)

	if not tracking then return ragdoll(victim.Character) end

	local now = os.clock()
	local killer, mostDamage, ltime = nil, 0, 0
	for _, info in pairs(tracking) do
		if now - info.Time > CREDIT_WINDOW or info.Player.Parent ~= Players or info.Damage < mostDamage then continue end
		if info.Damage == mostDamage and ltime < info.Time then continue end
		
		killer = info.Player
		mostDamage = info.Damage
		ltime = info.Time
	end

	if not killer then return ragdoll(victim.Character) end
	ragdoll(victim.Character, killer.Character and killer.Character.HumanoidRootPart and killer.Character.HumanoidRootPart.CFrame.LookVector)
	
	local killerStreak = streaks[killer.UserId]
	if not killerStreak then
		killerStreak = 0
	end
	
	killerStreak += 1
	streaks[killer.UserId] = killerStreak
	streaks[victim.UserId] = 0
	
	local success = playerStore:IncrementSession(killer, "Kills", 1)
	if not success then return false end
	
	FeedEvent:FireAllClients(killer, victim, mostDamage, killerStreak)

	local data = playerStore:Get(killer)
	local lifetimeKills = data and data.Kills
	if lifetimeKills then
		killsLeaderboardStore:UpdateLeaderboard(killer, lifetimeKills)
	end

	return true
end

function KillHandler.ProcessDamage(attacker: Player, targetHumanoid: Humanoid, damage: number)
	if not attacker or not targetHumanoid or targetHumanoid.Health <= 0 then return end
	local victim = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	
	targetHumanoid:TakeDamage(damage)
	KillHandler.RegisterAttacker(attacker, victim, damage)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		if not humanoid then return end
		
		humanoid.BreakJointsOnDeath = false
		humanoid.Died:Once(function()
			KillHandler.AwardKill(player)
			if player and player.Parent == Players then
				task.delay(RESPAWN_DELAY, function() player:LoadCharacterAsync() end)
			end
		end)
	end)
end

local function onPlayerRemoving(player: Player)
	KillHandler.AwardKill(player)

	tracker[player.UserId] = nil

	for _, tracking in pairs(tracker) do
		tracking[player.UserId] = nil
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

return KillHandler
