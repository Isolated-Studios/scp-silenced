local Settings = {
	GrenadeType = "Smoke"; -- What grenade config to grab from when exploding
	BulletTemplate = "M18 Smoke"; -- Tracer that is fired
	LandType = 1; -- 0 = Destroy when landed | 1 = Grenade-ify when landed | 2 = Turn into a tool when landed
	MaxBounces = 3; -- Amount of times tracer will bounce before landing
	ThrowPower = { -- Power of the toss respective to the Cursor arrows
		[1] = 40,
		[2] = 80,
		[3] = 120
	};
	
	TravelSpeed = 200; -- How fast the projectile is
	Acceleration = Vector3.new(0,-workspace.Gravity/2,0); -- the environmental force applied to bullet
	
	EquipSpeed = 0.1; -- Speed of equipping in seconds
	
	BindToHand = true; 
	
	LoadoutAmount = 2; -- Amount of item given when selecting a loadout.
	HighlightColor = Color3.fromRGB(100, 210, 210);
	InventorySize = Vector2.new(1,1); -- Size in inventory
	InventoryImage = "rbxassetid://84504723529526"; -- Icon in inventory
	Description = "" -- Description of the item
}
return Settings
