local module = {}

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Events = ReplicatedStorage.Events
local Modules = ReplicatedStorage.Modules

local Trove = require(ReplicatedStorage.Packages.Trove)
local CameraModule = require(script.Parent.Camera)
local CommonFuncs = require(Modules.CommonFuncs)
local KeybindHandler = require(Modules.UI.KeybindHandler)

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local LookEvent = Events.Character.LookEvent
local DamageEvent = Events.Tool.Damage
local SoundEvent = Events.Tool.SoundEvent
local StopRunningEvent = Events.Character.StopRunning

local PlayerAnimations = ReplicatedStorage.PlayerAssets.Animations.Character.Movement
local FallDamageSounds = ReplicatedStorage.Sounds.FallDamage

local CrouchTweenInfo = TweenInfo.new(.2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut)

local DefaultWalkSpeed = 16
local DefaultRunSpeed = 28
local DefaultCrouchSpeed = 10
local DefaultDownedSpeed = 5
local regenWaitNumber = 1
local MajorFallSoundDamage = 40 -- How much damage needs to at least happen for Major fall damage sound to play. 

-- Fall damage values
local MaxVelocity = 150 -- Maximum velocity for player to take the max damage.
local MinVelocity = 70 -- Minimum velocity to start taking fall damage.
local MaxFallDamage = 100
local FallDamageTeams = {"Class-D", "Facility Personnel"} -- Teams that can take fall damage.

local stillCrouchOffset = Vector3.new(0,-1.75,0)
local movingCrouchOffset = Vector3.new(0,-1.3,0)
local downedOffset = Vector3.new(0,-3.5,0)
local noneCrouchOffset = Vector3.new(0,0,0)

local MoveDirection = Vector3.zero
local TargetDirection = Vector3.zero
local Acceleration = 125
local WalkSpeed = 20
local currentSpeed = 0
local CameraLean = CFrame.new()

function module.GetWalkSpeed()
	return math.floor(WalkSpeed * 10) / 10
end

