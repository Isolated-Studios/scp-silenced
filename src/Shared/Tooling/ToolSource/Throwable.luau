local module = {}
--//Services
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--//Service Objects
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Events = ReplicatedStorage:WaitForChild("Events")

local ToolModules = Modules:WaitForChild("Tool")
local UIModules = Modules:WaitForChild("UI")

--//Modules
local CTF = require(ToolModules:WaitForChild("CommonToolFunctions"))
local KeybindHandler = require(UIModules:WaitForChild("KeybindHandler"))
local CustomMouse = require(UIModules:WaitForChild("CustomMouse"))

function module.Init(Tool,ToolObjects,Character,Viewmodel)
	if Tool.Parent ~= Character then return end
	Tool:SetAttribute("Activated",true)
	local Settings = require(ToolObjects:WaitForChild("Settings"))
	--//Player
	local Player = game.Players.LocalPlayer
	local Humanoid = Character:WaitForChild("Humanoid")
	local HRP = Character:WaitForChild("HumanoidRootPart")
	local MotorModel = Viewmodel:WaitForChild("MotorModel")
	
	--//UI
	local PlayerGui = Player.PlayerGui
	local MouseUI = Player.PlayerGui:WaitForChild("MouseUI")
	local DotFrame = MouseUI:WaitForChild("Dot")
	local ArrowPower = MouseUI:WaitForChild("Arrow")
	
	local GunFrame = PlayerGui:WaitForChild("HUD"):WaitForChild("RightFrame"):WaitForChild("ListFrame"):WaitForChild("GunFrame") 
	local CanvasGroup = GunFrame:WaitForChild("CanvasGroup")
	local InnerFrame = CanvasGroup:WaitForChild("InnerFrame")
	local ReserveFrame = CanvasGroup:WaitForChild("ReserveFrame")
	local InfoFrame = InnerFrame:WaitForChild("InfoFrame")
	local NameText = InfoFrame:WaitForChild("Name")
	local ModeText = InfoFrame:WaitForChild("Mode")
	local PrimeMagBullet = GunFrame:WaitForChild("MagBullet")
	local MagFrame = InnerFrame:WaitForChild("MagFrame")
	
	--//Bools
	local Throwing = false
	local Charging = false
	
	--//Tool Objects
	local Sounds = ToolObjects:WaitForChild("Sounds")
	local Handle = MotorModel:WaitForChild("Handle")
	
	--//Beginning Priming
	ArrowPower:SetAttribute("Enabled",true)
	
	--//Animation Priming
	local animationEventsList = {}
	local Animator = Humanoid:WaitForChild("Animator")
	local VMAnimator = Viewmodel.Humanoid.Animator
	local CharacterAnimations = ToolObjects:WaitForChild("CharacterAnimations")
	local VMAnimations = ToolObjects:WaitForChild("VMAnimations")
	
	local VMThrow = VMAnimator:LoadAnimation(VMAnimations.Throw)
	local CharThrow = Animator:LoadAnimation(CharacterAnimations.Throw) 
	local VMRoll = VMAnimator:LoadAnimation(VMAnimations.Roll)
	local CharRoll = Animator:LoadAnimation(CharacterAnimations.Roll) 
	
	local animationEvents = {
		--["AnimationName"] = CTF.getAllAnimationEventNames(VMAnimation),
		["Throw"] = CTF.getAllAnimationEventNames(VMThrow),
		["Roll"] = CTF.getAllAnimationEventNames(VMRoll),
	}

	local animationTable = {
		--["AnimationName"] = {VMAnimation,CharAnimation},
		["Throw"] = {VMThrow,CharThrow},
		["Roll"] = {VMRoll,CharRoll},
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
	
	local function startToss ()
		if Throwing then return end
		if ArrowPower.Value == 1 then 
			animationHandle("Roll","Play")
		else 
			animationHandle("Throw","Play")
		end
		Throwing = true
	end
	
	local function castThrowable ()
		local Origin = Handle.CFrame
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
		local randomValue = math.random(1,999999999)
		CTF.castBullet(Tool, Origin.Position, -Direction, Settings.ThrowPower[ArrowPower.Value], Settings.MaxDistance or nil, Settings.Acceleration or nil, Settings.BulletTemplate or nil, Character,  nil, randomValue, true)
	end
	--\\
	
	--//Animation Handling
	local eventBehavior = {
		["Pin"] = function()
			CTF.playSound(Sounds,"Pin",Handle,true,true)
		end,
		["Charge"] = function()
			if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or UIS:IsKeyDown(KeybindHandler.Keybind("Grenade",Player)) then
				Charging = true
				if VMRoll.IsPlaying then
					animationHandle("Roll","Speed",0)
				else
					animationHandle("Throw","Speed",0)
				end
			end
		end,
		["Throw"] = function()
			CTF.playSound(Sounds,"Throw",Handle,true,true)
			--VMRollAnimation:AdjustSpeed(2)
			Charging = false
			local Origin = Character.PrimaryPart.Position
			if Viewmodel:GetAttribute("CloseToWall") then 
				Origin = Character.PrimaryPart.Position
			end
			Tool:SetAttribute("Removing",true)
			Humanoid:UnequipTools()
			Tool.Parent = ReplicatedStorage
			castThrowable()
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
	--\\

	--//UI Priming
	ReserveFrame.Visible = false
	NameText.Text = Tool.Name
	ModeText.Text = ""
	CanvasGroup.GroupTransparency = 1	
	TweenService:Create(CanvasGroup,TweenInfo.new(0.3),{GroupTransparency = 0}):Play()
	
	local MagBullet = PrimeMagBullet:Clone()
	MagBullet.Parent = MagFrame
	MagFrame.UIGridLayout.CellSize = UDim2.new(1,-1,1,0)

	CanvasGroup.Visible = true
	--\\
	
	--//Events
	
	local inputBegan = UIS.InputBegan:Connect(function(Input,gpe)
		if Tool:GetAttribute("Unequipping") or gpe or Humanoid:GetAttribute("InventoryOpen") then return end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			startToss()
		end
		if not Throwing and Input.UserInputType == Enum.UserInputType.MouseButton2 then
			if ArrowPower.Value < 3 and ArrowPower.Value > 0 then
				ArrowPower.Value += 1
			else
				ArrowPower.Value = 1
			end
		end
		if Input.KeyCode == KeybindHandler.Keybind("Cancel Toss",Player) and Throwing then
			Charging = false
			Throwing = false
			animationHandle("Throw","Stop",0.1)
			animationHandle("Roll","Stop",0.1)
		end
		if Input.KeyCode == KeybindHandler.Keybind("Drop",Player) then
			CTF.dropItem(Character,Tool)
		end
	end)
	local unequippedTool = Tool:GetAttributeChangedSignal("Unequipping"):Connect(function()
		if Tool:GetAttribute("Unequipping") then
			TweenService:Create(CanvasGroup,TweenInfo.new(Settings.UnequipSpeed or 0.1),{GroupTransparency = 1}):Play()
			for index,_ in pairs(animationTable) do
				animationHandle(index,"Stop",0)
			end
		end
	end)
	local inputEnded = UIS.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.KeyCode == KeybindHandler.Keybind("Grenade",Player) then
			if Throwing and Charging and (VMThrow and VMThrow.IsPlaying or VMRoll and VMRoll.IsPlaying) then
				Charging = false
				if ArrowPower.Value == 1 then 
					animationHandle("Roll","Speed",1)
				else 
					animationHandle("Throw","Speed",1)
				end
			end
		end
	end)
	Tool.AncestryChanged:Once(function()
		for index,_ in pairs(animationTable) do
			animationHandle(index,"Stop",0)
		end
		for _,animationEvent in pairs(animationEventsList) do
			animationEvent:Disconnect()
		end
		disconnectFunctions({inputBegan,unequippedTool})
		Throwing = false
		Charging = false
		ArrowPower:SetAttribute("Enabled",false)
		CanvasGroup.Visible = false
		MagBullet:Destroy()
		Tool:SetAttribute("Activated",nil)
	end)
	--\\
end
return module