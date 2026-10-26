local Players = game:GetService("Players")
local PathFindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local model = ReplicatedStorage:WaitForChild("Zombie")
local CombatEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("CombatEvent")

local CONFIG = require(script.Parent.Configuration)

local zombies = {}
local zombieFolder = Instance.new("Folder")
zombieFolder.Name = "Zombies"
zombieFolder.Parent = workspace

local function loadAnimations(self, animations)
	for _, animation in animations do
		if self.CachedTracks[animation] then continue end

		self.CachedTracks[animation] = self.Animator:LoadAnimation(animation)
	end
end

local function playAnimation(self, animation: Animation, priority: Enum.AnimationPriority, weight: number?, speed: number?, looped: boolean?): AnimationTrack?
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

local function stopAnimation(self, animation: Animation)
	local track = self.CachedTracks[animation]

	if track and track.IsPlaying then
		track:Stop(0.2)
	end
end

local function getPosition(self)
	local zombieRoot = self.Model:FindFirstChild("HumanoidRootPart")
	if not zombieRoot then return nil end

	return zombieRoot.Position
end

local function nearestPlayer(self)
	local zombiePosition = getPosition(self)
	if not zombiePosition then return nil, CONFIG.AggroRange end

	local nearest, nearestDistance = nil, CONFIG.AggroRange

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then continue end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")
		if not hrp or not humanoid then continue end

		if humanoid.Health <= 0 then continue end
		if character:FindFirstChildOfClass("ForceField") then continue end

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {self.Model, character}

		local cantSee = workspace:Raycast(zombiePosition, hrp.Position - zombiePosition, rayParams)
		if cantSee then continue end

		local playerPosition = hrp.Position
		local distance = (playerPosition - zombiePosition).Magnitude

		if distance < nearestDistance then
			nearest = player
			nearestDistance = distance
		end
	end

	return nearest, nearestDistance
end

local function createRangeVisualizer(self)
	local function createRange(name, radius, color)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.1, radius * 2, radius * 2)
		part.Color = color
		part.Material = Enum.Material.Neon
		part.Transparency = 0.8
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		part.Parent = self.Model

		return part
	end

	self.AggroVisualizer = createRange("AggroRange", CONFIG.AggroRange, Color3.fromRGB(255, 65, 65))
	self.AttackVisualizer = createRange("AttackRange", CONFIG.AttackRange, Color3.fromRGB(255, 170, 0))
end

local function updateRangeVisualizer(self)
	local root = self.Model:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local position = root.Position - Vector3.new(0, root.Size.Y / 2 + 0.1, 0)
	local rotation = CFrame.Angles(0, 0, math.rad(90))

	self.AggroVisualizer.CFrame = CFrame.new(position) * rotation
	self.AttackVisualizer.CFrame = CFrame.new(position) * rotation
end

local function roam(self)
	if self.RoamThread then task.cancel(self.RoamThread) end

	stopAnimation(self, CONFIG.ChaseAnimation)
	self.Roaming = true
	self.RoamThread = task.spawn(function()
		while self.Roaming do
			playAnimation(self, CONFIG.WalkAnimation, Enum.AnimationPriority.Movement, 1, 1, true)
			local zombieRoot = self.Model:FindFirstChild("HumanoidRootPart")
			if not zombieRoot then return end

			local angle = math.random() * 2 * math.pi
			local distModifier = CONFIG.RoamRadius * math.random(-25,25) * 0.01
			local x = (CONFIG.RoamRadius+distModifier) * math.cos(angle)
			local z = (CONFIG.RoamRadius+distModifier) * math.sin(angle)

			local targetPos = zombieRoot.Position + Vector3.new(x, 0, z)

			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.RespectCanCollide = true
			rayParams.FilterDescendantsInstances = {self.Model}
			local result = workspace:Raycast(zombieRoot.Position, targetPos - zombieRoot.Position, rayParams)

			if result then
				self.Path:ComputeAsync(zombieRoot.Position, targetPos)

				if self.Path.Status ~= Enum.PathStatus.Success then 
					stopAnimation(self, CONFIG.WalkAnimation)
					task.wait(CONFIG.RoamRate + CONFIG.RoamRate * math.random(-25,25)*0.01)
					continue
				end

				local waypoints = self.Path:GetWaypoints()
				if #waypoints <= 2 then
					stopAnimation(self, CONFIG.WalkAnimation)
					task.wait(CONFIG.RoamRate + CONFIG.RoamRate * math.random(-25,25)*0.01)
					continue
				end

				targetPos = waypoints[2].Position
			end

			self.Humanoid:MoveTo(targetPos)
			self.Humanoid.MoveToFinished:Wait()

			stopAnimation(self, CONFIG.WalkAnimation)
			task.wait(CONFIG.RoamRate + CONFIG.RoamRate * math.random(-25,25)*0.01)
		end
	end)
end

