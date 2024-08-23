return {
	GrenadeType = "Smoke"; -- Type of grenade it plays in grenade module
	FuseTime = 0; -- Amount of time in seconds it takes to detonate
	Duration = 20; -- How long the cells last for in seconds
	SpreadRate = 0.1; -- How fast cell radius expands in seconds
	CellRadius = 4; -- Radius of the cell zone in amount of cells
	DispelTime = 20; -- How fast cells disappear after duration is over in seconds
	
	GrenadeEffect = "Smoke"; -- Type of grenade effect that plays.
	DestroyWhenDetonated = true; -- Destroy the model when detonated or after spreading is complete
	
	EnterZoneEffects = { -- What effects are played when entering cell zone
		["Blindness"] = {
			Power = 1,
			Duration = 999999,
		},
	};
	ExitZoneEffects = { -- What effects are played when exiting cell zone
		["Blindness"] = {
			Power = 1,
			Duration = 0.1,
		},
	}
}