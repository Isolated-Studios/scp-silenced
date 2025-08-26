local CodeNameBehavior = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TeamHandler = require(ReplicatedStorage.Modules.Interaction.TeamHandler)

CodeNameBehavior.UseCodeNames = {
	[0] = function(Player, OtherPlayer) -- Codenames are shown to no one.
		return false
	end,
	[1] = function(Player, OtherPlayer) -- Codenames are shown to all.
		return true
	end,
	[2] = function(Player, OtherPlayer) -- Codenames are shown to friendlies.
		if TeamHandler.Check(Player, OtherPlayer) == 0 then
			return true
		else
			return false
		end
	end,
	[3] = function(Player, OtherPlayer) -- Codenames are shown to enemies and neutrals.
		if TeamHandler.Check(Player, OtherPlayer) ~= 0 then
			return true
		else
			return false
		end
	end,
	[4] = function(Player, OtherPlayer) -- Codenames are shown to only members of the same team.
		if Player.Team == OtherPlayer.Team then
			return true
		else
			return false
		end
	end,
	[5] = function(Player, OtherPlayer) -- Codenames are shown to everyone except your own team.
		if Player.Team ~= OtherPlayer.Team then
			return true
		else
			return false
		end
	end,
}

return CodeNameBehavior