function module.LoadChar(Character)
	-- Booleans
	local inAir = false
	local jumpCooldown = false
	local staminaGrowthStarted = false
	local walkingBackwards = false
	local standingStill = false
	local CrouchWalking = false
	local DownedWalking = false
	local NewSprintInput = false

	-- Character stuff
	local Humanoid: Humanoid = Character:WaitForChild('Humanoid')
	local ViewmodelCrouch = Humanoid:WaitForChild("ViewmodelCrouch")
	local ViewmodelRun = Humanoid:WaitForChild("ViewmodelRun")
	local Animator = Humanoid:WaitForChild("Animator")
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	local Head = Character:WaitForChild("Head")
	local UpperTorso = Character:WaitForChild("UpperTorso")

	local LeftShoulder = Character:WaitForChild("LeftUpperArm"):WaitForChild("LeftShoulder")
	local RightShoulder = Character:WaitForChild("RightUpperArm"):WaitForChild("RightShoulder")
	local Waist = UpperTorso:WaitForChild("Waist")
	local Neck = Head:WaitForChild("Neck")

	-- UI
	local InteractUI = Player.PlayerGui:WaitForChild("InteractUI")
	local SittingUI = InteractUI.SittingUI

	-- Tables
	local AllowedLimbs = {
		"Head",
		"UpperTorso",
		"LowerTorso",
		"LeftUpperArm",
		"LeftLowerArm",
		"LeftHand",
		"RightUpperArm",
		"RightLowerArm",
		"RightHand",
		"LeftUpperLeg",
		"LeftLowerLeg",
		"LeftFoot",
		"RightUpperLeg",
		"RightLowerLeg",
		"RightFoot",
	}
	local _trove = Trove.new()

	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

	-- Create ShadowLimbs that will be used to display a shadow of the character
	local ShadowLimbs = Instance.new("Model")
	ShadowLimbs.Name = "ShadowLimbs"
	ShadowLimbs.Parent = Camera
	for _,ActualLimb in pairs(Character:GetChildren()) do
		if ActualLimb:IsA("BasePart") and table.find(AllowedLimbs,ActualLimb.Name) then
			local ShadowLimb = Instance.new("Part")
			ShadowLimb.Name = "Shadow"..ActualLimb.Name
			ShadowLimb.CanCollide = false
			ShadowLimb.Anchored = true
			CollectionService:AddTag(ShadowLimb, "CharPart")
			ShadowLimb.CollisionGroup = "Character"
			ShadowLimb.Material = Enum.Material.ForceField
			ShadowLimb.Transparency = -math.huge
			ShadowLimb.Size = ActualLimb.Size
			CollectionService:AddTag(ShadowLimb, "Ignore")
			ShadowLimb.Parent = ShadowLimbs

			local Actual = Instance.new("ObjectValue")
			Actual.Name = "ActualLimb"
			Actual.Value = ActualLimb
			Actual.Parent = ShadowLimb

			ShadowLimb:PivotTo(ActualLimb:GetPivot()) 
		end
	end

	local CharRun = Animator:LoadAnimation(PlayerAnimations:WaitForChild("Run"))
	local CharCrouchIdle = Animator:LoadAnimation(PlayerAnimations:WaitForChild("CrouchIdle"))
	local CharCrouchWalk = Animator:LoadAnimation(PlayerAnimations:WaitForChild("CrouchWalk"))
	local CharDownedIdle = Animator:LoadAnimation(PlayerAnimations:WaitForChild("DownedIdle"))
	local CharDownedWalk = Animator:LoadAnimation(PlayerAnimations:WaitForChild("DownedWalk"))

	local function setWalkSpeed()
		local directionCorrelation = (HumanoidRootPart.CFrame.LookVector:Dot(TargetDirection))
		if directionCorrelation ~= directionCorrelation then directionCorrelation = 1 end
		if directionCorrelation < -0.65 then
			walkingBackwards = true
			if Humanoid:GetAttribute("Running") then
				Humanoid:SetAttribute("Running", false)
			end
		else
			walkingBackwards = false
		end
		local directionalSlowdown = 1 - (math.min(math.abs(directionCorrelation), 0.8) / 0.8)
		directionalSlowdown = math.min(TweenService:GetValue(directionalSlowdown, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), 0.7)
		directionalSlowdown -= math.clamp(directionCorrelation, -1, 0)

		local SpeedDebuff = directionalSlowdown * 30
		if Humanoid:GetAttribute("Swinging") then
			SpeedDebuff +=-30
		end
		SpeedDebuff += Humanoid:GetAttribute("SpeedDebuff")
		if Humanoid:GetAttribute("FreezeWalkSpeed") then
			SpeedDebuff = 100
		end
		if SpeedDebuff > 100 then
			SpeedDebuff = 100
		end
		SpeedDebuff = SpeedDebuff*0.01
		if Humanoid:GetAttribute("Running") then
			WalkSpeed = DefaultRunSpeed-DefaultRunSpeed*SpeedDebuff
		elseif Humanoid:GetAttribute("Crouching") then
			WalkSpeed = DefaultCrouchSpeed-DefaultCrouchSpeed*SpeedDebuff
		elseif Humanoid:GetAttribute("Downed") then
			WalkSpeed = DefaultDownedSpeed-DefaultDownedSpeed*SpeedDebuff
		else
			WalkSpeed = DefaultWalkSpeed-DefaultWalkSpeed*SpeedDebuff
		end
	end

	local function regenWait ()
		local beginningStamina = Humanoid:GetAttribute("Stamina")
		local startTime = tick()
		while Humanoid:GetAttribute("Stamina") == beginningStamina do
			local currentTime = tick() - startTime
			if currentTime >= regenWaitNumber then
				break
			end
			task.wait()
		end
		local currentTime = tick() - startTime
		if currentTime < regenWaitNumber then
			regenWait()
		end
	end

	local function changeCrouchOffset ()
		if standingStill and Humanoid:GetAttribute("Crouching") then
			TweenService:Create(Humanoid,CrouchTweenInfo,{CameraOffset = stillCrouchOffset}):Play()
		elseif not standingStill and Humanoid:GetAttribute("Crouching") then
			TweenService:Create(Humanoid,CrouchTweenInfo,{CameraOffset = movingCrouchOffset}):Play()
		else
			TweenService:Create(Humanoid,CrouchTweenInfo,{CameraOffset = noneCrouchOffset}):Play()
		end
	end

	local function startCrouching ()
		if not Humanoid:GetAttribute("Downed") then
			Humanoid:SetAttribute("Crouching",true)
			changeCrouchOffset()
		end
	end
	local function stopCrouching ()
		Humanoid:SetAttribute("Crouching",false)
		changeCrouchOffset()
	end

	local function stopRunning ()
		if Humanoid:GetAttribute("Running") then
			Humanoid:SetAttribute("Running", false)
			TweenService:Create(ViewmodelRun,TweenInfo.new(0.2),{Value = 0}):Play()
		end
	end

	local function startRunning ()
		if not Humanoid:GetAttribute("Running") 
			and not standingStill 
			and not Humanoid:GetAttribute("Crouching") 
			and not Humanoid:GetAttribute("Aiming")
			and not Character:GetAttribute("Loaded") 
			and not walkingBackwards 
			and UIS:IsKeyDown(KeybindHandler.Keybind("Sprint",Player))
			and not Humanoid:GetAttribute("Downed") 
			and NewSprintInput -- prevents the weird "sprint dashes" you can do if you held down sprint with zero stamina and it returned to one and consumed it.
		then
			Humanoid:SetAttribute("Running",true)
			TweenService:Create(ViewmodelRun,TweenInfo.new(0.2),{Value = 1}):Play()
		end
	end

	local function beginStaminaGrowth ()
		staminaGrowthStarted = true
		regenWait()
		local staminaCheckNumber = Humanoid:GetAttribute("Stamina")
		while not Humanoid:GetAttribute("Running") and Humanoid:GetAttribute("Stamina") < Humanoid:GetAttribute("MaxStamina") do
			if staminaCheckNumber > Humanoid:GetAttribute("Stamina") then
				break
			end
			Humanoid:SetAttribute("Stamina",Humanoid:GetAttribute("Stamina")+1)
			staminaCheckNumber = Humanoid:GetAttribute("Stamina")
			task.wait(0.05)
		end
		staminaGrowthStarted = false
		if not staminaGrowthStarted then
			beginStaminaGrowth()
		end
	end

	local function beginStaminaDrain ()
		while Humanoid:GetAttribute("Stamina") > 0 and Humanoid:GetAttribute("Running") do
			Humanoid:SetAttribute("Stamina",Humanoid:GetAttribute("Stamina")-1)
			task.wait(0.15)
		end
		if Humanoid:GetAttribute("Stamina") <= 0 then
			NewSprintInput = false
			stopRunning()
		end
	end

	local attributeFunctions = {
		["Stamina"] = function()
			if not staminaGrowthStarted and not Character:GetAttribute("Loaded") then
				beginStaminaGrowth()
			end
		end,

		["Running"] = function()
			if Humanoid:GetAttribute("Running") and not Character:GetAttribute("Loaded") then
				beginStaminaDrain()
			end
		end,

		["Crouching"] = function()
			if Humanoid:GetAttribute("Crouching") and CharCrouchIdle then
				TweenService:Create(ViewmodelCrouch,TweenInfo.new(0.2),{Value = 1}):Play()
				CharCrouchIdle:Play(0.3)
				if currentSpeed > 0 and CharCrouchWalk and not CrouchWalking then
					CrouchWalking = true
					if not CharCrouchIdle.IsPlaying then
						CharCrouchIdle:Play(0.3)
					end
					CharCrouchWalk:Play(0.3)
				end
			elseif Humanoid:GetAttribute("Crouching") == false and CharCrouchIdle then	
				TweenService:Create(ViewmodelCrouch,TweenInfo.new(0.2),{Value = 0}):Play()
				CrouchWalking = false
				CharCrouchIdle:Stop(0.2)
				CharCrouchWalk:Stop(0.2)
			end
		end,

		["Sitting"] = function()
			if Humanoid:GetAttribute("Sitting") then
				SittingUI.Text = "Press '".. KeybindHandler.Keybind("Get Out of Seat", Player).Name .."' to get up."
				SittingUI.Visible = true
			else
				SittingUI.Visible = false
				Humanoid.Seat.Value = nil
				Humanoid.Sit = false
			end
		end,
	}

	-- Moves the neck, waist, and shoulders and bases it off of the camera direction.
	local function LimbMove (
		CameraDirection: Vector3, 
		LeftShoulder: Motor6D, 
		RightShoulder: Motor6D,
		Neck: Motor6D,
		Waist: Motor6D,
		HeldType: number)

		-- Make sure we have everything
		if not LeftShoulder 
			or not RightShoulder 
			or not Neck 
			or not Waist 
		then 
			return 
		end

		local LimbTweenInfo = TweenInfo.new(0.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)

		local NeckWaistYDirection = if math.asin(CameraDirection.y) > 0 then
			math.asin(CameraDirection.y)/6    
			else math.asin(CameraDirection.y)/2
		local NeckC0 = CFrame.new(Neck.C0.Position) * CFrame.Angles(0, -math.asin(CameraDirection.x), 0) * CFrame.Angles(math.asin(CameraDirection.y)/1.5, 0, 0)
		local LeftShoulderC0 = CFrame.new(LeftShoulder.C0.Position)
		local RightShoulderC0 = CFrame.new(RightShoulder.C0.Position)
		local WaistC0 = CFrame.new(Waist.C0.Position)

		WaistC0 = CFrame.new(Waist.C0.Position) * CFrame.Angles(NeckWaistYDirection, 0, 0)
		if HeldType == 0 then
			LeftShoulderC0 = CFrame.new(LeftShoulder.C0.Position) * CFrame.Angles(math.asin(CameraDirection.y),0,0)
			RightShoulderC0 = CFrame.new(RightShoulder.C0.Position) * CFrame.Angles(math.asin(CameraDirection.y),0,0)
		elseif HeldType == 1 then
			RightShoulderC0 = CFrame.new(RightShoulder.C0.Position) * CFrame.Angles(math.asin(CameraDirection.y),0,0)
		end

		TweenService:Create(Neck, 			LimbTweenInfo, {C0 = NeckC0})			:Play()
		TweenService:Create(LeftShoulder,	LimbTweenInfo, {C0 = LeftShoulderC0})	:Play()
		TweenService:Create(RightShoulder,	LimbTweenInfo, {C0 = RightShoulderC0})	:Play()
		TweenService:Create(Waist,	LimbTweenInfo, {C0 = WaistC0})	:Play()
	end

	local inputBegan = UIS.InputBegan:Connect(function(Input)
		if CommonFuncs.AreInputUIsActive("Inventory") then return end
		if Input.KeyCode == KeybindHandler.Keybind("Crouch", Player) then
			startCrouching()
		end
		if Input.KeyCode == KeybindHandler.Keybind("Sprint", Player) then
			NewSprintInput = true
		end
		if Input.KeyCode == KeybindHandler.Keybind("Get Out of Seat", Player) then
			if Humanoid:GetAttribute("Sitting") then
				Humanoid:SetAttribute("Sitting", nil)
			end
		end
	end)
	_trove:Add(inputBegan)

	local inputEnded = UIS.InputEnded:Connect(function(Input)
		if Input.KeyCode == KeybindHandler.Keybind("Sprint", Player) then
			stopRunning()
		elseif Input.KeyCode == KeybindHandler.Keybind("Crouch", Player) then
			stopCrouching()
			stopRunning()
		end
	end)
	_trove:Add(inputEnded)

	local humanoidRunning = Humanoid.Running:Connect(function(cS) --/ Get currentSpeed to tell if player is moving or not.
		currentSpeed = cS
	end)
	_trove:Add(humanoidRunning)

	local attributeChanged = Humanoid.AttributeChanged:Connect(function(atr)
		if attributeFunctions[atr] then --/ play attribute function from attribute if it exists
			attributeFunctions[atr]()
		end

		if Humanoid:GetAttribute("Downed") and CharDownedIdle then
			CharDownedIdle:Play()
			if currentSpeed > 0 and CharDownedWalk and not DownedWalking then
				DownedWalking = true
				CharDownedWalk:Play(.3)
			end
		elseif CharDownedIdle then
			CrouchWalking = false
			CharDownedIdle:Stop(.2)
			CharDownedWalk:Stop(.2)
		end
	end)
	_trove:Add(attributeChanged)

	local heartBeat = RunService.RenderStepped:Connect(function(dt)		
		-- set target direction
		TargetDirection = Vector3.new(
			(UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
			0,
			(UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
		)

		if CommonFuncs.AreInputUIsActive("Inventory") then 
			TargetDirection = Vector3.new(0,0,0) 
		end

		-- calculate camera lean
		local relativeMoveDir = CFrame.lookAt(Vector3.zero, HumanoidRootPart.CFrame.LookVector * Vector3.new(1, 0, 1)):VectorToObjectSpace(MoveDirection)
		local CamLeanTarget = CFrame.new(0, 0, 0) * CFrame.Angles(
			0.03 * math.sign(relativeMoveDir.Z) * math.min(math.abs(relativeMoveDir.Z), 10) / 10,
			0,
			-0.03 * math.sign(relativeMoveDir.X) * math.min(math.abs(relativeMoveDir.X), 10) / 10
		)
		CameraLean = CameraLean:Lerp(CamLeanTarget, dt * 5)
		CameraModule.AddModifier(CameraLean)

		-- make target relative to looking direction
		TargetDirection = (HumanoidRootPart.CFrame:VectorToWorldSpace(TargetDirection) * Vector3.new(1, 0, 1)).Unit
		setWalkSpeed()
		TargetDirection *= WalkSpeed
		if TargetDirection ~= TargetDirection then TargetDirection = Vector3.zero end

		-- accelerate MoveDirection towards target
		local change = MoveDirection:Lerp(TargetDirection, dt * 10) - MoveDirection
		if change.Magnitude > Acceleration * dt then
			change = change.Unit * Acceleration * dt
		end
		MoveDirection += change
		if (TargetDirection - MoveDirection).Magnitude < 0.1 then
			MoveDirection = TargetDirection
		end

		if MoveDirection.Magnitude > 0 then
			Humanoid.WalkSpeed = MoveDirection.Magnitude
			Humanoid:Move(MoveDirection.Unit)
		else
			Humanoid.WalkSpeed = 0
		end

		if Humanoid:GetAttribute("Crouching") then
			stopRunning()
		end

		if currentSpeed == 0 then
			standingStill = true
			if Humanoid:GetAttribute("Crouching") and Humanoid.CameraOffset == movingCrouchOffset then
				changeCrouchOffset()
			end
			stopRunning()
		else
			standingStill = false
			if Humanoid:GetAttribute("Crouching") and Humanoid.CameraOffset == stillCrouchOffset then
				changeCrouchOffset()
			end
		end

		startRunning()
		local CameraDirection = HumanoidRootPart.CFrame:toObjectSpace(Camera.CFrame).lookVector
		local HeldType = nil
		if Character:FindFirstChildOfClass("Tool") then
			HeldType = 0
			if Character:FindFirstChildOfClass("Tool"):GetAttribute("OneHanded") then
				HeldType = 1
			end
		end

		-- Move limbs and send limb movements to server for other players.
		LimbMove(CameraDirection, LeftShoulder, RightShoulder, Neck, Waist, HeldType)
		LookEvent:FireServer(
			CameraDirection,
			LeftShoulder,
			RightShoulder,
			Neck,
			Waist,
			HeldType
		)
		-- Pivot shadow limbs and set torso/head to collide.
		if Character then
			for _,ShadowLimb in pairs(ShadowLimbs:GetChildren()) do
				ShadowLimb:PivotTo(ShadowLimb.ActualLimb.Value:GetPivot())
			end
			Character.LowerTorso.CanCollide = true
			Character.UpperTorso.CanCollide = true
			Character.Head.CanCollide = true
		end
	end)
	_trove:Add(heartBeat)

	local runChange = Humanoid.Running:Connect(function(speed)
		if speed > 1 and Humanoid:GetAttribute("Running") then
			if not CharRun.IsPlaying then
				CharRun:Play(0.2)
				CharRun:AdjustWeight(5)
			end
		else
			if CharRun.IsPlaying then
				CharRun:Stop(0.2)
			end
		end

		if speed > 1 and Humanoid:GetAttribute("Crouching") and CharCrouchWalk and not CrouchWalking then
			CrouchWalking = true
			CharCrouchWalk:Play(.3)
		elseif CharCrouchWalk and speed <= 1 then
			CrouchWalking = false
			CharCrouchWalk:Stop(.2)
		end

		if speed > 1 and Humanoid:GetAttribute("Downed") and CharDownedWalk and not DownedWalking then
			DownedWalking = true
			CharDownedWalk:Play(.3)
		elseif CharDownedWalk and speed <= 1 then
			DownedWalking = false
			CharDownedWalk:Stop(.2)
		end
	end)
	_trove:Add(runChange)

	-- Determines fall damage.
	local StateChanged = Humanoid.StateChanged:Connect(function(OldState, NewState)
		if OldState == Enum.HumanoidStateType.Freefall 
			and NewState == Enum.HumanoidStateType.Landed
			and table.find(FallDamageTeams, Player.Team.Name) -- Player is a playing team, so they can take fall damage
		then
			local Velocity = HumanoidRootPart.Velocity.Y
			local FallDamageSound = FallDamageSounds.Minor
			local Damage = 0
			Velocity *= -1

			if Velocity > MaxVelocity then
				Damage = MaxFallDamage
			elseif Velocity > MinVelocity then
				Damage = math.clamp(Velocity / 2, 0, MaxFallDamage)
			end

			if Damage <= 0 then -- If damage is nothing, return.
				return 
			elseif Damage >= MajorFallSoundDamage then
				FallDamageSound = FallDamageSounds.Major
			end

			local Tool = {
				["Damage"] = Damage,
				["CanDown"] = false,
				["GibChance"] = 0.5,
				["AnnihilationRange"] = {1,5}
			}
			DamageEvent:FireServer(
				Tool,
				Character,
				Humanoid,
				Character.UpperTorso, -- HitPart
				9, -- Deathnote
				-HumanoidRootPart.CFrame.UpVector -- Direction
			)
			SoundEvent:FireServer(FallDamageSound, HumanoidRootPart, true, true)

		end
	end)
	_trove:Add(StateChanged)

	local LookEventFunction = LookEvent.OnClientEvent:Connect(function(
		CameraDirection: Vector3, 
		LeftShoulder: Motor6D, 
		RightShoulder: Motor6D,
		Neck: Motor6D,
		Waist: Motor6D,
		HeldType: number
	)
		LimbMove(CameraDirection, LeftShoulder, RightShoulder, Neck, Waist, HeldType)
	end)
	_trove:Add(LookEventFunction)
	
	local StopRunningFunction = StopRunningEvent.Event:Connect(function(DoesNotAffectInput: boolean)
		if not DoesNotAffectInput then
			NewSprintInput = false
		end
		stopRunning()
	end)
	_trove:Add(StopRunningFunction)

	Humanoid.Died:Once(function()
		Humanoid:SetAttribute("Sitting", nil)
		SittingUI.Visible = false
		if ShadowLimbs then
			ShadowLimbs:Destroy()
		end
		
		_trove:Destroy()
	end)
	Character.AncestryChanged:Once(function()
		Humanoid:SetAttribute("Running", false)
		Humanoid:SetAttribute("Stamina", Humanoid:GetAttribute("MaxStamina"))
		Humanoid:SetAttribute("Sitting", nil)
		SittingUI.Visible = false
		if ShadowLimbs then
			ShadowLimbs:Destroy()
		end
		
		_trove:Destroy()
	end)
end
return module
