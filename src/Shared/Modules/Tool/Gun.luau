local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolClass = require(script.Parent)
local Utils = require(ReplicatedStorage.Modules.Utils)

--[[
	====== TYPE DEFINITIONS ======
	
	This section defines the custom type for 'Tool', and some other
	useful definitions such as the custom Enum 'Tool.State'.
]]

local Gun = setmetatable({}, ToolClass)
Gun.__index = Gun
Gun.ClassName = "Gun"

export type ClassType = ToolClass.ClassType & typeof(setmetatable(
	{} :: {
		Bolted: boolean;
		Ammo: number;
		
		Settings: {
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
		};
	},
	Gun
))

--[[
	====== FUNCTION DEFINITIONS ======

	Functions defined here are statically accessible; they are not linked
	to any particular object. This includes the new object function and
	other utilities.
]]

function Gun.new(Tool: Tool): ClassType
	local self: ClassType = setmetatable(ToolClass.new(Tool), Gun)
	assert(self.Handle, `Gun {Tool:GetFullName()} is missing a Handle`)
	
	self.Bolted = false
	self.Ammo = self.Settings.MagSize
	
	self.Bindings["Fire"] = {
		InputType = Enum.UserInputType.MouseButton1;
		InputState = Enum.UserInputState.Begin;
		DebugBinding = true; -- so the KeybindHandler doesn't constantly get called and print warnings for no reason.
		Handler = Utils.wrapMethod(self, self.Click);
	}
	self.Bindings["R1"] = {
		InputType = Enum.UserInputType.Keyboard;
		InputState = Enum.UserInputState.Begin;
		DebugBinding = Enum.KeyCode.H;
		Handler = Utils.wrapMethod(self, self.Reload);
	}
	self.Bindings["R2"] = {
		InputType = Enum.UserInputType.Keyboard;
		InputState = Enum.UserInputState.Begin;
		DebugBinding = Enum.KeyCode.J;
		Handler = Utils.wrapMethod(self, self.Reload);
	}
	self.Bindings["R3"] = {
		InputType = Enum.UserInputType.Keyboard;
		InputState = Enum.UserInputState.Begin;
		DebugBinding = Enum.KeyCode.K;
		Handler = Utils.wrapMethod(self, self.Reload);
	}
	
	self.AnimationEvents = {
		-- DEPRECATED, PLEASE USE "Sound" EVENT FOR SOUNDS
		["LoadGate"] = function()
			Utils.SFX.playSound(self.Sounds,"GateOpen",self.Handle,true,true)
		end,
		["LoadGateClose"] = function()
			Utils.SFX.playSound(self.Sounds,"GateClose",self.Handle,true,true)
		end,
		["EjectShell"] = function()
			-- dispenseCasing()
			Utils.SFX.playSound(self.Sounds,"Eject",self.Handle,true,true)
		end,
		["InsertShell"] = function()
			Utils.SFX.playSound(self.Sounds,"Insert",self.Handle,true,true)
		end,
		["MagOut"] = function()
			Utils.SFX.playSound(self.Sounds,"MagOut",self.Handle,true,true)
		end,
		["MagIn"] = function()
			Utils.SFX.playSound(self.Sounds,"MagIn",self.Handle,true,true)
		end,
		["BoltBack"] = function()
			Utils.SFX.playSound(self.Sounds,"BoltBack",self.Handle,true,true)
		end,
		--\
		["Sound"] = function(SoundName)
			if self.Sounds:FindFirstChild(SoundName) then
				Utils.SFX.playSound(self.Sounds,SoundName,self.Handle,true,true)
			else
				warn("Sound animation event call error. Could not find sound named: ".. SoundName.." in folder.")
			end
		end,
		
		-- ["Hide"] = function(Target) -- Hide a part and replicate it to others
		-- 	if MotorModel:FindFirstChild(Target) then
		-- 		if not table.find(ModificationList,Target) then
		-- 			print("wow!")
		-- 			MotorModel[Target]:SetAttribute("OrigicalTransparency",MotorModel[Target].Transparency)
		-- 			table.insert(ModificationList,Target)
		-- 		end
		-- 		MotorModel[Target].Transparency = 1
		-- 		AnimationModifier:FireServer("Transparency",1,Tool,Target)
		-- 	end
		-- end,
		-- ["Appear"] = function(Target) -- Make a part appear replicate it to others
		-- 	if MotorModel:FindFirstChild(Target) then
		-- 		if not table.find(ModificationList,Target) then
		-- 			MotorModel[Target]:SetAttribute("OrigicalTransparency",MotorModel[Target].Transparency)
		-- 			table.insert(ModificationList,Target)
		-- 		end
		-- 		MotorModel[Target].Transparency = 0
		-- 		AnimationModifier:FireServer("Transparency",0,Tool,Target)
		-- 	end
		-- end,
		-- ["ReloadMag"] = function()
		-- 	if Settings.ReloadStyle == 0 then
		-- 		magBool.Value += 1
		-- 		ammoBool.Value -= 1
		-- 		SetItemHolder:FireServer(Tool,"Mag",magBool.Value)
		-- 	else
		-- 		local AmmoToUse = math.min(Settings.MagSize - magBool.Value,ammoBool.Value)
		-- 		magBool.Value += AmmoToUse
		-- 		ammoBool.Value -= AmmoToUse
		-- 		Reloading = false
		-- 	end
		-- end,
		-- ["FirstShellTransparency"] = function(transparency)
		-- 	if MotorModel:FindFirstChild("1") then
		-- 		MotorModel["1"].Transparency = transparency
		-- 	end
		-- end,
		-- ["BulletTransparency"] = function(transparency)
		-- 	if MotorModel:FindFirstChild("Bullet") then
		-- 		MotorModel["Bullet"].Transparency = transparency
		-- 	end
		-- end,
		["BoltForward"] = function()
			Utils.SFX.playSound(self.Sounds,"BoltForward",self.Handle,true,true)

			-- if magBool.Value == 0 and Settings.BoltBackWhenEmpty and Handle:FindFirstChild("Bolt") then
			-- 	local Bolt = Handle.Bolt
			-- 	TweenService:Create(Bolt,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{C1 = DefaultBoltC1}):Play()
			-- 	Tool:SetAttribute("BoltSet",nil)
			-- end
		end,

		-- ["BoltRound"] = function()
		-- 	assert(Settings.BoltRoundEvent ~= nil,"BoltRound animation event called, but BoltRoundEvent in settings is nil.")
		-- 	if Settings.BoltRoundEvent then
		-- 		SetItemHolder:FireServer(Tool,"Bolted",true)
		-- 		Bolted = true
		-- 		HoldFire = false
		-- 	end
		-- end,
	}

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
		self:PlayAnimationFor("Equip", self.Settings.EquipSpeed)
	else
		self:PlayAnimation("FirstEquip")
	end
	self.__task = task.delay(self.Settings.EquipSpeed, self.PlayAnimation, self, "Hold")
	task.wait(self.Settings.EquipCancel)
	self.Bolted = true -- !!TODO: Link this to an animation event instead maybe? So bolting matches with the animation
	self:__enable()
