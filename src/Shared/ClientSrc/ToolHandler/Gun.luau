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
local springModule = require(ToolModules.spring)
local ScopeModule = require(ToolModules.Scope)

--//Events
local HumanoidAttributeEvent = CharacterEvents.HumanoidAttribute
local Shove = ViewmodelEvents.Shove
local Aim = ViewmodelEvents.Aim
local SetItemHolder = ToolEvents.SetItemHolder
local AnimationModifier = ToolEvents.AnimationModifier

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
	local HUD = PlayerGui:WaitForChild("HUD")
	local CrosshairPercent = PlayerGui:WaitForChild("MouseUI"):WaitForChild("Crosshair")
	local GunVignette = HUD:WaitForChild("GunVignette")
	local VignetteAmount = GunVignette.Gradient.VignetteAmount

	--//Tool Objects
	local Sounds = ToolObjects:WaitForChild("Sounds")
	local Handle = MotorModel:WaitForChild("Handle")
	local Flash = Handle:WaitForChild("Flash")
	local Eject = Handle:WaitForChild("Eject")
	local PrimeCasing = Casings["Air"]
	local Holder = Tool:WaitForChild("Holder")
	local boltInstanceValue = Holder:WaitForChild("Bolted")
	local magInstanceValue= Holder:WaitForChild("Mag")
	local ammoInstanceValue = AmmoList:WaitForChild(Settings.AmmoType)

	--//Bools
	local Hammer = nil
	local Cylinder = nil
	local BackBoltC1 = nil
	local DefaultBoltC1 = nil
	local BoltBackTween = nil
	local Equipped = true
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
	local BoltPosition = Settings.BoltPosition or {"LookVector",0.2}
	local VignetteTween = nil
	local ModificationList = {}

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

	local function animationHandle (animation,action,num,charNum)
		if not num then num = 0 end
		if not charNum then charNum = num end
		local VManim = animationTable[animation][1] or nil
		local Charanim = animationTable[animation][2] or nil
		
		local actionFunctions = {
			["Play"] = function (anim,number)
				anim:Play(number)
			end,
			["Stop"] = function (anim,number)
				anim:Stop(number)
			end,
			["Speed"] = function (anim,number)
				anim:AdjustSpeed(number)
			end,
		}
		
		if VManim then
			actionFunctions[action](VManim,num)
		end
		if Charanim then
			actionFunctions[action](Charanim,charNum)
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

	local function regenWait (Value,WaitTime)
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
		if currentTime < Settings.SpreadRegenWait then
			regenWait(Value,WaitTime)
		end
	end

	local function beginSpreadReduction ()
		spreadReduction = true
		regenWait(BulletSpread,Settings.SpreadRegenWait)
		while not FireCooldown and BulletSpread > Settings.MinSpread do
			local ReductionIncrement = Settings.ReductionIncrement or 0.2
			local ReductionWait = Settings.ReductionWait or 0.01
			BulletSpread = math.clamp(BulletSpread-ReductionIncrement,Settings.MinSpread,Settings.MaxSpread)
			CrosshairPercent.Value = BulletSpread
			task.wait(ReductionWait)
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
	
	local function DarkenVignette () -- darkens a vignette when shooting
		if GunVignette then
			local startTime = tick()
			if VignetteTween then VignetteTween:Cancel() end
			local TimeToTween = math.clamp(8*(VignetteAmount.Value-1)^2,0.2,8) -- GENIUS equation....
			VignetteTween = TweenService:Create(VignetteAmount,TweenInfo.new(TimeToTween),{Value = 1})
			local DarkenAmount = Settings.Damage*Settings.BulletsPerShot/400
			if Settings.Automatic then
				DarkenAmount = Settings.Damage*Settings.BulletsPerShot/(Settings.RPM*2)
			end
			if VignetteAmount.Value > 0 then
				local newValue = math.clamp(VignetteAmount.Value-DarkenAmount,0,1)
				VignetteAmount.Value = newValue
			end
			
			local WaitTime = TimeToTween*2+2
			task.delay(WaitTime,function()
				local otherTime = tick()-startTime
				if math.abs(otherTime-WaitTime) < 0.1 and (spreadReduction or BulletSpread == Settings.MinSpread) then -- really cheap way to check if gun is still "firing"
					-- another really cheap way to check if gun is still "firing" when gun is automatic
					if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and Settings.Automatic and magInstanceValue.Value > 0 and not Humanoid:GetAttribute("Running") then return end
					VignetteTween:Play()
				end
			end)
		end
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
		if not Equipped then return end -- Prevents bolting when unequipping
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
			end
		end
		if not Settings.BoltRoundEvent then
			SetItemHolder:FireServer(Tool,"Bolted",true)
			Bolted = true
			HoldFire = false
		end
	end

	local function fireGun () --/ Big evil function that fires the gun
		if Bolted == false then return end --/ the mag is empty

		Bolted = false --/ subtract a round from the mag

		SetItemHolder:FireServer(Tool,"Mag",magInstanceValue.Value) -- UI shenanigans

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
		
		gunSpread() --/ apply gun spread
		CTF.flashGun(Flash,Flash.FlashLight,true) -- uses CTF to flash the gun for light and particles
		DarkenVignette() -- Darken the gun vignette for coolness
		
		local randomValue = math.random(1,999999999) -- I might be a little stupid (for a "key" in determining uniqueness of tracers)
		for i=1,Settings.BulletsPerShot,1 do
			ProjectBullet(randomValue)
		end
		
		animationHandle("Recoil","Play") --/ play the recoil animation

		if magInstanceValue.Value == 0 and Settings.BoltBackWhenEmpty and Handle:FindFirstChild("Bolt") then
			--/ pushes the bolt back if BoltBackWhenEmpty is true and mag is empty
			local Bolt = Handle.Bolt
			BoltBackTween:Play()
			Tool:SetAttribute("BoltSet",true)
		end

		local ShoveAmount = Vector3.new(Settings.CameraShove.X*recoil_modifier.X,Settings.CameraShove.Y*recoil_modifier.Y*possibleNegative,Settings.CameraShove.Z*recoil_modifier*possibleNegative)
		recoilSpring:shove(ShoveAmount) -- shoves the camera
		if Aiming and Settings.AimLinearShove and Settings.AimAngularShove then
			Shove:Fire(Settings.AimLinearShove,Settings.AimAngularShove) --/ shove event but aiming!
		else
			Shove:Fire(Settings.LinearShove,Settings.AngularShove) --/ shove event
		end
		
		task.wait(60/Settings.RPM)
		boltGun()
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
					if not UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
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
			print("fire again!")
			task.wait(60/Settings.RPM)
			boltGun()
			FireCooldown = false
		else
			task.wait()
		end
	end

	local function Reload ()
		-- if magBool.Value < Settings.MagSize and ammoInstanceValue.Value > 0 and not Reloading and (not Humanoid:GetAttribute("Running") or Settings.RunAndReload) then
		if ammoInstanceValue.Value > 0 and not Reloading and (not Humanoid:GetAttribute("Running") or Settings.RunAndReload) then
			CancelReload = false
			Reloading = true
			--ChangeGrip:Fire(Viewmodel.UpperTorso)

			if not Bolted then
				boltGun()
			end

			if Settings.ReloadStyle == 1 then --/ Mag reload
				if magInstanceValue.Value <= 0 and Settings.EmptyReload then
					animationHandle("EmptyReload","Play")
					if Settings.EmptyReloadSpeed then
						animationHandle("EmptyReload","Speed",VMEmptyReload.Length/Settings.EmptyReloadSpeed,CharEmptyReload.Length/Settings.EmptyReloadSpeed)
					end
					
					if Settings.BoltBackWhenEmpty then -- Set to default bolt position when empty reloading because it bolt back in the empty reload animation.
						BoltBackTween:Cancel()
						TweenService:Create(Handle.Bolt,TweenInfo.new(0.05,Enum.EasingStyle.Linear),{C1 = DefaultBoltC1}):Play()
					end
				else
					animationHandle("Reload1","Play")
					if Settings.Reload1Speed then
						animationHandle("Reload1","Speed",VMReload1.Length/Settings.Reload1Speed,CharReload1.Length/Settings.Reload1Speed)
					end
				end

			else --/ Shell reload
				if magInstanceValue.Value <= 0 and Settings.EmptyReload then --/ Will play the EmptyReload as a transition instead of Reload1 if mag is empty
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
				if magInstanceValue.Value <= 0 and Settings.EmptyReload then --/ STOPPPP the empty reload if it exists
					animationHandle("EmptyReload","Stop")
				else
					animationHandle("Reload1","Stop") --/ STOPPPP the reload1 instead
				end
				while Tool.Parent == Character and magInstanceValue.Value < Settings.MagSize and ammoInstanceValue.Value > 0 do
					--/Reload2 is our animation being looped to simulate the shells going in.
					if (magInstanceValue.Value == Settings.MagSize-1 or CancelReload or ammoInstanceValue.Value == 1) and VMReload2Last then -- if Reload2Last animation exists, play that if last shell is inserted
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
		if not Bursting and not FireCooldown and Equipped and (not Humanoid:GetAttribute("Running") or Settings.RunAndGun) then
			if Reloading and not CancelReload and Settings.ReloadStyle == 0 and magInstanceValue.Value > 0 then
				CancelReload = true
			elseif not Reloading then

				animationHandle("Reload1","Stop") --/ Still stop the reload animations just in case
				if VMEmptyReload then
					animationHandle("EmptyReload","Stop")
				end

				if VMReload3 then
					animationHandle("Reload3","Stop")
				end

				if magInstanceValue.Value > 0 then
					gunPrime() --/ If gun is full, go to next step
				else
					FireCooldown = true
					CTF.playSound(Sounds,"Empty",Handle,true,true) --/ if gun is empty, make clicking noise
					task.wait(60/Settings.RPM)
					FireCooldown = false
				end
			elseif Reloading and Settings.ReloadStyle == 1 and magInstanceValue.Value > 0 then
				Reloading = false
				animationHandle("Reload1","Stop")
				if VMEmptyReload then
					animationHandle("EmptyReload","Stop")
				end
				if magInstanceValue.Value > 0 then
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

	--//Actions
	if Humanoid:GetAttribute("Running") then
		checkRunning()
	end

	if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		AimGun(true)
	end

	if boltInstanceValue.Value then
		if Settings.HammerAngle then
			Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(Settings.HammerAngle.X),math.rad(Settings.HammerAngle.Y),math.rad(Settings.HammerAngle.Z))
		end
		if Settings.CylinderAngle then
			Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(Settings.CylinderAngle.X),math.rad(Settings.CylinderAngle.Y),math.rad(Settings.CylinderAngle.Z))
		end
		Bolted = true
		SetItemHolder:FireServer(Tool, "Bolted", true)
	else
		if Settings.HammerAngle then
			Hammer.C0 = CFrame.new(Hammer.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
		end
		if Settings.CylinderAngle then
			Cylinder.C0 = CFrame.new(Cylinder.C0.Position)*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))
		end
		if Settings.AutomaticBolt and not Bolted then
			boltGun()
		end
	end
	if Handle:FindFirstChild("Bolt") then
		DefaultBoltC1 = Handle.Bolt:GetAttribute("DefaultC1") or CFrame.new(0,0,0)
		BackBoltC1 = DefaultBoltC1+DefaultBoltC1[BoltPosition[1]]*BoltPosition[2]
	end
	BoltBackTween = TweenService:Create(Handle.Bolt,TweenInfo.new(0.2,Enum.EasingStyle.Linear),{C1 = BackBoltC1})
	--\\

	--//Events
	
	local renderStep = RunService.RenderStepped:Connect(function(dt)
		local updatedRecoilSpring = recoilSpring:update(dt)
		CameraModule.AddModifier(CFrame.Angles(math.rad(updatedRecoilSpring.x),updatedRecoilSpring.y,updatedRecoilSpring.z), true)
	end)

	local inputBegan = UIS.InputBegan:Connect(function(Input,gpe)
		if not Equipped or gpe or Humanoid:GetAttribute("InventoryOpen") then return end
		if Input.KeyCode == KeybindHandler.Keybind("Drop",Player) then
			CTF.dropItem(Character,Tool)
		end

		if Input.UserInputType == Enum.UserInputType.MouseButton2 then
			AimGun(true)
		end

		if Input.KeyCode == KeybindHandler.Keybind("Reload", Player) then
			Reload()
		end
	end)

	local unequippedTool = Tool:GetAttributeChangedSignal("Unequipping"):Connect(function()
		if Tool:GetAttribute("Unequipping") then
			Equipped = false
			AimGun(false)
			for index,_ in pairs(animationTable) do
				animationHandle(index,"Stop",0)
			end
			if Settings.BoltBackWhenEmpty and magInstanceValue.Value == 0 then -- If gun is empty and BoltBackWhenEmpty, set bolt because reload could be cancelled
				Handle.Bolt.C1 = BackBoltC1
			end
		end
	end)

	local inputEnded = UIS.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton2 then
			AimGun(false)
		end
	end)

	local runChange = Humanoid:GetAttributeChangedSignal("Running"):Connect(function()
		checkRunning()
	end)

	Tool.AncestryChanged:Once(function()
		SetItemHolder:FireServer(Tool, "Mag", magInstanceValue.Value)
		SetItemHolder:FireServer(Tool, "Bolted", Bolted)
		for index,_ in pairs(animationTable) do
			animationHandle(index, "Stop", 0)
		end
		for _,animationFunction in pairs(animationFunctionsList) do
			animationFunction:Disconnect()
		end
		
		for _,TargetName in pairs(ModificationList) do -- Reset any animation modified parts
			if Tool:FindFirstChild(TargetName) then
				if Tool[TargetName]:GetAttribute("OriginalTransparency") then
					Tool[TargetName].Transparency = Tool[TargetName]:GetAttribute("OriginalTransparency")
					AnimationModifier:FireServer("Transparency",Tool[TargetName]:GetAttribute("OriginalTransparency"),Tool,TargetName)
					Tool[TargetName]:SetAttribute("OriginalTransparency",nil)
				end
			end
		end

		if MotorModel:FindFirstChild("ScopeObject") then
			ScopeModule.SetEnabled(false)
		end
		
		if Settings.BoltBackWhenEmpty and magInstanceValue.Value == 0 and Handle:FindFirstChild("Bolt") then -- If gun is empty and BoltBackWhenEmpty, set bolt because reload could be cancelled
			Handle.Bolt.C1 = BackBoltC1
		end
		Equipped = false
		HoldFire = false
		Bolted = false
		FireCooldown = false
		Bursting = false
		Aiming = false
		Reloading = false
		CancelReload = false
		spreadReduction = false
		CrosshairPercent.Value = 0
		if VignetteTween then -- Reset Vignette	
			VignetteTween:Play()
		else
			VignetteAmount.Value = 1
		end
		--ChargePercent.Value = 0
		Humanoid:SetAttribute("Aiming",nil)
		AimGun(false)
		Aim:Fire(false,Settings.AimOutSpeed)
		if Flash:FindFirstChild("FlashLight") then
			Flash.FlashLight.Enabled = false
		end
		disconnectFunctions{inputBegan,inputEnded,renderStep,runChange,unequippedTool}
		Tool:SetAttribute("Activated",nil)
	end)
	--\\
end

return module
