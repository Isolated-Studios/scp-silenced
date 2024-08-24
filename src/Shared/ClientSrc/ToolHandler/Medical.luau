local module = {}
--//Services
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")

--//Modules
local CTF = require(Modules:WaitForChild("Tool"):WaitForChild("CommonToolFunctions"))
local KeybindHandler = require(Modules:WaitForChild("UI"):WaitForChild("KeybindHandler"))
local TeamHandler = require(Modules:WaitForChild("Interaction"):WaitForChild("TeamHandler"))

--//Service Objects
local Events = ReplicatedStorage:WaitForChild("Events")
local ToolEvents = Events:WaitForChild("Tool")

--//Tables
local healTextColor = {
	[0] = '"rgb(0,255,255)"',
	[1] = '"rgb(255,0,0)"',
	[2] = '"rgb(255,255,255)"',
}
function module.Init(Tool,ToolObjects,Character,Viewmodel)
	if Tool.Parent ~= Character then return end
	Tool:SetAttribute("Activated",true)
	local Settings = require(ToolObjects:WaitForChild("Settings"))
	
	--//Player
	local Player = game.Players.LocalPlayer
	local Mouse = Player:GetMouse()
	local Humanoid = Character:WaitForChild("Humanoid")
	local HRP = Character:WaitForChild("HumanoidRootPart")
	local MotorModel = Viewmodel:WaitForChild("MotorModel")
	
	--//UI
	local PlayerGui = Player.PlayerGui
	local MouseUI = PlayerGui:WaitForChild("MouseUI")
	local Texts = MouseUI:WaitForChild("Dot"):WaitForChild("Texts")
	local MessageText = Texts:WaitForChild("MessageText")
	local HealText = Texts:WaitForChild("HealText")
	local InteractText = Texts:WaitForChild("InteractText")
	
	local GunFrame = PlayerGui:WaitForChild("HUD"):WaitForChild("RightFrame"):WaitForChild("ListFrame"):WaitForChild("GunFrame") 
	local CanvasGroup = GunFrame:WaitForChild("CanvasGroup")
	local InnerFrame = CanvasGroup:WaitForChild("InnerFrame")
	local ReserveFrame = CanvasGroup:WaitForChild("ReserveFrame")
	local ReserveText = ReserveFrame:WaitForChild("Reserve")
	local InfoFrame = InnerFrame:WaitForChild("InfoFrame")
	local NameText = InfoFrame:WaitForChild("Name")
	local ModeText = InfoFrame:WaitForChild("Mode")
	local PrimeMagBullet = GunFrame:WaitForChild("MagBullet")
	local MagFrame = InnerFrame:WaitForChild("MagFrame")
	
	--//Events
	local HealEvent = ToolEvents:WaitForChild("Heal")
	local SetItemHolder = ToolEvents:WaitForChild("SetItemHolder")
	local ReviveTool = ToolEvents:WaitForChild("ReviveTool")
	
	--//Bools & Nils
	local Healing = false
	local selectedCharacter = nil
	
	--//Tool Objects
	local Holder = Tool:WaitForChild("Holder")
	local Durability = Holder:WaitForChild("Durability")
	
	--//Animation Priming
	local animationEventsList = {}
	local Animator = Humanoid:WaitForChild("Animator")
	local VMAnimator = Viewmodel.Humanoid.Animator
	local CharacterAnimations = ToolObjects:WaitForChild("CharacterAnimations")
	local VMAnimations = ToolObjects:WaitForChild("VMAnimations")
	
	local VMApply = VMAnimator:LoadAnimation(VMAnimations.Apply)
	local CharApply = Animator:LoadAnimation(CharacterAnimations.Apply)
	local VMAid = nil
	local CharAid = nil
	
	if VMAnimations:FindFirstChild("Aid") then
		VMAid = VMAnimator:LoadAnimation(VMAnimations.Aid)
		CharAid = Animator:LoadAnimation(CharacterAnimations.Aid)
	end 
	
	local animationEvents = {
		["Apply"] = CTF.getAllAnimationEventNames(VMApply),
		["Aid"] = CTF.getAllAnimationEventNames(VMAid),
	}

	local animationTable = {
		["Apply"] = {VMApply,CharApply},
		["Aid"] = {VMAid,CharAid},
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
	local function applyHealing (characterToHeal,revived)
		if Healing then
			if not characterToHeal then characterToHeal = Character end
			local HumanoidToHeal = characterToHeal.Humanoid
			local amountToActuallyHeal = HumanoidToHeal.MaxHealth - HumanoidToHeal.Health
			if amountToActuallyHeal > Settings.HealAmount or not Settings.HealthAsDurability then amountToActuallyHeal = Settings.HealAmount end
			if Settings.HealthAsDurability then
				if revived then
					Durability.Value -= Settings.ReviveHealth or 0
				else
					Durability.Value -= amountToActuallyHeal
				end
			else
				Durability.Value -= 1
			end
			if Durability.Value < 0 then
				Durability.Value = 0
			end
			TweenService:Create(MagFrame.UIGridLayout,TweenInfo.new(0.2,Enum.EasingStyle.Linear),{CellSize = UDim2.new(Durability.Value/Settings.MaxDurability,0,1,0)}):Play()
			--MagFrame.UIGridLayout.CellSize = UDim2.new(Durability.Value/Settings.MaxDurability,0,1,0)
			ReserveText.Text = Durability.Value

			if Durability.Value == 0 then
				task.defer(function()
					if Settings.HasEndMarker then
						Tool:SetAttribute("Removing",true)
						task.wait(Settings.HasEndMarker or 0.1)
					end
					Tool:SetAttribute("Removing",true)
					Humanoid:UnequipTools()
					Tool.Parent = ReplicatedStorage
				end)
			end

			HealEvent:FireServer(Tool,characterToHeal,Durability.Value,revived)
			Healing = false
		end
	end
	
	local function Heal (characterToHeal)
		local picked = nil
		local charpicked = nil
		if characterToHeal and Settings.RequireHarm and characterToHeal.Humanoid.Health >= characterToHeal.Humanoid.MaxHealth or 
			not characterToHeal and Settings.RequireHarm and Humanoid.Health >= Humanoid.MaxHealth or Tool:GetAttribute("Removing") then return end

		if characterToHeal and Settings.HealOthers then
			if Settings.HasAidAnimation and VMAid then
				picked = VMAid
				charpicked = CharAid
			elseif VMApply then
				picked = VMApply
				charpicked = CharApply
			end
		elseif VMApply then
			picked = VMApply
			charpicked = CharApply
		end
		if picked then
			Healing = true
			animationHandle(picked.Name,"Play")
			if Settings.HealSpeed then
				animationHandle(picked.Name,"Speed",picked.Length/Settings.HealSpeed,charpicked.Length/Settings.HealSpeed)
			end
			if not Settings.HasEndMarker then
				picked.Stopped:Wait()
			else
				picked:GetMarkerReachedSignal("End"):Wait()
			end
			--local playerToHeal = nil
			applyHealing(characterToHeal)
		end
	end
	local function AttemptHeal ()
		if selectedCharacter and selectedCharacter:FindFirstChild("Humanoid") then
			Heal(selectedCharacter)
		else
			Heal()
		end
	end
	local function disconnectFunctions (FunctionList)
		for _,Function in pairs(FunctionList) do
			if Function then
				Function:Disconnect()
			end
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
	
	if Settings.CanRevive then
		Tool:SetAttribute("CanRevive",true)
	end
	
	if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		AttemptHeal()
	end
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
	
	--//Events
	local inputBegan = UIS.InputBegan:Connect(function(Input,gpe)
		if Tool:GetAttribute("Unequipping") or gpe or Humanoid:GetAttribute("InventoryOpen") then return end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 and (not Settings.CanRevive or (Settings.CanRevive and not string.find(InteractText.Text,"REVIVE"))) then	
			AttemptHeal()
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
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if Healing then
				Healing = false
				animationHandle("Apply","Stop",0.2)
				animationHandle("Aid","Stop",0.2)
			end
		end	
	end)
	
	local reviveToolEvent = ReviveTool.OnClientEvent:Connect(function(characterToHeal)
		Healing = true
		applyHealing(characterToHeal,true)
	end)
	
	local renderStepped = RunService.RenderStepped:Connect(function()
		if Tool and Settings.HealOthers then
			if Mouse.Target and Mouse.Target.Parent and Mouse.Target.Parent.Parent and math.round((Mouse.Target.Position-HRP.Position).Magnitude) <= (Settings.HealRange or 10) then
				if Mouse.Target.Parent:IsA("Model") and Mouse.Target.Parent:GetAttribute("isCharacter") then
					selectedCharacter = Mouse.Target.Parent
				elseif Mouse.Target.Parent.Parent:IsA("Model") and Mouse.Target.Parent.Parent:GetAttribute("isCharacter") then
					selectedCharacter = Mouse.Target.Parent.Parent
				else
					selectedCharacter = nil
				end
			else
				selectedCharacter = nil
			end
		else
			selectedCharacter = nil
		end
		
		if selectedCharacter then
			if selectedCharacter:FindFirstChild("Humanoid") and selectedCharacter.Humanoid:GetAttribute("Downed") and Settings.CanRevive then
				Tool:SetAttribute("CanInteractWithTool",true)
			else
				Tool:SetAttribute("CanInteractWithTool",nil)
			end
			if selectedCharacter:FindFirstChild("Humanoid") and selectedCharacter.Humanoid:GetAttribute("Downed") then
				selectedCharacter = nil 
				return
			end
			HealText.Visible = true
			local textColor = healTextColor[2]
			if Players:GetPlayerFromCharacter(selectedCharacter) then
				textColor = healTextColor[TeamHandler.Check(Player,Players:GetPlayerFromCharacter(selectedCharacter))]
				if TeamHandler.Check(Player,Players:GetPlayerFromCharacter(selectedCharacter)) == 1  then
					selectedCharacter = nil
					--MessageText.Visible = true
					HealText.Text = ""
					return
				end
			end
			HealText.Text = "HEAL ".. '<font color='..textColor..'>'..string.upper(selectedCharacter.Name)..'</font>'.." WITH "..string.upper(Tool.Name)
		else
			--MessageText.Visible = true
			HealText.Visible = false
			HealText.Text = ""
		end
	end)
	Tool.AncestryChanged:Once(function()
		SetItemHolder:FireServer(Tool,"Durability",Durability.Value)
		for index,_ in pairs(animationTable) do
			animationHandle(index,"Stop",0)
		end
		for _,animationEvent in pairs(animationEventsList) do
			animationEvent:Disconnect()
		end
		CanvasGroup.Visible = false
		MagBullet:Destroy()
		--MessageText.Visible = true
		HealText.Visible = false
		HealText.Text = ""
		disconnectFunctions({inputBegan,inputEnded,renderStepped,reviveToolEvent,unequippedTool})
		Tool:SetAttribute("Activated",nil)
	end)
	--\\
end
return module