local module = {}
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ToolModules = Modules:WaitForChild("Tool")
local KeybindHandler = require(Modules:WaitForChild("UI"):WaitForChild("KeybindHandler"))
local CTF = require(ToolModules:WaitForChild("CommonToolFunctions"))
local RaycastHitbox = require(ToolModules:WaitForChild("RaycastHitboxV4"))
local Events = ReplicatedStorage:WaitForChild("Events")
local ToolEvents = Events:WaitForChild("Tool")
local CharacterEvents = Events:WaitForChild("Character")
local DamageEvent = ToolEvents:WaitForChild("Damage")
local HumanoidAttributeEvent = CharacterEvents:WaitForChild("HumanoidAttribute")
function module.Init(Tool,ToolObjects,Character,Viewmodel)
	if Tool.Parent ~= Character then return end
	local Player = game.Players.LocalPlayer
	local PlayerGui = Player:WaitForChild("PlayerGui")
	local Settings = require(ToolObjects:WaitForChild("Settings"))
	local Humanoid = Character:WaitForChild("Humanoid")
	local HRP = Character:WaitForChild("HumanoidRootPart")
	local Sounds = ToolObjects:WaitForChild("Sounds")
	local Meleebox = Tool:WaitForChild("Meleebox")
	local SwordTrail = Meleebox:WaitForChild("SwordTrail")
	local ShieldIcon = PlayerGui:WaitForChild("MouseUI"):WaitForChild("Dot"):WaitForChild("ShieldIcon")
	local HitHumanoidsList = {}
	local meleeFilter = {Character,Tool,Viewmodel}
	local RaycastMelee = RaycastHitbox.new(Meleebox)
	local meleeParams = RaycastParams.new()
	meleeParams.FilterType = Enum.RaycastFilterType.Exclude
	meleeParams.FilterDescendantsInstances = {meleeFilter}
	RaycastMelee.RaycastParams = meleeParams
	RaycastMelee.Visualizer = false
	RaycastMelee.DetectionMode = RaycastHitbox.DetectionMode.PartMode
	local Charging = false
	local Swinging = false
	local Feinting = false
	local FeintDebounce = false
	local BlockDebounce = false
	local Blocking = false
	local Stunned = false
	
	--//Animation Priming
	local animationEventsList = {}
	local Animator = Humanoid:WaitForChild("Animator")
	local VMAnimator = Viewmodel.Humanoid.Animator
	local CharacterAnimations = ToolObjects:WaitForChild("CharacterAnimations")
	local VMAnimations = ToolObjects:WaitForChild("VMAnimations")
	local VMHit1 = VMAnimator:LoadAnimation(VMAnimations.Hit1)
	local VMHit2 = VMAnimator:LoadAnimation(VMAnimations.Hit2)
	local VMStartBlock = VMAnimator:LoadAnimation(VMAnimations.StartBlock)
	local VMHoldBlock = VMAnimator:LoadAnimation(VMAnimations.HoldBlock)
	local CharHit1 = VMAnimator:LoadAnimation(CharacterAnimations.Hit1)
	local CharHit2 = VMAnimator:LoadAnimation(CharacterAnimations.Hit2)
	local CharStartBlock = VMAnimator:LoadAnimation(VMAnimations.StartBlock)
	local CharHoldBlock = VMAnimator:LoadAnimation(CharacterAnimations.HoldBlock)
	local animationEvents = {
		["Hit1"] = CTF.getAllAnimationEventNames(VMHit1),
		["Hit2"] = CTF.getAllAnimationEventNames(VMHit2),
	}
	local animationTable = {
		["Hit1"] = {VMHit1,CharHit1},
		["Hit2"] = {VMHit2,CharHit2},
		["StartBlock"] = {VMStartBlock,CharStartBlock},
		["HoldBlock"] = {VMHoldBlock,CharHoldBlock},
	}
	local function animationHandle (animation,action,num,secondNum)
		if not num then num = 0 end
		if not secondNum then secondNum = num end
		local VManim = animationTable[animation][1]
		local Charanim = animationTable[animation][2]
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
	local hitAnim = VMHit1
	local charHitAnim = CharHit1
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
	
	local function waitLoop (startTime,End)
		local currentTime = tick() - startTime
		if currentTime >= End then
			return true
		end
		task.wait()
	end
	
	local function smartWait (End,point)
		local startTime = tick()
		if point == 1 then
			while not Swinging and Tool.Parent == Character do
				local currentTime = tick() - startTime
				if currentTime >= End then
					break
				end
				task.wait()
			end
		end
		local currentTime = tick() - startTime
		if currentTime >= End then
			return true
		else
			return false
		end
	end
	
	local function swingFunction ()
		if not Stunned and not Charging and not Swinging and not VMHit2.IsPlaying and Humanoid:GetAttribute("Stamina") > Settings.SwingCost then
			HitHumanoidsList = {}
			Charging = true
			humAtt("Stamina",math.clamp(Humanoid:GetAttribute("Stamina")-Settings.SwingCost,0,Humanoid:GetAttribute("MaxStamina")))
			humAtt("Charging",true,true)
			if Feinting and VMHit1.IsPlaying then
				Feinting = false
				animationHandle("Hit1","Speed",1)
			else
				if VMHit1.IsPlaying then
					animationHandle("Hit2","Play",0.2)
					hitAnim = VMHit2
					charHitAnim = CharHit2
				else
					
					if Blocking then
						Blocking = false
						TweenService:Create(ShieldIcon,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(0,0),ImageTransparency = 1}):Play()
						animationHandle("StartBlock","Stop",0.2)
						animationHandle("HoldBlock","Stop",0.2)
						animationHandle("Hit1","Play",0.2)
						task.delay(1,function()
							if not Blocking then
								BlockDebounce = false
							end
						end)
					else
						animationHandle("Hit1","Play")
					end
					hitAnim = VMHit1
					charHitAnim = CharHit1
				end
			end
		end
	end
	
	local function swingStart ()
		Charging = false
		Swinging = true
		RaycastMelee:HitStart()
		SwordTrail.Enabled = true
		CTF.playSound(Sounds,"Swing",HRP,true,true)
		humAtt("Charging",nil,true)
		humAtt("Swinging",true,true)
	end
	
	local function swingEnd ()
		Swinging = false
		RaycastMelee:HitStop()
		SwordTrail.Enabled = false
		humAtt("Swinging",nil,true)
	end
	
	local function blockFunction ()
		if not Blocking and not Stunned and not Charging and not Swinging and not BlockDebounce and Humanoid:GetAttribute("Stamina") > Settings.BlockCost then
			BlockDebounce = true
			humAtt("Stamina",math.clamp(Humanoid:GetAttribute("Stamina")-Settings.BlockCost,0,Humanoid:GetAttribute("MaxStamina")))
			swingEnd()
			animationHandle("Hit1","Stop",0.1)
			animationHandle("Hit2","Stop",0.1)

			Blocking = true
			animationHandle("StartBlock","Play")
			animationHandle("StartBlock","Speed",VMStartBlock.Length/Settings.BlockSpeed,CharStartBlock.Length/Settings.BlockSpeed)
			ShieldIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			TweenService:Create(ShieldIcon,TweenInfo.new(Settings.BlockSpeed,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size = UDim2.fromScale(25,25),ImageTransparency = 0.75}):Play()
			if not smartWait(Settings.BlockSpeed,1) then return end
			animationHandle("StartBlock","Stop")
			animationHandle("HoldBlock","Play")
			TweenService:Create(ShieldIcon,TweenInfo.new(Settings.BlockTime,Enum.EasingStyle.Linear),{ImageColor3 = Color3.fromRGB(255, 45, 45)}):Play()
			if not smartWait(Settings.BlockTime,1) then return end
			TweenService:Create(ShieldIcon,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(0,0),ImageTransparency = 1}):Play()
			task.delay(0.3,function()
				if not VMHoldBlock.IsPlaying then
					Blocking = false
				end
			end)
			animationHandle("HoldBlock","Stop",0.3)
			if not smartWait(1,1) then return end
			BlockDebounce = false
		end
	end
	
	local function Feint ()
		if Charging and not Stunned and not Swinging and not FeintDebounce and not VMHit2.IsPlaying and Humanoid:GetAttribute("Stamina") > Settings.FeintCost then
			FeintDebounce = true
			humAtt("Stamina",math.clamp(Humanoid:GetAttribute("Stamina")-Settings.FeintCost,0,Humanoid:GetAttribute("MaxStamina")))
			humAtt("Charging",nil,true)
			humAtt("Swinging",nil,true)
			Charging = false
			Swinging = false
			Feinting = true
			swingEnd()
			if VMHit1.IsPlaying then
				animationHandle("Hit1","Speed",-1.2)
			end
			task.wait(0.1)
			FeintDebounce = false
		end
	end
	--\\
	
	--//Animation Handling
	local eventBehavior = {
		["Swing"] = function()
			swingEnd()
			swingStart()
		end,
		["SwingEnd"] = function()
			swingEnd()
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
	
	--//Events
	local inputBegan = UIS.InputBegan:Connect(function(Input)
		if Input.KeyCode == KeybindHandler.Keybind("Drop",Player) then
			CTF.dropItem(Character,Tool)
		end
		
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if Charging and not VMHit1.IsPlaying and not VMHit2.IsPlaying then
				Charging = false
			end
			swingFunction()
		end
		
		if Input.UserInputType == Enum.UserInputType.MouseButton2 then
			blockFunction()
		end
		
		if Input.KeyCode == KeybindHandler.Keybind("Feint",Player) then
			Feint()
		end
	end)
	
	local onHit = RaycastMelee.OnHit:Connect(function(Hit, _, RaycastResult)
		if RaycastResult then
			local HitHumanoid = nil
			if Hit and Hit.Parent then
				HitHumanoid = Hit.Parent:FindFirstChildOfClass("Humanoid")
				if not HitHumanoid and Hit.Parent.Parent then
					HitHumanoid = Hit.Parent.Parent:FindFirstChildOfClass("Humanoid")
				end
			end
			if HitHumanoid and not table.find(HitHumanoidsList, HitHumanoid) then
				table.insert(HitHumanoidsList, HitHumanoid)

				local facingForward = false
				local forward = HitHumanoid.Parent:FindFirstChild("HumanoidRootPart").CFrame.lookVector
				local displacement = HRP.Position - HitHumanoid.Parent:FindFirstChild("HumanoidRootPart").Position
				local amountForward = forward:Dot(displacement)
				if amountForward > 0 then
					facingForward = true
				end

				if HitHumanoid:GetAttribute("Blocking") and facingForward then
					CTF.playSound(Sounds,"Parry",Hit,true,true)
					Stunned = true
					task.defer(function()
						task.wait(0.05)
						hitAnim:AdjustSpeed(-0.7)
						charHitAnim:AdjustSpeed(-0.7)
						hitAnim:Stop(Settings.StunRecovery or 1)
						charHitAnim:Stop(Settings.StunRecovery or 1)
					end)
					swingEnd()
					task.wait(Settings.StunRecovery or 1)
					Stunned = false
				else
					CTF.playSound(Sounds,"Hit",Hit,true,true)
					DamageEvent:FireServer(Tool,Character,HitHumanoid,Hit)
					task.defer(function()
						hitAnim:AdjustSpeed(0.5)
						charHitAnim:AdjustSpeed(0.5)
						task.wait(0.05)
						hitAnim:AdjustSpeed(1)
						charHitAnim:AdjustSpeed(1)
					end)
				end
			end
		end
	end)
	
	Tool.AncestryChanged:Once(function()
		TweenService:Create(ShieldIcon,TweenInfo.new(0.1,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(0,0),ImageTransparency = 1}):Play()
		animationHandle("Hit1","Stop")
		animationHandle("Hit2","Stop")
		animationHandle("StartBlock","Stop")
		animationHandle("HoldBlock","Stop")
		for _,animationEvent in pairs(animationEventsList) do
			animationEvent:Disconnect()
		end
		Charging = false
		Swinging = false
		Feinting = false
		FeintDebounce = false
		BlockDebounce = false
		Blocking = false
		Stunned = false
		humAtt("Swinging",nil,true)
		humAtt("Charging",nil,true)
		humAtt("Blocking",nil,true)
		disconnectFunctions({inputBegan,onHit})
	end)
	--\\
end
return module