local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local ToolClass = require(script.Parent)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Spring = require(script.Parent.spring)
local CameraModule = require(ReplicatedStorage.ClientSrc.Camera)
local CustomMouse = require(ReplicatedStorage.Modules.UI.CustomMouse)
local CommonFuncs = require(ReplicatedStorage.Modules.CommonFuncs)
local HUDModule = nil
local CTF = nil
local ViewModelHandler = nil

local Player = Players.LocalPlayer

-- // UI
local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")
local CrosshairPercent = PlayerGui:WaitForChild("MouseUI"):WaitForChild("Crosshair")
local GunVignette = HUD:WaitForChild("GunVignette")
local VignetteAmount = GunVignette:WaitForChild("Gradient"):WaitForChild("VignetteAmount")
local VignetteTween: Tween = nil

local Character: Model, Humanoid: Humanoid, AmmoHolder: Configuration
local ViewModel: Model

local function __load_character(character)
	Character = character
	Humanoid = Character:WaitForChild("Humanoid")
	AmmoHolder = Character:WaitForChild("Ammo")
	Humanoid.Died:Connect(function()
		ViewModel = nil
	end)
	
	ViewModelHandler = ViewModelHandler or require(ReplicatedStorage.ClientSrc.ViewModelHandler)
	CTF = CTF or require(script.Parent.CommonToolFunctions) -- TODO: REMEMBER TO GET RID OF CTF LATER!!!!
	HUDModule = HUDModule or require(ReplicatedStorage.ClientSrc.HUD)
	CommonFuncs = CommonFuncs or require(ReplicatedStorage.Modules.CommonFuncs)
	
	ViewModel = ViewModelHandler.getViewModel()
	while ViewModel == nil do
		task.wait()
		ViewModel = ViewModelHandler.getViewModel()
	end
end
Player.CharacterAdded:Connect(__load_character)
if Player.Character then task.defer(__load_character, Player.Character) end -- task.defer because STUPID recursive requires() 💔

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
		GunState: number;
		Aiming: boolean;
		Bolted: boolean;
		Ammo: number;
		
		LastShotTick: number;
		SubsequentShotsFired: number;
		BulletSpread: number;
		SpreadReduction: boolean;
		RecoilSpring: {};
		
		Settings: {
			Damage: number,
			RPM: number,
			AP: number,
			MagSize: number,
			ReloadStyle: number,
			BulletsPerShot: number,
			BurstAmount: number,
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
			PlayHammerClick: boolean,
			RunAndGun: boolean,
			RunAndReload: boolean,
			EmptyReload: boolean,
			BoltBackWhenEmpty: boolean,

			AimInSpeed: number,
			AimOutSpeed: number,
			SqueezeTrigger: number,
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
	====== ENUM DEFINITIONS ======

	Custom Enums help with making the code more readable.
]]

Gun.State = {
	["Idle"] = 0;
	["CancelingSprint"] = 1;
	["Reloading"] = 2;
	["Cooldown"] = 3;
}

Gun.ReloadStyle = {
	["SingleCartridge"] = 0;
	["Magazine"] = 1;
}

Gun.UIState = {
	["Reset"] = 0,
	["Bolt"] = 1,
	["Reload"] = 2,
	["Fire"] = 3
}

--[[
	====== FUNCTION DEFINITIONS ======

	Functions defined here are statically accessible; they are not linked
	to any particular object. This includes the new object function and
	other utilities.
]]