end

function Gun:Unequip()
	if self.State ~= ToolClass.State.Equipped then return end
	self:StopAnimation("FirstEquip", math.min(0.2, self.Settings.UnequipSpeed))
	ToolClass.Unequip(self)
end

function Gun:Click()
	local Handle = self.Handle
	Utils.SFX.playSound(self.Sounds, "Fire", Handle, true, true)
	local CommonToolFunctions = require(script.Parent.CommonToolFunctions)
	CommonToolFunctions.flashGun(Handle.Flash,Handle.Flash.FlashLight,true) -- uses CTF to flash the gun for light and particles
end

function Gun:Reload(input: InputObject)
	if input.KeyCode == Enum.KeyCode.H then
		print("reload 1")
		self:PlayAnimation("Reload1", nil, nil, nil, true)
		self:PlayAnimation("Reload2", nil, nil, nil, true)
	elseif input.KeyCode == Enum.KeyCode.J then
		print("reload 2")
		self:PlayAnimation("Reload1", nil, nil, nil, true)
		self:PlayAnimation("Reload2", nil, nil, nil, true)
		self:PlayAnimation("Reload2Last", nil, nil, nil, true)
	else
		print("reload 2")
		self:PlayAnimation("EmptyReload", nil, nil, nil, true)
		self:PlayAnimation("Reload2", nil, nil, nil, true)
		self:PlayAnimation("Reload2Last", nil, nil, nil, true)
	end
	self:PlayAnimation("Reload3", nil, nil, nil, true)
end

return Gun
