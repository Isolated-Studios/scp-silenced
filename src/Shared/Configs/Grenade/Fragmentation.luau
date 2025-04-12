return {
	GrenadeType = "Fragmentation"; -- Type of grenade it plays in grenade module
	FuseTime = 1; -- Amount of time in seconds it takes to detonate
	
	GrenadeEffect = "Fragmentation"; -- Type of grenade effect that plays
	DestroyWhenDetonated = true; -- Destroy the model when detonated or after spreading is complete
	
	LowZone = 10; -- Inner zone of grenade
	MidZone = 50; -- Middle zone of grenade
	FarZone = 75; -- Outer zone of grenade
	
	GibChance = 0.4; -- Chance of gibbing when in damage zone for instant blast grenades (0 is 0%, 1 is 100%)
	
	LowZoneEffects = { -- What effects are played in the low zone
		["Disorientation"] = {
			Power = 1,
			Duration = 5,
		},
	};
	MidZoneEffects = { -- What effects are played in the mid zone
		["Disorientation"] = {
			Power = 1,
			Duration = 5,
		},
		["Bleed"] = {
			Power = 1,
			Duration = 10,
		},
	};
	FarZoneEffects = { -- What effects are played in the far zone
		["Disorientation"] = {
			Power = 1,
			Duration = 5,
		},
	};
}