local RunService = game:GetService("RunService")

local originalC0 = nil
local currentTilt = 0

local connection = nil

return {
	Enter = function(ctx)
		if connection then
			connection:Disconnect()
			connection = nil
		end

		if originalC0 == nil then originalC0 = ctx.rootPart.RootJoint.C0 end
		
		connection = RunService.RenderStepped:Connect(function(deltaTime)
			if not ctx.humanoid or not ctx.rootPart or not ctx.rootPart:FindFirstChild("RootJoint") then return end

			local isMoving = ctx.humanoid.MoveDirection.Magnitude > 0 and ctx.humanoid.WalkSpeed > 0

			local targetTilt = 0
			if isMoving and ctx.humanoid:GetState() == Enum.HumanoidStateType.Running then
				local sideSpeed = ctx.rootPart.AssemblyLinearVelocity:Dot(ctx.rootPart.CFrame.RightVector)
				local turnRate = ctx.rootPart.AssemblyAngularVelocity.Y

				local strafeTilt = -math.clamp(sideSpeed / 28, -1, 1)
				local turnTilt = math.clamp(turnRate / 6, -1, 1)
				targetTilt = math.clamp(strafeTilt + turnTilt, -1, 1) * math.rad(6)
			end

			currentTilt += (targetTilt - currentTilt) * math.min(1, 15 * deltaTime)
			ctx.rootPart.RootJoint.C0 = originalC0 * CFrame.Angles(0, currentTilt, currentTilt * 1.5)
		end)
	end,
	
	Exit = function(ctx)
		if currentTilt == 0 and connection then
			connection:Disconnect()
			connection = nil
		end

		originalC0 = nil
	end
}