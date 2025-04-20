local ChatFunctions = {}

local DotTweenInfo = TweenInfo.new(0.2,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out,0,true)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ChatSounds = ReplicatedStorage.Sounds.Chat
local ChatEvent = ReplicatedStorage.Events.Character.ChatEvent

local redactedTranslations = {
	[1] = ChatSounds.Censor.Censor1,
	[2] = ChatSounds.Censor.Censor2,
	[3] = ChatSounds.Censor.Censor3,
}

local whitelistedChars = {"#"}
local function isStringWhitelisted(strings)
	for char in strings:gmatch(".") do
		if not table.find(whitelistedChars, char) then
			return false
		end
	end
	return true
end

function ChatFunctions.RedactMessage (Message)
	if not Message then return end
	local TextTable = string.split(Message," ")
	local newText = ""
	local Redacted = false
	for _,Word in ipairs (TextTable) do
		if isStringWhitelisted(Word) then
			if #Word >= 13 then
				Word = "[DATA EXPUNGED]"
				Redacted = 1
			elseif #Word >= 8 then
				Word = "[REDACTED]"
				Redacted = 2
			else
				Word = string.gsub(Word, ".", "█")
				Redacted = 3
			end
		end
		if newText == "" then
			newText = Word
		else
			newText = newText.." "..Word
		end
	end
	return newText,Redacted
end

function ChatFunctions.VisualizeTyping (Character: model, Typing: bool, Replicate: bool)
	local UpperTorso = Character.UpperTorso
	local ChatBubble = UpperTorso.ChatBubble
	local TypingBubble = ChatBubble.Chatting
	
	if Replicate then
		ChatEvent:FireServer(Character,Typing)
	end
	
	if Typing then
		TypingBubble.Visible = true
		while TypingBubble.Visible and Character do
			for i=1,3,1 do
				if not TypingBubble.Visible or not Character then
					break
				end
				local x = (i*0.02)+0.46
				TypingBubble[tostring(i)].Position = UDim2.fromScale(x,0.5)
				TweenService:Create(TypingBubble[tostring(i)],DotTweenInfo,{Position = UDim2.fromScale(x,0.4)}):Play()
				task.wait(0.3)
			end
			task.wait(0.5)
		end
	else
		TypingBubble.Visible = false
		for i=1,3,1 do
			local x = (i*0.02)+0.46
			TypingBubble[tostring(i)].Position = UDim2.fromScale(x,0.5)
		end
	end
end

function ChatFunctions.VisualizeChat (Character: model, unreactedMessage: string, Redacted: bool, Replicate: bool)
	local Message = ChatFunctions.RedactMessage(unreactedMessage)
	if Message == "Roblox automatically translates supported languages in chat" or not Message then return end -- I hate you roblox
	local letterCount = #Message -- The amount of characters in the message
	local UpperTorso = Character.UpperTorso
	local Profile = Character.Profile
	local PickedVoice = ChatSounds.Voices[Profile:GetAttribute("Voice")] -- Get the voice from Profile of Character
	
	local BubbleMessage = nil
	local Player = game.Players:GetPlayerFromCharacter(Character)
	local ChatBubble = UpperTorso.ChatBubble
	
	local BubbleMessage = ChatBubble.DialogueFrame.Example:Clone() -- Create a new message
	BubbleMessage.Name = "NewMessage"
	BubbleMessage.Visible = true
	BubbleMessage.Parent = ChatBubble.DialogueFrame

	task.defer(function()
		
		if Redacted then -- Play redacted sounds
			local RedactedSound = redactedTranslations[Redacted]:Clone()
			RedactedSound.Parent = UpperTorso
			RedactedSound.Looped = true
			RedactedSound:Play()
			Debris:AddItem(RedactedSound,0.08*letterCount)
		end
		
		for i=1,letterCount,1 do
			local letter = string.sub(Message,i,i)
			if BubbleMessage then
				local NewText = BubbleMessage.Text..letter
				if Redacted then -- If redacted do cool � effect
					if Redacted ~= 3 then -- Roblox already does the � thing unintentially for █
						BubbleMessage.Text = BubbleMessage.Text.."�"
					end
					task.wait(0.03)
				end
				
				BubbleMessage.Text = NewText -- Set the message with the other letter
			end
			local Volume = 0.5
			local ROMinD = 10
			local ROMaxD = 100
			if letter ~= letter:lower() then -- If capitalized make LOUD!
				Volume = 1.5
				ROMinD = 30
				ROMaxD = 200
			end

			if letter ~= " " and not Redacted then -- Letter is not a space and also not redacted
				local VoiceSound = PickedVoice:Clone()
				VoiceSound.Volume = Volume
				VoiceSound.RollOffMinDistance = ROMinD
				VoiceSound.RollOffMaxDistance = ROMaxD
				VoiceSound.Parent = UpperTorso
				VoiceSound:Play()
				Debris:AddItem(VoiceSound,VoiceSound.TimeLength)
			end
			task.wait(0.05)
		end
		
		task.delay((letterCount/4)+3, function() -- Wait an amount of time and then fade the word and delete
			TweenService:Create(BubbleMessage,TweenInfo.new(2),{TextTransparency = 1}):Play()
			Debris:AddItem(BubbleMessage,2)	
		end)
		
	end)
	
	if Replicate then -- Replicate to other clients through server
		ChatEvent:FireServer(Character,Message,Redacted)
	end
end

return ChatFunctions
