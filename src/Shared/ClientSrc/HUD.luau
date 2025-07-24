local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Events = ReplicatedStorage.Events
local Modules = ReplicatedStorage.Modules
local Objects = ReplicatedStorage.Objects
local UIModules = Modules.UI
local DownedEvent = Events.Character.DownedEvent
local DowningObjects = Objects.DowningObjects

local CircleFramesModule = require(UIModules.CircleFrames)
local KeybindHandler = require(UIModules.KeybindHandler)
local CameraManipulator = require(UIModules.CameraManipulator)
local TeamHandler = require(Modules.Interaction.TeamHandler)
local ToolHandler = require(ReplicatedStorage.ClientSrc.ToolHandler)
local ToolClass = require(Modules.Tool)

local module = {}

local Player = game:GetService("Players").LocalPlayer
local Backpack = nil

local HUD
local HUDLoaded = false

local Bars
local RightFrame
local DownedFrame
local ReviveFrame
local GunVignette
local ListFrame
local Consumables
local ConsumablesFrame
local MedicalFrame
local ThrowableFrame
local MedicalNumber
local ThrowableNumber
local Gradient
local VignetteAmount
local EarRinging

-- // Gun frame stuff
local InfoFrame
local GunInfoFrame
local PrimeMagBullet
local InnerFrame
local ReserveFrame
local InnerScaleLayout
local MagFrame
local ReserveText
local InfoFrame
local NameText
local ModeText

local BloodScreen
local StaminaFrame
local StaminaL
local StaminaR
local HealthFrame
local HealthL
local HealthR
local AbsorptionFrame
local AbsorptionL
local AbsorptionR
local HealthNumber

local DownedProgressFrame
local MainDownedProgressFrame
local DownedProgress
local DownedMessage

local ReviveProgressFrame
local MainReviveProgressFrame
local ReviveProgress

function module.Init()
	HUD = Player.PlayerGui:WaitForChild("HUD")

	Bars = HUD:WaitForChild("Bars")
	RightFrame = HUD:WaitForChild("RightFrame")
	DownedFrame = HUD:WaitForChild("DownedFrame")
	ReviveFrame = HUD:WaitForChild("ReviveFrame")
	GunVignette = HUD:WaitForChild("GunVignette")
	ListFrame = RightFrame:WaitForChild("ListFrame")
	InfoFrame = ListFrame:WaitForChild("InfoFrame")
	Consumables = InfoFrame:WaitForChild("Consumables")
	ConsumablesFrame = Consumables:WaitForChild("Frame")
	MedicalFrame = ConsumablesFrame:WaitForChild("4")
	ThrowableFrame = ConsumablesFrame:WaitForChild("6")
	MedicalNumber = MedicalFrame:WaitForChild("Number")
	ThrowableNumber = ThrowableFrame:WaitForChild("Number")
	Gradient = GunVignette.Gradient
	VignetteAmount = Gradient.VignetteAmount
	EarRinging = GunVignette.EarRinging

	GunInfoFrame = InfoFrame:WaitForChild("GunInfo")
	PrimeMagBullet = InfoFrame:WaitForChild("MagBullet")
	InnerFrame = GunInfoFrame:WaitForChild("InnerFrame")
	ReserveFrame = GunInfoFrame:WaitForChild("ReserveFrame")
	InnerScaleLayout = InnerFrame:WaitForChild("InnerScale")
	MagFrame = InnerFrame:WaitForChild("MagFrame")
	ReserveText = ReserveFrame:WaitForChild("Reserve")
	InfoFrame = InnerFrame:WaitForChild("InfoFrame")
	NameText = InfoFrame:WaitForChild("Name")
	ModeText = InfoFrame:WaitForChild("Mode")
	
	BloodScreen = HUD:WaitForChild("BloodScreen")
	StaminaFrame = Bars:WaitForChild("Stamina")
	StaminaL = StaminaFrame:WaitForChild("L")
	StaminaR = StaminaFrame:WaitForChild("R")
	HealthFrame = Bars:WaitForChild("Health")
	HealthL = HealthFrame:WaitForChild("L")
	HealthR = HealthFrame:WaitForChild("R")
	AbsorptionFrame = Bars:WaitForChild("Absorption")
	AbsorptionL = AbsorptionFrame:WaitForChild("L")
	AbsorptionR = AbsorptionFrame:WaitForChild("R")
	HealthNumber = Bars:WaitForChild("HealthText")
	
	DownedProgressFrame = DownedFrame:WaitForChild("ProgressFrame")
	MainDownedProgressFrame = DownedProgressFrame:WaitForChild("Progress")
	DownedProgress = MainDownedProgressFrame:WaitForChild("Percentage")
	DownedMessage = DownedFrame:WaitForChild("Message")
	
	ReviveProgressFrame = ReviveFrame:WaitForChild("ProgressFrame")
	MainReviveProgressFrame = ReviveProgressFrame:WaitForChild("Progress")
	ReviveProgress = MainReviveProgressFrame:WaitForChild("Percentage")
	HUDLoaded = true
