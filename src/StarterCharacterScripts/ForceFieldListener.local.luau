local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local ForceFieldEvent = ReplicatedStorage.RemoteEvents.ForceFieldEvent

local Keybinds = require(ReplicatedStorage.Modules.Keybinds)

local function applyForceField()
	ForceFieldEvent:FireServer(true)
end

if character then
	applyForceField()
end

player.CharacterAdded:Connect(applyForceField)

local function removeForceField()
	ForceFieldEvent:FireServer(false)
	script:Destroy()
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	
	local movementKeys = {
		Enum.KeyCode.W,
		Enum.KeyCode.S,
		Enum.KeyCode.A,
		Enum.KeyCode.D,
		Enum.KeyCode.Space,
		Keybinds.BoundKeybinds["Dash"],
	}
	
	if input.UserInputType == Enum.UserInputType.Keyboard then
		for _, keybind in movementKeys do
			if input.KeyCode == keybind then
				removeForceField()
				return
			end
		end
	end
end)

character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then removeForceField() end
end)