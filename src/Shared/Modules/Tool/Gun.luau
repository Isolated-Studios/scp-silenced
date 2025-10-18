local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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

local spreadReduction = false -- TODO! this shouldn't be here, but I'm leaving it here till I implement spread.

local Character: Model, Humanoid: Humanoid
local ViewModel: Model

local function __load_character(character)
	Character = character
	Humanoid = Character:WaitForChild("Humanoid")
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
			--PlayHammerClick: boolean,
			RunAndGun: boolean,
			RunAndReload: boolean,
			EmptyReload: boolean,
			BoltBackWhenEmpty: boolean,
			ScrollAffectsAim: boolean,

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
	
	-- other internal stuff
	self.LastShotTick = 0
	self.SubsequentShotsFired = 1
	self.BulletSpread = self.Settings.MinSpread
	
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
	if self.Ammo > 0 and not self.Bolted then -- play the first equip (with bolting) animation if unbolted but has ammo
		self:PlayAnimation("FirstEquip")
		self:Bolt(true)
	else
		self:PlayAnimationFor("Equip", self.Settings.EquipSpeed)
	end
	task.defer(HUDModule.updateGunDisplay, self)
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

function Gun:Bolt(skipAnimation: boolean)
	if self.Bolted or self.Ammo <= 0 then return end
	if not skipAnimation then
		local Animation = self:PlayAnimation("Bolt")
		if Animation then
			Animation:GetMarkerReachedSignal("BoltRound"):Wait()
		end
	end
	self.Bolted = true
	self.Ammo -= 1
	task.defer(HUDModule.updateGunDisplay, self)
end

function Gun:__projectBullet(randomValue) -- TODO! this function and its dependencies might require some refactoring.
	local Origin = self.Handle.Flash.WorldCFrame
	if not ViewModel then return end
	if ViewModel:GetAttribute("CloseToWall") then
		Origin = ViewModel.CameraPart.CFrame
	end
	local MouseFilterList = {}
	for _,thing in pairs(ViewModel:GetDescendants()) do
		if thing:IsA("BasePart") then
			table.insert(MouseFilterList,thing)
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

function Gun:__fire()
	self.SubsequentShotsFired += 1
	self.LastShotTick = tick()
	
	local Handle = self.Handle
	
	local randomValue = math.random(1,999999999) -- I might be a little stupid (for a "key" in determining uniqueness of tracers)
	for _ = 1, self.Settings.BulletsPerShot, 1 do
		self:__projectBullet(randomValue)
	end
	
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
	if self.Aiming and self.Settings.AimLinearShove and self.ettings.AimAngularShove then
		ViewModelHandler.ShoveViewModel(self.Settings.AimLinearShove, self.Settings.AimAngularShove) --/ shove event but aiming!
	else
		ViewModelHandler.ShoveViewModel(self.Settings.LinearShove, self.Settings.AngularShove) --/ shove event
	end
	
	-- // play the firing sound (with pitch modifications as needed)
	if self.Settings.PitchLastBullets and self.Settings.PitchLastBullets > 0 and self.Ammo < self.Settings.PitchLastBullets then
		--/ The last <PitchLastBullets> bullets are pitched up incrementally
		local coefficient = (self.Settings.PitchLastBullets - self.Ammo) / self.Settings.PitchLastBullets
		local pitch = self.Sounds["Fire"].PlaybackSpeed + coefficient * self.Sounds["Fire"].PlaybackSpeed
		Utils.SFX.playSound(self.Sounds, "Fire", Handle, true, true, {["PlaybackSpeed"] = pitch})
	else
		Utils.SFX.playSound(self.Sounds, "Fire", Handle, true, true)
	end
	
	-- // darken vignette for coolness
	do -- local scope so these variables don't mix with others
		local startTime = tick()
		if VignetteTween then VignetteTween:Cancel() end
		local TimeToTween = math.clamp(8*(VignetteAmount.Value-1)^2,0.2,8) -- GENIUS equation....
		VignetteTween = TweenService:Create(VignetteAmount,TweenInfo.new(TimeToTween),{Value = 1})
		local DarkenAmount = self.Settings.Damage*self.Settings.BulletsPerShot / ((self.Settings.Automatic == true) and (self.Settings.RPM * 2) or 400)
		if VignetteAmount.Value > 0 then
			VignetteAmount.Value = math.clamp(VignetteAmount.Value - DarkenAmount, 0, 1)
		end
		
		local WaitTime = TimeToTween*2+2
		task.delay(WaitTime,function()
			local otherTime = tick()-startTime
			if math.abs(otherTime-WaitTime) < 0.1 and (tick() - self.LastShotTick > 100 / self.Settings.RPM) then -- is gun still firing?
				-- another really cheap way to check if gun is still "firing" when gun is automatic
				if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and self.Settings.Automatic and self.Ammo > 0 and not Humanoid:GetAttribute("Running") then return end
				VignetteTween:Play()
			end
		end)
	end
	
	-- // play other VFX like muzzle flash, bolt movement, and shell casings
	self:PlayAnimation("Recoil")
	CTF.flashGun(Handle.Flash, Handle.Flash.FlashLight, true) -- uses CTF to flash the gun for light and particles
	-- TODO!
