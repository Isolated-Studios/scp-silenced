local module = {}

function module.Init()
	local Player = game.Players.LocalPlayer
	
	local TextChatService = game:GetService("TextChatService")
	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
	local ChatFunctions = require(ReplicatedStorage.Modules.UI.ChatFunctions)
	local ChatSounds = ReplicatedStorage.Sounds.Chat
	local ChatEvent = ReplicatedStorage.Events.Character.ChatEvent
	
	local GeneralChannel: TextChannel = TextChatService:WaitForChild("TextChannels").RBXGeneral
	local ChatInputBarConfiguration = TextChatService:WaitForChild("ChatInputBarConfiguration")

	--local textstring = ""
	--GeneralChannel:SendAsync("hi")
	--UIS.InputBegan:Connect(function(i,gpe)
	--	if ChatInputBarConfiguration.IsFocused then

	--		if i.KeyCode == Enum.KeyCode.Backspace then
	--			textstring = textstring:gsub(".?$","");
	--		else
	--			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
	--				print("wow")
	--				textstring ..= string.upper(UIS:GetStringForKeyCode(i.KeyCode))
	--			else
	--				textstring ..= string.lower(UIS:GetStringForKeyCode(i.KeyCode))
	--			end
	--		end
	--		print(textstring)
	--	end
	--end)
	
	TextChatService.ChatInputBarConfiguration:GetPropertyChangedSignal("IsFocused"):Connect(function()
		local IsTyping = TextChatService.ChatInputBarConfiguration.IsFocused
		ChatFunctions.VisualizeTyping(Player.Character,IsTyping,true)
	end)
	
	
	TextChatService.OnIncomingMessage = function(Message: TextChatMessage)
		local newText,Redacted = ChatFunctions.RedactMessage(Message.Text)
		if Message.Status == Enum.TextChatMessageStatus.Success and Message.TextSource and Message.TextSource.UserId and Message.TextSource.UserId == Player.UserId then
			ChatFunctions.VisualizeChat(Player.Character,newText,Redacted,true)
		end

		Message.Text = newText
	end
	
	ChatEvent.OnClientEvent:Connect(function(OtherCharacter,Message,Redacted)
		if typeof(Message) == "boolean" then
			ChatFunctions.VisualizeTyping(OtherCharacter,Message)
		else
			ChatFunctions.VisualizeChat(OtherCharacter,Message,Redacted)
		end
	end)
end

return module
