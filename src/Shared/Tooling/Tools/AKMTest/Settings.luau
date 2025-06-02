local Settings = {
	Damage = 25; -- Base damage against target
	RPM = 550; -- The amount of rounds that can theoretically be fired in a minute
	AP = .6; -- Value between 0 and 1 (0 being no armor penetration, 1 being complete armor penetration)
	MagSize = 30; -- The maximum ammount of ammo held in a gun
	ReloadStyle = 1; -- 0 = single cartridge insert | 1 = mag reload
	BulletsPerShot = 1; -- The amount of projectiles fired from one shot (Shotgun)
	BurstAmount = 1; -- The amount of times fired per shot
	--BurstDelay = 0.05; -- The amount of time it takes to recover from each burst shot in seconds (AFFECTS FIRE SPEED)
	HeadshotFactor = 0.4; -- Damage + Damage * HeadshotFactor if head is shot
	LegMultiplier = 0.8; -- Damage * LegMultiplier if legs are hit. (is supposed to be <=1)
	CanDown = 60; -- If defined, non-headshots will down the target and will bleed out in the number defined.
	AmmoType = "Rifle"; -- What ammo it takes (Pistol , PDW , Handcannon , Rifle , Shotgun , LMG)
	Acceleration = Vector3.new(0, -workspace.Gravity, 0); -- the environmental force applied to bullet
	GibChance = 0.5;
	PitchLastBullets = 10; -- If greater than zero will gradually pitch up until fire sound is double in pitch. The number determines how many bullets you must have left before it starts pitching.
	Weight = 0; -- Does nothing right now

	AimFOV = 35; -- Field of view when aiming
	TravelSpeed = 3000; -- How fast the projectile is
	Casing = ".45"; -- What casing is ejected from Casings folder
	BulletTemplate = "OriginalTracer"; -- Tracer that is fired
	RunType = 1; -- Controls the run animation that will play on the viewmodel. 1 is rifle running, 2 is pistol running.

	Automatic = true; -- Holding down the mouse button will cause the gun to continuously fire
	Bolted = false; -- Must manually chamber a round
	AutomaticBolt = false; -- Automatically bolt the gun if Bolted is true
	HeldWhenSqueezed = false; -- Must hold down the mouse button to squeeze a trigger if SqueezeTrigger is real
	--PlayHammerClick = false; -- Plays "BoltBack" from Sounds folder when hammer is pulled back
	RunAndGun = false; -- Running does not interrupt firing and bolting
	RunAndReload = true; -- Running does not interrupt reloading
	EmptyReload = true; -- Will use the ReloadEmpty animation when reloading if the mag is at zero
	BoltBackWhenEmpty = false;
	ScrollAffectsAim = true;

	EquipSpeed = 0.75; -- Speed of equipping in seconds
	EquipCancel = 0.5;
	UnequipSpeed = 0.75;
	AimInSpeed = 0.35; -- Speed of aiming-in in seconds
	AimOutSpeed = 0.35; -- Speed of aiming-out in seconds
	--SqueezeTrigger = 0.2; -- How long it takes to squeeze the trigger to fire/bolt gun in seconds (AFFECTS FIRE SPEED)
	--FireDelay = 0.1; -- Delay after mouse button is clicked to fire gun (AFFECTS FIRE SPEED)
	Reload1Speed = 3.00; -- Speed of Reload1's animation in seconds
	--Reload2Speed = 0.5; -- Speed of Reload2's animation in seconds
	--Reload3Speed = 0.6; -- Speed of Reload3's animation in seconds
	ReloadEmptySpeed = 3.5; -- Speed of ReloadEmpty's animation in seconds. Only works if EmptyReload is true

	MinSpread = 0; -- Minimum bullet spread of gun
	MaxSpread = 10; -- Maximum bullet spread of gun
	SpreadCost = 0.5; -- How much is added onto bullet spread
	SpreadRegenWait = 0.25; -- How much time in seconds must pass before spread reduces
	ReductionIncrement = 0.5; --The incremental amount bulletspread is reduced to its MinSpread
	ReductionWait = 0.01; --The amount of time for each wait in the reduction spread loop
	XRecoilDampFactor = 1; -- The factor by which the x in (1/x) which is then multiplied by the recoil. x is the number of subsequent shots.
	YRecoilDampFactor = 1; -- By increasing this factor, dampening becomes faster which means the gun will stabilize faster.
	XRecoilDampExponent = -1/4; -- Exponent applied to each subsequent shot when accounting for recoil dampening of the x axis.
	YRecoilDampExponent = -1/2; -- Exponent applied to each subsequent shot when accounting for recoil dampening of the y axis.

	MaxDistance = 500; -- Maximum distance a bullet can travel.
	MidFallOffDist = 100; -- Studs from Shooter to Target in which damage enters the Medium Fall Off Zone. (Base Damage will Decrease.)
	LongFallOffDist = 150; -- Studs from Shooter to Target in which damage enters the Long Fall Off Zone. (Base Damage will Decrease.)
	MidFallOffMult = 0.75; -- Damage Multiplier applied to when damage enters the Medium Fall Off Zone.
	LongFallOffMult = 0.50; -- Damage Multiplier applied to when damage enters the Long Fall Off Zone.

	CameraShove = Vector3.new(15,0.1,0); -- Shove applied to camera when recoiled
	LinearShove = Vector3.new(0.5,0.5,1); -- Linear shove applied to viewmodel when recoiled
	AngularShove = Vector3.new(1,0.25,.25); -- Angular shove applied to viewmodel when recoiled
	AimLinearShove = Vector3.new(0,0,5); -- Linear shove applied to the viewmodel when aiming and recoiled.
	AimAngularShove = Vector3.new(0,0,0); -- Angular shove applied to the viewmodel when aiming and recoiled.
	Stability = nil; -- Determines the torque of the gun when recoiling. Lower number is more unstable (more torque), Higher is more stable (less torque).
	AimStability = nil; -- Determines the torque of the gun when recoiling and aiming. Lower number is more unstable (more torque), Higher is more stable (less torque).
	
	RunPosition = nil; -- Table of numbers {1,2,3,4,5,6}. Overrides the run positions, allowing custom run positions. 1 is Front position, 2 is Up position, 3 is Side position, 4 is Front angle, 5 is Up angle, 6 is Side angle.
	CrouchPosition = nil; -- Table of numbers {1,2,3,4,5,6}. Overrides the crouch positions, allowing custom crouch positions. 1 is Front position, 2 is Up position, 3 is Side position, 4 is Front angle, 5 is Up angle, 6 is Side angle.

	HighlightColor = Color3.fromRGB(100, 210, 210);
	Size = Vector2.new(6,3); -- Does nothing right now
	Image = "rbxassetid://10811553601"; -- Does nothing right now
	Description = "A reliable Soviet-era rifle used by a wide variety of groups, especially those based outside of the US and Western Europe. Despite lower than average RPM, the 7.62x39mm rounds it fires have substantial stopping power. " -- Does nothing right now
}
return Settings
