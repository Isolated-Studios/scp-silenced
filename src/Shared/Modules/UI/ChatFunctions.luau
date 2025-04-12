local ChatFunctions = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local Debris = game:GetService("Debris")
local ChatSounds = ReplicatedStorage.Sounds.Chat
local ChatEvent = ReplicatedStorage.Events.Character.ChatEvent

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
			Redacted = true
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
	return newText,Redacted
end

function ChatFunctions.VisualizeChat (Character: model, unreactedMessage: string, Replicate: bool)
	local Message,Redacted = ChatFunctions.RedactMessage(unreactedMessage)
	if Message == "Roblox automatically translates supported languages in chat" or not Message then return end -- I hate you roblox
	local letterCount = #Message
	local Head = Character.Head
	local Profile = Character.Profile
	local PickedVoice = ChatSounds.Voices[Profile:GetAttribute("Voice")]
	task.defer(function()
		if not Redacted then
			for i=1,letterCount,1 do
				local letter = string.sub(Message,i,i)
				local Volume = 0.5
				local ROMinD = 10
				local ROMaxD = 100
				if letter ~= letter:lower() then
					Volume = 1.5
					ROMinD = 30
					ROMaxD = 200
				end

				if letter ~= " " then
					local VoiceSound = PickedVoice:Clone()
					VoiceSound.Volume = Volume
					VoiceSound.RollOffMinDistance = ROMinD
					VoiceSound.RollOffMaxDistance = ROMaxD
					VoiceSound.Parent = Head
					VoiceSound:Play()
					Debris:AddItem(VoiceSound,VoiceSound.TimeLength)
				end
				task.wait(0.05)
			end
		end
	end)
	
	if Replicate then
		ChatEvent:FireServer(Character,Message)
	end
end

return ChatFunctions
