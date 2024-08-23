local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PlayersFolder = ReplicatedStorage.Players
local PlayerDataTemplate = ServerStorage.PlayerDataTemplate
local Events = ReplicatedStorage.Events

function module.Init()
	game.Players.PlayerAdded:Connect(function(Player)
		local playerData = PlayerDataTemplate:Clone()
		playerData.Name = Player.UserId
		playerData.Parent = PlayersFolder
	end)
	
	require(script.GlobalChatHandler).Init()
end
return module
