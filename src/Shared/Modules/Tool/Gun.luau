local ToolClass = require(script.Parent)

--[[
	====== TYPE DEFINITIONS ======
	
	This section defines the custom type for 'Tool', and some other
	useful definitions such as the custom Enum 'Tool.State'.
]]

export type ClassType = ToolClass.ClassType & {
	Damage: number,
	RPM: number,
	AP: number,
	MagSize: number,
	ReloadStyle: number,
	BulletsPerShot: number,
	BurstAmount: number,
	--BurstDelay: number,
	HeadshotFactor: number,
	LegMultiplier: number,
	CanDown: number,
	AmmoType: string,
	Acceleration: Vector3,
	GibChance: number,
	PitchLastBullets: number,
	Weight: number,

	AimFOV: number,
	TravelSpeed: number,
	Casing: string,
	BulletTemplate: string,
	RunType: number,

	Automatic: boolean,
	Bolted: boolean,
	AutomaticBolt: boolean,
	HeldWhenSqueezed: boolean,
	--PlayHammerClick: boolean,
	RunAndGun: boolean,
	RunAndReload: boolean,
	EmptyReload: boolean,
	BoltBackWhenEmpty: boolean,
	ScrollAffectsAim: boolean,

	AimInSpeed: number,
	AimOutSpeed: number,
	--SqueezeTrigger: number,
	--FireDelay: number,
	Reload1Speed: number,
	--Reload2Speed: number,
	--Reload3Speed: number,
	ReloadEmptySpeed: number,

	MinSpread: number,
	MaxSpread: number,
	SpreadCost: number,
	SpreadRegenWait: number,
	ReductionIncrement: number,
	ReductionWait: number,
	XRecoilDampFactor: number,
	YRecoilDampFactor: number,
	XRecoilDampExponent: number,
	YRecoilDampExponent: number,

	MaxDistance: number,
	MidFallOffDist: number,
	LongFallOffDist: number,
	MidFallOffMult: number,
	LongFallOffMult: number,

	CameraShove: Vector3,
	LinearShove: Vector3,
	AngularShove: Vector3,
	AimLinearShove: Vector3,
	AimAngularShove: Vector3,
	Stability: number?,
	AimStability: number?,

	RunPosition: {number}?,
	CrouchPosition: {number}?,
}

local Gun = setmetatable({}, ToolClass)
Gun.__index = Gun

--[[
	====== FUNCTION DEFINITIONS ======

	Functions defined here are statically accessible; they are not linked
	to any particular object. This includes the new object function and
	other utilities.
]]

function Gun.new(Tool: Tool, data: ClassType): ClassType
	local self: ClassType = setmetatable(ToolClass.new(Tool, data), Gun)
	
	self.Bolted = false

	return self
end

--[[
	====== METHOD DEFINITIONS ======

	Functions defined here are associated with unique objects.
	This includes functions for animation handling, default methods, etc.
]]
	
function Gun:Equip()
	if self.State ~= ToolClass.State.Unequipped then return end
	self.State = ToolClass.State.Equipping
	ToolClass.getHumanoid():EquipTool(self.Instance)
	if self.Bolted then
		self:PlayAnimationFor("Equip", self.EquipSpeed)
	else
		self:PlayAnimation("FirstEquip")
	end
	self.__task = task.delay(self.EquipSpeed, self.PlayAnimation, self, "Hold")
	task.wait(self.EquipCancel)
	self.Bolted = true -- !!TODO: Link this to an animation event instead maybe? So bolting matches with the animation
	self:__enable()
end

function Gun:Unequip()
	if self.State ~= ToolClass.State.Equipped then return end
	self:StopAnimation("FirstEquip", math.min(0.2, self.UnequipSpeed))
	ToolClass.Unequip(self)
end

return Gun
