local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local MAX_MESSAGE_COUNT = 4

local Player = Players.LocalPlayer
local HUD: ScreenGui = Player.PlayerGui:WaitForChild("HUD")
local MessageFrame: Frame = HUD:WaitForChild("MessageFrame")
local MessageTemplate: TextLabel = MessageFrame:WaitForChild("Message")
local Messages: Folder = MessageFrame:WaitForChild("Messages")

local Messager = {}

local function destroyMessage(Message: TextLabel, fadeTime: number)
	if Message.Parent == nil or Message:GetAttribute("Destroying") then return end
	Message:SetAttribute("Destroying", true)
	TweenService:Create(Message, TweenInfo.new(fadeTime), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
	task.delay(fadeTime, function(DestroyMessage)
		DestroyMessage:Destroy()
		-- We have UIListLayout at home
		for _, OtherMessage in pairs(Messages:GetChildren()) do
			OtherMessage.Name = tostring(tonumber(OtherMessage.Name) - 1)
		end
	end, Message) -- passing an argument to a single function instead of creating a new one for every different "Message"
				  -- for function cache optimization blah blah blah (actually this is called very rarely it prob wont impact much but why not)
end

-- Creates a message on the player's screen (right above the hp/stam bars) with the given Text
function Messager.SendMessage(Text: string, TextColor: Color3)
	local TextCharacters = #Text
	
	-- Creates a message
	local NewMessage = MessageTemplate:Clone()
	NewMessage.Text = Text
	NewMessage.TextColor3 = TextColor or NewMessage.TextColor3
	NewMessage.Parent = Messages
	local MessageCount = #Messages:GetChildren()
	NewMessage.Name = tostring(MessageCount)
	local newYSize = NewMessage.Size.Y.Scale * math.ceil(TextCharacters/69)
	NewMessage.Size = UDim2.fromScale(1, newYSize)
	NewMessage.Position = UDim2.fromScale(0, 1.174)
	
	-- Positions other messages up to make room for the new message
	for _, Message in pairs(Messages:GetChildren()) do
		if Message ~= NewMessage then
			local MessageNumber = tonumber(Message.Name)
			local otherMessageYPosition = Message.Position.Y.Scale
			-- Set a Goal just in case it is spammed
			if Message:GetAttribute("Goal") then
				otherMessageYPosition = Message:GetAttribute("Goal")
			end
			Message:SetAttribute("Goal", otherMessageYPosition - newYSize)
			TweenService:Create(
				Message,
				TweenInfo.new(0.5),
				{Position = UDim2.fromScale(0, otherMessageYPosition - newYSize)}
			):Play()
			if MessageCount - MessageNumber >= MAX_MESSAGE_COUNT then
				destroyMessage(Message, 0.3)
			end
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
	task.delay(3 + (TextCharacters/60) * 3, destroyMessage, NewMessage, 1)
end

return Messager
