local Players = game:GetService("Players")

local CONFIG = require(script.Parent.Configuration)

local Utils = {}

local RESET_DELAY = 2
local lastSide = "Right Arm"
local lastAttackTime = 0

function Utils.GetAttackSide()
	local now = os.clock()
	if now - lastAttackTime >= RESET_DELAY then
		lastSide = "Right Arm"
	else
		lastSide = (lastSide == "Right Arm") and "Left Arm" or "Right Arm"
	end
	lastAttackTime = now
	return lastSide
end

function Utils.cancelThread(self, name)
	local thread = self[name]
	if thread then
		task.cancel(thread)
		self[name] = nil
	end
end

function Utils.getPosition(self)
	local root = self.Model:FindFirstChild("HumanoidRootPart")
	return root and root.Position or nil
end

function Utils.randWait(t)
	task.wait(t + t * math.random(-25, 25) * 0.01)
end

function Utils.loadAnimations(self, animations)
	for _, animation in animations do
		if self.CachedTracks[animation] then continue end

		self.CachedTracks[animation] = self.Animator:LoadAnimation(animation)
	end
end

function Utils.nearestPlayer(self)
	local noobPosition = Utils.getPosition(self)
	if not noobPosition then return nil, CONFIG.AggroRange end

	local nearest, nearestDistance = nil, CONFIG.AggroRange

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then continue end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")
		if not hrp or not humanoid then continue end

		if humanoid.Health <= 0 then continue end
		if character:FindFirstChildOfClass("ForceField") then continue end

		rayParams.FilterDescendantsInstances = {self.Model, character}

		local cantSee = workspace:Raycast(noobPosition, hrp.Position - noobPosition, rayParams)
		if cantSee then continue end

		local distance = (hrp.Position - noobPosition).Magnitude

		if distance < nearestDistance then
			nearest = player
			nearestDistance = distance
		end
	end

	return nearest, nearestDistance
end

return Utils