local function chase(self)
	if self.ChaseThread then task.cancel(self.ChaseThread) end

	local zombieRoot = self.Model:FindFirstChild("HumanoidRootPart")
	if not zombieRoot then return end

	stopAnimation(self, CONFIG.WalkAnimation)
	playAnimation(self, CONFIG.ChaseAnimation, Enum.AnimationPriority.Movement, 1, 1, true)

	self.ChaseThread = task.spawn(function()
		while true do
			local hrp = self.Target and self.Target:FindFirstChild("HumanoidRootPart")
			if not hrp then
				self.ChaseThread = nil
				return
			end

			if not self.Target.Parent or not hrp.Parent then
				if self.WaypointThread then
					task.cancel(self.WaypointThread)
					self.WaypointThread = nil
				end

				self.ChaseThread = nil
				return
			end

			local position = getPosition(self)
			if not position then
				self.ChaseThread = nil
				return
			end

			self.Path:ComputeAsync(position, hrp.Position)

			if self.Path.Status ~= Enum.PathStatus.Success then
				task.wait(CONFIG.ChasePathRate)
				continue
			end

			local waypoints = self.Path:GetWaypoints()

			if self.WaypointThread then
				task.cancel(self.WaypointThread)
			end

			self.WaypointThread = task.spawn(function()
				table.remove(waypoints, 1)

				for _, waypoint in waypoints do
					if not self.ChaseThread then return end
					if (waypoint.Position-zombieRoot.Position).Magnitude <= 2 then continue end

					if waypoint.Action == Enum.PathWaypointAction.Jump then
						self.Humanoid.Jump = true
						playAnimation(self, CONFIG.JumpAnimation, Enum.AnimationPriority.Action, 1, 1, false)
					end

					self.Humanoid:MoveTo(waypoint.Position)

					local reached = self.Humanoid.MoveToFinished:Wait()
					if not reached then return end
				end
			end)

			task.wait(CONFIG.ChasePathRate)
		end
	end)
end

local function attack(self)
	if self.AttackThread then task.cancel(self.AttackThread) end
	self.AttackThread = task.spawn(function()
		return -- todo
	end)
end

local function cancelThread(self, name)
	local thread = self[name]
	if thread then
		task.cancel(thread)
		self[name] = nil
	end
end

local Zombie = {}
Zombie.__index = Zombie

function Zombie.new(position: CFrame)
	if #zombies >= CONFIG.ZombieCap then return nil end
	local self = setmetatable({}, Zombie)

	self.Model = model:Clone()
	self.Model.Parent = zombieFolder
	self.Model:PivotTo(position or CONFIG.DefaultSpawn)

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
	loadAnimations(self, {CONFIG.ChaseAnimation, CONFIG.WalkAnimation, CONFIG.JumpAnimation})

	self.Health = math.random(CONFIG.Health[1], CONFIG.Health[2])
	self.Walkspeed = math.random(CONFIG.Walkspeed[1], CONFIG.Walkspeed[2])
	self.Damage = math.random(CONFIG.Damage[1], CONFIG.Damage[2])

	self.Humanoid.WalkSpeed = self.Walkspeed
	self.Humanoid.MaxHealth = self.Health
	self.Humanoid.Health = self.Health

	self.UpdateThread = nil
	self.RoamThread = nil
	self.ChaseThread = nil
	self.WaypointThread = nil
	self.AttackThread = nil

	self.Target = nil

	self.Path = PathFindingService:CreatePath({Costs = {WaterBlock = math.huge}}) -- idk why this is not working

	createRangeVisualizer(self)
	updateRangeVisualizer(self)

	self:Update()
	table.insert(zombies, self)

	return self
end

function Zombie:Update()
	cancelThread(self, "UpdateThread")

	self.UpdateThread = task.spawn(function()
		while task.wait(CONFIG.UpdateRate) do
			updateRangeVisualizer(self)

			local target = nearestPlayer(self) 
			self.Target = target and target.Character

			if target then
				cancelThread(self, "RoamThread")

				if not self.ChaseThread then
					self.Humanoid.WalkSpeed = self.Walkspeed * 1.5
					chase(self)
				end
			else
				if self.ChaseThread then
					cancelThread(self, "ChaseThread")
					stopAnimation(self, CONFIG.ChaseAnimation)
				end

				cancelThread(self, "WaypointThread")

				if not self.RoamThread then
					self.Humanoid.WalkSpeed = self.Walkspeed
					roam(self)
				end
			end
		end
	end)
end

function Zombie:Destroy()
	if self.UpdateThread then task.cancel(self.UpdateThread) end
	if self.RoamThread then task.cancel(self.RoamThread) end
	if self.ChaseThread then task.cancel(self.ChaseThread) end
	if self.WaypointThread then task.cancel(self.WaypointThread) end

	local index = table.find(zombies, self)
	if index then table.remove(zombies, index) end

	self.Model:Destroy()
end

return Zombie