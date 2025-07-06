local module = {}
module.Chart = { -- 0 = Friendly , 1 = Enemy , 2 = Neutral
	["Tester"] = {
		["Tester"] = 2,
	}
}

function module.Check (Caster: Player, Target: Player)
	if not Caster.Neutral and module.Chart[Caster.Team.Name] and Caster and Target then
		if not module.Chart[Caster.Team.Name][Target.Team.Name] then warn("Could not find Caster and/or Target teams in chart") end
		return module.Chart[Caster.Team.Name][Target.Team.Name] or 2
	else
		return 2
	end
end
return module
