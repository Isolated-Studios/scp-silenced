local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local module = {}

local Tooling = ReplicatedStorage.Tooling
local Tools = Tooling.Tools
local PlayerAssets = ReplicatedStorage.PlayerAssets
local Events = ReplicatedStorage.Events
local ViewmodelEvents = Events.Viewmodel

local Shove = ViewmodelEvents.Shove
local Aim = ViewmodelEvents.Aim
local ChangeGrip = ViewmodelEvents.ChangeGrip

local Modules = ReplicatedStorage.Modules
local FolderViewmodels = PlayerAssets.Viewmodels
local PrimeViewmodel = FolderViewmodels.AwesomeViewModel

local ToolModules = Modules.Tool
local UIModules = Modules.UI

local CameraModule = require(script.Parent.Camera)
local MovementModule = require(script.Parent.Movement)
local springModule = require(ToolModules.spring)
local spring2Module = require(ToolModules.spring2)
local CommonToolFunctions = require(ToolModules.CommonToolFunctions)
local KeybindHandler = require(UIModules.KeybindHandler)
local CommonFuncs = require(Modules.CommonFuncs)
local ToolHandler = nil -- will be set later to avoid memory leaks

local RunType = nil
local RunPosition = nil
local CrouchPosition = nil
local Humanoid = nil
local RootPart = nil
local RightHand = nil
local Character: Model? = nil
local ViewModel: Model? = nil
local ViewModelAnimator: Animator? = nil
local HandleTransform = nil
local OriginalTransform = nil
local AimTransform = nil
local Sensitivity = 1
local SwaySize = 1
local SwayDividend = 16
local Stability = 10
local AimStability = 10
local randomStabilityNum = 1

local Running = false

local WalkSway = CFrame.new(0,0,0)
local StrafeSway = CFrame.new(0,0,0)
local finalcf = CFrame.new(0,0,0)

local lastCameraCFVM = workspace.CurrentCamera.CFrame
local swayOffsetVM = CFrame.new(0,0,0)
local swayOffsetTool = CFrame.new(0,0,0)
local swayMultvm = 0
local swayMulttool = 0

local wallcheckFilterList = {}
local wallcheckParams = RaycastParams.new()
wallcheckParams.FilterDescendantsInstances = wallcheckFilterList
wallcheckParams.FilterType = Enum.RaycastFilterType.Exclude
local jumpswaygoal = Instance.new("CFrameValue")

local ShowArms = true
local LocalTransparency = 0
local LocalTransparencyTransitionTime = 0.1
local ArmParts = {
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperArm", "LeftLowerArm", "LeftHand"
}

local IgnoreToolCameraing = {
	"Hitbox","Meleebox","Holder"
}

local charPartToViewmodelPart = {
	["RightUpperArm"] = "UpperArmAttachment",
	["RightLowerArm"] = "LowerArmAttachment",
	["RightHand"] = 	"HandAttachment",
	["LeftUpperArm"] = 	"UpperArmAttachment",
	["LeftLowerArm"] = 	"LowerArmAttachment",
	["LeftHand"] = 		"HandAttachment",
}
local TorsoPartsToHide = {
	"uppertorso",
	"shirt",
	"tag",
	"logo",
	"uppertorsocloth",
	"uppertorso1",
	"uppertorso2",
	"uppertorso3",
	"lowertorso1",
	"lowertorso2",
	"lowertorso3",
}

function module.getViewModel(): Model?
	return ViewModel
end

function module.getViewModelAnimator(): Animator?
	return ViewModelAnimator
end

local AimSpring = nil
function module.Aim(desiredState, speed)
	if not AimSpring then return end
	if desiredState then
		AimSpring.Target = 1
		AimSpring.Speed = 16 / speed
	else
		AimSpring.Target = 0
		AimSpring.Speed = 16 / speed
	end
end

module.ShoveViewModel = nil

local Player = game.Players.LocalPlayer

function module.Init()
	ToolHandler = require(script.Parent.ToolHandler)
end

