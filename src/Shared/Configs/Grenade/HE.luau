return {
	GrenadeType = "HE"; -- Type of grenade it plays in grenade module
	FuseTime = 1; -- Amount of time in seconds it takes to detonate
	
	GrenadeEffect = "HE"; -- Type of grenade effect that plays
	DestroyWhenDetonated = true; -- Destroy the model when detonated or after spreading is complete
	
	LowZone = 20; -- Inner zone of grenade
	MidZone = 40; -- Middle zone of grenade
	FarZone = 75; -- Outer zone of grenade
	
	LowZoneEffects = { -- What effects are played in the low zone
		["Disorientation"] = {
			Power = 1,
			Duration = 8,
		},
	};
	MidZoneEffects = { -- What effects are played in the mid zone
		["Disorientation"] = {
			Power = 1,
			Duration = 8,
		},
	};
	FarZoneEffects = { -- What effects are played in the far zone
		["Disorientation"] = {
			Power = 1,
			Duration = 8,
		},
	};
}