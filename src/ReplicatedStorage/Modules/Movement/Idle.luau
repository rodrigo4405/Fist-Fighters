local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AnimationManager"))
local StaminaManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("StaminaManager"))
local Configuration = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Movement"):WaitForChild("Configuration"))

local idleAnim = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Movement"):WaitForChild("Idle")

return {
	Enter = function(ctx)
		ctx.humanoid.WalkSpeed = Configuration.Walking.Speed
		StaminaManager.StopDrain("Sprinting")
		
		AnimationManager.PlayAnimation(idleAnim, Enum.AnimationPriority.Idle, 1, 1, true)
	end,

	Exit = function(ctx)
		AnimationManager.StopAnimation(idleAnim)
	end,
}