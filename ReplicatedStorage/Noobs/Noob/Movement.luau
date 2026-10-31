local CONFIG = require(script.Parent.Configuration)
local Utils = require(script.Parent.Utils)

local cancelThread = Utils.cancelThread
local getPosition = Utils.getPosition
local randWait = Utils.randWait

local Movement = {}

function Movement.Roam(self)
	cancelThread(self, "RoamThread")

	self:StopAnimation(CONFIG.ChaseAnimation)
	self.Roaming = true

	self.RoamThread = task.spawn(function()
		while self.Roaming do
			self:PlayAnimation(CONFIG.WalkAnimation, Enum.AnimationPriority.Movement, 1, 1, true)

			local noobRoot = self.Model:FindFirstChild("HumanoidRootPart")
			if not noobRoot then return end

			local angle = math.random() * 2 * math.pi
			local distModifier = CONFIG.RoamRadius * math.random(-25, 25) * 0.01
			local x = (CONFIG.RoamRadius + distModifier) * math.cos(angle)
			local z = (CONFIG.RoamRadius + distModifier) * math.sin(angle)

			local targetPos = noobRoot.Position + Vector3.new(x, 0, z)

			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.RespectCanCollide = true
			rayParams.FilterDescendantsInstances = {self.Model}
			local result = workspace:Raycast(noobRoot.Position, targetPos - noobRoot.Position, rayParams)

			if result then
				self.Path:ComputeAsync(noobRoot.Position, targetPos)

				if self.Path.Status ~= Enum.PathStatus.Success then
					self:StopAnimation(CONFIG.WalkAnimation)
					randWait(CONFIG.RoamRate)
					continue
				end

				local waypoints = self.Path:GetWaypoints()
				if #waypoints <= 2 then
					self:StopAnimation(CONFIG.WalkAnimation)
					randWait(CONFIG.RoamRate)
					continue
				end

				targetPos = waypoints[2].Position
			end

			self.Humanoid:MoveTo(targetPos)
			self.Humanoid.MoveToFinished:Wait()

			self:StopAnimation(CONFIG.WalkAnimation)
			randWait(CONFIG.RoamRate)
		end
	end)
end

function Movement.Chase(self)
	cancelThread(self, "ChaseThread")

	local noobRoot = self.Model:FindFirstChild("HumanoidRootPart")
	if not noobRoot then return end

	self:StopAnimation(CONFIG.WalkAnimation)
	self:PlayAnimation(CONFIG.ChaseAnimation, Enum.AnimationPriority.Movement, 1, 1, true)

	self.ChaseThread = task.spawn(function()
		while true do
			local hrp = self.Target and self.Target:FindFirstChild("HumanoidRootPart")
			if not hrp or not self.Target.Parent or not hrp.Parent then
				cancelThread(self, "WaypointThread")
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

			cancelThread(self, "WaypointThread")

			self.WaypointThread = task.spawn(function()
				table.remove(waypoints, 1)

				for _, waypoint in waypoints do
					if not self.ChaseThread then return end
					if (waypoint.Position - noobRoot.Position).Magnitude <= 2 then continue end

					if waypoint.Action == Enum.PathWaypointAction.Jump then
						self.Humanoid.Jump = true
						self:PlayAnimation(CONFIG.JumpAnimation, Enum.AnimationPriority.Action, 1, 1, false)
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

function Movement.StopRoam(self)
	self.Roaming = false
	cancelThread(self, "RoamThread")
	self:StopAnimation(CONFIG.WalkAnimation)
end

function Movement.StopChase(self)
	cancelThread(self, "ChaseThread")
	cancelThread(self, "WaypointThread")
	self:StopAnimation(CONFIG.ChaseAnimation)
end

function Movement.StopAll(self)
	Movement.StopRoam(self)
	Movement.StopChase(self)
end

return Movement