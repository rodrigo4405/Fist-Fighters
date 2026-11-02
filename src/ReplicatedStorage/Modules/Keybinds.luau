local player = game:GetService("Players").LocalPlayer
local playerModule = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
local mouseLockController = playerModule:WaitForChild("CameraModule"):WaitForChild("MouseLockController")
local shiftlockKeys = mouseLockController:WaitForChild("BoundKeys")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local saveKeybind = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("SaveKeybind")

local KeybindModule = {}

KeybindModule.DefaultKeybinds = {
	Sprint = Enum.KeyCode.LeftShift,
	Dash = Enum.KeyCode.Q,
	Shiftlock = Enum.KeyCode.LeftAlt,

	Hook = Enum.KeyCode.E,
	Uppercut = Enum.KeyCode.R,
	BodyShot = Enum.KeyCode.F,
	Overhand = Enum.KeyCode.C,
	Block = Enum.KeyCode.G,
}

KeybindModule.BoundKeybinds = table.clone(KeybindModule.DefaultKeybinds)

function KeybindModule.Get(actionName: string): Enum.KeyCode
	return KeybindModule.BoundKeybinds[actionName]
end

function KeybindModule.Set(actionName: string, newKey: Enum.KeyCode): {[string]: Enum.KeyCode}
	local changes = {}
	
	if KeybindModule.BoundKeybinds[actionName] == nil then
		warn("Invalid action name:", actionName)
		return changes
	end
	
	local oldkey = KeybindModule.BoundKeybinds[actionName]
	
	KeybindModule.BoundKeybinds[actionName] = newKey
	if actionName == "Shiftlock" then shiftlockKeys.Value = newKey.Name end
	
	changes[actionName] = newKey
	
	for action, currentKey in KeybindModule.BoundKeybinds do
		if newKey == currentKey and action ~= actionName then
			KeybindModule.BoundKeybinds[action] = oldkey
			if action == "Shiftlock" then shiftlockKeys.Value = oldkey.Name end

			changes[action] = oldkey
		end
	end
	
	saveKeybind:FireServer(changes)
	return changes
end

saveKeybind.OnClientEvent:Connect(function(keybinds)
	KeybindModule.BoundKeybinds = table.clone(keybinds)
	shiftlockKeys.Value = keybinds.Shiftlock.Name
end)

return KeybindModule