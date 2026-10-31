local PathFindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local model = ReplicatedStorage:WaitForChild("Noob")

local CONFIG = require(script.Configuration)
local Movement = require(script.Movement)
local Utils = require(script.Utils)
local Attack = require(script.Attack)

local cancelThread = Utils.cancelThread

local noobs = {}
local noobFolder = Instance.new("Folder")
noobFolder.Name = "Noobs"
noobFolder.Parent = workspace

local spawns = workspace:WaitForChild("Map"):WaitForChild("Spawns"):GetChildren()

local Noob = {}
Noob.__index = Noob

Noob.States = {
	Idle = "Idle",
	Roaming = "Roaming",
	Chasing = "Chasing",
	Attacking = "Attacking",
	Dead = "Dead",
}

function Noob.new(position: CFrame)
	if #noobs >= CONFIG.NoobCap then return nil end
	local self = setmetatable({}, Noob)

	self.Model = model:Clone()
	self.Model.Parent = noobFolder
	self.Model:PivotTo(position or spawns[math.random(1, #spawns)].CFrame)

	self.Humanoid = self.Model:FindFirstChild("Humanoid")
	if not self.Humanoid then
		self.Model:Destroy()
		return nil
	end
	self.Humanoid.Died:Once(function() self:Destroy() end)

	self.CachedTracks = {}
	self.Animator = self.Humanoid:FindFirstChild("Animator")
	if not self.Animator then
		self.Model:Destroy()
		return nil
	end

	Utils.loadAnimations(self, {
		CONFIG.ChaseAnimation, CONFIG.WalkAnimation, CONFIG.JumpAnimation,
		CONFIG.AttackLeftAnimation, CONFIG.AttackRightAnimation
	})

	self.Humanoid.WalkSpeed = CONFIG.Walkspeed
	self.Humanoid.MaxHealth = CONFIG.Health
	self.Humanoid.Health = CONFIG.Health

	self.UpdateThread = nil
	self.RoamThread = nil
	self.ChaseThread = nil
	self.WaypointThread = nil
	self.AttackThread = nil
	
	self.State = Noob.States.Idle

	self.Target = nil

	self.Path = PathFindingService:CreatePath({Costs = {Water = math.huge}})

	self:Update()
	table.insert(noobs, self)

	return self
end

function Noob:SetState(newState: string)
	if self.State == newState then return end
	
	local oldState = self.State
	self.State = newState
	
	if newState == Noob.States.Dead then
		cancelThread(self, "UpdateThread")
		cancelThread(self, "AttackThread")
		Movement.StopAll(self)
	elseif newState == Noob.States.Attacking then
		if self.ChaseThread then
			Movement.StopChase(self)
		end
	elseif newState == Noob.States.Chasing then
		if self.Target and not self.ChaseThread then
			self.Humanoid.WalkSpeed = CONFIG.ChaseWalkspeed
			Movement.Chase(self)
		end
	end
	
	-- print(string.format("State: %s -> %s", oldState, newState))
end

function Noob:PlayAnimation(animation: Animation, priority: Enum.AnimationPriority, weight: number?, speed: number?, looped: boolean?): AnimationTrack?
	local track = self.CachedTracks[animation]
	if not track then return nil end

	speed = speed or 1
	weight = weight or 1

	track.Priority = priority

	if looped ~= nil then
		track.Looped = looped
	end

	if track.IsPlaying then
		track:AdjustSpeed(speed)
		track:AdjustWeight(weight, 0.2)
		return track
	end

	track:Play(0.2, weight, speed)

	return track
end

function Noob:StopAnimation(animation: Animation)
	local track = self.CachedTracks[animation]

	if track and track.IsPlaying then
		track:Stop(0.2)
	end
end

function Noob:Update()
	cancelThread(self, "UpdateThread")

	self.UpdateThread = task.spawn(function()
		while task.wait(CONFIG.UpdateRate) do
			if self.Humanoid.Health <= 0 then
				self:SetState(Noob.States.Dead)
				break
			end
			
			local target = Utils.nearestPlayer(self)
			self.Target = target and target.Character

			if target then
				Movement.StopRoam(self)

				if not self.ChaseThread and not self:IsState(Noob.States.Attacking) then
					self.Humanoid.WalkSpeed = CONFIG.ChaseWalkspeed
					Movement.Chase(self)
					self:SetState(Noob.States.Chasing)
				end
				
				if not self.AttackThread then
					self.AttackThread = task.spawn(function()
						self:AttackLoop()
					end)
				end
			else
				if self.ChaseThread then
					Movement.StopChase(self)
				end
				
				if self.AttackThread then
					cancelThread(self, "AttackThread")
				end

				if not self.RoamThread then
					self.Humanoid.WalkSpeed = CONFIG.Walkspeed
					Movement.Roam(self)
					self:SetState(Noob.States.Roaming)
				end
			end
		end
	end)
end

function Noob:AttackLoop()
	local ATTACK_RANGE = CONFIG.AttackRange or 6
	local ATTACK_COOLDOWN = CONFIG.AttackCooldown or 1
	
	while self.Target and self.Target.Parent and self.Humanoid.Health > 0 do
		local targetRoot = self.Target:FindFirstChild("HumanoidRootPart")
		local noobRoot = self.Model:FindFirstChild("HumanoidRootPart")
		local humanoid = self.Humanoid
		
		if not targetRoot or not noobRoot or not humanoid or humanoid.Health <= 0 then
			break
		end
		
		local distance = (targetRoot.Position - noobRoot.Position).Magnitude
		
		if distance <= ATTACK_RANGE then
			self:SetState(Noob.States.Attacking)
			
			local lookAt = CFrame.lookAt(noobRoot.Position, Vector3.new(targetRoot.Position.X, noobRoot.Position.Y, targetRoot.Position.Z))
			noobRoot.CFrame = lookAt
			
			self.Humanoid:MoveTo(noobRoot.Position)
			
			if Attack.CanEnter("Jab") then
				Attack.Enter(self, "Jab")
				task.wait(ATTACK_COOLDOWN)
			else
				task.wait(0.2)
			end
		else
			if self:IsState(Noob.States.Attacking) then
				self:SetState(Noob.States.Chasing)
			end
			task.wait(0.2)
		end
	end
	
	if self:IsState(Noob.States.Attacking) then
		self:SetState(Noob.States.Chasing)
	end
	
	self.AttackThread = nil
end

function Noob:Destroy()
	self:SetState(Noob.States.Dead)
	cancelThread(self, "UpdateThread")
	cancelThread(self, "AttackThread")
	Movement.StopAll(self)

	local index = table.find(noobs, self)
	if index then table.remove(noobs, index) end

	self.Model:Destroy()
end

return Noob
