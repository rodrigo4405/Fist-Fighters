local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local CONFIG = require(script:WaitForChild("Configuration"))

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("RemoteFunctions")
local commandFunction = remotes:WaitForChild("RunCommand")

local channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")
local systemChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem")

local chatGui = player:WaitForChild("PlayerGui"):WaitForChild("Chat", 9e9)
local container = chatGui:WaitForChild("UwuFrame")
local inputFrame = container:WaitForChild("InputFrame")
local inputBox = inputFrame:WaitForChild("Input")
local sendBtn = inputFrame:WaitForChild("SendBtn")

local history = container:WaitForChild("ChatHistory")
local templates = {
	message = history:WaitForChild("Template"),
	success = history:WaitForChild("TemplateSuccess"),
	error = history:WaitForChild("TemplateError"),
	system = history:WaitForChild("TemplateSystem"),
}

local success, result = pcall(TextChatService.CanUserChatAsync, TextChatService, player.UserId)
local canChat = success and result

local lastCommand = ""
local draft = ""

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function escapeRichText(s)
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function truncate(text, maxChars)
	local len = utf8.len(text)
	if not len then
		return text:sub(1, maxChars)
	end
	if len <= maxChars then
		return text
	end
	return text:sub(1, utf8.offset(text, maxChars + 1) - 1)
end

local function getPlayerColor(player)
	local hash = 0
	for i = 1, #player.Name do
		hash = (hash * 31 + string.byte(player.Name, i)) % #CONFIG.PLAYER_COLORS
	end
	return CONFIG.PLAYER_COLORS[hash + 1] 
end

local lineFrames = {}
local lineCount = 0
local nextIndex = 1
local layoutOrder = 0

local function addLine(template, richText)
	local wasAtBottom = history.CanvasPosition.Y >= history.AbsoluteCanvasSize.Y - history.AbsoluteSize.Y - 1

	local line = template:Clone()
	local label = line.Message
	label.RichText = true
	label.Text = richText

	layoutOrder += 1
	line.LayoutOrder = layoutOrder
	line.Visible = true
	line.Parent = history

	if lineCount < CONFIG.MAX_LINES then
		lineCount += 1
		lineFrames[lineCount] = line
	else
		lineFrames[nextIndex]:Destroy()
		lineFrames[nextIndex] = line
		nextIndex = nextIndex % CONFIG.MAX_LINES + 1
	end

	if wasAtBottom then
		history.CanvasPosition = Vector2.new(0, history.AbsoluteCanvasSize.Y - history.AbsoluteSize.Y)
	end
end

local function showCommandResult(success, text)
	local color = success and "#22C55E" or "#EF4444"
	local title = success and "Success" or "Error"

	addLine(
		success and templates.success or templates.error,
		`<font color="{color}">[{title}]</font> <font color="#F1F5F9">{escapeRichText(tostring(text))}</font>`
	)
end

local function showSystemMessage(text)
	text = trim(tostring(text or ""))
	if text == "" then return end

	addLine(
		templates.system,
		`<font color="#FFDA21" size="15">[System]</font> <font color="#FFFFFF" size="14">{escapeRichText(text)}</font>`
	)
end

local function showWhisperMessage(player, message)
	if not player then return end
	addLine(
		templates.message,
		`<font color="#AAAAAA"><i>[WHISPER]</i></font> <font color="#FFFFFF">{escapeRichText(player.DisplayName)}:</font> <i>{escapeRichText(message)}</i>`
	)
end

local function formatPlayerMessage(player, text)
	local tag = player:GetAttribute("Tag")
	local tagInfo = tag and CONFIG.Tags[tag]

	local prefix = ""
	if tagInfo then
		prefix = `<font color="{tagInfo.Color}">[{tag}]</font> `
	end

	local playerColor = getPlayerColor(player)
	return `{prefix}<font color="{playerColor}">{escapeRichText(player.DisplayName)}</font>: {text}`
end

local function processCommand(message)
	local success, result = commandFunction:InvokeServer(message)
	if not result then return success end

	local whisper = string.split(result, ":")
	if whisper[1] == "whisper" then
		channel:SendAsync(whisper[4], result)
		showCommandResult(success, "Whisper sent")
	elseif result then
		showCommandResult(success, result)
	end

	lastCommand = message

	return success
end


local function sendMessage()
	if not canChat then return false end

	local message = trim(inputBox.Text)
	inputBox.Text = ""
	if message == "" then return false end

	if message:sub(1, #CONFIG.COMMAND_PREFIX) == CONFIG.COMMAND_PREFIX then
		return processCommand(message)
	end

	return channel:SendAsync(message)
end

local function disableInput()
	sendBtn:Destroy()
	inputBox.Size = UDim2.fromScale(1, 1)
	inputBox.PlaceholderText = "Chat is disabled for your account."
	inputBox.TextEditable = false
end

local function setupInput()
	if not canChat then
		return disableInput()
	end

	local keyName = UserInputService:GetStringForKeyCode(CONFIG.CHAT_KEY)
	keyName = keyName or "/"
	if keyName == "Slash" then keyName = "/" end
	inputBox.PlaceholderText = `Press "{keyName}" to chat`

	UserInputService.InputBegan:Connect(function(input, gameProcessed)		
		local history

		if input.KeyCode == CONFIG.CHAT_KEY then
			if gameProcessed then return end

			task.delay(0.01,function()
				inputBox:CaptureFocus()
				inputBox.Text = inputBox.Text:gsub("/", "")
			end)
			
		elseif inputBox:IsFocused() then 
			if input.KeyCode == Enum.KeyCode.Up and lastCommand and inputBox.Text ~= lastCommand then
				draft = inputBox.Text
				inputBox.Text = lastCommand
				inputBox.CursorPosition = #lastCommand + 1
				
			elseif input.KeyCode == Enum.KeyCode.Down then
				inputBox.Text = draft
				inputBox.CursorPosition = #draft + 1
			end
		end
	end)

	inputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			sendMessage()
		end
	end)

	inputBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = inputBox.Text
		local limited = truncate(text, CONFIG.MAX_MESSAGE_LENGTH)
		if limited ~= text then
			inputBox.Text = limited
		end
	end)

	sendBtn.Activated:Connect(sendMessage)
end

local function onMessageReceived(message)
	local source = message.TextSource

	if not message.Text then return end
		
	if message.Metadata then
		local metadata = string.split(message.Metadata, ":")
		if metadata and metadata[1] == "whisper" and tonumber(metadata[2]) then
			local plr = Players:GetPlayerByUserId(tonumber(metadata[2]))
			if plr then
				showWhisperMessage(plr, message.Text)
			end
			return
		end
	end
	
	if not source then
		showSystemMessage(message.Text)
		return
	end

	local player = Players:GetPlayerByUserId(source.UserId)
	if player then
		addLine(templates.message, formatPlayerMessage(player, message.Text))
	else
		addLine(templates.message, `{escapeRichText(source.Name)}: {message.Text}`)
	end
end


setupInput()
channel.MessageReceived:Connect(onMessageReceived)
systemChannel.MessageReceived:Connect(function(message)
	showSystemMessage(message.Text)
end)