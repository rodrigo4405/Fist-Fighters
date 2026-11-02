local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AnimationManager"))
local Configuration = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Movement"):WaitForChild("Configuration"))

local jumpAnim = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Movement"):WaitForChild("Jump")

return {
	Enter = function(ctx)
		ctx.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		
		task.delay(Configuration.Jumping.Delay, function()
			ctx.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end)

		AnimationManager.PlayAnimation(jumpAnim, Enum.AnimationPriority.Action3, 1, 1, false)
	end,

	Exit = function(ctx)
		AnimationManager.StopAnimation(jumpAnim)
	end,
}