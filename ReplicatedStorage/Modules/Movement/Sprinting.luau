local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AnimationManager"))
local StaminaManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("StaminaManager"))
local Configuration = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Movement"):WaitForChild("Configuration"))

local sprintAnimation = ReplicatedStorage.Animations.Movement.Sprint

return {
	Enter = function(ctx)
		ctx.humanoid.WalkSpeed = Configuration.Sprinting.Speed
		StaminaManager.StartDrain("Sprinting", Configuration.Sprinting.StaminaDrain)
		AnimationManager.PlayAnimation(sprintAnimation, Enum.AnimationPriority.Action2, 1, 1, true)
	end,

	Exit = function(ctx)
		AnimationManager.StopAnimation(sprintAnimation)
	end,
}