function Gun.new(Tool: Tool): ClassType
	local self: ClassType = setmetatable(ToolClass.new(Tool), Gun)
	assert(self.Handle, `Gun {Tool:GetFullName()} is missing a Handle`)
	assert(self.Handle:FindFirstChild("Flash"), `Gun {Tool:GetFullName()}'s Handle is missing a 'Flash' attachment.`)
		
	self.GunState = Gun.State.Idle
	self.Aiming = false
	self.Bolted = false
	self.Ammo = self.Settings.MagSize
	self.ReserveHolder = AmmoHolder:FindFirstChild(self.Settings.AmmoType)
	if self.Settings.Casing and ReplicatedStorage.Objects.Casings:FindFirstChild(self.Settings.Casing) and self.Handle:FindFirstChild("Eject") then
		self.PrimeCasing = ReplicatedStorage.Objects.Casings[self.Settings.Casing]
	end
	
	-- stuff used for effects
	self.Hammer = self.Handle:FindFirstChild("Hammer")
	self.Cylinder = self.Handle:FindFirstChild("Cylinder")
	self.BoltPart = self.Handle:FindFirstChild("Bolt")
	if self.BoltPart then
		self.DefaultBoltC1 = self.BoltPart:GetAttribute("DefaultC1") or CFrame.new(0,0,0)
		self.BackBoltC1 = self.DefaultBoltC1 + self.DefaultBoltC1["LookVector"] * 0.2
	end
	
	-- other internal stuff
	self.LastShotTick = 0
	self.SubsequentShotsFired = 1
	self.BulletSpread = self.Settings.MinSpread
	self.SpreadReduction = false
	
	self.RecoilSpring = Spring.new()
	self.RecoilSpring.Speed = 6
	
	self.Bindings["Fire"] = {
		InputType = Enum.UserInputType.MouseButton1;
		InputState = Enum.UserInputState.Begin;
		DebugBinding = true; -- so the KeybindHandler doesn't constantly get called and print warnings for no reason.
		Handler = Utils.wrapMethod(self, self.Click);
	}
	self.Bindings["Aim"] = {
		InputType = Enum.UserInputType.MouseButton2;
		InputState = nil;
		DebugBinding = true;
		Handler = Utils.wrapMethod(self, self.Aim, false);
	}
	self.Bindings["Reload"] = {
		InputType = Enum.UserInputType.Keyboard;
		InputState = Enum.UserInputState.Begin;
		DebugBinding = Enum.KeyCode.R;
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
	CrosshairPercent.Value = math.clamp(self.BulletSpread, 0.001, math.huge)
	ToolClass.getHumanoid():EquipTool(self.Instance)
	if self.Ammo > 0 and not self.Bolted then -- play the first equip (with bolting) animation if unbolted but has ammo
		self:PlayAnimation("FirstEquip")
		self:Bolt(true)
	else
		self:PlayAnimationFor("Equip", self.Settings.EquipSpeed)
	end
	HUDModule.updateGunDisplay(self, Gun.UIState.Reset)
	self.__task = task.delay(self.Settings.EquipSpeed, self.PlayAnimation, self, "Hold")
	task.wait(self.Settings.EquipCancel)
	self.GunState = Gun.State.Idle -- in case the gun breaks and locks itself somehow, reequipping it should fix it
	self:__enable()
end

function Gun:Unequip()
	if self.State ~= ToolClass.State.Equipped then return end
	self:StopAnimation("FirstEquip", math.min(0.2, self.Settings.UnequipSpeed or 0))
	self:Aim(false)
	ToolClass.Unequip(self)
end

--[[
	Here are all the methods used for firing, reloading and all the very gun-specific stuff.
]]

function Gun:__modifyHammerAndCylinder(h0, h1, h2, c0, c1, c2) -- because it's used too many times
	if self.Hammer and self.Settings.HammerAngle and h0 and h1 and h2 then
		self.Hammer.C0 = CFrame.new(self.Hammer.C0.Position) * CFrame.Angles(
			math.rad(self.Settings.HammerAngle.X) * h0,
			math.rad(self.Settings.HammerAngle.Y) * h1,
			math.rad(self.Settings.HammerAngle.Z) * h2
		)
	end
	if self.Cylinder and self.Settings.CylinderAngle and c0 and c1 and c2 then
		self.Cylinder.C0 = CFrame.new(self.Cylinder.C0.Position) * CFrame.Angles(
			math.rad(self.Settings.CylinderAngle.X) * c0,
			math.rad(self.Settings.CylinderAngle.Y) * c1,
			math.rad(self.Settings.CylinderAngle.Z) * c2
		)
	end
end

function Gun:Bolt(skipAnimation: boolean)
	if self.Bolted then return end
	if self.Ammo <= 0 then
		if self.BoltPart and self.Settings.BoltBackWhenEmpty then
			TweenService:Create(self.BoltPart, TweenInfo.new(0.05), {C1 = self.BackBoltC1}):Play()
		end
		return
	else
		if self.BoltPart and self.Settings.BoltBackWhenEmpty then
			TweenService:Create(self.BoltPart, TweenInfo.new(0.05), {C1 = self.DefaultBoltC1}):Play()
		end
	end
	if not skipAnimation then
		local Animation = self:PlayAnimation("Bolt")
		if Animation then
			Animation:GetMarkerReachedSignal("BoltRound"):Wait()
		end
	end
	self.Bolted = true
	self.Ammo -= 1
	HUDModule.updateGunDisplay(self, Gun.UIState.Bolt)
	
	if self.Settings.PlayHammerClick then
		Utils.SFX.playSound(self.Sounds, "BoltBack", self.Handle, true, true)
	end
	self:__modifyHammerAndCylinder(1, 1, 1, 1, 1, 1)
end

function Gun:__projectBullet(randomValue) -- TODO! this function and its dependencies might require some refactoring.
	local Origin = self.Handle.Flash.WorldCFrame
	if not ViewModel then return end
	if ViewModel:GetAttribute("CloseToWall") then
		Origin = ViewModel.CameraPart.CFrame
	end
	local MouseFilterList = {}
	for _, ViewModelPart in pairs(ViewModel:GetDescendants()) do
		if ViewModelPart:IsA("BasePart") then
			table.insert(MouseFilterList, ViewModelPart)
		end
	end
	for _, IgnorePart in pairs(CollectionService:GetTagged("Ignore")) do
		if IgnorePart:IsA("BasePart") then
			table.insert(MouseFilterList, IgnorePart)
		end
	end
	CustomMouse.TargetBlackList = MouseFilterList
	local Direction = -(CustomMouse.Hit.Position-Origin.Position).Unit
	local Spread = self.BulletSpread*0.003
	Direction = CFrame.Angles(
		(0.5 - math.random()) * 2 * Spread,
		(0.5 - math.random()) * 2 * Spread,
		(0.5 - math.random()) * 2 * Spread) * Direction
	CTF.castBullet(self.Instance, Origin.Position, -Direction, self.Settings.TravelSpeed or nil, self.Settings.MaxDistance or nil, self.Settings.Acceleration or nil, self.Settings.BulletTemplate or nil, Player.Character, self.Settings.BulletsPerShot, randomValue, true)
end

function Gun:__beginSpreadReduction()
	local function regenWait (Value, WaitTime)
		local beginningValue = Value
		local startTime = tick()
		while Value == beginningValue do
			local currentTime = tick() - startTime
			if currentTime >= WaitTime then
				break
			end
			task.wait()
		end
		local currentTime = tick() - startTime
		if currentTime < self.Settings.SpreadRegenWait then
			regenWait(Value, WaitTime)
		end
	end

	regenWait(self.BulletSpread, self.Settings.SpreadRegenWait)
	while tick() - self.LastShotTick >= 60 / self.Settings.RPM and self.BulletSpread > self.Settings.MinSpread do
		local ReductionIncrement = self.Settings.ReductionIncrement or 0.2
		local ReductionWait = self.Settings.ReductionWait or 0.01
		self.BulletSpread = math.clamp(self.BulletSpread-ReductionIncrement, self.Settings.MinSpread, self.Settings.MaxSpread)
		CrosshairPercent.Value = math.clamp(self.BulletSpread, 0.001, math.huge)
		task.wait(ReductionWait)
	end
	self.SpreadReduction = false
	if self.BulletSpread > self.Settings.MinSpread then
		self.SpreadReduction = true
		self:__beginSpreadReduction()
	end
end

function Gun:__fire()
	self.SubsequentShotsFired += 1
	self.LastShotTick = tick()
	
	-- apply spread and cast bullet
	self.BulletSpread = math.clamp(self.BulletSpread + self.Settings.SpreadCost, self.Settings.MinSpread, self.Settings.MaxSpread)
	CrosshairPercent.Value = math.clamp(self.BulletSpread, 0.001, math.huge)
	if not self.SpreadReduction then
		self.SpreadReduction = true
		task.defer(self.__beginSpreadReduction, self)
	end
	
	local randomValue = math.random(1,999999999) -- I might be a little stupid (for a "key" in determining uniqueness of tracers)
	for _ = 1, self.Settings.BulletsPerShot, 1 do
		self:__projectBullet(randomValue)
	end
	
	-- ESSENTIAL effects (recoil and sound)
	
	-- // shove camera
	local XRecoilDampExponent = self.Settings.XRecoilDampExponent or 1
	local YRecoilDampExponent = self.Settings.YRecoilDampExponent or 1
	local randomizedDirection = math.random(0, 1) * 2 - 1
	local recoil_modifier = Vector3.new(
		1/((self.SubsequentShotsFired^XRecoilDampExponent) * self.Settings.XRecoilDampFactor),
		1/((self.SubsequentShotsFired^YRecoilDampExponent) * self.Settings.YRecoilDampFactor) * randomizedDirection,
		randomizedDirection
	)
	if self.Aiming then
		recoil_modifier /= 2
	end
	local ShoveAmount = self.Settings.CameraShove * recoil_modifier
	self.RecoilSpring:shove(ShoveAmount) -- shoves the camera
	if self.Aiming and self.Settings.AimLinearShove and self.Settings.AimAngularShove then
		ViewModelHandler.ShoveViewModel(self.Settings.AimLinearShove, self.Settings.AimAngularShove) --/ shove event but aiming!
	else
		ViewModelHandler.ShoveViewModel(self.Settings.LinearShove, self.Settings.AngularShove) --/ shove event
	end
	
	-- // play the firing sound (with pitch modifications as needed)
	if self.Settings.PitchLastBullets and self.Settings.PitchLastBullets > 0 and self.Ammo < self.Settings.PitchLastBullets then
		--/ The last <PitchLastBullets> bullets are pitched up incrementally
		local coefficient = (self.Settings.PitchLastBullets - self.Ammo) / self.Settings.PitchLastBullets
		local pitch = self.Sounds["Fire"].PlaybackSpeed + coefficient * self.Sounds["Fire"].PlaybackSpeed
		Utils.SFX.playSound(self.Sounds, "Fire", self.Handle, true, true, {["PlaybackSpeed"] = pitch})
	else
		Utils.SFX.playSound(self.Sounds, "Fire", self.Handle, true, true)
	end
	
	-- COOOOL effects (vignette, recoil animation, gun flash, dispense casing, hammer and cylinder movement)
	
	if self.PrimeCasing then
		local Casing = self.PrimeCasing:Clone()
		Casing.Parent = workspace
		Casing.Anchored = false
		Casing.CFrame = self.Handle.Eject.WorldCFrame
		Casing.AssemblyLinearVelocity = Casing.CFrame.LookVector * 25
		Debris:AddItem(Casing,10)
	end
	
	-- // darken vignette for coolness
	do -- local scope so these variables don't mix with others
		local startTime = tick()
		if VignetteTween then
			VignetteTween:Cancel()
		end
		
		local DarkenAmount = self.Settings.Damage * self.Settings.BulletsPerShot / ((self.Settings.Automatic == true and self.Settings.RPM * 5) or 1000)
		if VignetteAmount.Value > 0 then
			VignetteAmount.Value = math.clamp(VignetteAmount.Value - DarkenAmount, 0, 1)
		end
		
		local TimeToTween = math.clamp( -- This equation really isn't any better
			10 * math.pow(1 - VignetteAmount.Value, 1.5),
			0.3,
			10
		)
		
		VignetteTween = TweenService:Create(VignetteAmount, TweenInfo.new(TimeToTween), {Value = 1})
		
		local WaitTime = TimeToTween * 2 + 2
		task.delay(WaitTime,function()
			local otherTime = tick()-startTime
			if math.abs(otherTime-WaitTime) < 0.1 and (tick() - self.LastShotTick > 100 / self.Settings.RPM) then -- is gun still firing?
				-- another really cheap way to check if gun is still "firing" when gun is automatic
				if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					and self.Settings.Automatic
					and self.Ammo > 0
					and not Humanoid:GetAttribute("Running")
				then
					return
				end
				VignetteTween:Play()
			end
		end)
	end
	
	self:__modifyHammerAndCylinder(0, 0, 0, 0, 0, 0)
	
	-- // play other VFX like muzzle flash, bolt movement, and shell casings
	self:StopAnimation("Bolt")
	self:PlayAnimation("Recoil")
	CTF.flashGun(self.Handle.Flash, self.Handle.Flash.FlashLight, true) -- uses CTF to flash the gun for light and particles
	-- TODO!
end

function Gun:__attemptFire()
	if self.Bolted then
		CommonFuncs.SafeCall(self.__fire, self) -- gun no sad if __fire sad
		self.Bolted = false
		HUDModule.updateGunDisplay(self, Gun.UIState.Bolt)
	end
	HUDModule.updateGunDisplay(self, Gun.UIState.Fire)
	task.wait(60 / self.Settings.RPM)
	self:Bolt() -- attempt to bolt gun again if it has ammo
end

function Gun:Click(input: InputObject)
	if self.GunState ~= Gun.State.Idle and self.GunState ~= Gun.State.Reloading then return end
	if self.GunState == Gun.State.Reloading then
		task.cancel(self.__task)
		self:StopAnimation("EmptyReload")
		self:StopAnimation("Reload1")
		self:StopAnimation("Reload2")
		self:StopAnimation("Reload2Last")
		self:StopAnimation("Reload3")
	end
	
	-- If player is running, cancel it
	if Humanoid:GetAttribute("Running") then
		CTF.stopRunning()
		task.wait(0.1) -- Delays firing while transitioning from running anims to idle anims. (Could probably be improved less crudely)
	end
	
	self.GunState = Gun.State.Cooldown
	
	-- Trigger squeezing delay
	if self.Settings.SqueezeTrigger then
		local connection = nil
		local cancel = false
		if self.Settings.HeldWhenSqueezed then
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					self.GunState = Gun.State.Idle
					cancel = true
					connection:Disconnect()
				end
			end)
		end
		local initialTime = tick()
		local currentTime = 0
		self:__modifyHammerAndCylinder(0, 0, 0, 0, 0, 0)
		while task.wait() and currentTime < self.Settings.SqueezeTrigger and self.State == ToolClass.State.Equipped and cancel == false do
			currentTime = tick() - initialTime
			local t = currentTime / self.Settings.SqueezeTrigger
			self:__modifyHammerAndCylinder(t, t, t, t, t, t)
		end
		self:__modifyHammerAndCylinder(0, 0, 0, 0, 0, 0)
		if connection then connection:Disconnect() end
		if cancel then return end
	end
	
	CTF.playSound(self.Sounds, "Empty", self.Handle, true, true)
	if tick() - self.LastShotTick > 150 / self.Settings.RPM then
		self.SubsequentShotsFired = 0
	end
	if self.Settings.Automatic or self.Settings.BurstAmount > 1 then
		local i = if self.Settings.BurstAmount > 1 then self.Settings.BurstAmount else math.huge
		repeat
			self:__attemptFire()
			i -= 1
		until (i == 0) or not (input.UserInputState ~= Enum.UserInputState.End and self.State == ToolClass.State.Equipped and self.Bolted)
	else
		self:__attemptFire()
	end
	self.GunState = Gun.State.Idle
