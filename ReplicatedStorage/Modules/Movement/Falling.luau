-- Configurations
local FALL_DROP = 3
local FALL_HEIGHT = 15
--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AnimationManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AnimationManager"))
local StaminaManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("StaminaManager"))
local Configuration = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Movement"):WaitForChild("Configuration"))

local fallAnimation = ReplicatedStorage.Animations.Movement.Fall
local landingAnimation = ReplicatedStorage.Animations.Movement.Land

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local heartbeatConnection, stateConnection = nil
local fallSpeed = 0

return {
	ShouldEnter = function(ctx)
		local rootPart = ctx.rootPart
		local velocityY = rootPart.AssemblyLinearVelocity.Y
		if velocityY >= 0 then return false end

		local drop = velocityY * velocityY / (2 * Workspace.Gravity)
		if drop < FALL_DROP then return false end

		rayParams.FilterDescendantsInstances = { ctx.character }

		local feetOffset = ctx.humanoid.HipHeight + rootPart.Size.Y / 2
		local direction = Vector3.new(0, -(feetOffset + FALL_HEIGHT), 0)
		return Workspace:Raycast(rootPart.Position, direction, rayParams) == nil
	end,

	Enter = function(ctx)
		ctx.humanoid.WalkSpeed = Configuration.Walking.Speed
		StaminaManager.StopDrain("Sprinting")
		AnimationManager.PlayAnimation(fallAnimation, Enum.AnimationPriority.Action2, 1, 1, true)

		fallSpeed = 0
		local Movement = require(script.Parent)

		if heartbeatConnection then heartbeatConnection:Disconnect() end
		heartbeatConnection = RunService.Heartbeat:Connect(function()
			if ctx.humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				fallSpeed = math.max(fallSpeed, -ctx.rootPart.AssemblyLinearVelocity.Y)
			end
		end)

		if stateConnection then stateConnection:Disconnect() end
		stateConnection = ctx.humanoid.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Landed then
				stateConnection:Disconnect()
				stateConnection = nil

				if fallSpeed >= Configuration.Landing.SpeedCap then
					AnimationManager.PlayAnimation(landingAnimation, Enum.AnimationPriority.Action4, 1, 1, false)
					ctx.humanoid:TakeDamage(fallSpeed // 15)
				end
			end
		end)
	end,

	Exit = function(ctx)
		if heartbeatConnection then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
		end
		if stateConnection then
			stateConnection:Disconnect()
			stateConnection = nil
		end
		AnimationManager.StopAnimation(fallAnimation)
	end
}

