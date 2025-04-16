local Settings = {
	Damage = 22; -- Base damage against target
	RPM = 100; -- The amount of rounds that can theoretically be fired in a minute
	AP = 0; -- Value between 0 and 1 (0 being no armor penetration, 1 being complete armor penetration)
	MagSize = 16; -- The maximum ammount of ammo held in a gun
	ReloadStyle = 0; -- 0 = single cartridge insert | 1 = mag reload
	BulletsPerShot = 1; -- The amount of projectiles fired from one shot (Shotgun)
	BurstAmount = 1; -- The amount of times fired per shot
	--BurstDelay = 0.05; -- The amount of time it takes to recover from each burst shot in seconds (AFFECTS FIRE SPEED)
	HeadshotFactor = 0.4; -- Damage + Damage * HeadshotFactor if head is shot
	LegMultiplier = 0.8; -- Damage * LegMultiplier if legs are hit. (is supposed to be <=1)
	CanDown = 60; -- If defined, non-headshots will down the target and will bleed out in the number defined.
	AmmoType = "Pistol"; -- What ammo it takes (Pistol , PDW , Handcannon , Rifle , Shotgun , LMG)
	Acceleration = Vector3.new(0, -workspace.Gravity, 0); -- the environmental force applied to bullet
	GibChance = 0.2;
	PitchLastBullets = 4; -- If greater than zero will gradually pitch up until fire sound is double in pitch. The number determines how many bullets you must have left before it starts pitching.
	Weight = 0; -- Does nothing right now

	AimFOV = 55; -- Field of view when aiming
	TravelSpeed = 3000; -- How fast the projectile is
	Casing = ".45"; -- What casing is ejected from Casings folder
	BulletTemplate = "OriginalTracer"; -- Tracer that is fired

	Automatic = false; -- Holding down the mouse button will cause the gun to continuously fire
	Bolted = true; -- Must manually chamber a round
	AutomaticBolt = true; -- Automatically bolt the gun if Bolted is true
	HeldWhenSqueezed = false; -- Must hold down the mouse button to squeeze a trigger if SqueezeTrigger is real
	--PlayHammerClick = false; -- Plays "BoltBack" from Sounds folder when hammer is pulled back
	RunAndGun = false; -- Running does not interrupt firing and bolting
	RunAndReload = true; -- Running does not interrupt reloading
	EmptyReload = true; -- Will use the ReloadEmpty animation when reloading if the mag is at zero
	BoltBackWhenEmpty = true;
	ScrollAffectsAim = true;

	EquipSpeed = 0.3; -- Speed of equipping in seconds
	--UnequipSpeed = 1;
	AimInSpeed = 0.5; -- Speed of aiming-in in seconds
	AimOutSpeed = 0.3; -- Speed of aiming-out in seconds
	--SqueezeTrigger = 0.2; -- How long it takes to squeeze the trigger to fire/bolt gun in seconds (AFFECTS FIRE SPEED)
	--FireDelay = 0.1; -- Delay after mouse button is clicked to fire gun (AFFECTS FIRE SPEED)
	--Reload1Speed = 0.6; -- Speed of Reload1's animation in seconds
	--Reload2Speed = 0.5; -- Speed of Reload2's animation in seconds
	--Reload3Speed = 0.6; -- Speed of Reload3's animation in seconds
	--ReloadEmptySpeed = 0.5; -- Speed of ReloadEmpty's animation in seconds. Only works if EmptyReload is true

	MinSpread = 1; -- Minimum bullet spread of gun
	MaxSpread = 20; -- Maximum bullet spread of gun
	SpreadCost = 4; -- How much is added onto bullet spread
	SpreadRegenWait = 1; -- How much time in seconds must pass before spread reduces
	XRecoilDampFactor = 1; -- The factor by which the x in (1/x) which is then multiplied by the recoil. x is the number of subsequent shots.
	YRecoilDampFactor = 1; -- By increasing this factor, dampening becomes faster which means the gun will stabilize faster.

	MaxDistance = 500; -- Maximum distance a bullet can travel.
	MidFallOffDist = 100; -- Studs from Shooter to Target in which damage enters the Medium Fall Off Zone. (Base Damage will Decrease.)
	LongFallOffDist = 150; -- Studs from Shooter to Target in which damage enters the Long Fall Off Zone. (Base Damage will Decrease.)
	MidFallOffMult = 0.75; -- Damage Multiplier applied to when damage enters the Medium Fall Off Zone.
	LongFallOffMult = 0.50; -- Damage Multiplier applied to when damage enters the Long Fall Off Zone.

	CameraShove = Vector3.new(4,0.01,0.2); -- Shove applied to camera when recoiled
	LinearShove = Vector3.new(-0.1,0.1,.1); -- Linear shove applied to viewmodel when recoiled
	AngularShove = Vector3.new(5,0,0); -- Angular shove applied to viewmodel when recoiled

	HighlightColor = Color3.fromRGB(100, 210, 210);
	Size = Vector2.new(1,1); -- Does nothing right now
	Image = "rbxassetid://0"; -- Does nothing right now
	Description = "" -- Does nothing right now
}
return Settings
