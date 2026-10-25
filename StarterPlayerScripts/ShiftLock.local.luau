local Keybinds = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Keybinds"))
local UserInputService = game:GetService("UserInputService")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
local mouseLockController = playerModule:WaitForChild("CameraModule"):WaitForChild("MouseLockController")

local cursorImage = Instance.new("StringValue")
cursorImage.Name = "CursorImage"
cursorImage.Value = ""
cursorImage.Parent = mouseLockController

local boundKeys = mouseLockController:WaitForChild("BoundKeys")
boundKeys.Value = Keybinds.Get("Shiftlock").Name

local conn = nil
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function applyLockState(humanoid)
	local cursor = player.PlayerGui:WaitForChild("Shiftlock").Frame

	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		humanoid.CameraOffset = Vector3.new(1, 0.5, 0)
		UserInputService.MouseIconEnabled = false
		cursor.Visible = true
		
		local character = humanoid.Parent
		local head = character:FindFirstChild("Head")
		rayParams.FilterDescendantsInstances = {character}
		conn = RunService:BindToRenderStep(
			"CameraCollision",
			Enum.RenderPriority.Camera.Value + 1,
			function()
				local origin = head.Position
				local cameraPos = Camera.CFrame.Position
				local direction = cameraPos - origin

				local hit = workspace:Raycast(origin, direction, rayParams)

				if hit then
					local newPos = hit.Position + hit.Normal * 0.25
					Camera.CFrame = CFrame.new(newPos) * Camera.CFrame.Rotation
				end
			end
		)
		
	elseif UserInputService.MouseBehavior == Enum.MouseBehavior.Default then
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
		UserInputService.MouseIconEnabled = true
		cursor.Visible = false
		if conn then conn:Disconnect() end
	end
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	applyLockState(humanoid)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

UserInputService:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	applyLockState(humanoid)
end)