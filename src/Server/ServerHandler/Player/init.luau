local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local PlayersFolder = ReplicatedStorage.Players
local PlayerDataTemplate = ServerStorage.PlayerDataTemplate
local Events = ReplicatedStorage.Events

function module.Init()
	local function PlayerAdded (Player)
		local playerData = PlayerDataTemplate:Clone()
		playerData.Name = Player.UserId
		playerData.Parent = PlayersFolder
		
		-- Fires when a player joins the game. PlayerDataHandler will deal with ProfileStore data storage.
		--(Disabled for now because roblox studio keeps lagging for some reason thx roblox)
		--require(script.PlayerDataHandler).Init(Player)
	end
	
	-- In case Players have joined the server earlier than this script ran:
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerAdded, player)
	end
	Players.PlayerAdded:Connect(PlayerAdded)
	
	require(script.GlobalChatHandler).Init()
end
return module