end

-- // Aiming and reloading.

function Gun:Aim(desiredState, input: InputObject?)
	if input then
		if input.UserInputState == Enum.UserInputState.Begin then
			desiredState = true
		elseif input.UserInputState == Enum.UserInputState.End then
			desiredState = false
		end
	end
	
	-- If player is running, cancel it (Does not require another run button input. that is what that true is)
	local RunMultiplier = 1
	if Humanoid:GetAttribute("Running") then
		CTF.stopRunning(true)
		RunMultiplier = 2 -- Will make the aiming tweens longer to account for the run animation tranisitioning to idle.
	end
	
	self.Aiming = desiredState and self.State == ToolClass.State.Equipped
	ViewModelHandler.Aim(self.Aiming, if self.Aiming then self.Settings.AimInSpeed * RunMultiplier else self.Settings.AimOutSpeed * RunMultiplier)
	Humanoid:SetAttribute("Aiming", self.Aiming or nil)
	if self.Aiming then
		TweenService:Create(workspace.CurrentCamera, TweenInfo.new(self.Settings.AimInSpeed * RunMultiplier, Enum.EasingStyle.Cubic,Enum.EasingDirection.Out), {FieldOfView = self.Settings.AimFOV}):Play()
		TweenService:Create(CrosshairPercent, TweenInfo.new(self.Settings.AimInSpeed * RunMultiplier, Enum.EasingStyle.Exponential,Enum.EasingDirection.Out), {Value = 1}):Play()
	else	
		TweenService:Create(workspace.CurrentCamera, TweenInfo.new(self.Settings.AimOutSpeed * RunMultiplier, Enum.EasingStyle.Cubic,Enum.EasingDirection.Out), {FieldOfView = 70}):Play()
		if self.State ~= ToolClass.State.Unequipped then
			TweenService:Create(CrosshairPercent, TweenInfo.new(self.Settings.AimOutSpeed * RunMultiplier, Enum.EasingStyle.Exponential,Enum.EasingDirection.Out), {Value = self.BulletSpread}):Play()
		end
	end
