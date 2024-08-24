local module = {}
--//Services
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")

--//Modules
local CTF = require(Modules:WaitForChild("Tool"):WaitForChild("CommonToolFunctions"))
local KeybindHandler = require(Modules:WaitForChild("UI"):WaitForChild("KeybindHandler"))

--//Service Objects
local Events = ReplicatedStorage:WaitForChild("Events")

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

	local GunFrame = PlayerGui:WaitForChild("HUD"):WaitForChild("RightFrame"):WaitForChild("ListFrame"):WaitForChild("GunFrame") 
	local CanvasGroup = GunFrame:WaitForChild("CanvasGroup")
	local InnerFrame = CanvasGroup:WaitForChild("InnerFrame")
	local ReserveFrame = CanvasGroup:WaitForChild("ReserveFrame")
	local InfoFrame = InnerFrame:WaitForChild("InfoFrame")
	local NameText = InfoFrame:WaitForChild("Name")
	local ModeText = InfoFrame:WaitForChild("Mode")
	local PrimeMagBullet = GunFrame:WaitForChild("MagBullet")
	local MagFrame = InnerFrame:WaitForChild("MagFrame")
	local ReserveText = ReserveFrame:WaitForChild("Reserve")
	
	--//Tool Objects
	local Holder = Tool:WaitForChild("Holder")
	local Durability = Holder:WaitForChild("Durability")
	
	--//Bools
	local Winding = false
	local Swinging = false
	local Recovering = false
	local inputCooldown = false
	
	--//Animation Priming
	local animationEventsList = {}
	local Animator = Humanoid:WaitForChild("Animator")
	local VMAnimator = Viewmodel.Humanoid.Animator
	local CharacterAnimations = ToolObjects:WaitForChild("CharacterAnimations")
	local VMAnimations = ToolObjects:WaitForChild("VMAnimations")
	
	local VMSwing1 = VMAnimator:LoadAnimation(VMAnimations.Swing1)
	local CharSwing1 = Animator:LoadAnimation(CharacterAnimations.Swing1)
	
	local VMSwing2 = nil
	local CharSwing2 = nil
	
	if VMAnimations:FindFirstChild("Swing2") then
		VMSwing2 = VMAnimator:LoadAnimation(VMAnimations.Swing2)
		CharSwing2 = Animator:LoadAnimation(CharacterAnimations.Swing2)
	end
	
	local animationEvents = {
		["Swing1"] = CTF.getAllAnimationEventNames(VMSwing1),
		["Swing2"] = CTF.getAllAnimationEventNames(VMSwing2),
	}

	local animationTable = {
		["Swing1"] = {VMSwing1,CharSwing1},
		["Swing2"] = {VMSwing2,CharSwing2},
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
	
	local function startSwing ()
		if not inputCooldown then
			inputCooldown = true
			if not Winding and not Swinging then
				if VMSwing2 and VMSwing2.IsPlaying then inputCooldown = false return end
				task.defer(function()
					Winding = true
					Swinging = false
					local picked = VMSwing1
					local charPicked = CharSwing1
					local SwingSpeed = Settings.Swing1Speed or nil
					if Recovering and Settings.CanCombo and VMSwing2 then
						animationHandle("Swing1","Stop")
						picked = VMSwing2
						charPicked = CharSwing2
						SwingSpeed = Settings.Swing2Speed or nil
					end 
					Recovering = false
					animationHandle(picked.Name,"Play")
					if SwingSpeed then
						animationHandle(picked.Name,"Speed",picked.Length/SwingSpeed,charPicked.Length/SwingSpeed)
					end
					picked:GetMarkerReachedSignal("Swing"):Wait()
					Winding = false
					Swinging = true
					Recovering = false
					if SwingSpeed then
						animationHandle(picked.Name,"Speed",(picked.Length/SwingSpeed)*2,(charPicked.Length/SwingSpeed)*2)
					else
						animationHandle(picked.Name,"Speed",2,2)
					end
					if Settings.RecoveryMarker then
						picked:GetMarkerReachedSignal("Recover"):Wait()
						Winding = false
						Swinging = false
						Recovering = true
						if SwingSpeed then
							animationHandle(picked.Name,"Speed",picked.Length/SwingSpeed,charPicked.Length/SwingSpeed)
						else
							animationHandle(picked.Name,"Speed",1,1)
						end
						picked.Stopped:Wait()
						Winding = false
						Swinging = false
						Recovering = false
					else
						picked.Stopped:Wait()
						Winding = false
						Swinging = false
						Recovering = true
						if SwingSpeed then
							animationHandle(picked.Name,"Speed",picked.Length/SwingSpeed,charPicked.Length/SwingSpeed)
						else
							animationHandle(picked.Name,"Speed",1,1)
						end
						task.wait(Settings.SwingCooldown or 0.1)
						Winding = false
						Swinging = false
						Recovering = false
					end
				end)
			end
			task.wait()
			inputCooldown = false
		end
	end
	--\\
	
	--//Animation Handling
	local eventBehavior = {
		["meow"] = function()
			print("meow")
		end,
		["woof"] = function()
			print("woof")
		end,
	}
	
	--//Actions
	--\\
	
	--//UI Priming
	ReserveFrame.Visible = true
	NameText.Text = Tool.Name
	ModeText.Text = ""
	ReserveText.Text = Durability.Value
	CanvasGroup.GroupTransparency = 1	
	TweenService:Create(CanvasGroup,TweenInfo.new(0.3),{GroupTransparency = 0}):Play()
	
	local MagBullet = PrimeMagBullet:Clone()
	MagBullet.Parent = MagFrame
	MagFrame.UIGridLayout.CellSize = UDim2.new(0,0,1,0)
	TweenService:Create(MagFrame.UIGridLayout,TweenInfo.new(0.2,Enum.EasingStyle.Linear),{CellSize = UDim2.new(Durability.Value/Settings.MaxDurability,0,1,0)}):Play()

	CanvasGroup.Visible = true
	--\\

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
	
	--//Events
	local inputBegan = UIS.InputBegan:Connect(function(Input,gpe)
		if Tool:GetAttribute("Unequipping") or gpe or Humanoid:GetAttribute("InventoryOpen") then return end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			startSwing()
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
	Tool.AncestryChanged:Once(function()
		for index,_ in pairs(animationTable) do
			animationHandle(index,"Stop",0)
		end
		for _,animationEvent in pairs(animationEventsList) do
			animationEvent:Disconnect()
		end
		disconnectFunctions({inputBegan,unequippedTool})
		CanvasGroup.Visible = false
		MagBullet:Destroy()
		Tool:SetAttribute("Activated",nil)
	end)
	--\\
end
return module