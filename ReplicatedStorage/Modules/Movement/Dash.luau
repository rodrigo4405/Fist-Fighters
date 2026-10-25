local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AnimationManager"))
local StaminaManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("StaminaManager"))
local SoundManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundManager"))
local Movement = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Movement"))
local Configuration = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Movement"):WaitForChild("Configuration"))

local dashAnimation = ReplicatedStorage.Animations.Movement.Dash

local lastDashTime = 0

return {
	CanEnter = function()
		if os.clock() - lastDashTime < Configuration.Dash.Cooldown then return false end
		if not StaminaManager.Deduct(Configuration.Dash.StaminaCost) then return false end
		
		return true
	end,

	Enter = function(ctx)
		lastDashTime = os.clock()
		
		SoundManager.PlaySFX(SoundManager.SFX.Movement.Dash, ctx.rootPart)
		AnimationManager.PlayAnimation(dashAnimation, Enum.AnimationPriority.Action4, 1, 1, true)

		local dashDirection = ctx.humanoid.MoveDirection
		if dashDirection.Magnitude == 0 then
			dashDirection = ctx.rootPart.CFrame.LookVector
		end

		local dashSpeed = Configuration.Dash.Distance / Configuration.Dash.Duration

		local attachment = Instance.new("Attachment")
		attachment.Parent = ctx.rootPart

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.MaxForce = 50000
		linearVelocity.VectorVelocity = dashDirection.Unit * dashSpeed
		linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		linearVelocity.Attachment0 = attachment
		linearVelocity.Parent = ctx.rootPart

		task.delay(Configuration.Dash.Duration, function()
			linearVelocity:Destroy()
			attachment:Destroy()

			AnimationManager.StopAnimation(dashAnimation)
			Movement.SetState(ctx, "Idle")
		end)
	end,
	
	Exit = function(ctx)
		AnimationManager.StopAnimation(dashAnimation)
	end
}