function module.LoadChar(Character)
	local Camera = workspace.CurrentCamera
	ViewModel = PrimeViewmodel:Clone()
	ViewModelAnimator = ViewModel.Humanoid.Animator
	ViewModel.Parent = Camera
	ViewModel.PrimaryPart = ViewModel.CameraPart

	local VMup = 0
	local VMright = 0
	local VMlook = 0
	local VMsway = 1
	local VMaimsway = 0.1
	local SwaySpring = springModule.new(nil, nil, nil, 15, 4)
	local HandleSpring = springModule.new(nil,nil,90,4,3)
	AimSpring = spring2Module.new(0)
	AimSpring.Damper = 1
	AimSpring.Speed = 16
	local Offset = CFrame.identity
	Humanoid = Character:WaitForChild("Humanoid")
	local ViewmodelRun = Humanoid:WaitForChild("ViewmodelRun")
	local ViewmodelCrouch = Humanoid:WaitForChild("ViewmodelCrouch")
	local BodyColor = Character:WaitForChild("BodyColor")
	RootPart = Character:WaitForChild("HumanoidRootPart")
	RightHand = Character:WaitForChild("RightHand")

	local function armBind(Clothing, Arm)
		local attachment = Arm[charPartToViewmodelPart[Clothing:GetAttribute("TargetPart")]]
		local weld = Clothing:WaitForChild("BodyWeld",3)
		if not weld then return end
		Clothing:PivotTo(attachment.WorldCFrame)
		weld.Part1 = Arm
		Clothing:PivotTo(attachment.WorldCFrame)
		local ori = Clothing:GetAttribute("OffsetOri") or Vector3.new()
		weld.C1 = ((CFrame.new(Clothing:GetAttribute("Offset")) or CFrame.new())) * CFrame.Angles(math.rad(ori.X), math.rad(ori.Y), math.rad(ori.Z))
		weld.C0 = attachment.CFrame:Inverse()
		for _,part in pairs(Clothing:GetChildren()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end
	end

	local function addClothing(Model)
		if Model:GetAttribute("TargetPart") and string.find(Model:GetAttribute("TargetPart"), "Arm") then
			local Clothing = Model:Clone()
			Clothing.Parent = ReplicatedStorage
			for _,part in pairs(Clothing:GetChildren()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.Anchored = true
					part.CastShadow = false
					part.CollisionGroup = "Viewmodel"
				end
			end
			if string.find(Clothing.Name,"Left") then
				armBind(Clothing,ViewModel.LeftArm)
			elseif string.find(Clothing.Name,"Right") then
				armBind(Clothing,ViewModel.RightArm)
			end
			local ActualClothing = Instance.new("ObjectValue")
			ActualClothing.Name = "ActualClothing"
			ActualClothing.Value = Model
			ActualClothing.Parent = Clothing
			Clothing.Parent = ViewModel
		end
	end

	for _, clothing in ipairs(ViewModel:GetChildren()) do
		if clothing:IsA("Model") and clothing:GetAttribute("TargetPart") then
			clothing:Destroy()
		end
	end
	for _, clothing in ipairs(Character:GetChildren()) do
		if clothing:IsA("Model") then
			addClothing(clothing)
		end
	end
	ViewModel.LeftArm.Color = BodyColor.LeftArmColor3
	ViewModel.RightArm.Color = BodyColor.RightArmColor3
	local bodyColorChange = BodyColor.Changed:Connect(function()
		ViewModel.LeftArm.Color = BodyColor.LeftArmColor3
		ViewModel.RightArm.Color = BodyColor.RightArmColor3
	end)

	local runChange = Humanoid.Running:Connect(function(speed)
		if speed <= .3 then
			Running = false
		else
			Running = true
		end
	end)
	local stateChange = Humanoid.StateChanged:Connect(function(oldstate, newstate)
		if newstate == Enum.HumanoidStateType.Landed then
			local camedit = Instance.new("CFrameValue")
			camedit.Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(-0.75)*SwaySize,0,0)
			local landedrecoil = TweenService:Create(camedit, TweenInfo.new((0.03*6)/Sensitivity, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Value = CFrame.new(0,0,0)}) ; landedrecoil:Play() ; game.Debris:AddItem(landedrecoil, 2)
			landedrecoil.Completed:Connect(function()
				camedit.Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(0.225)*SwaySize,0,0)
				local landedrecovery = TweenService:Create(camedit, TweenInfo.new((0.03*24)/Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Value = CFrame.new(0,0,0)}) ; landedrecovery:Play(); game.Debris:AddItem(landedrecovery, 3)
			end)
			task.defer(function()
				for i = 1,60 do
					Camera.CFrame = Camera.CFrame*camedit.Value
					RunService.Heartbeat:Wait()
				end
			end)
			local viewmodelrecoil = TweenService:Create(jumpswaygoal, TweenInfo.new(0.15/Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Value = CFrame.new(0,0,0)*CFrame.Angles(-math.rad(5)*SwaySize,0,0)}) ; viewmodelrecoil:Play(); game.Debris:AddItem(viewmodelrecoil, 2)
			viewmodelrecoil.Completed:Connect(function()
				local viewmodelrecovery = TweenService:Create(jumpswaygoal, TweenInfo.new(0.7/Sensitivity, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Value = CFrame.new(0,0,0)}) ; viewmodelrecovery:Play() ; game.Debris:AddItem(viewmodelrecovery, 2)
			end)
		elseif newstate == Enum.HumanoidStateType.Freefall then
			local viewmodeljump = TweenService:Create(jumpswaygoal, TweenInfo.new(0.5/Sensitivity, Enum.EasingStyle.Sine), {Value = CFrame.new(0,0,0)*CFrame.Angles(math.rad(7.5)*SwaySize,0,0)}) ; viewmodeljump:Play() ; game.Debris:AddItem(viewmodeljump, 2)
		end
	end)

	module.ShoveViewModel = function(Force, rotForce)
		local divisor = 1
		if AimSpring.Target == 1 then
			divisor = 3
		end
		--local Force = Vector3.new(Force.X,Force.Y,Force.Z)
		SwaySpring:shove(Force/divisor)
		if rotForce then
			local GripWeld = ViewModel["RightArm"]["RightArm"]
			--local rotForce = Vector3.new(rotForce.X,rotForce.Y,rotForce.Z)
			HandleSpring:shove(rotForce/divisor/2)
			--local g0X,g0Y,g0Z = GripWeld.C0:ToEulerAnglesXYZ()
			--local g1X,g1Y,g1Z = GripWeld.C1:ToEulerAnglesXYZ()
		end
	end

	local ChangeGripFunction = ChangeGrip.Event:Connect(function(Part0)
		if ViewModel.RightArm:FindFirstChild("GripWeld") then
			local GripWeld = ViewModel.RightArm["GripWeld"]
			GripWeld.Part0 = Part0
		end
	end)

	local charChildAdd = Character.ChildAdded:Connect(function(Tool: Tool)
		if Tool:IsA("Tool") and not Tool:GetAttribute("Removing") and not ViewModel:FindFirstChild("MotorModel") then

			if RightHand:FindFirstChild("RightGrip") then Character["RightHand"]["RightGrip"]:Destroy() end
			if not Tool:FindFirstChild("Handle") and ViewModel:FindFirstChild("MotorModel") then ToolHandler.UnequipTool(Tool) return end
			if Tool.RequiresHandle or Tool.CanBeDropped then ToolHandler.UnequipTool(Tool) warn("Attempted to equip tool with RequiresHandle/CanBeDropped set to true") end

			-- Set RunType if it exists in the tool

			local GripWeld = Instance.new("Motor6D")
			GripWeld.Name = "GripWeld"
			GripWeld.C1 = Tool.Grip
			GripWeld.C0 = ViewModel.RightArm.Grip.CFrame
			GripWeld.Parent = ViewModel.UpperTorso
			GripWeld.Part0 = ViewModel.UpperTorso
			GripWeld.Part1 = Tool.Handle

			if ReplicatedStorage.Tooling.Tools:FindFirstChild(Tool:GetAttribute("ToolName")) then
				local toolSettings = require(ReplicatedStorage.Tooling.Tools[Tool:GetAttribute("ToolName")].Settings)
				RunType = toolSettings.RunType
				RunPosition = toolSettings.RunPosition
				CrouchPosition = toolSettings.CrouchPosition
				Stability = toolSettings.Stability or 10
				AimStability = toolSettings.AimStability or 10
				if toolSettings.BindToHand then
					GripWeld.Part0 = ViewModel.RightArm
				end
			else
				RunType = nil
				RunPosition = nil
				CrouchPosition = nil
				Stability = 10
				AimStability = 10
			end

			local MotorModel = Instance.new("Model")
			MotorModel.Name = "MotorModel"
			MotorModel.Parent = ViewModel
			for _,toolPart in pairs(Tool:GetChildren()) do
				if toolPart:IsA("BasePart") then
					toolPart.CanCollide = false
					toolPart.Anchored = false
				end
				if not table.find(IgnoreToolCameraing, toolPart.Name) then
					toolPart.Parent = MotorModel
					if toolPart:IsA("BasePart") then
						toolPart.CollisionGroup = "Viewmodel"
					end
				end
			end
			MotorModel.Handle.Anchored = true

			local function destroyMotorModel()
				if not MotorModel then return end
				for _, Child in pairs(MotorModel:GetChildren()) do
					Child.Parent = Tool
					if Child:IsA("BasePart") then
						Child.CanCollide = false
						Child.Anchored = false
					end
				end
				MotorModel:Destroy()
				MotorModel = nil
			end

			Tool.Unequipped:Once(destroyMotorModel)
			Tool.Destroying:Once(destroyMotorModel)
		elseif Tool:GetAttribute("TargetPart") then
			addClothing(Tool)
		end
	end)

	local charChildRemove = Character.ChildRemoved:Connect(function(Child: Model | Tool)
		if Child:IsA("Tool") then
			-- // Unequip Tool
			if ViewModel.UpperTorso:FindFirstChild("GripWeld") then
				VMup = 0
				VMright = 0
				VMlook = 0
				VMsway = 1
				VMaimsway = 0.1
				if ViewModel:FindFirstChild("UpperTorso") and ViewModel.UpperTorso:FindFirstChild("GripWeld") then--and ViewModel.UpperTorso.GripWeld.Part1 == Child:FindFirstChild("Handle") then
					ViewModel.UpperTorso.GripWeld:Destroy()
				end
			end
			AimSpring.Target = 0
		elseif Child:IsA("Model") and Child:GetAttribute("TargetPart") then
			-- // Unequip Clothing
			for _,VMclothing in pairs(ViewModel:GetChildren()) do
				if VMclothing:IsA("Model") and VMclothing:GetAttribute("TargetPart")and VMclothing.ActualClothing.Value == Child then
					VMclothing:Destroy()
				end
			end
		end
	end)

	local changeRunTransforms = {
		[1] = function () -- Rifle run
			local Front = 0.4
			local Up = -0.2
			local Side = 0.8
			local FrontRot = 20
			local UpRot = -15
			local SideRot = 60
			return Front,Up,Side,FrontRot,UpRot,SideRot
		end,

		[2] = function () -- Pistol run
			local Front = 0
			local Up = -0.84
			local Side = 0.3
			local FrontRot = 0 
			local UpRot = 30
			local SideRot = 10
			return Front,Up,Side,FrontRot,UpRot,SideRot
		end,

		[3] = function () -- Random tool run (medical items, etc.)
			local Front = 0
			local Up = 0
			local Side = 0
			local FrontRot = 0 
			local UpRot = -20
			local SideRot = 0
			return Front,Up,Side,FrontRot,UpRot,SideRot
		end,
	}

	local function swayRotLoop (swayMultvm,swayMulttool) -- Rotational sway for turning camera
		if ViewModel and ViewModel:FindFirstChild("MotorModel") and ViewModel.MotorModel:FindFirstChild("Handle") then
			local rotationVM = workspace.CurrentCamera.CFrame:toObjectSpace(lastCameraCFVM) 
			local xVM,yVM,zVM = rotationVM:ToOrientation()
			swayOffsetVM = swayOffsetVM:Lerp(CFrame.Angles(math.sin(xVM)*swayMultvm,math.sin(yVM)*swayMultvm,0), 0.1)
			swayOffsetTool = swayOffsetTool:Lerp(CFrame.Angles(math.sin(xVM)*swayMulttool,math.sin(yVM)*swayMulttool,0), 0.1)
			ViewModel:PivotTo(ViewModel.PrimaryPart.CFrame * swayOffsetVM)
			ViewModel.MotorModel.Handle.CFrame = ViewModel.MotorModel.Handle.CFrame * swayOffsetTool
			lastCameraCFVM = workspace.CurrentCamera.CFrame
		end
	end

	ViewModel:SetAttribute("CloseToWall",false)
	local function uglyViewmodelMath (MouseDelta,updatedSwaySpring,updatedHandleSpring,dt)
		local WalkSpeed = MovementModule:GetWalkSpeed()
		local AppliedSwaySize = SwaySize
		if AimSpring.Target == 1 then
			AppliedSwaySize = SwaySize/5
		end
		if Humanoid and Running and Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Humanoid:GetState() ~= Enum.HumanoidStateType.Landed then
			WalkSway = WalkSway:Lerp(
				CFrame.new((0.07*AppliedSwaySize) * math.sin(tick() * (2 * math.floor(WalkSpeed/4))),(0.07*AppliedSwaySize) * math.cos(tick() * (4 * math.floor(WalkSpeed/4))),0)*
					CFrame.Angles(0,0,(-.06*AppliedSwaySize) * math.cos(tick() * (2 * WalkSpeed/4))),3*Sensitivity*dt)
		else
			WalkSway = WalkSway:Lerp(CFrame.new(), 1.5*Sensitivity*dt)
		end

		--//Sway that deals with Strafing
		local AimSwayDivisor = 1
		local Handle = ViewModel["MotorModel"]["Handle"]
		local Aim = nil
		if ViewModel.MotorModel:FindFirstChild("Aim") then
			Aim = ViewModel.MotorModel.Aim
		end

		local SwayDividend = 16
		if AimSpring.Target == 1 then
			SwayDividend = 5
		end
		local walkingLeanForward = 0
		local walkingLeanSide = 0
		local walkingLeanRot = -RootPart.CFrame.RightVector:Dot(Humanoid.MoveDirection)/(SwayDividend/SwaySize)
		if AimSpring.Target == 0 then
			local divisorForward = 0.8
			if (-RootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection)) > 0 then
				divisorForward = 3
			end

			walkingLeanForward = -RootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection)/(SwayDividend/(SwaySize/divisorForward))
			walkingLeanSide = RootPart.CFrame.RightVector:Dot(Humanoid.MoveDirection)/(SwayDividend/(SwaySize*1.5))
		end
		--local StrafeSway = StrafeSway:Lerp(CFrame.Angles(walkingLeanForward,walkingLeanSide,walkingLeanRot), 0.1)
		--\\

		--//Set viewmodel cframe based on if you're aiming or not
		if Aim then
			Aim.CFrame = Camera.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0.5, -0.5, -0.8), Vector3.new(0, 0, -100)))
		end
		local HeadOffset =  0.2
		local FrontOffset =  0
		local SideOffset =  0
		finalcf = Camera.CFrame:ToObjectSpace((Camera.CFrame*WalkSway*StrafeSway+Camera.CFrame.UpVector*-HeadOffset+Camera.CFrame.LookVector*FrontOffset+Camera.CFrame.RightVector*SideOffset))

		-- Default transforms
		local Front = 0
		local Up = 0
		local Side = 0
		local FrontRot = 0 
		local UpRot = 0
		local SideRot = 0

		if RunType then
			Front,Up,Side,FrontRot,UpRot,SideRot = changeRunTransforms[RunType]()
		end

		if RunPosition then -- If RunPosition in tool settings, override run positions
			Front = RunPosition[1]
			Up = RunPosition[2]
			Side = RunPosition[3]
			FrontRot = RunPosition[4] 
			UpRot = RunPosition[5]
			SideRot = RunPosition[6]
		end

		-- Apply run transforms
		finalcf = finalcf:Lerp((finalcf+finalcf.RightVector*Side+finalcf.LookVector*Front+finalcf.UpVector*Up)*CFrame.Angles(math.rad(UpRot),math.rad(SideRot),math.rad(FrontRot)),ViewmodelRun.Value)
		--Crouch Transforms
		local CrouchFront = -0
		local CrouchUp = -0.1
		local CrouchSide = -0.1
		local CrouchFrontRot = 27
		local CrouchUpRot = 0
		local CrouchSideRot = 0

		if CrouchPosition then -- If CrouchPosition in tool settings, override crouch positions
			CrouchFront = RunPosition[1]
			CrouchUp = RunPosition[2]
			CrouchSide = RunPosition[3]
			CrouchFrontRot = RunPosition[4] 
			CrouchUpRot = RunPosition[5]
			CrouchSideRot = RunPosition[6]
		end

		-- Apply crouch transforms
		finalcf = finalcf:Lerp((finalcf+finalcf.RightVector*CrouchSide+finalcf.LookVector*CrouchFront+finalcf.UpVector*CrouchUp)*CFrame.Angles(math.rad(CrouchUpRot),math.rad(CrouchSideRot),math.rad(CrouchFrontRot)),ViewmodelCrouch.Value)
		--~~~~~~~~~~~~~~~~~
		if finalcf and ViewModel and ViewModel.PrimaryPart then
			-- set stability based on aiming or not
			local stabilityToUse = Stability/10
			if AimSpring.Target == 1 and AimStability then
				stabilityToUse = AimStability/10
			end

			ViewModel:PivotTo((((Camera.CFrame:ToWorldSpace(finalcf)*WalkSway*StrafeSway))) * CFrame.new(0, 0.175, 0))
			if Aim then -- Set aim using aim spring
				Aim.CFrame = Aim.CFrame:Lerp(Camera.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0, 0, -0.3), Vector3.new(0, 0, -100))*WalkSway*StrafeSway), AimSpring.Position) 
			end

			ViewModel:PivotTo(ViewModel.PrimaryPart.CFrame*CFrame.new(updatedSwaySpring.x,updatedSwaySpring.y,updatedSwaySpring.z))
			Handle.CFrame = Handle.CFrame*CFrame.Angles( (((updatedHandleSpring.z)^2)^0.5) / stabilityToUse , (((updatedHandleSpring.y)^2)^0.5) / (stabilityToUse*2) ,0)	
			if AimSpring.Target == 0 then swayRotLoop(1,1.2) else swayRotLoop(0.3,0.5) end -- Apply rotational sway
		end

		if ViewModel:FindFirstChild("MotorModel") and ViewModel["MotorModel"]:FindFirstChild("Handle") then
			ViewModel["MotorModel"]["Handle"].CFrame = ViewModel["MotorModel"]["Handle"].CFrame*CFrame.Angles(updatedHandleSpring.x/6,updatedHandleSpring.y/6,updatedHandleSpring.z/6)
		end
	end

	RunService:BindToRenderStep("UpdateViewModel", Enum.RenderPriority.Camera.Value + 2, function(dt)

		for _, part in ipairs(Character:GetDescendants()) do
			if not part:IsA("BasePart") then continue end
			if part.Name ~= "Head" 
				-- Torso is hidden to prevent seeing it when rocking character's waist back and forth in Movement.
				and not table.find(TorsoPartsToHide,string.lower(part.Name))
				and (ShowArms or table.find(ArmParts, part.Name) == nil) 
			then
				part.LocalTransparencyModifier = LocalTransparency
			elseif Humanoid.Health > 0 then -- prevents corpse parts being invisible.
				part.LocalTransparencyModifier = 1
			end
		end
		-- set stability based on aiming or not
		local stabilityToUse = Stability/10
		if AimSpring.Target == 1 and AimStability then
			stabilityToUse = AimStability/10
		end

		CameraModule.AddModifier(ViewModel.CameraPart.HumanoidRootPart.Transform) -- apply camera animations
		local MouseDelta = UserInputService:GetMouseDelta()
		local updatedSwaySpring = SwaySpring:update(dt)
		local updatedHandleSpring = HandleSpring:update(dt,stabilityToUse)
		ViewModel:PivotTo(Camera.CFrame:ToWorldSpace(Offset))
		ShowArms = 
			if Character and Character:FindFirstChildOfClass("Tool") then false
			else true

		if Character and Character:FindFirstChildOfClass("Tool") and not CommonFuncs.AreInputUIsActive() then
			if Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolSource") == "Gun"
				and Player.PlayerGui 
				and Player.PlayerGui:FindFirstChild("MouseUI")
				and Player.PlayerGui.MouseUI:FindFirstChild("Dot")
			then
				Player.PlayerGui.MouseUI["Dot"]["Crosshair"].GroupTransparency = AimSpring.Position
				Player.PlayerGui.MouseUI["Dot"].BackgroundTransparency = 1
				Player.PlayerGui.MouseUI["Dot"]["UIStroke"].Transparency = 1
			end
		else
			if Player.PlayerGui 
				and Player.PlayerGui:FindFirstChild("MouseUI") 
				and Player.PlayerGui.MouseUI:FindFirstChild("Dot") 
			then
				Player.PlayerGui.MouseUI["Dot"]["Crosshair"].GroupTransparency = AimSpring.Position
				Player.PlayerGui.MouseUI["Crosshair"].Value = 0
				Player.PlayerGui.MouseUI["Dot"].BackgroundTransparency = 0
				Player.PlayerGui.MouseUI["Dot"]["UIStroke"].Transparency = 0.8
			end
		end

		if ShowArms then
			LocalTransparency = math.max(0, LocalTransparency - dt / LocalTransparencyTransitionTime)
		else
			LocalTransparency = math.min(1, LocalTransparency + dt / LocalTransparencyTransitionTime)
		end

		if not ShowArms then
			uglyViewmodelMath(MouseDelta,updatedSwaySpring,updatedHandleSpring,dt)
		end
	end)

	Humanoid.Died:Once(function()
		task.wait()
		bodyColorChange:Disconnect()
		charChildAdd:Disconnect()
		charChildRemove:Disconnect()
		stateChange:Disconnect()
		runChange:Disconnect()
		ChangeGripFunction:Disconnect()
		RunService:UnbindFromRenderStep("UpdateViewModel")
		Running = false
		ViewModel:Destroy()
		ViewModel = nil
		ViewModelAnimator = nil
	end)
end

return module