end

function Gun:__attemptFire()
	if self.Bolted then
		CommonFuncs.SafeCall(self.__fire, self) -- gun no sad if __fire sad
		self.Bolted = false
		task.defer(HUDModule.updateGunDisplay, self)
	end
	
	task.wait(60 / self.Settings.RPM)
	self:Bolt() -- attempt to bolt gun again if it has ammo
	task.defer(HUDModule.updateGunDisplay, self)
end

function Gun:Click(input: InputObject)
	if self.GunState ~= Gun.State.Idle and self.GunState ~= Gun.State.Reloading then return end
	if self.GunState == Gun.State.Reloading and (self.Bolted or self.Ammo > 0) then
		task.cancel(self.__task)
		self:StopAnimation("EmptyReload")
		self:StopAnimation("Reload1")
		self:StopAnimation("Reload2")
		self:StopAnimation("Reload2Last")
		self:StopAnimation("Reload3")
	end
	
	-- TODO: cancel running
	
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
		task.wait(self.Settings.SqueezeTrigger)
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
	self.Aiming = desiredState and not Humanoid:GetAttribute("Running") and self.State == ToolClass.State.Equipped
	ViewModelHandler.Aim(self.Aiming, if self.Aiming then self.Settings.AimInSpeed else self.Settings.AimOutSpeed)
	Humanoid:SetAttribute("Aiming", self.Aiming or nil)
	if self.Aiming then
		TweenService:Create(workspace.CurrentCamera, TweenInfo.new(self.Settings.AimInSpeed,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out), {FieldOfView = self.Settings.AimFOV}):Play()
		TweenService:Create(CrosshairPercent, TweenInfo.new(self.Settings.AimInSpeed,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out), {Value = 1}):Play()
	else
		TweenService:Create(workspace.CurrentCamera, TweenInfo.new(self.Settings.AimOutSpeed,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{FieldOfView = 70}):Play()
		if self.State ~= ToolClass.State.Unequipped then
			TweenService:Create(CrosshairPercent, TweenInfo.new(self.Settings.AimOutSpeed,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out), {Value = self.BulletSpread}):Play()
		end
	end
end

function Gun:Reload()
	if self.Ammo >= self.Settings.MagSize and self.Bolted then return end
	if self.GunState ~= Gun.State.Idle then return end
	self.GunState = Gun.State.Reloading
	
	if self.Settings.ReloadStyle == Gun.ReloadStyle.Magazine then
		if self.Ammo == 0 and self.Bolted == false then -- empty reload
			self.__task = task.spawn(function()
				self:PlayAnimation("EmptyReload", nil, nil, nil, true)
				self.Ammo = self.Settings.MagSize
				self:Bolt()
				task.defer(HUDModule.updateGunDisplay, self)
				self.GunState = Gun.State.Idle
			end)
		else
			self.__task = task.spawn(function()
				self:PlayAnimation("Reload1", nil, nil, nil, true)
				self.Ammo = self.Settings.MagSize
				self:Bolt()
				task.defer(HUDModule.updateGunDisplay, self)
				self.GunState = Gun.State.Idle
			end)
		end
	elseif self.Settings.ReloadStyle == Gun.ReloadStyle.SingleCartridge then
		local function loadCartridge()
			if self.Ammo >= self.Settings.MagSize then
				self:PlayAnimation("Reload3")
				self.GunState = Gun.State.Idle
				return
			elseif self.Ammo == self.Settings.MagSize - 1 then
				self:PlayAnimation("Reload2Last", nil, nil, nil, true)
			else
				self:PlayAnimation("Reload2", nil, nil, nil, true)
			end
			self.Ammo += 1
			task.defer(HUDModule.updateGunDisplay, self)
			self.__task = task.spawn(loadCartridge)
		end
		
		if self.Bolted == false then -- empty reload
			self.__task = task.spawn(function()
				self:PlayAnimation("EmptyReload", nil, nil, nil, true)
				self.Bolted = true
				task.defer(HUDModule.updateGunDisplay, self)
				self.__task = task.spawn(loadCartridge)
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
	self:__connect("RecoilSpringUpdate", RunService.RenderStepped, function(dt)
		local updatedRecoilSpring = self.RecoilSpring:update(dt)
		CameraModule.AddModifier(CFrame.Angles(math.rad(updatedRecoilSpring.x), updatedRecoilSpring.y, updatedRecoilSpring.z), true)
	end)
end

return Gun
