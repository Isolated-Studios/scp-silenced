local module = {}
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Player = game:GetService("Players").LocalPlayer

function module.LoadChar(Character)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local Events = ReplicatedStorage:WaitForChild("Events")
	local Modules = ReplicatedStorage:WaitForChild("Modules")
	local Objects = ReplicatedStorage:WaitForChild("Objects")
	local UIModules = Modules:WaitForChild("UI")
	local DownedEvent = Events:WaitForChild("Character"):WaitForChild("DownedEvent")
	local DowningObjects = Objects:WaitForChild("DowningObjects")
	
	local CircleFramesModule = require(UIModules:WaitForChild("CircleFrames"))
	local KeybindHandler = require(UIModules:WaitForChild("KeybindHandler"))
	local CameraManipulator = require(UIModules:WaitForChild("CameraManipulator"))
	local TeamHandler = require(Modules:WaitForChild("Interaction"):WaitForChild("TeamHandler"))
	
	local Backpack = Player.Backpack
	local HUD = Player.PlayerGui:WaitForChild("HUD")
	local Bars = HUD:WaitForChild("Bars")
	local RightFrame = HUD:WaitForChild("RightFrame")
	local DownedFrame = HUD:WaitForChild("DownedFrame")
	local ReviveFrame = HUD:WaitForChild("ReviveFrame")
	local GunVignette = HUD:WaitForChild("GunVignette")
	
	local ListFrame = RightFrame:WaitForChild("ListFrame")
	local GunFrame = ListFrame:WaitForChild("GunFrame")
	local Consumables = GunFrame:WaitForChild("Consumables")
	local ConsumablesFrame = Consumables:WaitForChild("Frame")
	local MedicalFrame = ConsumablesFrame:WaitForChild("4")
	local ThrowableFrame = ConsumablesFrame:WaitForChild("6")
	local MedicalNumber = MedicalFrame:WaitForChild("Number")
	local ThrowableNumber = ThrowableFrame:WaitForChild("Number")
	local Gradient = GunVignette.Gradient
	local VignetteAmount = Gradient.VignetteAmount
	local EarRinging = GunVignette.EarRinging
	
	local BloodScreen = HUD:WaitForChild("BloodScreen")
	local StaminaFrame = Bars:WaitForChild("Stamina")
	local StaminaL = StaminaFrame:WaitForChild("L")
	local StaminaR = StaminaFrame:WaitForChild("R")
	local HealthFrame = Bars:WaitForChild("Health")
	local HealthL = HealthFrame:WaitForChild("L")
	local HealthR = HealthFrame:WaitForChild("R")
	local AbsorptionFrame = Bars:WaitForChild("Absorption")
	local AbsorptionL = AbsorptionFrame:WaitForChild("L")
	local AbsorptionR = AbsorptionFrame:WaitForChild("R")
	local HealthNumber = Bars:WaitForChild("HealthText")
	
	local DownedProgressFrame = DownedFrame:WaitForChild("ProgressFrame")
	local MainDownedProgressFrame = DownedProgressFrame:WaitForChild("Progress")
	local DownedProgress = MainDownedProgressFrame:WaitForChild("Percentage")
	local DownedMessage = DownedFrame:WaitForChild("Message")
	
	local ReviveProgressFrame = ReviveFrame:WaitForChild("ProgressFrame")
	local MainReviveProgressFrame = ReviveProgressFrame:WaitForChild("Progress")
	local ReviveProgress = MainReviveProgressFrame:WaitForChild("Percentage")
	
	local Humanoid = Character:WaitForChild("Humanoid")
	local PlayerEffectsFolder = Player.PlayerScripts:WaitForChild("Effects")
	
	local allyIdTable = {
		[0] = {Color3.fromRGB(0,255,255)},
		[1] = {Color3.fromRGB(255,0,0)},
		[2] = {Color3.fromRGB(255,255,255)},
	}
	local lastAbsorption = Humanoid:GetAttribute("Absorption")
	
	local function barSetup (bar,value)
		bar.Main.Size = UDim2.fromScale(value,1)
		bar.Fade.Size = UDim2.fromScale(value,1)
	end
	local function barChange (bar,value,tween)
		if tween then
			TweenService:Create(bar.Main,TweenInfo.new(tween,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(value,1)}):Play()
		else
			bar.Main.Size = UDim2.fromScale(value,1)
		end
		if bar:FindFirstChild("Fade") and bar.Fade.Size.X.Scale >= bar.Fade.Size.X.Scale then
			TweenService:Create(bar.Fade,TweenInfo.new(1,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(value,1)}):Play()
		elseif bar:FindFirstChild("Fade") then
			bar.Fade.Size = UDim2.fromScale(value,1)
		end
	end
	local function absorptionBarCheck ()
		local Absorption = Humanoid:GetAttribute("Absorption")
		HealthNumber.Text = math.floor(Humanoid.Health+Absorption)
		if Absorption > 0 then
			--AbsorptionFrame.Visible = true
			HealthNumber.TextColor3 = Color3.fromRGB(255, 235, 133)
		else
			--AbsorptionFrame.Visible = false
			HealthNumber.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
	
	barSetup(StaminaL,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
	barSetup(StaminaR,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
	barSetup(HealthL,Humanoid.Health/Humanoid.MaxHealth)
	barSetup(HealthR,Humanoid.Health/Humanoid.MaxHealth)
	barChange(AbsorptionL,Humanoid:GetAttribute("Absorption")/Humanoid:GetAttribute("MaxAbsorption"))
	barChange(AbsorptionR,Humanoid:GetAttribute("Absorption")/Humanoid:GetAttribute("MaxAbsorption"))
	absorptionBarCheck()
	
	local staminaChanged = Humanoid:GetAttributeChangedSignal("Stamina"):Connect(function()
		barChange(StaminaL,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
		barChange(StaminaR,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
	end)
	
	local maxStaminaChanged = Humanoid:GetAttributeChangedSignal("MaxStamina"):Connect(function()
		barChange(StaminaL,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
		barChange(StaminaR,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
	end)
	
	local GradientChange = VignetteAmount.Changed:Connect(function() -- Darkens vignette based on VignetteAmount
		local Amount = VignetteAmount.Value
		if Amount <= 0.8 then
			if not EarRinging.IsPlaying then
				EarRinging:Play()
			end
			EarRinging.Volume = (1-Amount)*2
		else
			EarRinging:Stop()
			EarRinging.Volume = 0
		end
		Gradient.Transparency = NumberSequence.new(
			{
				NumberSequenceKeypoint.new(0,math.clamp(Amount,0.2,1)),
				NumberSequenceKeypoint.new(0.5,1),
				NumberSequenceKeypoint.new(1,math.clamp(Amount,0.2,1)),
			}
		)
	end)
	
	local healthChanged = Humanoid.HealthChanged:Connect(function()
		HealthNumber.Text = math.floor(Humanoid.Health)
		
		barChange(HealthL,Humanoid.Health/Humanoid.MaxHealth)
		barChange(HealthR,Humanoid.Health/Humanoid.MaxHealth)
		
		if Humanoid.Health <= Humanoid.MaxHealth/1.25 then
			TweenService:Create(BloodScreen,TweenInfo.new(0.2),{ImageTransparency = Humanoid.Health/Humanoid.MaxHealth}):Play()
		end
		if Humanoid.Health > Humanoid.MaxHealth/1.25 and BloodScreen.ImageTransparency < 1 then
			TweenService:Create(BloodScreen,TweenInfo.new(0.2),{ImageTransparency = 1}):Play()
		end
	end)
	
	local absorptionChanged = Humanoid:GetAttributeChangedSignal("Absorption"):Connect(function()
		absorptionBarCheck()
		local changeAmount = math.abs(lastAbsorption-Humanoid:GetAttribute("Absorption"))
		lastAbsorption = Humanoid:GetAttribute("Absorption")
		barChange(AbsorptionL,Humanoid:GetAttribute("Absorption")/Humanoid:GetAttribute("MaxAbsorption"),changeAmount/100)
		barChange(AbsorptionR,Humanoid:GetAttribute("Absorption")/Humanoid:GetAttribute("MaxAbsorption"),changeAmount/100)
	end)
	
	task.defer(function()
		while task.wait() and Humanoid.Health > 0 do
			if Humanoid.Health <= Humanoid.MaxHealth/2.5 and BloodScreen.ImageTransparency-0.1 > 0 then
				TweenService:Create(BloodScreen,TweenInfo.new(0.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,true),{ImageTransparency = BloodScreen.ImageTransparency-0.1}):Play()
				task.wait((Humanoid.Health/Humanoid.MaxHealth)*5)
			end
		end
	end)
	
	local function getConsumableTotal()
		local throwableTotal = 0
		local medicalTotal = 0
		for _,tool in pairs(Backpack:GetChildren()) do
			if tool:GetAttribute("ToolType") == 6 then
				throwableTotal += 1
			elseif tool:GetAttribute("ToolType") == 4 then
				medicalTotal += 1
			end
		end
		if Character:FindFirstChildOfClass("Tool") then
			local characterTool = Character:FindFirstChildOfClass("Tool")
			if characterTool:GetAttribute("ToolType") == 6 then
				throwableTotal += 1
			elseif characterTool:GetAttribute("ToolType") == 4 then
				medicalTotal += 1
			end
		end
		ThrowableNumber.Text = tostring(throwableTotal)
		MedicalNumber.Text = tostring(medicalTotal)
	end
	
	local backpackAdded = Backpack.ChildAdded:Connect(function(Tool)
		if Tool:IsA("Tool") and (Tool:GetAttribute("ToolType") == 6 or Tool:GetAttribute("ToolType") == 4) then
			getConsumableTotal()
		end
	end)
	
	local backpackRemoved = Backpack.ChildRemoved:Connect(function(Tool)
		if Tool:IsA("Tool") and (Tool:GetAttribute("ToolType") == 6 or Tool:GetAttribute("ToolType") == 4) then
			getConsumableTotal()
		end
	end)
	
	local charAdded = Character.ChildAdded:Connect(function(Tool)
		if Tool:IsA("Tool") and (Tool:GetAttribute("ToolType") == 6 or Tool:GetAttribute("ToolType") == 4) then
			getConsumableTotal()
		end
	end)

	local charRemoved = Character.ChildRemoved:Connect(function(Tool)
		if Tool:IsA("Tool") and (Tool:GetAttribute("ToolType") == 6 or Tool:GetAttribute("ToolType") == 4) then
			getConsumableTotal()
		end
	end)
	
	getConsumableTotal()
	
	DownedProgress.Value = 100
	ReviveProgress.Value = 0
	CircleFramesModule.Progress(MainDownedProgressFrame,DownedProgress,DownedProgress.Value)
	CircleFramesModule.Progress(MainReviveProgressFrame,ReviveProgress,ReviveProgress.Value)
	local bannedParts = {"Head"}--,"RightUpperArm","LeftUpperArm","RightLowerArm","LeftLowerArm","RightHand","LeftHand"}
	
	local DownedEventFunction = DownedEvent.OnClientEvent:Connect(function(interactCharacter)
		
		if interactCharacter then
			if interactCharacter:FindFirstChild("Humanoid") and interactCharacter.Humanoid:GetAttribute("Downed") then
				local interactPlayer = game.Players:GetPlayerFromCharacter(interactCharacter)
				local allyId = TeamHandler.Check(Player,interactPlayer)
				interactCharacter:SetAttribute("HighlightColor",allyIdTable[allyId][1])
				--if allyId == 1 then
				--	interactCharacter:SetAttribute("interactFinishEventId",5)
				---	interactCharacter:SetAttribute("interactText","EXECUTE")
				--end
			end
			return
		end
		
		local beginningheartbeatPitch = 0.8
		local droneVolume = 3
		local heartbeatVolume = 4
		local ccBrightness = -0.5
		local ccContrast = 1
		local ccTintSat = 255
		local droneNoise = DowningObjects:WaitForChild("Drone"):Clone()
		local heartbeatNoise = DowningObjects:WaitForChild("Heartbeat"):Clone()
		local DownedCC = DowningObjects:WaitForChild("DownedCC"):Clone()
		DownedCC.Parent = Lighting
		droneNoise.Parent = PlayerEffectsFolder
		heartbeatNoise.Parent = PlayerEffectsFolder
		droneNoise:Play()
		heartbeatNoise:Play()
		
		DownedFrame.GroupTransparency = 1
		DownedProgress.Value = 100
		DownedMessage.Text = 'Hold  <font color="rgb(170,0,0)">"'.. KeybindHandler.Keybind("Speed Up Downing",Player).Name ..'"</font> To Give Up.'
		CircleFramesModule.Progress(MainDownedProgressFrame,DownedProgress,DownedProgress.Value)
		TweenService:Create(DownedFrame,TweenInfo.new(2,Enum.EasingStyle.Linear),{GroupTransparency = 0}):Play()
		DownedFrame.Visible = true
		
		local Increment = 0.5
		local Time = Humanoid:GetAttribute("DownStart") or 60
		local waitTime = (Time/100)*Increment
		
		Humanoid:GetAttributeChangedSignal("Reviving"):Connect(function()
			if Humanoid:GetAttribute("Reviving") > 0 then
				DownedFrame.Visible = false
				ReviveFrame.Visible = true
				ReviveProgress.Value = 0
				CircleFramesModule.Progress(MainReviveProgressFrame,ReviveProgress,ReviveProgress.Value)
				TweenService:Create(ReviveProgress,TweenInfo.new(Humanoid:GetAttribute("Reviving"),Enum.EasingStyle.Linear),{Value = 100}):Play()
			else
				if Humanoid:GetAttribute("Downed") then
					DownedFrame.Visible = true
				end
				ReviveFrame.Visible = false
				ReviveProgress.Value = 0
				CircleFramesModule.Progress(MainReviveProgressFrame,ReviveProgress,ReviveProgress.Value)
			end
		end)
	
		task.defer(function()
			while task.wait() and Humanoid.Health > 0 do
				CircleFramesModule.Progress(MainDownedProgressFrame,DownedProgress,DownedProgress.Value)
				CircleFramesModule.Progress(MainReviveProgressFrame,ReviveProgress,ReviveProgress.Value)
				heartbeatNoise.PlaybackSpeed = (1-(DownedProgress.Value/100))+beginningheartbeatPitch
				droneNoise.Volume = droneVolume+((DownedProgress.Value/100)*-droneVolume)
				heartbeatNoise.Volume = heartbeatVolume+((DownedProgress.Value/100)*-heartbeatVolume)
				DownedCC.Brightness = ccBrightness+((DownedProgress.Value/100)*-ccBrightness)
				DownedCC.Contrast = ccContrast+((DownedProgress.Value/100)*-ccContrast)
				DownedCC.TintColor = Color3.fromHSV(0,1+((DownedProgress.Value/100)*-1),1)
				if UIS:IsKeyDown(KeybindHandler.Keybind("Speed Up Downing",Player)) then
					waitTime = (Time/100)*Increment*0.02
					DownedMessage.Text = '<font color="rgb(255,0,0)">Giving Up on Life</font>'
				else
					waitTime = (Time/100)*Increment
					DownedMessage.Text = 'Hold  <font color="rgb(255,0,0)">"'.. KeybindHandler.Keybind("Speed Up Downing",Player).Name ..'"</font> To Give Up.'
				end
			end
		end)
		
		
		task.defer(function()
			while DownedProgress.Value > 0 and Humanoid:GetAttribute("Downed") and Humanoid.Health > 0 do
				
				if Humanoid:GetAttribute("Reviving") == 0 then
					TweenService:Create(DownedProgress,TweenInfo.new(waitTime,Enum.EasingStyle.Linear),{Value = DownedProgress.Value-Increment}):Play()
				end
				task.wait(waitTime)
			end
			RunService:UnbindFromRenderStep("CharacterTransparency")
			DownedFrame.GroupTransparency = 1
			DownedProgress.Value = 100
			DownedFrame.Visible = false
			droneNoise:Destroy()
			heartbeatNoise:Destroy()
			DownedCC:Destroy()
			if Humanoid:GetAttribute("Downed") then
				DownedEvent:FireServer(Humanoid)
			end
		end)
		
	end)
		
	Humanoid.Died:Once(function()
		for _, connection in {staminaChanged,maxStaminaChanged,healthChanged,backpackAdded,backpackRemoved,charAdded,charRemoved,DownedEventFunction,absorptionChanged,GradientChange} do
			connection:Disconnect()
		end
	end)
end

return module
