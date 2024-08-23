local Settings = {
	Damage = 30; -- Base damage against target
	RPM = 600; -- The amount of rounds that can theoretically be fired in a minute
	AP = 0; -- Value between 0 and 1 (0 being no armor penetration, 1 being complete armor penetration)
	MagSize = 6; -- The maximum ammount of ammo held in a gun
	BulletsPerShot = 1; -- The amount of projectiles fired from one shot (Shotgun)
	BurstAmount = 1; -- The amount of times fired per shot
	--BurstDelay = 0.05; -- The amount of time it takes to recover from each burst shot in seconds (AFFECTS FIRE SPEED)
	HeadshotFactor = 0.5; -- Damage + Damage * HeadshotFactor if head is shot
	AmmoType = "Handcannon"; -- What ammo it takes (Pistol , PDW , Handcannon , Rifle , Shotgun , LMG)
	Acceleration = Vector3.new(0, -workspace.Gravity, 0); -- the environmental force applied to bullet
	Weight = 0; -- Does nothing right now
	
	AimFOV = 55; -- Field of view when aiming
	TravelSpeed = 3000; -- How fast the projectile is
	Casing = ".45"; -- What casing is ejected from Casings folder
	
	Automatic = false; -- Holding down the mouse button will cause the gun to continuously fire
	Bolted = true; -- Must manually chamber a round
	AutomaticBolt = false; -- Automatically bolt the gun if Bolted is true
	HeldWhenSqueezed = false; -- Must hold down the mouse button to squeeze a trigger if SqueezeTrigger is real
	PlayHammerClick = true; -- Plays "BoltBack" from Sounds folder when hammer is pulled back
	RunAndGun = false; -- Running does not interrupt firing and bolting
	RunAndReload = false; -- Running does not interrupt reloading
	EmptyReload = false; -- Will use the ReloadEmpty animation when reloading if the mag is at zero
	
	EquipSpeed = 0.8; -- Speed of equipping in seconds
	AimInSpeed = 0.5; -- Speed of aiming-in in seconds
	AimOutSpeed = 0.3; -- Speed of aiming-out in seconds
	SqueezeTrigger = 0.2; -- How long it takes to squeeze the trigger to fire/bolt gun in seconds (AFFECTS FIRE SPEED)
	FireDelay = 0.1; -- Delay after mouse button is clicked to fire gun (AFFECTS FIRE SPEED)
	Reload1Speed = 0.6; -- Speed of Reload1's animation in seconds
	Reload2Speed = 0.5; -- Speed of Reload2's animation in seconds
	Reload3Speed = 0.6; -- Speed of Reload3's animation in seconds
	ReloadEmptySpeed = 0.5; -- Speed of ReloadEmpty's animation in seconds. Only works if EmptyReload is true
	
	MinSpread = 1; -- Minimum bullet spread of gun
	MaxSpread = 10; -- Maximum bullet spread of gun
	SpreadCost = 3; -- How much is added onto bullet spread
	SpreadRegenWait = 1; -- How much time in seconds must pass before spread reduces
	XRecoilDamp = 0; -- Does nothing right now
	YRecoilDamp = 0; -- Does nothing right now
	
	CameraShove = Vector3.new(4,0.01,0.2); -- Shove applied to camera when recoiled
	LinearShove = Vector3.new(0,0,2); -- Linear shove applied to viewmodel when recoiled
	AngularShove = Vector3.new(30,0,0); -- Angular shove applied to viewmodel when recoiled
	
	HammerAngle = Vector3.new(70,0,0); -- Angle at which Hammer is pulled back when preparing to fire. Comment out if no Hammer or Hammer should not move 
	CylinderAngle = Vector3.new(0,0,-60); -- Angle at which Cylinder is pulled back when preparing to fire. Comment out if no Cylinder or Cylinder should not move
	
	Size = Vector2.new(1,1); -- Does nothing right now
	Image = "rbxassetid://0"; -- Does nothing right now
	Description = "" -- Does nothing right now
}
return Settings