local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Tooling = ReplicatedStorage:WaitForChild("Tooling")
local Tools = Tooling:WaitForChild("Tools")
local PlayerAssets = ReplicatedStorage:WaitForChild("PlayerAssets")
local Events = ReplicatedStorage:WaitForChild("Events")
local ViewmodelEvents = Events:WaitForChild("Viewmodel")

local Shove = ViewmodelEvents:WaitForChild("Shove")
local Aim = ViewmodelEvents:WaitForChild("Aim")
local ChangeGrip = ViewmodelEvents:WaitForChild("ChangeGrip")
local UnequipTool = ViewmodelEvents:WaitForChild("UnequipTool")

local ToolSource = Tooling:WaitForChild("ToolSource")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local FolderViewmodels = PlayerAssets:WaitForChild("Viewmodels")
local PrimeViewmodel = FolderViewmodels:WaitForChild("AwesomeViewModel")

local ToolModules = Modules:WaitForChild("Tool")
local UIModules = Modules:WaitForChild("UI")

local CameraModule = require(script.Parent.Camera)
local MovementModule = require(script.Parent.Movement)
local springModule = require(ToolModules:WaitForChild("spring"))
local spring2Module = require(ToolModules:WaitForChild("spring2"))
local CTF = require(ToolModules:WaitForChild("CommonToolFunctions"))
local KeybindHandler = require(UIModules:WaitForChild("KeybindHandler"))

local Humanoid = nil
local RootPart = nil
local RightHand = nil
local Character = nil
local Sensitivity = 1
local SwaySize = 1
local SwayDividend = 16

local VMAnimator, Animator = nil
local LoadedAnimations: {AnimationTrack}, LoadedCharAnimations: {AnimationTrack} = {}, {}
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

--local bannedAccessories = {"Vest","Belt"}

function module.playAnimation(Anim: Animation, fade: number?, weight: number?, speed: number?)
	if not VMAnimator or VMAnimator.Parent == nil then return end
	local LoadedAnimation = LoadedAnimations[Anim]
	if not LoadedAnimation then
		LoadedAnimation = VMAnimator:LoadAnimation(Anim)
		LoadedAnimations[Anim] = LoadedAnimation
	end
	LoadedAnimation:Play(fade, weight, speed)
	return LoadedAnimation
end

function module.playCharAnimation(Anim: Animation, fade: number?, weight: number?, speed: number?)
	if not Animator or Animator.Parent == nil then return end
	local LoadedAnimation = LoadedCharAnimations[Anim]
	if not LoadedAnimation then
		LoadedAnimation = Animator:LoadAnimation(Anim)
		LoadedCharAnimations[Anim] = LoadedAnimation
	end
	LoadedAnimation:Play(fade, weight, speed)
	return LoadedAnimation
end

function module.stopAnimation(Anim: Animation)
	if not VMAnimator or VMAnimator.Parent == nil then return end
	local LoadedAnimation = LoadedAnimations[Anim]
	if LoadedAnimation then
		LoadedAnimation:Stop()
		return LoadedAnimation
	end
end

function module.stopCharAnimation(Anim: Animation)
	if not Animator or Animator.Parent == nil then return end
	local LoadedAnimation = LoadedCharAnimations[Anim]
	if LoadedAnimation then
		LoadedAnimation:Stop()
		return LoadedAnimation
	end
end

--- Load animation if not already loaded and return it.
function module.getAnimation(Anim: Animation)
	if not VMAnimator or VMAnimator.Parent == nil then return end
	local LoadedAnimation = LoadedAnimations[Anim]
	if not LoadedAnimation then
		LoadedAnimation = VMAnimator:LoadAnimation(Anim)
		LoadedAnimations[Anim] = LoadedAnimation
	end
	return LoadedAnimation
end

--- Load character animation if not already loaded and return it.
function module.getCharAnimation(Anim: Animation)
	if not Animator or Animator.Parent == nil then return end
	local LoadedAnimation = LoadedCharAnimations[Anim]
	if not LoadedAnimation then
		LoadedAnimation = Animator:LoadAnimation(Anim)
		LoadedCharAnimations[Anim] = LoadedAnimation
	end
	return LoadedAnimation
