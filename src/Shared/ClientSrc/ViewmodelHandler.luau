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
local ToolHandler = require(script.Parent.ToolHandler)
ToolHandler.injectViewModelHandler(module)

local Humanoid = nil
local RootPart = nil
local RightHand = nil
local Character: Model? = nil
local ViewModel: Model? = nil
local ViewModelAnimator: Animator? = nil
local Sensitivity = 1
local SwaySize = 1
local SwayDividend = 16

local Running = false

local sway = Vector3.new(0,0,0)
local walksway = CFrame.new(0,0,0)
local strafesway = CFrame.Angles(0,0,0)
local jumpsway = CFrame.new(0,0,0)

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

function module.getViewModel(): Model?
	return ViewModel
end

function module.getViewModelAnimator(): Animator?
	return ViewModelAnimator
end

local Player = game.Players.LocalPlayer

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
	local AimSpring = spring2Module.new(0)
	AimSpring.Damper = 1
	AimSpring.Speed = 16
	local Offset = CFrame.identity
	Humanoid = Character:WaitForChild("Humanoid")
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

	local ShoveFunction = Shove.Event:Connect(function(Force,rotForce)
		local divisor = 1
		if AimSpring.Target == 1 then
			divisor = 3
		end
		SwaySpring:shove(Force/divisor)
		if rotForce then
			local GripWeld = ViewModel["RightArm"]["RightArm"]
			HandleSpring:shove(rotForce/divisor/2)
			local g0X,g0Y,g0Z = GripWeld.C0:ToEulerAnglesXYZ()
			local g1X,g1Y,g1Z = GripWeld.C1:ToEulerAnglesXYZ()
		end
	end)

	local AimFunction = Aim.Event:Connect(function(aiming,speed)
		if aiming then
			AimSpring.Target = 1
			AimSpring.Speed = 16/speed
		else
			AimSpring.Target = 0
			AimSpring.Speed = 16/speed
		end
	end)

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

			local GripWeld = Instance.new("Motor6D")
			GripWeld.Name = "GripWeld"
			GripWeld.C1 = Tool.Grip
			GripWeld.C0 = ViewModel.RightArm.Grip.CFrame
			GripWeld.Parent = ViewModel.UpperTorso
			GripWeld.Part0 = ViewModel.UpperTorso
			GripWeld.Part1 = Tool.Handle

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
				-- task.wait()
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
	
	local HandleTransform = nil
	local OriginalTransform = nil
	local AimTransform = nil
	ViewModel:SetAttribute("CloseToWall",false)
	
	local function uglyViewmodelMath (MouseDelta,updatedSwaySpring,updatedHandleSpring,dt)
		local WalkSpeed = MovementModule:GetWalkSpeed()
		if Humanoid and Running and Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Humanoid:GetState() ~= Enum.HumanoidStateType.Landed then
			walksway = walksway:Lerp(
				CFrame.new((0.07*SwaySize) * math.sin(tick() * (2 * math.floor(WalkSpeed/4))),(0.07*SwaySize) * math.cos(tick() * (4 * math.floor(WalkSpeed/4))),0)*
					CFrame.Angles(0,0,(-.06*SwaySize) * math.cos(tick() * (2 * WalkSpeed/4))),3*Sensitivity*dt)
		else
			walksway = walksway:Lerp(CFrame.new(), 1.5*Sensitivity*dt)
		end
		sway = sway:Lerp(Vector3.new(MouseDelta.X/2,MouseDelta.Y/2,MouseDelta.X/4), 3*Sensitivity*dt)
		if RootPart and Humanoid then
			wallcheckFilterList = {ViewModel,Character}
			wallcheckParams.FilterDescendantsInstances = wallcheckFilterList
			local wallcheckDistance = 1.8
			local raycastResult = workspace:Raycast(RootPart.Position+RootPart.CFrame.RightVector*.8+Vector3.new(0,2,0), RootPart.CFrame.LookVector * (wallcheckDistance), wallcheckParams)
			if raycastResult and not raycastResult.Instance.Parent:FindFirstChildOfClass("Humanoid") and not raycastResult.Instance.Parent.Parent:FindFirstChildOfClass("Humanoid") then
				if not ViewModel:GetAttribute("CloseToWall") then
					ViewModel:SetAttribute("CloseToWall",true)
				end
			else
				if ViewModel:GetAttribute("CloseToWall") then
					ViewModel:SetAttribute("CloseToWall",false)
				end
			end
			local walkingLeanForward = 0
			local walkingLeanSide = 0
			local walkingLeanRot = -RootPart.CFrame.RightVector:Dot(Humanoid.MoveDirection)*(WalkSpeed/16)/(SwayDividend/SwaySize)
			local divisorForward = 0.8
			local divisorSide = 1
			if (-RootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection)) > 0 then
				divisorForward = 0.4
			end
			if AimSpring.Target == 1 then
				divisorForward = 0
				divisorSide = 0
				SwaySize = VMaimsway
				SwaySpring:shove(Vector3.new(-MouseDelta.X/1600,MouseDelta.Y/1600,0))
			else
				SwaySize = VMsway
				SwaySpring:shove(Vector3.new(-MouseDelta.X/200,MouseDelta.Y/200,0))
			end
			walkingLeanForward = -RootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection)/(SwayDividend/SwaySize/divisorForward)*(WalkSpeed/16)
			walkingLeanSide = RootPart.CFrame.RightVector:Dot(Humanoid.MoveDirection)/(SwayDividend/(SwaySize*divisorSide))*(WalkSpeed/16)
			if Humanoid and Running then
				strafesway = strafesway:Lerp(CFrame.Angles(walkingLeanForward,walkingLeanSide,walkingLeanRot), 3*Sensitivity*dt)
			else
				strafesway = strafesway:Lerp(CFrame.new(), 3*Sensitivity*dt)
			end
		end
		jumpsway = jumpswaygoal.Value

		if Character and not Character:FindFirstChildOfClass("Tool") then
			VMup = 0
			VMright = 0
			VMlook = 0
		end

		local finalcf =
			(Camera.CFrame:ToWorldSpace(Offset)*walksway*jumpsway*strafesway *
				CFrame.Angles(math.rad(sway.Y*SwaySize),math.rad(sway.X*SwaySize)/10,math.rad(sway.Z*SwaySize)/2))
			+ (ViewModel.PrimaryPart.CFrame.UpVector*VMup)
			+ (ViewModel.PrimaryPart.CFrame.RightVector*VMright)
			+ (ViewModel.PrimaryPart.CFrame.LookVector*VMlook)
		finalcf *= CFrame.new(updatedSwaySpring.X,updatedSwaySpring.Y,updatedSwaySpring.Z)
		finalcf *= CFrame.new(updatedHandleSpring.Z/4,updatedHandleSpring.Y/4,updatedHandleSpring.X/4)
		ViewModel:PivotTo(finalcf)

		if ViewModel:FindFirstChild("MotorModel") and ViewModel["MotorModel"]:FindFirstChild("Handle") then
			local Handle = ViewModel["MotorModel"]["Handle"]
			local HandleTransform = ViewModel:GetPrimaryPartCFrame():ToObjectSpace(Handle.CFrame)
			OriginalTransform = HandleTransform * HandleTransform:Inverse()
			if ViewModel["MotorModel"]["Handle"]:FindFirstChild("Aim") then
				local AimPart = Handle["Aim"]
				AimTransform = AimPart.WorldCFrame:ToObjectSpace(Handle.CFrame) * HandleTransform:Inverse()

			end
			if AimTransform then
				Offset = OriginalTransform:Lerp(AimTransform, AimSpring.Position)
			end
		else
			AimSpring.Target = 0
			Offset = CFrame.new(0,0,0)
		end

		if ViewModel:FindFirstChild("MotorModel") and ViewModel["MotorModel"]:FindFirstChild("Handle") then
			ViewModel["MotorModel"]["Handle"].CFrame = ViewModel["MotorModel"]["Handle"].CFrame*CFrame.Angles(updatedHandleSpring.x/6,updatedHandleSpring.y/6,updatedHandleSpring.z/6)
		end
	end
	
	RunService:BindToRenderStep("UpdateViewModel", Enum.RenderPriority.Camera.Value + 2, function(dt)
		
		for _, part in ipairs(Character:GetDescendants()) do
			if not part:IsA("BasePart") then continue end
			if part.Name ~= "Head" and (ShowArms or table.find(ArmParts, part.Name) == nil) then
				part.LocalTransparencyModifier = LocalTransparency
			else
				part.LocalTransparencyModifier = 1
			end
		end
		
		CameraModule.AddModifier(ViewModel.CameraPart.HumanoidRootPart.Transform) -- apply camera animations
		local MouseDelta = UserInputService:GetMouseDelta()
		local updatedSwaySpring = SwaySpring:update(dt)
		local updatedHandleSpring = HandleSpring:update(dt)
		ViewModel:PivotTo(Camera.CFrame:ToWorldSpace(Offset))

		if Character and Character:FindFirstChildOfClass("Tool") then
			ShowArms = false
			if Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolSource") == "Gun" then
				if Player.PlayerGui and Player.PlayerGui:FindFirstChild("MouseUI") and Player.PlayerGui.MouseUI:FindFirstChild("Dot") then
					Player.PlayerGui.MouseUI["Dot"]["Crosshair"].GroupTransparency = AimSpring.Position
					Player.PlayerGui.MouseUI["Dot"].BackgroundTransparency = 1
					Player.PlayerGui.MouseUI["Dot"]["UIStroke"].Transparency = 1
				end
			end
		else
			if Player.PlayerGui and Player.PlayerGui:FindFirstChild("MouseUI") and Player.PlayerGui.MouseUI:FindFirstChild("Dot") then
				Player.PlayerGui.MouseUI["Dot"]["Crosshair"].GroupTransparency = AimSpring.Position
				Player.PlayerGui.MouseUI["Crosshair"].Value = 0
				Player.PlayerGui.MouseUI["Dot"].BackgroundTransparency = 0
				Player.PlayerGui.MouseUI["Dot"]["UIStroke"].Transparency = 0.8
			end
			ShowArms = true
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
		--shirtChange:Disconnect()
		bodyColorChange:Disconnect()
		charChildAdd:Disconnect()
		charChildRemove:Disconnect()
		stateChange:Disconnect()
		runChange:Disconnect()
		AimFunction:Disconnect()
		ShoveFunction:Disconnect()
		ChangeGripFunction:Disconnect()
		RunService:UnbindFromRenderStep("UpdateViewModel")
		Running = false
		ViewModel:Destroy()
	end)
end

return module
