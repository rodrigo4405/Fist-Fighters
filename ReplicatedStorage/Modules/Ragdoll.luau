local SPEED = 50

local Ragdoll = {}	

function Ragdoll.Play(character, lv)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid.RequiresNeck = false
	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	humanoid.AutoRotate = false


	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part:SetNetworkOwner(nil)
		end
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		lv = lv or -hrp.CFrame.LookVector
		hrp.AssemblyLinearVelocity = -lv * SPEED
		hrp.CanCollide = false
	end

	for _, joint in pairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
			local attachment0 = Instance.new("Attachment")
			attachment0.CFrame = joint.C0
			attachment0.Parent = joint.Part0

			local attachment1 = Instance.new("Attachment")
			attachment1.CFrame = joint.C1
			attachment1.Parent = joint.Part1

			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = attachment0
			socket.Attachment1 = attachment1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.Parent = joint.Parent

			joint.Enabled = false
		end
	end

	return false
end

return Ragdoll