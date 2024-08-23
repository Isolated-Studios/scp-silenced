return {
	GrenadeType = "Incendiary"; -- Type of grenade it plays in grenade module
	FuseTime = 0; -- Amount of time in seconds it takes to detonate
	Duration = 20; -- How long the cells last for in seconds
	SpreadRate = 0.1; -- How fast cell radius expands in seconds
	CellRadius = 4; -- Radius of the cell zone in amount of cells
	DispelTime = 5; -- How fast cells disappear after duration is over in seconds
	
	GrenadeEffect = "Incendiary"; -- Type of grenade effect that plays.
	DestroyWhenDetonated = true; -- Destroy the model when detonated or after spreading is complete
	
	EnterZoneEffects = { -- What effects are played when entering cell zone
		["Burning"] = {
			Power = 2,
			Duration = 999999,
		},
	};
	ExitZoneEffects = { -- What effects are played when exiting cell zone
		["Burning"] = {
			Power = 1,
			Duration = 5,
		},
	}
}