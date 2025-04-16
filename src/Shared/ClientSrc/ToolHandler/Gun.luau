local module = {}
--//Services
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--//Service Objects
local TemporaryParts = workspace:WaitForChild("TemporaryParts")
local Objects = ReplicatedStorage.Objects
local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events
local ClientSrc = ReplicatedStorage.ClientSrc
local CameraModule = require(ClientSrc.Camera)

local Casings = Objects.Casings
local ToolEvents = Events.Tool
local ViewmodelEvents = Events.Viewmodel
local CharacterEvents = Events.Character

local ToolModules = Modules.Tool
local UIModules = Modules.UI

--//Modules
local CTF = require(ToolModules.CommonToolFunctions)
local CustomMouse = require(UIModules.CustomMouse)
local KeybindHandler = require(UIModules.KeybindHandler)
local RaycastHitbox = require(ToolModules.RaycastHitboxV4)
local springModule = require(ToolModules.spring)
local ScopeModule = require(ToolModules.Scope)

--//Events
local HumanoidAttributeEvent = CharacterEvents.HumanoidAttribute
local Shove = ViewmodelEvents.Shove
local Aim = ViewmodelEvents.Aim
local SetItemHolder = ToolEvents.SetItemHolder

---//Module Setup
local recoilSpring = springModule.new(nil,nil,nil,nil,6)

