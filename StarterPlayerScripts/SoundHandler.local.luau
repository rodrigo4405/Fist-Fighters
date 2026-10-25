local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlaySound = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PlaySound")

local SoundManager = require(ReplicatedStorage.Modules.SoundManager)

PlaySound.OnClientEvent:Connect(function(player, sound, parent: Instance)
	if not player or player.Parent ~= game:GetService("Players") then return end
	if not parent:IsA("Instance") then return end

	if not sound then
		warn("SoundHandler: SFX '" .. sound .. "' not found")
		return
	end

	if not sound:IsA("Sound") then
		warn("SoundHandler: '" .. sound.Name .. "' is not a Sound instance")
		return
	end	

	if not parent then
		local character = player.Character or player.CharacterAdded:Wait()
		local hrp = character:WaitForChild("HumanoidRootPart")
		parent = hrp
	end

	local newSound = sound:Clone()
	newSound.Parent = parent
	newSound:Play()

	newSound.Ended:Once(function()
		newSound:Destroy()
	end)
end)