local Settings = {
	HealAmount = 65; -- How much health is restored.
	HealSpeed = 5;
	MaxDurability = 65;
	DestroyStatusEffects = { -- Status effects that are destroyed.
		"Bleeding",
		"Burning",
	};
	StatusEffects = { -- Status effects that are given.

	};
	
	ReviveHealth = 50; -- How much health the player has after being revived.
	ReviveTime = 2; -- How long it takes in seconds to revive a player.
	
	HasEndMarker = 0.7; -- If number is defined, Apply and/or Aid animation will apply the effects during "End" animation marker. The number determines amount of seconds when the server destroys the tool.
	EquipSpeed = 0.1;
	
	CanRevive = true; -- If true, can be used to revive players.
	HealOthers = true; -- If true, can heal other players.
	RequireHarm = true; -- If true, requires the player to be harmed to use.
	UseDurability = true; -- If true, will use 1 durability each use (Unless HealthAsDurability is true).
	HealthAsDurability = true; -- If true, makes it so the total amount of health healed is the amount of durability consumed.
	HasAidAnimation = false; -- If true, will use the Aid animation when healing other players
	BindToHand = true;
	
	HighlightColor = Color3.fromRGB(100, 210, 210);
	Size = Vector2.new(1,2); -- Inventory Size
	Image = "rbxassetid://18387305281"; -- Inventory Image
	Description = "" -- Does nothing right now
}
return Settings