end

local editMagTable = {
	["Empty"] = function(tweenTime)
		if not tweenTime then tweenTime = 0.1 end
		local bullet = MagFrame["1"]
		local round = bullet.Round
		TweenService:Create(round,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,0)}):Play()
	end,
	["Cycle"] = function(tweenTime)
		if not tweenTime then tweenTime = 0.1 end
		if gun.Ammo+1 <= Settings.MagSize and gun.Ammo > 0 and MagFrame:FindFirstChild((gun.Ammo+1)) then
			local bullet = MagFrame[tostring(gun.Ammo+1)]
			local round = bullet.Round
			TweenService:Create(round,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,0)}):Play()
			local firstBullet = MagFrame["1"]
			local firstRound = firstBullet.Round
			TweenService:Create(firstRound,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,1),}):Play()
		end
	end,
	["Load"] = function(tweenTime)
		if not tweenTime then tweenTime = 0.1 end
		local bullet = MagFrame[tostring(gun.Ammo)]
		local round = bullet.Round
		if MagFrame["1"].Round.Size.Y.Scale < 1 then
			bullet = MagFrame["1"]
			round = bullet.Round
		end
		TweenService:Create(round,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,1)}):Play()
	end,
	["Mag"] = function(tweenTime)
		if not tweenTime then tweenTime = 0.1 end
		for i=1,gun.Ammo,1 do
			local bullet = MagFrame[tostring(i)]
			local round = bullet.Round
			TweenService:Create(round,TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Size = UDim2.fromScale(1,1)}):Play()
		end
	end,
}

local function editBulletFrame (action,tweenTime)
	ReserveText.Text = ammoBool.Value
	NameText.Text = Tool.Name
	if Settings.Automatic then
		ModeText.Text = "Auto"
	else
		ModeText.Text = "Semi"
	end
	if not MagFrame:FindFirstChild("1") then
		return
	end
	editMagTable[action](tweenTime)
end

local function updateGunDisplay(Gun: ToolClass.ClassType)
	ReserveFrame.Visible = true
	ReserveText.Text = Gun.Ammo
	if Gun.Settings.Automatic then
		ModeText.Text = "Auto"
	else
		ModeText.Text = "Semi"
	end
	
	for _,oldBullet in pairs (MagFrame:GetChildren()) do
		if oldBullet:IsA("Frame") then
			oldBullet:Destroy()
		end
	end
	
	MagFrame.UIGridLayout.CellSize = UDim2.new(1/Gun.Settings.MagSize,-1,1,0)
	if Gun.Settings.MagSize > 50 then
		MagFrame.UIGridLayout.CellSize = UDim2.new((1/Gun.Settings.MagSize)*2,-1,1,0)
		InnerScaleLayout.Padding = UDim.new(1.2,0)
	else
		InnerScaleLayout.Padding = UDim.new(0.2,0)
	end
	for i=1,Gun.Settings.MagSize,1 do
		local bullet = PrimeMagBullet:Clone()
		--bullet.Size = UDim2.new(1/Settings.MagSize,-1,1,0)
		if i == 1 then
			bullet.Round.BackgroundColor3 = Color3.fromRGB(255,255,255)
		end
		bullet.Name = tostring(i)
		if tonumber(bullet.Name) > Gun.Ammo then
			bullet.Round.Size = UDim2.fromScale(1,0)
		end
		bullet.Parent = MagFrame
	end
	if not Gun.Bolted and Gun.Settings.Bolted and Gun.Ammo < Gun.Settings.MagSize and Gun.Ammo > 0 then
		local firstRound = MagFrame["1"].Round
		firstRound.Size = UDim2.fromScale(1,0)
	local otherRound = MagFrame[tostring(Gun.Ammo+1)].Round
		otherRound.Size = UDim2.fromScale(1,1)
	end
end

local function updateToolDisplay(equipping, Tool: ToolClass.ClassType, transitionTime)
	if equipping == 1 then
		NameText.Text = Tool.Instance.Name
		TweenService:Create(GunInfoFrame, TweenInfo.new(transitionTime), {GroupTransparency = 0}):Play()
		GunInfoFrame.Visible = true
		
		if Tool and Tool.ClassName == "Gun" then
			updateGunDisplay(Tool)
		end
	else
		local Tween = TweenService:Create(GunInfoFrame,TweenInfo.new(0.3),{GroupTransparency = 1})
		Tween:Play()
		Tween.Completed:Once(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				GunInfoFrame.Visible = false
			end
		end)
	end
end

function module.LoadChar(Character)
	Backpack = Player:WaitForChild("Backpack")
	
	ToolHandler.ToolEquipping:Connect(updateToolDisplay, 1)
	ToolHandler.ToolUnequipping:Connect(updateToolDisplay, 0)
	
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
				if UserInputService:IsKeyDown(KeybindHandler.Keybind("Speed Up Downing",Player)) then
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
