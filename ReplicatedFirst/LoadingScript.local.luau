local SKIP_MAIN_MENU_STUDIO = false

local ReplicatedFirst = game:GetService("ReplicatedFirst")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)

local playerGUI = player:WaitForChild("PlayerGui")

local loadingGUI = ReplicatedFirst:WaitForChild("LoadingScreen")
loadingGUI.Parent = playerGUI

local background = loadingGUI:WaitForChild("Background")
local label = background:WaitForChild("TextLabel")


pcall(function()
	ContentProvider:PreloadAsync(workspace:GetDescendants())
	ContentProvider:PreloadAsync(ReplicatedStorage:GetDescendants())
	ContentProvider:PreloadAsync(player.PlayerGui:GetDescendants())
end)

task.wait(2)

-- SETUP CAMERA

local Camera = workspace.CurrentCamera
local cameraPositions = workspace:WaitForChild("Map"):WaitForChild("CameraPositions")
local cam = cameraPositions:WaitForChild("Model"):WaitForChild("Position")

player.ReplicationFocus = cam

Camera.CameraType = Enum.CameraType.Scriptable
Camera.CFrame = cam.CFrame

-- SETUP MAIN MENU

local mainMenuGui = ReplicatedFirst:WaitForChild("MainMenu")
mainMenuGui.Parent = playerGUI

local mainMenuBackground = mainMenuGui:WaitForChild("Background")
local playBtn = mainMenuBackground:WaitForChild("Play")

local welcomeLbl = mainMenuBackground:WaitForChild("Welcome")
welcomeLbl.RichText = true
welcomeLbl.Text = `<stroke color="#000000" thickness="2">Welcome to </stroke><stroke color="#ff0000" thickness="2">Fist Fighters</stroke><stroke color="#000000" thickness="2">, {player.DisplayName}!</stroke>`

local Lighting = game:GetService("Lighting")
local blur = Lighting:WaitForChild("Blur")
blur.Enabled = true
blur.Size = 7

-- SETUP SOUNDS

local music = SoundService:WaitForChild("Music")
local mainMenuMusic = music:WaitForChild("MainMenuMusic")
local sfx = SoundService:WaitForChild("SFX")
local clickSound = sfx:WaitForChild("Misc"):WaitForChild("Click")
mainMenuMusic.Volume = 0

label.Text = "Loaded!"
task.wait(1)


-- FADE OUT LOADING SCREEN / PLAY MAIN MENU

local fadeInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local slideInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local backgroundFade = TweenService:Create(background, fadeInfo, {
	BackgroundTransparency = 1
})

local textFade = TweenService:Create(label, fadeInfo, {
	TextTransparency = 1
})

local buttonSlide = TweenService:Create(playBtn, slideInfo, {
	Position = UDim2.new(playBtn.Position.X.Scale, playBtn.Position.X.Offset, 0.7, 0)
})

local textSlide = TweenService:Create(welcomeLbl, slideInfo, {
	Position = UDim2.new(welcomeLbl.Position.X.Scale, welcomeLbl.Position.X.Offset, 0.25, 0)
})

local musicFade = TweenService:Create(mainMenuMusic, fadeInfo, {
	Volume = 0.08
})

mainMenuMusic:Play()
musicFade:Play()
backgroundFade:Play()
textFade:Play()
textSlide:Play()

-- let background fully load before enabling play button
task.delay(3, function() buttonSlide:Play() end)

backgroundFade.Completed:Wait()

loadingGUI:Destroy()

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local startGameEvent = remotes:WaitForChild("StartGameEvent")

local SoundManager = require(ReplicatedStorage.Modules.SoundManager)


-- START PLAYING

playBtn.MouseButton1Click:Connect(function()
	clickSound:Play()	
	local blurFade = TweenService:Create(blur, fadeInfo, {
		Size = 0
	})

	local buttonSlide = TweenService:Create(playBtn, slideInfo, {
		Position = UDim2.new(playBtn.Position.X.Scale, playBtn.Position.X.Offset, 1, 100)
	})

	local textSlide = TweenService:Create(welcomeLbl, slideInfo, {
		Position = UDim2.new(welcomeLbl.Position.X.Scale, welcomeLbl.Position.X.Offset, -0.5, 0)
	})

	local musicFade = TweenService:Create(mainMenuMusic, fadeInfo, {
		Volume = 0
	})

	textSlide:Play()
	blurFade:Play()
	musicFade:Play()
	buttonSlide:Play()

	musicFade.Completed:Wait()
	buttonSlide.Completed:Wait()

	startGameEvent:FireServer() -- spawn character

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom

	local character = player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	camera.CameraSubject = humanoid

	local barsGui = playerGUI:WaitForChild("Bars")
	barsGui.Enabled = true

	blur:Destroy()
	mainMenuGui:Destroy()
	mainMenuMusic:Stop()
	
	--SoundManager.StartBackgroundMusic()
end)

-- todo: bypass main menu on studio session