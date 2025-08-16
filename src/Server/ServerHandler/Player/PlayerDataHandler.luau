-- I really should have set this up at the beginning when I wasn't storing everything in physical values but I think I can work with this.
local PlayerDataHandler = {}

-- Services
local ServerScriptStorage = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

-- Modules
local ProfileStore = require(ServerScriptStorage.ServerStoredModules.ProfileStore)

-- Events
local DataEvents = ReplicatedStorage.Events.Data

local SaveSettingChange = DataEvents.SaveSettingChange
local StatChange = DataEvents.StatChange

-- ProfileStore setup
local TemplateSettings = ServerStorage.PlayerDataTemplate.Settings
local TemplateStats = ServerStorage.PlayerDataTemplate.Stats
local GatheredSettingDefaults = {}
local GatheredStatDefaults = {}

for _,Setting in pairs(TemplateSettings:GetDescendants()) do
	if not Setting:IsA("Folder") then
		GatheredSettingDefaults[Setting.Name] = Setting:GetAttribute("Default")
	end
end

for _,Stat in pairs(TemplateStats:GetDescendants()) do
	if not Stat:IsA("Folder") then
		GatheredStatDefaults[Stat.Name] = Stat:GetAttribute("Default")
	end
end

local ProfileTemplate = {
	Settings = GatheredSettingDefaults,
	Stats = GatheredStatDefaults,
}
local PlayerStore = ProfileStore.New("PlayerStore", ProfileTemplate)

if RunService:IsStudio() == true then
	PlayerStore = PlayerStore.Mock
end

local Profiles: {[player]: typeof(PlayerStore:StartSessionAsync())} = {}

function PlayerDataHandler.Init (Player)
	-- Start profile session for player's data
	local Profile = PlayerStore:StartSessionAsync(`{Player.UserId}`, {
		Cancel = function()
			return Player.Parent ~= Players
		end,
	})
	-- Handle new profile session or failure to start new session.
	if Profile then
		Profile:AddUserId(Player.UserId)
		Profile:Reconcile() -- This fills any missing variables in from our ProfileTemplate

		-- Kick the player out because the session has ended
		Profile.OnSessionEnd:Connect(function()
			Profiles[Player] = nil
			Player:Kick("Profile Session has ended. Please rejoin.")
		end)

		-- Player exists, load profile.
		if Player.Parent == Players then
			Profiles[Player] = Profile
		else
			-- Player left before profile session was started.
			Profile:EndSession()
		end

		for _,Setting in pairs(ReplicatedStorage.Players[tostring(Player.UserId)].Settings:GetDescendants()) do
			if not Setting:IsA("Folder") then
				Setting.Value = Profile.Data.Settings[Setting.Name]
			end
		end

		for _,Stat in pairs(ReplicatedStorage.Players[tostring(Player.UserId)].Stats:GetDescendants()) do
			if not Stat:IsA("Folder") then
				Stat.Value = Profile.Data.Stats[Stat.Name]
			end
		end

	else
		-- This should really only happen if the Roblox server shuts down.
		Player:Kick("Server shutdown. Please rejoin.")
	end
end

-- End session when player leaves
Players.PlayerRemoving:Connect(function(Player)
	local Profile = Profiles[Player]
	if Profile ~= nil then
		Profile:EndSession()
	end
end)

-- Very low security because it is just settings. (only checks if player firing is the same player modifying the profile) 
SaveSettingChange.OnServerEvent:Connect(function(Player, Setting, NewValue)
	-- Check if the player owns the settings they are modifying.
	if Setting and NewValue and tonumber(Setting.Parent.Parent.Parent.Name) == Player.UserId then
		-- Set the value in the profile and the value object.
		local Profile = Profiles[Player]
		Setting.Value = NewValue
		Profile.Data.Settings[Setting.Name] = NewValue
	end
end)

StatChange.Event:Connect(function(Player, Stat, NewValue)
	if Stat and NewValue then
		local Profile = Profiles[Player]
		Stat.Value = NewValue
		Profile.Data.Stats[Stat.Name] = NewValue
	end
end)

return PlayerDataHandler