local Settings = {
	Type = "Slashing"; -- Can be Blunt, Slashing, Stabbing. Blunt will slow players, slashing will bleed, stabbing will prevent healing.
	MaxDurability = 60; -- Maximum durability of the tool.
	AP = 0; -- Value between 0 and 1 (0 being no armor penetration, 1 being complete armor penetration)
	
	JabDamage = 10; -- How much damage a jab does.
	JabSpeed = 1; -- How fast a jab is in seconds.
	JabCost = 1; -- How much a jab costs (in durability) if it hits.
	JabDurabilityDamage = 1; -- How much damage it does to the victim's durability if they block a jab.
	
	AttackDamage = 10; -- How much damage an attack does.
	AttackSpeed = 1; -- How fast an attack is in seconds.
	AttackCost = 1; -- How much an attack costs (in durability) if it hits.
	AttackDurabilityDamage = 1; -- How much damage it does to the victim's durability if they block an attack.
	
	RiposteDamage = 10; -- How much damage a riposte does.
	RiposteSpeed = 1; -- How fast a riposte is in seconds.
	RiposteCost = 1; -- How much a riposte costs (in durability) if it hits.
	RiposteDurabilityDamage = 1; -- How much damage it does to the victim's durability if they block a riposte.
	
	BlockSpeed = 0.2; -- How fast a block is in seconds.
	EquipSpeed = .6; -- Speed of equipping in seconds.
	
	CanCombo = true; -- If true, can follow an attack immediately with another.
	ComboCount = 2; -- Amount of permissible follow-up attacks if CanCombo is true.
	
	BindToHand = true;
	RecoveryMarker = true;
	
	HighlightColor = Color3.fromRGB(100, 210, 210);
	Size = Vector2.new(5,2);
	Image = "rbxassetid://18387587518";
}
return Settings