local walkSpeed = 0

return {
	Enter = function(ctx)
		walkSpeed = ctx.humanoid.WalkSpeed

		ctx.humanoid.WalkSpeed = 0
		ctx.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end,
	
	Exit = function(ctx)
		ctx.humanoid.WalkSpeed = walkSpeed
		ctx.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end,
}