function module.Init(Tool,ToolObjects,Character,Viewmodel)
	if Tool.Parent ~= Character then return end
	Tool:SetAttribute("Activated",true)
	local Settings = require(ToolObjects:WaitForChild("Settings"))
	--//Player
	local AmmoList = Character:WaitForChild("Ammo")
	local MotorModel = Viewmodel:WaitForChild("MotorModel")
	local Player = game.Players.LocalPlayer
	local Mouse = Player:GetMouse()
	local PlayerGui = Player:WaitForChild("PlayerGui")
	local Camera = workspace.CurrentCamera
	local Humanoid = Character:WaitForChild("Humanoid")
	local HRP = Character:WaitForChild("HumanoidRootPart")

	--UI
	local CrosshairPercent = PlayerGui:WaitForChild("MouseUI"):WaitForChild("Crosshair")
	local GunFrame = PlayerGui:WaitForChild("HUD"):WaitForChild("RightFrame"):WaitForChild("ListFrame"):WaitForChild("GunFrame")
	local CanvasGroup = GunFrame:WaitForChild("CanvasGroup")
	local InnerFrame = CanvasGroup:WaitForChild("InnerFrame")
	local InnerScaleLayout = InnerFrame:WaitForChild("InnerScale")
	local MagFrame = InnerFrame:WaitForChild("MagFrame")
	local ReserveFrame = CanvasGroup:WaitForChild("ReserveFrame")
	local ReserveText = ReserveFrame:WaitForChild("Reserve")
	local InfoFrame = InnerFrame:WaitForChild("InfoFrame")
	local NameText = InfoFrame:WaitForChild("Name")
	local ModeText = InfoFrame:WaitForChild("Mode")
	local PrimeMagBullet = GunFrame:WaitForChild("MagBullet")

	--//Tool Objects
	local Sounds = ToolObjects:WaitForChild("Sounds")
	local Handle = MotorModel:WaitForChild("Handle")
	local Flash = Handle:WaitForChild("Flash")
	local Eject = Handle:WaitForChild("Eject")
	local PrimeCasing = Casings["Air"]
	local Holder = Tool:WaitForChild("Holder")
	local boltBool = Holder:WaitForChild("Bolted")
	local magBool = Holder:WaitForChild("Mag")
	local ammoBool = AmmoList:WaitForChild(Settings.AmmoType)

	--//Bools
	local Hammer = nil
	local Cylinder = nil
	local BackBoltC1 = nil
	local DefaultBoltC1 = nil
	local HoldFire = false
	local FireCooldown = false
	local Aiming = false
	local Bolted = false
	local Bursting = false
	local Reloading = false
	local CancelReload = false
	local spreadReduction = false

	--//Sets
	local BulletSpread = math.round(Settings.MinSpread)
	local SubsequentShotsFired = 0
	local LastShotTick = 0
	local BoltPosition = Settings.BoltPosition or {"LookVector",0.2}

	--//Beginning Priming
	CrosshairPercent.Value = BulletSpread
	if Settings.Casing and Casings:FindFirstChild(Settings.Casing) then
		PrimeCasing = Casings[Settings.Casing]
	end
	if Handle:FindFirstChild("Hammer") then
		Hammer = Handle.Hammer
	end
	if Handle:FindFirstChild("Cylinder") then
		Cylinder = Handle.Cylinder
	end

	if MotorModel:FindFirstChild("ScopeObject") then
		ScopeModule.SetEnabled(true,MotorModel["ScopeObject"])
	end

	--//Animation Priming
	local animationEventsList = {}
	local Animator = Humanoid:WaitForChild("Animator")
	local VMAnimator = Viewmodel.Humanoid.Animator
	local CharacterAnimations = ToolObjects:WaitForChild("CharacterAnimations")
	local VMAnimations = ToolObjects:WaitForChild("VMAnimations")

	local VMReload1 = VMAnimator:LoadAnimation(VMAnimations.Reload1)
	local CharReload1 = Animator:LoadAnimation(CharacterAnimations.Reload1)
	local VMReload2 = nil
	local CharReload2 = nil
	local VMReload2Last = nil
	local CharReload2Last = nil
	local VMReload3 = nil
	local CharReload3 = nil
	local VMEmptyReload = nil
	local CharEmptyReload = nil
	local VMBolt = nil
	local CharBolt = nil
	local VMRecoil = nil
	local CharRecoil = nil
	local VMRun = nil
	local CharRun = nil

	if VMAnimations:FindFirstChild("Bolt") then
		VMBolt = VMAnimator:LoadAnimation(VMAnimations.Bolt)
		CharBolt = Animator:LoadAnimation(CharacterAnimations.Bolt)
	end
	if VMAnimations:FindFirstChild("Reload2") then
		VMReload2 = VMAnimator:LoadAnimation(VMAnimations.Reload2)
		CharReload2 = Animator:LoadAnimation(CharacterAnimations.Reload2)
	end
	if VMAnimations:FindFirstChild("Reload2Last") then
		VMReload2Last = VMAnimator:LoadAnimation(VMAnimations.Reload2Last)
		CharReload2Last = Animator:LoadAnimation(CharacterAnimations.Reload2Last)
	end
	if VMAnimations:FindFirstChild("Reload3") then
		VMReload3 = VMAnimator:LoadAnimation(VMAnimations.Reload3)
		CharReload3 = Animator:LoadAnimation(CharacterAnimations.Reload3)
	end
	if VMAnimations:FindFirstChild("EmptyReload") then
		VMEmptyReload = VMAnimator:LoadAnimation(VMAnimations.EmptyReload)
		CharEmptyReload = Animator:LoadAnimation(CharacterAnimations.EmptyReload)
	end
	if VMAnimations:FindFirstChild("Recoil") then
		VMRecoil = VMAnimator:LoadAnimation(VMAnimations.Recoil)
		CharRecoil = Animator:LoadAnimation(CharacterAnimations.Recoil)
	end
	if VMAnimations:FindFirstChild("Run") then
		VMRun = VMAnimator:LoadAnimation(VMAnimations.Run)
		CharRun = Animator:LoadAnimation(CharacterAnimations.Run)
	end
	local animationEvents = {
		["Reload1"] = CTF.getAllAnimationEventNames(VMReload1),
		["Reload2"] = CTF.getAllAnimationEventNames(VMReload2),
		["Reload2Last"] = CTF.getAllAnimationEventNames(VMReload2Last),
		["Reload3"] = CTF.getAllAnimationEventNames(VMReload3),
		["EmptyReload"] = CTF.getAllAnimationEventNames(VMEmptyReload),
		["Bolt"] = CTF.getAllAnimationEventNames(VMBolt)
	}
	local animationTable = {
		["Run"] = {VMRun,CharRun},
		["Recoil"] = {VMRecoil,CharRecoil},
		["Bolt"] = {VMBolt,CharBolt},
		["Reload1"] = {VMReload1,CharReload1},
		["Reload2"] = {VMReload2,CharReload2},
		["Reload2Last"] = {VMReload2Last,CharReload2Last},
		["Reload3"] = {VMReload3,CharReload3},
		["EmptyReload"] = {VMEmptyReload,CharEmptyReload},
	}

	local function animationHandle (animation,action,num,secondNum)
		if not num then num = 0 end
		if not secondNum then secondNum = num end
		local VManim = animationTable[animation][1]
		local Charanim = animationTable[animation][2]
		if VManim and Charanim then
			if action == "Play" then
				VManim:Play(num)
				Charanim:Play(secondNum)
			elseif action == "Stop" then
				VManim:Stop(num)
				Charanim:Stop(secondNum)
			elseif action == "Speed" then
				VManim:AdjustSpeed(num)
				Charanim:AdjustSpeed(secondNum)
			end
		end
	end
	--\\

	--//Functions
	local function disconnectFunctions (FunctionList)
		for _,Function in pairs(FunctionList) do
			if Function then
				Function:Disconnect()
			end
		end
	end

	local function humAtt (name,val,rep)
		if rep then
			HumanoidAttributeEvent:FireServer(Humanoid,name,val)
		else
			Humanoid:SetAttribute(name,val)
		end
	end

	local editMagTable = {
		["Empty"] = function(tweenTime)
			if not tweenTime then tweenTime = 0.1 end
			local bullet = MagFrame["1"]
			local round = bullet.Round
			TweenService:Create(round,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,0)}):Play()
		end,
		["Cycle"] = function(tweenTime)
			if not tweenTime then tweenTime = 0.1 end
			if magBool.Value+1 <= Settings.MagSize and magBool.Value > 0 and MagFrame:FindFirstChild((magBool.Value+1)) then
				local bullet = MagFrame[tostring(magBool.Value+1)]
				local round = bullet.Round
				TweenService:Create(round,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,0)}):Play()
				local firstBullet = MagFrame["1"]
				local firstRound = firstBullet.Round
				TweenService:Create(firstRound,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,1),}):Play()
			end
		end,
		["Load"] = function(tweenTime)
			if not tweenTime then tweenTime = 0.1 end
			local bullet = MagFrame[tostring(magBool.Value)]
			local round = bullet.Round
			if MagFrame["1"].Round.Size.Y.Scale < 1 then
				bullet = MagFrame["1"]
				round = bullet.Round
			end
			TweenService:Create(round,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,1)}):Play()
		end,
		["Mag"] = function(tweenTime)
			if not tweenTime then tweenTime = 0.1 end
			for i=1,magBool.Value,1 do
				local bullet = MagFrame[tostring(i)]
				local round = bullet.Round
				TweenService:Create(round,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,1)}):Play()
			end
		end,
	}

	local function editBulletFrame (action,tweenTime)
		ReserveText.Text = ammoBool.Value
		NameText.Text = Tool.Name
		if Settings.Automatic then
			ModeText.Text = "Auto"
		else
			ModeText.Text = "Semi"
		end
		editMagTable[action](tweenTime)
	end

	local function AimGun (State)
		if State and not Humanoid:GetAttribute("Running") then
			Aim:Fire(true,Settings.AimInSpeed)
			Aiming = true
			Humanoid:SetAttribute("Aiming",true)
			TweenService:Create(Camera,TweenInfo.new(Settings.AimInSpeed,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{FieldOfView = Settings.AimFOV}):Play()
			TweenService:Create(CrosshairPercent,TweenInfo.new(Settings.AimInSpeed,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{Value = 1}):Play()
		else
			Aim:Fire(false,Settings.AimOutSpeed)
			Aiming = false
			Humanoid:SetAttribute("Aiming",nil)
			TweenService:Create(Camera,TweenInfo.new(Settings.AimOutSpeed,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{FieldOfView = 70}):Play()
			if Tool.Parent == Character then
				TweenService:Create(CrosshairPercent,TweenInfo.new(Settings.AimOutSpeed,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out),{Value = BulletSpread}):Play()
			end
		end
	end

	local function dispenseCasing ()
		local Casing = PrimeCasing:Clone()
		Casing.Parent = TemporaryParts
		Casing.Anchored = false
		Casing.CFrame = Eject.WorldCFrame
		Debris:AddItem(Casing,10)
	end

	local function regenWait ()
		local beginningSpread = BulletSpread
		local startTime = tick()
		while BulletSpread == beginningSpread do
			local currentTime = tick() - startTime
			if currentTime >= Settings.SpreadRegenWait then
				break
			end
			task.wait()
		end
		local currentTime = tick() - startTime
		if currentTime < Settings.SpreadRegenWait then
			regenWait()
		end
	end

	local function beginSpreadReduction ()
		spreadReduction = true
		regenWait()
		while not FireCooldown and BulletSpread > Settings.MinSpread do
			BulletSpread = math.clamp(BulletSpread-0.2,Settings.MinSpread,Settings.MaxSpread)
			CrosshairPercent.Value = BulletSpread
			task.wait()
		end
		spreadReduction = false
		if BulletSpread > Settings.MinSpread then
			beginSpreadReduction()
		end
	end

	local function gunSpread ()
		task.defer(function()
			BulletSpread = math.clamp(BulletSpread+Settings.SpreadCost,Settings.MinSpread,Settings.MaxSpread)
			CrosshairPercent.Value = BulletSpread
			if not spreadReduction then
				beginSpreadReduction()
			end
		end)
	end

	local function ProjectBullet (randomValue)
		local Origin = Flash.WorldCFrame
		if Viewmodel:GetAttribute("CloseToWall") then
			Origin = Viewmodel.CameraPart.CFrame
		end
		local MouseFilterList = {}
		for _,thing in pairs(Viewmodel:GetDescendants()) do
			if thing:IsA("BasePart") then
				table.insert(MouseFilterList,thing)
			end
		end
		CustomMouse.TargetBlackList = MouseFilterList
		local Direction = -(CustomMouse.Hit.Position-Origin.Position).Unit
		local Spread = BulletSpread*0.003
		Direction = CFrame.Angles(
			(0.5 - math.random()) * 2 * Spread,
			(0.5 - math.random()) * 2 * Spread,
			(0.5 - math.random()) * 2 * Spread) * Direction
		CTF.castBullet(Tool, Origin.Position, -Direction, Settings.TravelSpeed or nil, Settings.MaxDistance or nil, Settings.Acceleration or nil, Settings.BulletTemplate or nil, Character,  Settings.BulletsPerShot, randomValue, true)
	end

	local function boltGun ()
		HoldFire = true
		if Settings.PlayHammerClick then
			CTF.playSound(Sounds,"BoltBack",Handle,true,true)
		end

		if Settings.HammerAngle then
			Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(Settings.HammerAngle.X),math.rad(Settings.HammerAngle.Y),math.rad(Settings.HammerAngle.Z))
		end

		if Settings.CylinderAngle then
			Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(Settings.CylinderAngle.X),math.rad(Settings.CylinderAngle.Y),math.rad(Settings.CylinderAngle.Z))
		end

		if VMBolt then
			animationHandle("Bolt","Play")
			if not Settings.BoltRoundEvent then
				VMBolt.Stopped:Wait()
				animationHandle("Bolt","Stop")
				editBulletFrame("Cycle")
			end
		end
		if not Settings.BoltRoundEvent then
			SetItemHolder:FireServer(Tool,"Bolted",true)
			Bolted = true
			HoldFire = false
		end
	end

	local function fireGun () --/ Big evil function that fires the gun
		if magBool.Value <= 0 then return end --/ the mag is empty

		local currentTick = tick()
		if currentTick - LastShotTick >= 150/Settings.RPM then
			SubsequentShotsFired = 0
		end
		LastShotTick = currentTick
		magBool.Value -= 1 --/ subtract a round from the mag

		SetItemHolder:FireServer(Tool,"Mag",magBool.Value) -- UI shenanigans
		editBulletFrame("Empty",0.02)

		if Settings.BurstAmount > 1 then --/ If the gun is a burst gun, will delay the cycle for the UI
			local burstdelay = Settings.BurstDelay or 0.01
			task.delay(burstdelay,function()
				editBulletFrame("Cycle",0.2)
			end)
		end

		if Settings.BoltRoundEvent then --/ Will stop the Bolt animation when fired (only for if BoltRoundEvent is true)
			animationHandle("Bolt","Stop")
		end

		Bolted = false --/ Gun is no longer bolted
		SetItemHolder:FireServer(Tool,"Bolted",false)

		HoldFire = true

		if Settings.FireDelay then -- Used for when you want a delay for the round to be fired, typically when the hammer is coming down.
			if Settings.HammerAngle then
				Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(Settings.HammerAngle.X),math.rad(Settings.HammerAngle.Y),math.rad(Settings.HammerAngle.Z))
			end
			if Settings.CylinderAngle then
				Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(Settings.CylinderAngle.X),math.rad(Settings.CylinderAngle.Y),math.rad(Settings.CylinderAngle.Z))
			end
			task.wait(Settings.FireDelay)
		end

		if Settings.HammerAngle then -- If hammer exists, will reset position
			Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
		end
		if Settings.CylinderAngle then -- If hammer exists, will reset position
			Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
		end

		if Settings.PitchLastBullets and Settings.PitchLastBullets > 0 and magBool.Value+1<= Settings.PitchLastBullets then
			--/ The last 3 or so bullets are pitched up incrementally
			local value = Settings.PitchLastBullets-(magBool.Value)
			local pitch = Sounds["Fire"].PlaybackSpeed+((Sounds["Fire"].PlaybackSpeed*value)/Settings.PitchLastBullets)
			CTF.playSound(Sounds,"Fire",Handle,true,true,{["PlaybackSpeed"] = pitch})
		else
			--/ bullets aren't pitched up
			CTF.playSound(Sounds,"Fire",Handle,true,true)
		end

		Shove:Fire(Settings.LinearShove,Settings.AngularShove) --/ shove event

		gunSpread() --/ apply gun spread

		CTF.flashGun(Flash,Flash.FlashLight,true) -- uses CTF to flash the gun for light and particles

		SubsequentShotsFired += 1
		local recoil_modifier = Vector2.new(1/(SubsequentShotsFired * Settings.XRecoilDampFactor), 1/(SubsequentShotsFired * Settings.YRecoilDampFactor)) --/ This section reduces the shove of the gun if you're aiming
		local possibleNegative = math.random(0, 1) * 2 - 1
		if Aiming then
			recoil_modifier /= 2
		end

		animationHandle("Recoil","Play") --/ play the recoil animation

		if magBool.Value == 0 and Settings.BoltBackWhenEmpty and Handle:FindFirstChild("Bolt") then
			--/ pushes the bolt back if BoltBackWhenEmpty is true and mag is empty
			local Bolt = Handle.Bolt
			TweenService:Create(Bolt,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{C1 = BackBoltC1}):Play()
			Tool:SetAttribute("BoltSet",true)
		end

		local ShoveAmount = Vector3.new(Settings.CameraShove.X*recoil_modifier.X,Settings.CameraShove.Y*recoil_modifier.Y*possibleNegative,Settings.CameraShove.Z*recoil_modifier*possibleNegative)
		recoilSpring:shove(ShoveAmount)
		local randomValue = math.random(1,999999999)
		for i=1,Settings.BulletsPerShot,1 do
			ProjectBullet(randomValue)
		end
		if Settings.AutomaticBolt then
			task.wait(60/Settings.RPM)
			boltGun()
		end
		HoldFire = false
	end

	local function attemptToFire()
		if Settings.Bolted and not Bolted then --/ If the gun can and must be bolted
			boltGun()
		end
		for i=1,Settings.BurstAmount,1 do --/ Burst loop pow pow pow
			fireGun()
			if Settings.BurstDelay then
				task.wait(Settings.BurstDelay)
			end
		end
	end

	local function gunPrime ()
		if not HoldFire and not FireCooldown then
			FireCooldown = true
			if Settings.SqueezeTrigger and not Bolted then -- Holding trigger to squeeze
				local initialTime = tick()
				local currentTime = tick() - initialTime
				if Settings.HammerAngle then --/ If a hammer exists will reset
					Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
				end
				if Settings.CylinderAngle then --/ If a cylinder exists will reset
					Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
				end
				while task.wait() and currentTime < Settings.SqueezeTrigger and Tool.Parent == Character do
					--/ The squeezing of the trigger that sets the positions of the hammer and/or cylinder
					if Settings.HeldWhenSqueezed and not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
						break
					end
					currentTime = tick() - initialTime
					if Settings.HammerAngle then --/ If a hammer exists will pull back
						Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad((currentTime/Settings.SqueezeTrigger)*Settings.HammerAngle.X),math.rad((currentTime/Settings.SqueezeTrigger)*Settings.HammerAngle.Y),math.rad((currentTime/Settings.SqueezeTrigger)*Settings.HammerAngle.Z))
					end
					if Settings.CylinderAngle then --/ If a cylinder exists will cycle
						Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad((currentTime/Settings.SqueezeTrigger)*Settings.CylinderAngle.X),math.rad((currentTime/Settings.SqueezeTrigger)*Settings.CylinderAngle.Y),math.rad((currentTime/Settings.SqueezeTrigger)*Settings.CylinderAngle.Z))
					end
				end
				if currentTime >= Settings.SqueezeTrigger then -- the squeezing has ended and will attempt to fire gun
					attemptToFire()
				else
					if Settings.HammerAngle then -- reset hammer position
						Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
					end

					if Settings.CylinderAngle then -- reset cylinder position
						Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
					end
				end
			else
				attemptToFire()
			end
			if Settings.BurstAmount == 1 then
				task.delay((60/Settings.RPM)-0.1,function()
					editBulletFrame("Cycle")
				end)
			end
			task.wait(60/Settings.RPM)
			FireCooldown = false
		else
			task.wait()
		end
	end

	local function Reload ()
		if magBool.Value < Settings.MagSize and ammoBool.Value > 0 and not Reloading and (not Humanoid:GetAttribute("Running") or Settings.RunAndReload) then
			CancelReload = false
			Reloading = true
			--ChangeGrip:Fire(Viewmodel.UpperTorso)

			if not Bolted then
				if Settings.AutomaticBolt then
					Bolted = true
				else
					boltGun()
				end
				editBulletFrame("Cycle")
			end

			if Settings.ReloadStyle == 1 then --/ Mag reload
				if magBool.Value <= 0 and Settings.EmptyReload then
					animationHandle("EmptyReload","Play")
					if Settings.EmptyReloadSpeed then
						animationHandle("EmptyReload","Speed",VMEmptyReload.Length/Settings.EmptyReloadSpeed,CharEmptyReload.Length/Settings.EmptyReloadSpeed)
					end
				else
					animationHandle("Reload1","Play")
					if Settings.Reload1Speed then
						animationHandle("Reload1","Speed",VMReload1.Length/Settings.Reload1Speed,CharReload1.Length/Settings.Reload1Speed)
					end
				end

			else --/ Shell reload
				if magBool.Value <= 0 and Settings.EmptyReload then --/ Will play the EmptyReload as a transition instead of Reload1 if mag is empty
					animationHandle("EmptyReload","Play")
					if Settings.EmptyReloadSpeed then
						animationHandle("EmptyReload","Speed",VMEmptyReload.Length/Settings.EmptyReloadSpeed,CharEmptyReload.Length/Settings.EmptyReloadSpeed)
					end
					VMEmptyReload.Stopped:Wait() --/ Wait for the reload to stop
				else --/ Otherwise, just play Reload1 as a transition
					animationHandle("Reload1","Play")
					if Settings.Reload1Speed then
						animationHandle("Reload1","Speed",VMReload1.Length/Settings.Reload1Speed,CharReload1.Length/Settings.Reload1Speed)
					end
					VMReload1.Stopped:Wait() --/ Wait for the reload to stop
				end
				if Tool.Parent ~= Character then return end --/ stupid dumb idiot check i hate you gun script
				if magBool.Value <= 0 and Settings.EmptyReload then --/ STOPPPP the empty reload if it exists
					animationHandle("EmptyReload","Stop")
				else
					animationHandle("Reload1","Stop") --/ STOPPPP the reload1 instead
				end
				while Tool.Parent == Character and magBool.Value < Settings.MagSize and ammoBool.Value > 0 do
					--/Reload2 is our animation being looped to simulate the shells going in.
					if (magBool.Value == Settings.MagSize-1 or CancelReload or ammoBool.Value == 1) and VMReload2Last then -- if Reload2Last animation exists, play that if last shell is inserted
						-- This will also play if CancelReload is true and then stop the reload cycle after Reload2Last is finished.
						animationHandle("Reload2Last","Play")
						if Settings.Reload2LastSpeed then
							animationHandle("Reload2Last","Speed",VMReload2Last.Length/Settings.Reload2LastSpeed,CharReload2Last.Length/Settings.Reload2LastSpeed)
						end
						VMReload2Last.Stopped:Wait()
						if CancelReload then break end
					else -- Otherwise, play the regular Reload2 animation
						animationHandle("Reload2","Play")
						if Settings.Reload2Speed then
							animationHandle("Reload2","Speed",VMReload2.Length/Settings.Reload2Speed,CharReload2.Length/Settings.Reload2Speed)
						end
						VMReload2.Stopped:Wait()
						if CancelReload and not VMReload2Last then break end -- Will only play if Reload2Last does not exist
					end
				end
				CancelReload = false
				if Tool.Parent ~= Character then return end
				--animationHandle("Reload2","Stop")
				animationHandle("Reload3","Play")
				if Settings.Reload3Speed then
					animationHandle("Reload3","Speed",VMReload3.Length/Settings.Reload3Speed,CharReload3.Length/Settings.Reload3Speed)
				end

				if Tool.Parent ~= Character then return end
				--animationHandle("Reload3","Stop")
				--ChangeGrip:Fire(Viewmodel.RightHand)
				Reloading = false
			end
		else
			task.wait()
		end
	end

	local function mouseButtonFire () --/ Checks if gun is full
		if not Bursting and not FireCooldown and (not Humanoid:GetAttribute("Running") or Settings.RunAndGun) then
			if Reloading and not CancelReload and Settings.ReloadStyle == 0 and magBool.Value > 0 then
				CancelReload = true
			elseif not Reloading then

				animationHandle("Reload1","Stop") --/ Still stop the reload animations just in case
				if VMEmptyReload then
					animationHandle("EmptyReload","Stop")
				end

				if VMReload3 then
					animationHandle("Reload3","Stop")
				end

				if magBool.Value > 0 then
					gunPrime() --/ If gun is full, go to next step
				else
					FireCooldown = true
					CTF.playSound(Sounds,"Empty",Handle,true,true) --/ if gun is empty, make clicking noise
					task.wait(60/Settings.RPM)
					FireCooldown = false
				end
			elseif Reloading and Settings.ReloadStyle == 1 and magBool.Value > 0 then
				Reloading = false
				animationHandle("Reload1","Stop")
				if VMEmptyReload then
					animationHandle("EmptyReload","Stop")
				end
				if magBool.Value > 0 then
					gunPrime()
				else
					task.wait()
				end
			else
				task.wait()
			end
		else
			task.wait()
		end
	end
	local function starterFireFunction ()
		if Settings.Automatic then
			while Settings.Automatic and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				mouseButtonFire()
			end
		else
			mouseButtonFire()
		end
	end

	local function scrollAim (Forward)
		if Settings.ScrollAffectsAim and Aiming and Handle:FindFirstChild("AimNear") then
			local Aim = Handle.Aim
			local AimNear = Handle.AimNear
			local AimFar = Handle.AimFar
			local increment = (AimNear.Position-AimFar.Position).Magnitude/10
			if Tool:GetAttribute("AimPosition") then
				Aim.Position = Vector3.new(Aim.Position.X,Aim.Position.Y,Tool:GetAttribute("AimPosition"))
			end
			if Forward then
				Tool:SetAttribute("AimPosition",math.clamp(Aim.Position.Z+increment,AimNear.Position.Z,AimFar.Position.Z))
				TweenService:Create(Aim,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{Position = Vector3.new(Aim.Position.X,Aim.Position.Y,math.clamp(Aim.Position.Z+increment,AimNear.Position.Z,AimFar.Position.Z))}):Play()
			else
				Tool:SetAttribute("AimPosition",math.clamp(Aim.Position.Z-increment,AimNear.Position.Z,AimFar.Position.Z))
				TweenService:Create(Aim,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{Position = Vector3.new(Aim.Position.X,Aim.Position.Y,math.clamp(Aim.Position.Z-increment,AimNear.Position.Z,AimFar.Position.Z))}):Play()
			end
		end
	end

	local function checkRunning ()
		if Humanoid:GetAttribute("Running") then
			if Aiming then
				AimGun(false)
			end
			if Reloading and not CancelReload and Settings.ReloadStyle == 0 and not Settings.RunAndReload then
				CancelReload = true
			elseif Reloading and Settings.ReloadStyle == 1 and not Settings.RunAndReload then
				Reloading = false
				animationHandle("Reload1","Stop",0.1)
				if Settings.EmptyReload then
					animationHandle("EmptyReload","Stop",0.1)
				end
			end
			if not Settings.RunAndGun then
				animationHandle("Run","Play",0.3)
			end
		else
			if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				AimGun(true)
			end
			if UIS:IsKeyDown(KeybindHandler.Keybind("Reload",Player)) then
				Reload()
			end
			animationHandle("Run","Stop",0.3)
		end
	end
	--\\

	--//Animation Handling
	local eventBehavior = {
		["LoadGate"] = function()
			CTF.playSound(Sounds,"GateOpen",Handle,true,true)
		end,
		["LoadGateClose"] = function()
			CTF.playSound(Sounds,"GateClose",Handle,true,true)
		end,
		["EjectShell"] = function()
			dispenseCasing()
			CTF.playSound(Sounds,"Eject",Handle,true,true)
		end,
		["InsertShell"] = function()
			CTF.playSound(Sounds,"Insert",Handle,true,true)
		end,
		["ReloadMag"] = function()
			if Settings.ReloadStyle == 0 then
				magBool.Value += 1
				ammoBool.Value -= 1
				SetItemHolder:FireServer(Tool,"Mag",magBool.Value)
				editBulletFrame("Load")
			else
				local AmmoToUse = math.min(Settings.MagSize - magBool.Value,ammoBool.Value)
				magBool.Value += AmmoToUse
				ammoBool.Value -= AmmoToUse
				editBulletFrame("Mag")
				Reloading = false
			end
		end,
		["FirstShellTransparency"] = function(transparency)
			if MotorModel:FindFirstChild("1") then
				MotorModel["1"].Transparency = transparency
			end
		end,
		["BulletTransparency"] = function(transparency)
			if MotorModel:FindFirstChild("Bullet") then
				MotorModel["Bullet"].Transparency = transparency
			end
		end,
		["MagOut"] = function()
			CTF.playSound(Sounds,"MagOut",Handle,true,true)
		end,
		["MagIn"] = function()
			CTF.playSound(Sounds,"MagIn",Handle,true,true)
		end,
		["BoltBack"] = function()
			CTF.playSound(Sounds,"BoltBack",Handle,true,true)
		end,
		["BoltForward"] = function()
			CTF.playSound(Sounds,"BoltForward",Handle,true,true)

			if magBool.Value == 0 and Settings.BoltBackWhenEmpty and Handle:FindFirstChild("Bolt") then
				local Bolt = Handle.Bolt
				TweenService:Create(Bolt,TweenInfo.new(0.05,Enum.EasingStyle.Linear),{C1 = DefaultBoltC1}):Play()
				Tool:SetAttribute("BoltSet",nil)
			end
		end,

		["BoltRound"] = function()
			assert(Settings.BoltRoundEvent ~= nil,"BoltRound animation event called, but BoltRoundEvent in settings is nil.")
			if Settings.BoltRoundEvent then
				editBulletFrame("Cycle")
				SetItemHolder:FireServer(Tool,"Bolted",true)
				Bolted = true
				HoldFire = false
			end
		end,
	}

	for animName,animation in pairs(animationTable) do
		local VManimation = animation[1]
		local animationEvents = animationEvents[animName]
		if VManimation and animationEvents then
			for _,event in pairs(animationEvents) do
				local eventFunction = VManimation:GetMarkerReachedSignal(event):Connect(function(parameter)
					if eventBehavior[event] then
						eventBehavior[event](parameter)
					end
				end)
				table.insert(animationEventsList,eventFunction)
			end
		end
	end
	--\\

	--//Actions
	if Humanoid:GetAttribute("Running") then
		checkRunning()
	end

	if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		AimGun(true)
	end

	if boltBool.Value then
		if Settings.HammerAngle then
			Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(Settings.HammerAngle.X),math.rad(Settings.HammerAngle.Y),math.rad(Settings.HammerAngle.Z))
		end
		if Settings.CylinderAngle then
			Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(Settings.CylinderAngle.X),math.rad(Settings.CylinderAngle.Y),math.rad(Settings.CylinderAngle.Z))
		end
		Bolted = true
		SetItemHolder:FireServer(Tool,"Bolted",true)
	else
		if Settings.HammerAngle then
			Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
		end
		if Settings.CylinderAngle then
			Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
		end
		if Settings.AutomaticBolt and not Bolted then
			gunPrime()
		end
	end
		--//UI Priming
		ReserveFrame.Visible = true
		ReserveText.Text = ammoBool.Value
		NameText.Text = Tool.Name
		if Settings.Automatic then
			ModeText.Text = "Auto"
		else
			ModeText.Text = "Semi"
		end
		for _,oldBullet in pairs (MagFrame:GetChildren()) do
			if oldBullet:IsA("Frame") then
				oldBullet:Destroy()
			end
		end

			MagFrame.UIGridLayout.CellSize = UDim2.new(1/Settings.MagSize,-1,1,0)
			if Settings.MagSize > 50 then
				MagFrame.UIGridLayout.CellSize = UDim2.new((1/Settings.MagSize)*2,-1,1,0)
				InnerScaleLayout.Padding = UDim.new(1.2,0)
			else
				InnerScaleLayout.Padding = UDim.new(0.2,0)
			end
			for i=1,Settings.MagSize,1 do
				local bullet = PrimeMagBullet:Clone()
				--bullet.Size = UDim2.new(1/Settings.MagSize,-1,1,0)
				if i == 1 then
					bullet.Round.BackgroundColor3 = Color3.fromRGB(255,255,255)
				end
				bullet.Name = tostring(i)
				if tonumber(bullet.Name) > magBool.Value then
					bullet.Round.Size = UDim2.fromScale(1,0)
				end
				bullet.Parent = MagFrame
			end
			if not Bolted and Settings.Bolted and magBool.Value < Settings.MagSize and magBool.Value > 0 then
				local firstRound = MagFrame["1"].Round
				firstRound.Size = UDim2.fromScale(1,0)
			local otherRound = MagFrame[tostring(magBool.Value+1)].Round
				otherRound.Size = UDim2.fromScale(1,1)
			end
		CanvasGroup.GroupTransparency = 1
	TweenService:Create(CanvasGroup,TweenInfo.new(0.3),{GroupTransparency = 0}):Play()

		CanvasGroup.Visible = true
		--\\
	if Handle:FindFirstChild("Bolt") then
		DefaultBoltC1 = Handle.Bolt:GetAttribute("DefaultC1") or Handle.Bolt.C1
		BackBoltC1 = Handle.Bolt.C1+Handle.Bolt.C1[BoltPosition[1]]*BoltPosition[2]
	end
	--\\

	--//Events
	local renderStep = RunService.RenderStepped:Connect(function(dt)
		local updatedRecoilSpring = recoilSpring:update(dt)
		CameraModule.AddModifier(CFrame.Angles(math.rad(updatedRecoilSpring.x),updatedRecoilSpring.y,updatedRecoilSpring.z), true)
	end)

	local inputBegan = UIS.InputBegan:Connect(function(Input,gpe)
		if Tool:GetAttribute("Unequipping") or gpe or Humanoid:GetAttribute("InventoryOpen") then return end
		if Input.KeyCode == KeybindHandler.Keybind("Drop",Player) then
			CTF.dropItem(Character,Tool)
		end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			starterFireFunction()
		end

		if Input.UserInputType == Enum.UserInputType.MouseButton2 then
			AimGun(true)
		end

		if Input.KeyCode == KeybindHandler.Keybind("Reload",Player) then
			Reload()
		end
	end)

	local unequippedTool = Tool:GetAttributeChangedSignal("Unequipping"):Connect(function()
		if Tool:GetAttribute("Unequipping") then
			TweenService:Create(CanvasGroup,TweenInfo.new(Settings.UnequipSpeed or 0.1),{GroupTransparency = 1}):Play()
			AimGun(false)
			for index,_ in pairs(animationTable) do
				animationHandle(index,"Stop",0)
			end
		end
	end)

	local inputEnded = UIS.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton2 then
			AimGun(false)
		end
	end)

	local wheelForward = Mouse.WheelForward:Connect(function()
		scrollAim(true)
	end)
	local wheelBackward = Mouse.WheelBackward:Connect(function()
		scrollAim(false)
	end)

	local runChange = Humanoid:GetAttributeChangedSignal("Running"):Connect(function()
		checkRunning()
	end)

	local backpackChildRemoved = Player.Backpack.ChildRemoved:Connect(function()
		task.delay(0.001,function()
			ReserveText.Text = ammoBool.Value
		end)
	end)

	local backpackChildAdded = Player.Backpack.ChildAdded:Connect(function()
		task.delay(0.001,function()
			ReserveText.Text = ammoBool.Value
		end)
	end)

	Tool.AncestryChanged:Once(function()
		SetItemHolder:FireServer(Tool,"Mag",magBool.Value)
		SetItemHolder:FireServer(Tool,"Bolted",Bolted)
		for index,_ in pairs(animationTable) do
			animationHandle(index,"Stop",0)
		end
		for _,animationEvent in pairs(animationEventsList) do
			animationEvent:Disconnect()
		end

		if MotorModel:FindFirstChild("ScopeObject") then
			ScopeModule.SetEnabled(false)
		end

		CanvasGroup.Visible = false
		HoldFire = false
		Bolted = false
		FireCooldown = false
		Bursting = false
		Aiming = false
		Reloading = false
		CancelReload = false
		spreadReduction = false
		CrosshairPercent.Value = 0
		--ChargePercent.Value = 0
		Humanoid:SetAttribute("Aiming",nil)
		AimGun(false)
		Aim:Fire(false,Settings.AimOutSpeed)
		if Flash:FindFirstChild("FlashLight") then
			Flash.FlashLight.Enabled = false
		end
		for _,bulletFrames in pairs(MagFrame:GetChildren()) do
			if bulletFrames:IsA("Frame") then
				bulletFrames:Destroy()
			end
		end
		disconnectFunctions{inputBegan,inputEnded,renderStep,runChange,wheelBackward,wheelBackward,unequippedTool,backpackChildRemoved}
		Tool:SetAttribute("Activated",nil)
	end)
	--\\
end

return module