end

local Player = game.Players.LocalPlayer

function module.LoadChar(Character)
	LoadedAnimations = {}
	local Camera = workspace.CurrentCamera
	local Viewmodel = PrimeViewmodel:Clone()
	Viewmodel.Parent = Camera
	Viewmodel.PrimaryPart = Viewmodel.CameraPart

	local evilLightingPart = ReplicatedStorage:WaitForChild("EvilLightingPart"):Clone()
	evilLightingPart.Parent = Camera

	local VMup = 0
	local VMright = 0
	local VMlook = 0
	local VMsway = 1
	local VMaimsway = 0.1
	local SwaySpring = springModule.new()
	local HandleSpring = springModule.new(nil,nil,90,4,3)
	local AimSpring = spring2Module.new(0)
	AimSpring.Damper = 1
	AimSpring.Speed = 16
	local Offset = script:WaitForChild("Offset")
	Humanoid = Character:WaitForChild("Humanoid")
	local BodyColor = Character:WaitForChild("BodyColor")
	Animator = Humanoid:WaitForChild("Animator")
	VMAnimator = Viewmodel.Humanoid.Animator
	RootPart = Character:WaitForChild("HumanoidRootPart")
	RightHand = Character:WaitForChild("RightHand")
	--LeftHandIK = RootPart:WaitForChild("LeftHandIKTarget")
	--RightHandIK = RootPart:WaitForChild("RightHandIKTarget")

	local function armBind (Clothing,Arm)
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

	local function addClothing (Model)
		if Model:GetAttribute("TargetPart") and string.find(Model:GetAttribute("TargetPart"),"Arm") then
			local Clothing = Model:Clone()
			--Clothing:ScaleTo(0.9)
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
				armBind(Clothing,Viewmodel.LeftArm)
			elseif string.find(Clothing.Name,"Right") then
				armBind(Clothing,Viewmodel.RightArm)
			end
			local ActualClothing = Instance.new("ObjectValue")
			ActualClothing.Name = "ActualClothing"
			ActualClothing.Value = Model
			ActualClothing.Parent = Clothing
			Clothing.Parent = Viewmodel
		end
	end
	for _,clothing in pairs(Viewmodel:GetChildren()) do
		if clothing:IsA("Model") and clothing:GetAttribute("TargetPart") then
			clothing:Destroy()
		end
	end
	for _,clothing in pairs(Character:GetChildren()) do
		if clothing:IsA("Model") then
			addClothing(clothing)
		end
	end
	Viewmodel.LeftArm.Color = BodyColor.LeftArmColor3
	Viewmodel.RightArm.Color = BodyColor.RightArmColor3
	local bodyColorChange = BodyColor.Changed:Connect(function()
		Viewmodel.LeftArm.Color = BodyColor.LeftArmColor3
		Viewmodel.RightArm.Color = BodyColor.RightArmColor3
	end)

	local runChange = Humanoid.Running:Connect(function(speed)
		if speed <= .3 then
			Running = false
		else
			Running = true
		end
	end)
	local stateChange = Humanoid.StateChanged:connect(function(oldstate, newstate)
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
			local GripWeld = Viewmodel["RightArm"]["RightArm"]
			--GripWeld.C0 = CFrame.new(GripWeld.C0.Position)*CFrame.Angles(0,0,0)
			--GripWeld.C1 = CFrame.new(GripWeld.C1.Position)*CFrame.Angles(0,0,0)
			HandleSpring:shove(rotForce/divisor/2)
			local g0X,g0Y,g0Z = GripWeld.C0:ToEulerAnglesXYZ()
			local g1X,g1Y,g1Z = GripWeld.C1:ToEulerAnglesXYZ()
			--GripWeld.C1 = CFrame.new(GripWeld.C1.Position)*CFrame.Angles(g0X,g0Y,g0Z)
			--task.delay(0.2,function()
			--	if math.deg(g0X)-math.deg(g1X) >= 0.5 then
			--		GripWeld.C0 = CFrame.new(GripWeld.C0.Position)*CFrame.Angles(0,0,0)
			--		GripWeld.C1 = CFrame.new(GripWeld.C1.Position)*CFrame.Angles(0,0,0)
			--	end
			--end)
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
		if Viewmodel.RightArm:FindFirstChild("GripWeld") then
			local GripWeld = Viewmodel.RightArm["GripWeld"]
			GripWeld.Part0 = Part0
		end
	end)

	local charChildAdd = Character.ChildAdded:Connect(function(Tool)
		if Tool:IsA("Tool") and not Tool:GetAttribute("Removing") and not Viewmodel:FindFirstChild("MotorModel") then
			local T = os.clock()
			if RightHand:FindFirstChild("RightGrip") then Character["RightHand"]["RightGrip"]:Destroy() end
			if not Tool:FindFirstChild("Handle") and Viewmodel:FindFirstChild("MotorModel") then Humanoid:UnequipTools() return end
			local GripWeld = Instance.new("Motor6D")
			GripWeld.Name = "GripWeld"
			GripWeld.C1 = Tool.Grip
			GripWeld.C0 = Viewmodel.RightArm.Grip.CFrame
			GripWeld.Parent = Viewmodel.UpperTorso
			GripWeld.Part0 = Viewmodel.UpperTorso
			GripWeld.Part1 = Tool.Handle

			local MotorModel = Instance.new("Model")
			local MotorModelTool = Instance.new("ObjectValue")
			MotorModelTool.Value = Tool
			MotorModelTool.Name = "Tool"
			MotorModelTool.Parent = MotorModel
			MotorModel.Name = "MotorModel"
			MotorModel.Parent = Viewmodel
			for _,toolPart in pairs(Tool:GetChildren()) do
				if toolPart:IsA("BasePart") then
					toolPart.CanCollide = false
					toolPart.Anchored = false
				end
				if not table.find(IgnoreToolCameraing,toolPart.Name) then
					toolPart.Parent = MotorModel
					if toolPart:IsA("BasePart") then
						toolPart.CollisionGroup = "Viewmodel"
					end
				end
			end
			MotorModel.Handle.Anchored = true

			local animationTable = {}
			local function animationHandle (animation,action,num,secondNum)
				if not num then num = 0 end
				if not secondNum then secondNum = num end
				local animPair = animationTable[animation]
				if not animPair then return end
				local VManim = animPair[1]
				local Charanim = animPair[2]
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

			local function destroyMotorModels ()
				for _,motormodels in pairs(Viewmodel:GetChildren()) do
					if motormodels.Name == "MotorModel" then
						for _,motorPart in pairs(Viewmodel.MotorModel:GetChildren()) do
							if motorPart:IsA("BasePart") or motorPart:IsA("Configuration") then
								motorPart.Parent = motormodels.Tool.Value
								if motorPart:IsA("BasePart") then
									motorPart.CanCollide = false
									motorPart.Anchored = false
								end
							end
						end
						motormodels:Destroy()
						animationHandle("Hold","Stop")
					end
				end
			end

			local animationEventsList = {}
			Tool.AncestryChanged:Once(function()
				destroyMotorModels()
				animationHandle("Unequip","Stop")
				for _,animationEvent in pairs(animationEventsList) do
					animationEvent:Disconnect()
				end
			end)

			if Tools:FindFirstChild(Tool:GetAttribute("ToolName")) then
				print(`T-1 : {os.clock() - T}`)
				local ToolObjects = Tools:FindFirstChild(Tool:GetAttribute("ToolName"))
				if Tool:GetAttribute("ToolSource") and ToolSource[Tool:GetAttribute("ToolSource")] then
					local MMT = 0
					for _, motormodels in pairs(Viewmodel:GetChildren()) do
						if motormodels.Name == "MotorModel" then
							MMT += 1
						end
					end
					if MMT > 1 then destroyMotorModels() return end
					local Source = require(ToolSource[Tool:GetAttribute("ToolSource")])
					Source.Init(Tool, ToolObjects, Character, Viewmodel)
				end
				print(`T-2 : {os.clock() - T}`)

				local Sounds = ToolObjects.Sounds
				local Handle = MotorModel.Handle
				local Settings = require(ToolObjects.Settings)
				local CharacterAnimations = ToolObjects.CharacterAnimations
				local VMAnimations = ToolObjects.VMAnimations
				local CharEquip = nil
				local VMEquip = nil
				local CharFirstEquip = nil
				local VMFirstEquip = nil
				local VMUnequip = nil
				local CharUnequip = nil
				local CharHold = module.getAnimation(VMAnimations.Hold)
				local VMHold = module.getCharAnimation(CharacterAnimations.Hold)
				if VMAnimations:FindFirstChild("FirstEquip") then
					VMFirstEquip = module.getAnimation(VMAnimations.FirstEquip)
					CharFirstEquip = module.getCharAnimation(CharacterAnimations.FirstEquip)
				end
				if VMAnimations:FindFirstChild("Equip") then
					VMEquip = module.getAnimation(VMAnimations.Equip)
					CharEquip = module.getCharAnimation(CharacterAnimations.Equip)
				end
				if VMAnimations:FindFirstChild("Unequip") then
					VMUnequip = module.getAnimation(VMAnimations.Unequip)
					CharUnequip = module.getCharAnimation(CharacterAnimations.Unequip)
				end

				if Settings.BindToHand then
					GripWeld.Parent = Viewmodel.RightArm
					GripWeld.Part0 = Viewmodel.RightArm
				end

				if Settings.GripWeldPosition then
					GripWeld.C0 = CFrame.new(Settings.GripWeldPosition)*CFrame.Angles(GripWeld.C0.Rotation:ToEulerAnglesXYZ())
				end

				Tool:SetAttribute("Unequipping",nil)
				if Tool:GetAttribute("ToolSource") and Tool:GetAttribute("ToolSource") == "Gun" then
					local BackBoltC1 = nil
					local DefaultBoltC1 = nil
					local BoltPosition = Settings.BoltPosition or {"LookVector",0.2}
					local magBool = Tool:WaitForChild("Holder"):WaitForChild("Mag")
					if Handle:FindFirstChild("Bolt") then
						DefaultBoltC1 = Handle.Bolt:GetAttribute("DefaultC1") or Handle.Bolt.C1
						BackBoltC1 = Handle.Bolt.C1+Handle.Bolt.C1[BoltPosition[1]]*BoltPosition[2]
					end
					if magBool.Value == 0 and Settings.BoltBackWhenEmpty and Handle:FindFirstChild("Bolt") and Handle.Bolt.C1 ~= BackBoltC1 and not Tool:GetAttribute("BoltSet") then
						Tool:SetAttribute("BoltSet",true)
						local Bolt = Handle.Bolt
						Bolt.C1 = BackBoltC1
					end
				end

				print(`T-4 : {os.clock() - T}`)

				VMup = Settings.UpOffset or 0
				VMright = Settings.RightOffset or 0
				VMlook = Settings.LookOffset or 0
				VMsway = Settings.Sway or 1
				VMaimsway = Settings.AimSway or 0.1

				local animationEvents = {
					["FirstEquip"] = CTF.getAllAnimationEventNames(VMFirstEquip),
					["Equip"] = CTF.getAllAnimationEventNames(VMEquip),
					["Unequip"] = CTF.getAllAnimationEventNames(VMUnequip),
					["Hold"] = CTF.getAllAnimationEventNames(VMHold),
				}
				animationTable = {
					["FirstEquip"] = {VMFirstEquip,CharFirstEquip},
					["Equip"] = {VMEquip,CharEquip},
					["Unequip"] = {VMUnequip,CharUnequip},
					["Hold"] = {VMHold,CharHold},
				}

				print(`T-5 : {os.clock() - T}`)

				local eventBehavior = {
					["LoadGate"] = function()
						CTF.playSound(Sounds,"GateOpen",Handle,true,true)
					end,
					["LoadGateClose"] = function()
						CTF.playSound(Sounds,"GateClose",Handle,true,true)
					end,
					["EjectShell"] = function()
						CTF.playSound(Sounds,"Eject",Handle,true,true)
					end,
					["InsertShell"] = function()
						CTF.playSound(Sounds,"Insert",Handle,true,true)
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


				print(`T-6 : {os.clock() - T}`)

				if Settings.EquipSpeed then
					if VMAnimations:FindFirstChild("FirstEquip") and not Tool:GetAttribute("FirstEquipActivated") then
						animationHandle("FirstEquip","Play")
						Humanoid:SetAttribute("DisableEquip",true)
						task.wait(Settings.EquipSpeed)
						Humanoid:SetAttribute("DisableEquip",nil)
					else
						animationHandle("Equip","Play")
						animationHandle("Equip","Speed",VMEquip.Length/Settings.EquipSpeed,CharEquip.Length/Settings.EquipSpeed)

						task.delay(Settings.EquipSpeed-0.05,function()
							animationHandle("Equip","Speed",0)
						end)
						Humanoid:SetAttribute("DisableEquip",true)
						task.wait(Settings.EquipSpeed)
						animationHandle("Equip","Stop")
						Humanoid:SetAttribute("DisableEquip",nil)
					end
				end

				print(`T-7 : {os.clock() - T}`)
				if VMAnimations:FindFirstChild("FirstEquip") and not Tool:GetAttribute("FirstEquipActivated") then
					Tool:SetAttribute("FirstEquipActivated",true)
					local inputsThatCancel = {
						KeybindHandler.Keybind("Reload",Player).Name,
						KeybindHandler.Keybind("Drop",Player).Name,
						KeybindHandler.Keybind("Feint",Player).Name,
						KeybindHandler.Keybind("Sprint",Player).Name,
						Enum.UserInputType.MouseButton1.Name,
						Enum.UserInputType.MouseButton2.Name,
					}
					local equipInputCancel = nil
					equipInputCancel = UIS.InputBegan:Connect(function(key,gpe)
						if gpe then return end
						if VMFirstEquip.IsPlaying and (table.find(inputsThatCancel,key.UserInputType.Name) or table.find(inputsThatCancel,key.KeyCode.Name)) then
							animationHandle("FirstEquip","Stop")
							animationHandle("Hold","Play")
							equipInputCancel:Disconnect()
						end
					end)
					VMFirstEquip.Stopped:Once(function()
						if Tool.Parent == Character then
							animationHandle("FirstEquip","Stop")
							animationHandle("Hold","Play")
						end
					end)
				else
					animationHandle("Hold","Play")
				end

				print("TOOL FULLY LOADED")

				local UnequipToolEvent = UnequipTool.Event:Once(function(t)
					if t ~= Tool then return end
					animationHandle("Hold","Stop")
					animationHandle("Unequip","Play")
					if Settings.UnequipSpeed then
						animationHandle("Unequip","Speed",VMUnequip.Length/Settings.UnequipSpeed,CharUnequip.Length/Settings.UnequipSpeed)
					end
				end)
			else
				Humanoid:UnequipTools()
				warn("Invalid ToolName: "..Tool:GetAttribute("ToolName"))
			end
		elseif Tool:IsA("Model") then
			addClothing(Tool)
		end
	end)

	local charChildRemove = Character.ChildRemoved:Connect(function(Tool)
		if Tool:IsA("Tool") then
			-- // Unequip Tool
			if Viewmodel.UpperTorso:FindFirstChild("GripWeld") then
				VMup = 0
				VMright = 0
				VMlook = 0
				VMsway = 1
				VMaimsway = 0.1
				task.wait()
				if Viewmodel:FindFirstChild("UpperTorso") and Viewmodel.UpperTorso:FindFirstChild("GripWeld") and Viewmodel.UpperTorso.GripWeld.Part1 == Tool:FindFirstChild("Handle") then
					Viewmodel.UpperTorso.GripWeld:Destroy()
				end
			end
			AimSpring.Target = 0
		elseif Tool:IsA("Model") and Tool:GetAttribute("TargetPart") then
			-- // Unequip Clothing
			for _,VMclothing in pairs(Viewmodel:GetChildren()) do
				if VMclothing:IsA("Model") and VMclothing:GetAttribute("TargetPart")and VMclothing.ActualClothing.Value == Tool then
					VMclothing:Destroy()
				end
			end
		end
	end)

	local HandleTransform = nil
	local OriginalTransform = nil
	local AimTransform = nil
	Viewmodel:SetAttribute("CloseToWall",false)
	RunService:BindToRenderStep("UpdateViewModel", Enum.RenderPriority.Camera.Value + 2, function(dt)
		for _, part in ipairs(Character:GetDescendants()) do
			if not part:IsA("BasePart") then continue end
			if part.Name ~= "Head" and (ShowArms or table.find(ArmParts, part.Name) == nil) then
				part.LocalTransparencyModifier = LocalTransparency
			else
				part.LocalTransparencyModifier = 1
			end
		end
		CameraModule.AddModifier(Viewmodel.CameraPart.HumanoidRootPart.Transform) -- apply camera animations
		evilLightingPart:PivotTo(Camera.CFrame)
		local MouseDelta = UserInputService:GetMouseDelta()
		local updatedSwaySpring = SwaySpring:update(dt)
		local updatedHandleSpring = HandleSpring:update(dt)
		Viewmodel:PivotTo(Camera.CFrame:ToWorldSpace(Offset.Value))

		--if Character and not Character:FindFirstChildOfClass("Tool") or Character and Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolSource") ~= "Gun" and Player.PlayerGui.MouseUI["Crosshair"].Value > 0 then
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

		if Humanoid and Running and Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Humanoid:GetState() ~= Enum.HumanoidStateType.Landed then
			local WalkSpeed = MovementModule:GetWalkSpeed()
			walksway = walksway:Lerp(
				CFrame.new((0.07*SwaySize) * math.sin(tick() * (2 * math.floor(WalkSpeed/4))),(0.07*SwaySize) * math.cos(tick() * (4 * math.floor(WalkSpeed/4))),0)*
					CFrame.Angles(0,0,(-.06*SwaySize) * math.cos(tick() * (2 * WalkSpeed/4))),3*Sensitivity*dt)
		else
			walksway = walksway:Lerp(CFrame.new(), 1.5*Sensitivity*dt)
		end
		sway = sway:Lerp(Vector3.new(MouseDelta.X/2,MouseDelta.Y/2,MouseDelta.X/4), 3*Sensitivity*dt)
		if RootPart and Humanoid then
			wallcheckFilterList = {Viewmodel,Character}
			wallcheckParams.FilterDescendantsInstances = wallcheckFilterList
			local wallcheckDistance = 1.8
			local raycastResult = workspace:Raycast(RootPart.Position+RootPart.CFrame.RightVector*.8+Vector3.new(0,2,0), RootPart.CFrame.LookVector * (wallcheckDistance), wallcheckParams)
			if raycastResult and not raycastResult.Instance.Parent:FindFirstChildOfClass("Humanoid") and not raycastResult.Instance.Parent.Parent:FindFirstChildOfClass("Humanoid") then
				if not Viewmodel:GetAttribute("CloseToWall") then
					Viewmodel:SetAttribute("CloseToWall",true)
				end
			else
				if Viewmodel:GetAttribute("CloseToWall") then
					Viewmodel:SetAttribute("CloseToWall",false)
				end
			end
			local walkingLeanForward = 0
			local walkingLeanSide = 0
			local walkingLeanRot = -RootPart.CFrame.RightVector:Dot(Humanoid.MoveDirection)/(SwayDividend/SwaySize)
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
			walkingLeanForward = -RootPart.CFrame.LookVector:Dot(Humanoid.MoveDirection)/(SwayDividend/SwaySize/divisorForward)
			walkingLeanSide = RootPart.CFrame.RightVector:Dot(Humanoid.MoveDirection)/(SwayDividend/(SwaySize*divisorSide))
			strafesway = strafesway:Lerp(CFrame.Angles(walkingLeanForward,walkingLeanSide,walkingLeanRot), 3*Sensitivity*dt)
		end
		jumpsway = jumpswaygoal.Value

		if Character and not Character:FindFirstChildOfClass("Tool") then
			VMup = 0
			VMright = 0
			VMlook = 0
		end

		local finalcf =
			(Camera.CFrame:ToWorldSpace(Offset.Value)*walksway*jumpsway*strafesway *
				CFrame.Angles(math.rad(sway.Y*SwaySize),math.rad(sway.X*SwaySize)/10,math.rad(sway.Z*SwaySize)/2))
			+ (Viewmodel.PrimaryPart.CFrame.UpVector*VMup)
			+ (Viewmodel.PrimaryPart.CFrame.RightVector*VMright)
			+ (Viewmodel.PrimaryPart.CFrame.LookVector*VMlook)
		finalcf *= CFrame.new(updatedSwaySpring.X,updatedSwaySpring.Y,updatedSwaySpring.Z)
		finalcf *= CFrame.new(updatedHandleSpring.Z/4,updatedHandleSpring.Y/4,updatedHandleSpring.X/4)
		Viewmodel:PivotTo(finalcf)

		if Viewmodel:FindFirstChild("MotorModel") and Viewmodel["MotorModel"]:FindFirstChild("Handle") then
			local Handle = Viewmodel["MotorModel"]["Handle"]
			local HandleTransform = Viewmodel:GetPrimaryPartCFrame():ToObjectSpace(Handle.CFrame)
			OriginalTransform = HandleTransform * HandleTransform:Inverse()
			if Viewmodel["MotorModel"]["Handle"]:FindFirstChild("Aim") then
				local AimPart = Handle["Aim"]
				AimTransform = AimPart.WorldCFrame:ToObjectSpace(Handle.CFrame) * HandleTransform:Inverse()

			end
			if AimTransform then
				Offset.Value = OriginalTransform:Lerp(AimTransform, AimSpring.Position)
			end
		else
			AimSpring.Target = 0
			Offset.Value = CFrame.new(0,0,0)
		end

		if Viewmodel:FindFirstChild("MotorModel") and Viewmodel["MotorModel"]:FindFirstChild("Handle") then
			Viewmodel["MotorModel"]["Handle"].CFrame = Viewmodel["MotorModel"]["Handle"].CFrame*CFrame.Angles(updatedHandleSpring.x/6,updatedHandleSpring.y/6,updatedHandleSpring.z/6)
		end

		--LeftHandIK.WorldCFrame = Viewmodel.LeftArm.CFrame * CFrame.new(0, -1.1, 0) * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)
		--RightHandIK.WorldCFrame = Viewmodel.RightArm.CFrame * CFrame.new(0, -1.1, 0) * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)
	end)

	Humanoid.Died:Once(function()
		Humanoid:UnequipTools()
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
		Viewmodel:Destroy()
		evilLightingPart:Destroy()
	end)
end

--function module.Init()
--	local Emotes = PlayerAssets:WaitForChild("Animations"):WaitForChild("Viewmodel"):WaitForChild("Emotes")
--	for _,Emote in pairs(Emotes:GetChildren()) do
--		if Emote:IsA("Animation") then
--				local EmoteAnimation = module.loadAnimation(Emote)
--			for _,emoteSound in pairs(Emote:GetChildren()) do
--				if emoteSound:IsA("Sound") then
--					EmoteAnimation:GetMarkerReachedSignal(emoteSound.Name):Connect(function()
--						if RootPart then
--							CTF.playSound(Emote,emoteSound.Name,RootPart,true,true)
--						end
--					end)
--				end
--			end
--			--EmoteAnimation:Play()
--		end
--	end
--end

return module
