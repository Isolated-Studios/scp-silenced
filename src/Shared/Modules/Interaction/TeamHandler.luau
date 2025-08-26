local module = {}

local Projections = game:GetService("ReplicatedStorage").RoundElements.Projections
local Gamemode = Projections.Gamemode
local FreeToKill = Projections.FreeToKill

local PlayingTeams = {
	"Class-D",
	"Facility Personnel"
}

module.Chart = { -- 0 = Friendly , 1 = Enemy , 2 = Neutral
	["Menu"] = {
		["Menu"] = 0,
		["Lobby"] = 0,
		["Facility Personnel"] = 0,
		["Class-D"] = 0,
		["Not Playing"] = 0,
	},
	["Not Playing"] = {
		["Menu"] = 2,
		["Lobby"] = 0,
		["Facility Personnel"] = 2,
		["Class-D"] = 2,
		["Not Playing"] = 0,
	},
	["Lobby"] = {
		["Menu"] = 2,
		["Lobby"] = 0,
		["Facility Personnel"] = 2,
		["Class-D"] = 2,
		["Not Playing"] = 0,
	},
	["Facility Personnel"] = {
		["Menu"] = 0,
		["Lobby"] = 0,
		["Facility Personnel"] = 0,
		["Class-D"] = 1,
		["Not Playing"] = 0,
	},
	["Class-D"] = {
		["Menu"] = 0,
		["Lobby"] = 0,
		["Facility Personnel"] = 1,
		["Class-D"] = 0,
		["Not Playing"] = 0,
	},
}

function module.Check (Caster: Player, Target: Player)
	if not Caster.Neutral and module.Chart[Caster.Team.Name] and Caster and Target then
		if not module.Chart[Caster.Team.Name][Target.Team.Name] then 
			warn("Could not find Caster and/or Target teams in chart") 
		end

		-- If FFA or FreeToKill then any playing players may hurt eachother.
		if table.find(PlayingTeams, Caster.Team.Name)
			and table.find(PlayingTeams, Target.Team.Name)
			and (Gamemode.Value == "FreeToKill" or FreeToKill.Value == true)
		then
			return 1
		end

		return module.Chart[Caster.Team.Name][Target.Team.Name] or 2
	else
		return 2
	end
end
return module