end

function Gun:Reload()
	if self.Ammo >= self.Settings.MagSize and self.Bolted then return end
	if self.GunState ~= Gun.State.Idle then return end
	if self.ReserveHolder.Value == 0 then return end -- Ran out of reserve ammo.
	self.GunState = Gun.State.Reloading
	
	if self.Settings.ReloadStyle == Gun.ReloadStyle.Magazine then
		if self.Ammo == 0 and self.Bolted == false then -- empty reload
			self.__task = task.spawn(function()
				if self.BoltPart and self.Settings.BoltBackWhenEmpty then
					TweenService:Create(self.BoltPart, TweenInfo.new(0.05), {C1 = self.DefaultBoltC1}):Play()
				end
				self:PlayAnimation("EmptyReload", nil, nil, nil, true)
				-- This will get the exact amount needed to load the mag with respect to the reserve ammo.
				local LoadingAmount = math.min(self.Settings.MagSize - self.Ammo, self.ReserveHolder.Value)
				self.Ammo += LoadingAmount
				self.ReserveHolder.Value -= LoadingAmount
				HUDModule.updateGunDisplay(self, Gun.UIState.Reload)
				self:Bolt(true)
				self.GunState = Gun.State.Idle
			end)
		else
			self.__task = task.spawn(function()
				self:PlayAnimation("Reload1", nil, nil, nil, true)
				-- This will get the exact amount needed to load the mag with respect to the reserve ammo.
				local LoadingAmount = math.min(self.Settings.MagSize - self.Ammo, self.ReserveHolder.Value)
				self.Ammo += LoadingAmount
				self.ReserveHolder.Value -= LoadingAmount
				HUDModule.updateGunDisplay(self, Gun.UIState.Reload)
				self:Bolt()
				self.GunState = Gun.State.Idle
			end)
		end
	elseif self.Settings.ReloadStyle == Gun.ReloadStyle.SingleCartridge then
		local function loadCartridge()
			if self.Ammo >= self.Settings.MagSize or self.ReserveHolder.Value == 0 then
				self:PlayAnimation("Reload3")
				self.GunState = Gun.State.Idle
				return
			elseif self.Ammo == self.Settings.MagSize - 1 or self.ReserveHolder.Value == 1 then
				self:PlayAnimation("Reload2Last", nil, nil, nil, true)
			else
				self:PlayAnimation("Reload2", nil, nil, nil, true)
			end
			self.Ammo += 1
			self.ReserveHolder.Value -= 1
			self.__task = task.spawn(loadCartridge)
			HUDModule.updateGunDisplay(self, Gun.UIState.Reload)
		end
		
		if self.Bolted == false then -- empty reload
			self.__task = task.spawn(function()
				self:PlayAnimation("EmptyReload", nil, nil, nil, true)
				self.Bolted = true
				self.__task = task.spawn(loadCartridge)
				HUDModule.updateGunDisplay(self, Gun.UIState.Reload)
			end)
		else
			self.__task = task.spawn(function()
				self:PlayAnimation("Reload1", nil, nil, nil, true)
				self.__task = task.spawn(loadCartridge)
			end)
		end
	end
end

function Gun:__enable()
	ToolClass.__enable(self)
	task.spawn(function()
		local startTime = os.clock()
		local virtualFrameCounter = 0
		while true do
			RunService.RenderStepped:Wait()
			if self.State == ToolClass.State.Unequipped then
				return
			end
			
			local currentTime = os.clock()
			local elapsedTime = currentTime - startTime
			local expectedFrameCount = math.floor(elapsedTime * 240)
			if expectedFrameCount > virtualFrameCounter then
				for _ = 0, expectedFrameCount - virtualFrameCounter, 1 do
					local updatedRecoilSpring = self.RecoilSpring:update(1/240)
					CameraModule.AddModifier(CFrame.Angles(math.rad(updatedRecoilSpring.x), updatedRecoilSpring.y, updatedRecoilSpring.z), true)
				end
			end
			virtualFrameCounter = expectedFrameCount
		end
	end)
end

return Gun
