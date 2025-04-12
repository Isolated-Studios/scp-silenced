local module = {}
function module.Init()
	local TextChatService = game:GetService("TextChatService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local TextService = game:GetService("TextService")
	local ChatEvent = ReplicatedStorage.Events.Character.ChatEvent
	local generalChannel: TextChannel = TextChatService:WaitForChild("TextChannels").RBXGeneral

	--//proximity chat
	local function getPositionFromUserId(userId: number)
		local targetPlayer = Players:GetPlayerByUserId(userId)
		if targetPlayer then
			local targetCharacter = targetPlayer.Character
			if targetCharacter then
				return targetCharacter:GetPivot().Position
			end
		end
		return Vector3.zero
	end

	generalChannel.ShouldDeliverCallback = function(textChatMessage: TextChatMessage, targetTextSource: TextSource)
		local sourcePos = getPositionFromUserId(textChatMessage.TextSource.UserId)
		local targetPos = getPositionFromUserId(targetTextSource.UserId)
		return (targetPos - sourcePos).Magnitude < 50
	end
	--\\
	
	ChatEvent.OnServerEvent:Connect(function(sendingPlayer, Character, Message)
		if sendingPlayer.Character == Character then
			for _,otherPlayer in pairs(Players:GetPlayers()) do
				if sendingPlayer ~= otherPlayer then 
					ChatEvent:FireClient(otherPlayer,Character,Message)
				end
			end
		end
	end)
end
return module
