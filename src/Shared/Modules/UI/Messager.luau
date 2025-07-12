local TweenService = game:GetService("TweenService")

local Messager = {}

-- Creates a message on the player's screen (right above the hp/stam bars) with the given Text
function Messager.SendMessage (Player: Player, Text: string, TextColor: Color3)
	local TextCharacters = #Text
	local HUD: ScreenGui = Player.PlayerGui:WaitForChild("HUD")
	local MessageFrame: Frame = HUD:WaitForChild("MessageFrame")
	local Message: TextLabel = MessageFrame:WaitForChild("Message")
	local Messages: Folder = MessageFrame:WaitForChild("Messages")
	
	-- Creates a message
	local NewMessage = Message:Clone()
	NewMessage.Text = Text
	NewMessage.TextColor3 = TextColor or NewMessage.TextColor3
	NewMessage.Parent = Messages
	local Count = #Messages:GetChildren()
	NewMessage.Name = tostring(Count)
	local newYSize = NewMessage.Size.Y.Scale * math.ceil(TextCharacters/69)
	NewMessage.Size = UDim2.fromScale(1, newYSize)
	NewMessage.Position = UDim2.fromScale(0, 1.174)
	
	-- Positions other messages up to make room for the new message
	for _, otherMessages in pairs(Messages:GetChildren()) do
		if otherMessages ~= NewMessage then
			local ActualPosition = 0
			local otherMessageYPosition = otherMessages.Position.Y.Scale
			-- Set a Goal just in case it is spammed
			if otherMessages:GetAttribute("Goal") then
				otherMessageYPosition = otherMessages:GetAttribute("Goal")
			end
			otherMessages:SetAttribute("Goal", otherMessageYPosition - newYSize)
			TweenService:Create(
				otherMessages,
				TweenInfo.new(0.5),
				{Position = UDim2.fromScale(0, otherMessageYPosition - newYSize)}
			):Play()
		end
	end
	
	-- Position the new message
	NewMessage:SetAttribute("Goal", 1)
	TweenService:Create(
		NewMessage,
		TweenInfo.new(0.5),
		{TextTransparency = 0.4, TextStrokeTransparency = 0.69, Position = UDim2.fromScale(0, 1)}
	):Play()
	
	-- Despawns the new message based on text character length
	task.delay(3 + (TextCharacters/60) * 3, function()
		TweenService:Create(NewMessage, TweenInfo.new(1), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		task.wait(1)
		NewMessage:Destroy()
		-- We have UIListLayout at home
		for _, otherMessages in pairs(Messages:GetChildren()) do
			otherMessages.Name = tostring(tonumber(otherMessages.Name) - 1)
		end
	end)
end

return Messager
