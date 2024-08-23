local module = {}

local whitelistedChars = {"#"}
local function isStringWhitelisted(strings)
	for char in strings:gmatch(".") do
		if not table.find(whitelistedChars, char) then
			return false
		end
	end
	return true
end

function module.Init()
	local Player = game.Players.LocalPlayer
	local TextChatService = game:GetService("TextChatService")
	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
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
	
	TextChatService.OnIncomingMessage = function(Message: TextChatMessage, Character: PartorCharacter)
		local TextTable = string.split(Message.Text," ")
		local newText = ""
		for _,Word in ipairs (TextTable) do
			if isStringWhitelisted(Word) then
				if #Word >= 13 then
					Word = "[DATA EXPUNGED]"
				elseif #Word >= 8 then
					Word = "[REDACTED]"
				else
					Word = string.gsub(Word, ".", "█")
				end
			end
			if newText == "" then
				newText = Word
			else
				newText = newText.." "..Word
			end
		end
		
		Message.Text = newText
		--if Message.Status == Enum.TextChatMessageStatus.Success then
			--textstring = ""
		--end
	end
end

return module