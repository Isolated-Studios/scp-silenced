local module = {}
-- Services
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

-- Replicated Storage References
local Events = ReplicatedStorage.Events
local Modules = ReplicatedStorage.Modules
local Objects = ReplicatedStorage.Objects
local UIModules = Modules.UI
local DownedEvent = Events.Character.DownedEvent
local DowningObjects = Objects.DowningObjects

-- Modules
local CircleFramesModule = require(UIModules.CircleFrames)
local KeybindHandler = require(UIModules.KeybindHandler)
local CameraManipulator = require(UIModules.CameraManipulator)
local TeamHandler = require(Modules.Interaction.TeamHandler)
local ToolHandler = require(ReplicatedStorage.ClientSrc.ToolHandler)
local ToolClass = require(Modules.Tool)

-- Player
local Player = game:GetService("Players").LocalPlayer
local Backpack = nil
local PlayerSettings = ReplicatedStorage.Players:WaitForChild(tostring(Player.UserId)).Settings
local SoundSettings = PlayerSettings.Sound
local LowHealthMuffleSetting = SoundSettings["Low Health Muffle"]
local Camera = workspace.CurrentCamera

-- UI
local HUD
local HUDLoaded = false

-- Values
local PreviousAmmo = nil
local LastCamCF = CFrame.new()
local shakeOffset = Vector2.new()
local UIStates = {
	[0] = "Reset",
	[1] = "Bolt",
	[2] = "Reload",
	[3] = "Fire"
}

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
	game.StarterGui:SetCoreGuiEnabled("Health", false)
	HUD = Player.PlayerGui:WaitForChild("HUD")

	Bars = HUD.Bars
	RightFrame = HUD.RightFrame
	DownedFrame = HUD.DownedFrame
	ReviveFrame = HUD.ReviveFrame
	GunVignette = HUD.GunVignette
	ListFrame = RightFrame.ListFrame
	InfoFrame = ListFrame.InfoFrame
	Consumables = InfoFrame.Consumables
	ConsumablesFrame = Consumables.Frame
	MedicalFrame = ConsumablesFrame["4"]
	ThrowableFrame = ConsumablesFrame["6"]
	MedicalNumber = MedicalFrame.Number
	ThrowableNumber = ThrowableFrame.Number
	Gradient = GunVignette.Gradient
	VignetteAmount = Gradient.VignetteAmount
	EarRinging = GunVignette.EarRinging

	GunInfoFrame = InfoFrame.GunInfo
	PrimeMagBullet = InfoFrame.MagBullet
	InnerFrame = GunInfoFrame.InnerFrame
	ReserveFrame = GunInfoFrame.ReserveFrame
	InnerScaleLayout = InnerFrame.InnerScale
	MagFrame = InnerFrame.MagFrame
	ReserveText = ReserveFrame.Reserve
	InfoFrame = InnerFrame.InfoFrame
	NameText = InfoFrame.ToolName
	ModeText = InfoFrame.Mode

	BloodScreen = HUD.BloodScreen
	StaminaFrame = Bars.Stamina
	StaminaL = StaminaFrame.L
	StaminaR = StaminaFrame.R
	HealthFrame = Bars.Health
	HealthL = HealthFrame.L
	HealthR = HealthFrame.R
	AbsorptionFrame = Bars.Absorption
	AbsorptionL = AbsorptionFrame.L
	AbsorptionR = AbsorptionFrame.R
	HealthNumber = Bars.HealthText

	DownedProgressFrame = DownedFrame.ProgressFrame
	MainDownedProgressFrame = DownedProgressFrame.Progress
	DownedProgress = MainDownedProgressFrame.Percentage
	DownedMessage = DownedFrame.Message

	ReviveProgressFrame = ReviveFrame.ProgressFrame
	MainReviveProgressFrame = ReviveProgressFrame.Progress
	ReviveProgress = MainReviveProgressFrame.Percentage
	HUDLoaded = true
end

local function updateGunDisplay (Gun: ToolClass.ClassType, UIState: number)
	ReserveFrame.Visible = true
	ReserveText.Text = Gun.ReserveHolder.Value
	if Gun.Settings.Automatic then
		ModeText.Text = "Auto"
	else
		ModeText.Text = "Semi"
	end
	
	local GunUIFunctions = {
		["Reset"] = function()
			for _, oldBullet in pairs (MagFrame:GetChildren()) do
				if oldBullet:IsA("Frame") then
					oldBullet:Destroy()
				end
			end

			local TotalCells = Gun.Settings.MagSize + 1
			MagFrame.UIGridLayout.CellSize = UDim2.new(1/TotalCells,-1,1,0)
			if TotalCells > 50 then
				MagFrame.UIGridLayout.CellSize = UDim2.new((1/TotalCells)*2,-1,1,0)
				InnerScaleLayout.Padding = UDim.new(1.2,0)
			else
				InnerScaleLayout.Padding = UDim.new(0.2,0)
			end
			for i = 1, TotalCells, 1 do
				local bullet = PrimeMagBullet:Clone()
				if i == 1 then
					bullet.Round.BackgroundColor3 = Color3.fromRGB(255,255,255)
				end
				bullet.Name = tostring(i)
				if i > Gun.Ammo + 1 or (i == 1 and not Gun.Bolted) then
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
			PreviousAmmo = Gun.Ammo
		end,
		["Bolt"] = function()
			MagFrame[1].Round.Size = UDim2.new(MagFrame[1].Round.Size.X.Scale, -1, 0, 0)
			TweenService:Create(MagFrame[1].Round, TweenInfo.new(0.1), {Size = UDim2.new(MagFrame[1].Round.Size.X.Scale, -1, 1, 0)}):Play()
			
			for i = 1, Gun.Settings.MagSize do
				local bullet = MagFrame:FindFirstChild(tostring(i + 1))
				if not bullet then break end
				bullet = bullet.Round
				if Gun.Ammo < i then
					TweenService:Create(bullet, TweenInfo.new(0.1), {Size = UDim2.new(bullet.Size.X.Scale, -1, 0, 0)}):Play()
				end
			end
		end,
		
		["Reload"] = function()
			TweenService:Create(MagFrame[1].Round, TweenInfo.new(0.1), {Size = UDim2.new(MagFrame[1].Round.Size.X.Scale, -1, 1, 0)}):Play()
			
			for i = 1, Gun.Settings.MagSize do
				local bullet = MagFrame:FindFirstChild(tostring(i + 1))
				if not bullet then break end
				bullet = bullet.Round
				if Gun.Ammo >= i then
					TweenService:Create(bullet, TweenInfo.new(0.1), {Size = UDim2.new(bullet.Size.X.Scale, -1, 1, 0)}):Play()
				end
			end
			PreviousAmmo = Gun.Ammo
		end,
		
		["Fire"] = function()
			if PreviousAmmo > 0 then
				MagFrame[1].Round.Size = UDim2.new(MagFrame[1].Round.Size.X.Scale, -1, 1, 0)
				TweenService:Create(MagFrame[1].Round, TweenInfo.new(0.1), {Size = UDim2.new(MagFrame[1].Round.Size.X.Scale, -1, 0, 0)}):Play()
			end
			PreviousAmmo = Gun.Ammo
		end,
	}
	
	GunUIFunctions[UIStates[UIState]]()
end

local function updateToolDisplay(equipping, Tool: ToolClass.ClassType, transitionTime)
	if equipping then
		NameText.Text = Tool.Instance.Name
		TweenService:Create(GunInfoFrame, TweenInfo.new(transitionTime or 0.3), {GroupTransparency = 0}):Play()
		GunInfoFrame.Visible = true

		if Tool and Tool.ClassName == "Gun" then
			updateGunDisplay(Tool, 0)
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

-- Enable LowHealthMuffle of all sound groups. If Unmuffle true, disable all sound group LowHealthMuffles.
local function MuffleSounds (Unmuffle: boolean)
	if Unmuffle then
		for _,SoundGroup in pairs (SoundService:GetChildren()) do
			if SoundGroup:IsA("SoundGroup") then
				task.defer(function()
					TweenService:Create(SoundGroup.LowHealthMuffle,TweenInfo.new(1),{HighGain = 0, LowGain = 0, MidGain = 0}):Play()
					task.wait(1)
					if SoundGroup.LowHealthMuffle.MidGain == 0 then
						SoundGroup.LowHealthMuffle.Enabled = false
					end
				end)
			end
		end
	else
		if LowHealthMuffleSetting.Value then
			for _,SoundGroup in pairs (SoundService:GetChildren()) do
				if SoundGroup:IsA("SoundGroup") then
					SoundGroup.LowHealthMuffle.Enabled = true
					TweenService:Create(SoundGroup.LowHealthMuffle,TweenInfo.new(1),{HighGain = -120, LowGain = 60, MidGain = 0}):Play()
				end
			end
		end
	end
end

function module.updateGunDisplay(Tool: ToolClass.ClassType, UIState: number)
	updateGunDisplay(Tool, UIState)
end

function module.LoadChar(Character)
	-- Numbers
	local BloodScreenRegainRatio = 1.5
	local PreviousHealthRatio = 1
	
	Backpack = Player:WaitForChild("Backpack")

	ToolHandler.ToolEquipping:Connect(updateToolDisplay, true)
	ToolHandler.ToolUnequipping:Connect(updateToolDisplay, false)

	local Humanoid = Character:WaitForChild("Humanoid")
	local PlayerEffectsFolder = Player.PlayerScripts:WaitForChild("Effects")

	local allyIdTable = {
		[0] = {Color3.fromRGB(0,255,255)},
		[1] = {Color3.fromRGB(255,0,0)},
		[2] = {Color3.fromRGB(255,255,255)},
	}
	local lastAbsorption = Humanoid:GetAttribute("Absorption")
	
	-- Set up bar by scaling the Main and Fade frames.
	local function barSetup (bar,value)
		bar.Main.Size = UDim2.fromScale(value,1)
		bar.Fade.Size = UDim2.fromScale(value,1)
	end
	
	-- Change the bar by scaling the Main and Fade frames.
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
	
	-- Check if there is absorption and apply absorption color to HealthNumber
	local function absorptionBarCheck (HealthRatio)
		local Absorption = Humanoid:GetAttribute("Absorption")
		HealthNumber.Text = math.floor(Humanoid.Health+Absorption)
		if Absorption > 0 then
			HealthNumber.TextColor3 = Color3.fromRGB(255, 235, 133) -- yellow
		else
			if HealthRatio and HealthRatio <= 0.2 then
				HealthNumber.TextColor3 = Color3.fromRGB(255, 133, 133) -- red
			else
				HealthNumber.TextColor3 = Color3.fromRGB(255, 255, 255) -- white
			end
		end
	end
	
	-- Set up all Stamina, Health, Absorption bars.
	barSetup(StaminaL,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
	barSetup(StaminaR,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
	barSetup(HealthL,Humanoid.Health/Humanoid.MaxHealth)
	barSetup(HealthR,Humanoid.Health/Humanoid.MaxHealth)
	barChange(AbsorptionL,Humanoid:GetAttribute("Absorption")/Humanoid:GetAttribute("MaxAbsorption"))
	barChange(AbsorptionR,Humanoid:GetAttribute("Absorption")/Humanoid:GetAttribute("MaxAbsorption"))
	absorptionBarCheck()
	
	-- If Stamina changes, do a barChange on them.
	local staminaChanged = Humanoid:GetAttributeChangedSignal("Stamina"):Connect(function()
		barChange(StaminaL,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
		barChange(StaminaR,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
	end)

	local maxStaminaChanged = Humanoid:GetAttributeChangedSignal("MaxStamina"):Connect(function()
		barChange(StaminaL,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
		barChange(StaminaR,Humanoid:GetAttribute("Stamina")/Humanoid:GetAttribute("MaxStamina"))
	end)
	
	-- Darkens vignette based on VignetteAmount and plays ear ringing noise. Used for continuous shooting making a concussive effect.
	local GradientChange = VignetteAmount.Changed:Connect(function() 
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
				NumberSequenceKeypoint.new(0,math.clamp(Amount, 0.5, 1)),
				NumberSequenceKeypoint.new(0.5, 1),
				NumberSequenceKeypoint.new(1,math.clamp(Amount, 0.5, 1)),
			}
		)
	end)

	local healthChanged = Humanoid.HealthChanged:Connect(function()
		HealthNumber.Text = math.floor(Humanoid.Health)
		local HealthRatio = Humanoid.Health/Humanoid.MaxHealth
		
		-- Muffle sounds if health ratio is 30% or lower. Unmuffle if above 30%.
		if HealthRatio <= 0.3 and PreviousHealthRatio > 0.3 then
			MuffleSounds()
		elseif PreviousHealthRatio <= 0.3 and HealthRatio > 0.3 then
			MuffleSounds(true)
		end
		
		
		absorptionBarCheck(HealthRatio) -- Serves as a means to turn the HealthNumber red when health is low while also accounting for absorption with this.
		
		-- Change health bars
		barChange(HealthL, HealthRatio)
		barChange(HealthR, HealthRatio)
		
		-- If Health is below or at 80%, set TransparencyLevel of BloodScreen for the heart beating effect of BloodScreen.
		-- BloodScreen transparency will intensify and become more visible when health is lower.
		if Humanoid.Health <= Humanoid.MaxHealth * 0.8 then
			BloodScreen:SetAttribute("TransparencyLevel", HealthRatio)
		end
		-- If Health is above 80%, set TransparencyLevel to 1. Thre is no BloodScreen effect.
		if Humanoid.Health > Humanoid.MaxHealth * 0.8 and BloodScreen.ImageTransparency < 1 then
			BloodScreen:SetAttribute("TransparencyLevel", 1)
		end
		
		-- Set the image transparency to the TransparencyLevel multiplied by the BloodScreenRegainRatio.
		-- BloodScreenRegainRatio is supposed to dictate how much transparency is regained from the beating effect.
		BloodScreen.ImageTransparency = math.clamp(BloodScreen:GetAttribute("TransparencyLevel") * BloodScreenRegainRatio, 0, 1)

		PreviousHealthRatio = HealthRatio
	end)
	
	-- Change absorption bar if absorption changes.
	local absorptionChanged = Humanoid:GetAttributeChangedSignal("Absorption"):Connect(function()
		absorptionBarCheck()
		local changeAmount = math.abs(lastAbsorption-Humanoid:GetAttribute("Absorption"))
		lastAbsorption = Humanoid:GetAttribute("Absorption")
		barChange(AbsorptionL,Humanoid:GetAttribute("Absorption")/Humanoid:GetAttribute("MaxAbsorption"), changeAmount/100)
		barChange(AbsorptionR,Humanoid:GetAttribute("Absorption")/Humanoid:GetAttribute("MaxAbsorption"), changeAmount/100)
	end)
	
	-- If the LowHealthMuffleSetting is changed, muffle sounds if health is 30% or lower. Unmuffle if above 30%.
	local LowHealthMuffleSettingChanged = LowHealthMuffleSetting.Changed:Connect(function()
		if LowHealthMuffleSetting.Value then
			if Humanoid.Health/Humanoid.MaxHealth <= 0.3 then
				MuffleSounds()
			else
				MuffleSounds(true)
			end
		end
	end)
	
	-- This loop creates a heart beating effect with BloodScreen using TransparencyLevel and BloodScreenRegainRatio.
	task.defer(function()
		while Humanoid.Health > 0 do
			if Humanoid.Health <= Humanoid.MaxHealth * 0.8 then
				local HealthRatio = Humanoid.Health / Humanoid.MaxHealth
				local Intensity = (1 - HealthRatio)^2.5 

				-- How deeper the beat gets.
				local BeatTransparency = math.clamp(BloodScreen:GetAttribute("TransparencyLevel") - (0.35 * Intensity), 0, 1)

				-- Beat in.
				TweenService:Create(
					BloodScreen,
					TweenInfo.new(0.1, Enum.EasingStyle.Linear),
					{ImageTransparency = BeatTransparency}
				):Play()

				task.wait(0.1) -- constant wait inbetween both beats. For that ba-dum effect.

				-- Beat out.
				TweenService:Create(
					BloodScreen,
					TweenInfo.new(0.1, Enum.EasingStyle.Linear),
					{ImageTransparency = math.clamp(BloodScreen:GetAttribute("TransparencyLevel") + (Intensity * 0.2), 0, 1)}
				):Play()

				task.wait((HealthRatio ^ 1.25) * 4) -- Heartbeat speed.
			end
			task.wait()
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
	MuffleSounds(true)

	DownedProgress.Value = 100
	ReviveProgress.Value = 0
	CircleFramesModule.Progress(MainDownedProgressFrame,DownedProgress,DownedProgress.Value)
	CircleFramesModule.Progress(MainReviveProgressFrame,ReviveProgress,ReviveProgress.Value)
	local bannedParts = {"Head"}--,"RightUpperArm","LeftUpperArm","RightLowerArm","LeftLowerArm","RightHand","LeftHand"}

	local DownedEventFunction = DownedEvent.OnClientEvent:Connect(function(interactCharacter)

		--if interactCharacter then
		--	if interactCharacter:FindFirstChild("Humanoid") and interactCharacter.Humanoid:GetAttribute("Downed") then
		--		local interactPlayer = game.Players:GetPlayerFromCharacter(interactCharacter)
		--		local allyId = TeamHandler.Check(Player,interactPlayer)
		--		interactCharacter:SetAttribute("HighlightColor",allyIdTable[allyId][1])
		--		--if allyId == 1 then
		--		--	interactCharacter:SetAttribute("InteractId",5)
		--		---	interactCharacter:SetAttribute("InteractText","EXECUTE")
		--		--end
		--	end
		--	return
		--end

		--local beginningheartbeatPitch = 0.8
		--local droneVolume = 3
		--local heartbeatVolume = 4
		--local ccBrightness = -0.5
		--local ccContrast = 1
		--local ccTintSat = 255
		--local droneNoise = DowningObjects:WaitForChild("Drone"):Clone()
		--local heartbeatNoise = DowningObjects:WaitForChild("Heartbeat"):Clone()
		--local DownedCC = DowningObjects:WaitForChild("DownedCC"):Clone()
		--DownedCC.Parent = Lighting
		--droneNoise.Parent = PlayerEffectsFolder
		--heartbeatNoise.Parent = PlayerEffectsFolder
		--droneNoise:Play()
		--heartbeatNoise:Play()

		--DownedFrame.GroupTransparency = 1
		--DownedProgress.Value = 100
		--DownedMessage.Text = 'Hold  <font color="rgb(170,0,0)">"'.. KeybindHandler.Keybind("Speed Up Downing",Player).Name ..'"</font> To Give Up.'
		--CircleFramesModule.Progress(MainDownedProgressFrame,DownedProgress,DownedProgress.Value)
		--TweenService:Create(DownedFrame,TweenInfo.new(2,Enum.EasingStyle.Linear),{GroupTransparency = 0}):Play()
		--DownedFrame.Visible = true

		--local Increment = 0.5
		--local Time = Humanoid:GetAttribute("DownStart") or 60
		--local waitTime = (Time/100)*Increment

		--Humanoid:GetAttributeChangedSignal("Reviving"):Connect(function()
		--	if Humanoid:GetAttribute("Reviving") > 0 then
		--		DownedFrame.Visible = false
		--		ReviveFrame.Visible = true
		--		ReviveProgress.Value = 0
		--		CircleFramesModule.Progress(MainReviveProgressFrame,ReviveProgress,ReviveProgress.Value)
		--		TweenService:Create(ReviveProgress,TweenInfo.new(Humanoid:GetAttribute("Reviving"),Enum.EasingStyle.Linear),{Value = 100}):Play()
		--	else
		--		if Humanoid:GetAttribute("Downed") then
		--			DownedFrame.Visible = true
		--		end
		--		ReviveFrame.Visible = false
		--		ReviveProgress.Value = 0
		--		CircleFramesModule.Progress(MainReviveProgressFrame,ReviveProgress,ReviveProgress.Value)
		--	end
		--end)

		--task.defer(function()
		--	while task.wait() and Humanoid.Health > 0 do
		--		CircleFramesModule.Progress(MainDownedProgressFrame,DownedProgress,DownedProgress.Value)
		--		CircleFramesModule.Progress(MainReviveProgressFrame,ReviveProgress,ReviveProgress.Value)

		--		heartbeatNoise.PlaybackSpeed = (1-(DownedProgress.Value/100))+beginningheartbeatPitch
		--		droneNoise.Volume = droneVolume+((DownedProgress.Value/100)*-droneVolume)
		--		heartbeatNoise.Volume = heartbeatVolume+((DownedProgress.Value/100)*-heartbeatVolume)
		--		DownedCC.Brightness = ccBrightness+((DownedProgress.Value/100)*-ccBrightness)
		--		DownedCC.Contrast = ccContrast+((DownedProgress.Value/100)*-ccContrast)
		--		DownedCC.TintColor = Color3.fromHSV(0,1+((DownedProgress.Value/100)*-1),1)
		--		if UserInputService:IsKeyDown(KeybindHandler.Keybind("Speed Up Downing",Player)) then
		--			waitTime = (Time/100)*Increment*0.02
		--			DownedMessage.Text = '<font color="rgb(255,0,0)">Giving Up on Life</font>'
		--		else
		--			waitTime = (Time/100)*Increment
		--			DownedMessage.Text = 'Hold  <font color="rgb(255,0,0)">"'.. KeybindHandler.Keybind("Speed Up Downing",Player).Name ..'"</font> To Give Up.'
		--		end
		--	end
		--end)


		--task.defer(function()
		--	while DownedProgress.Value > 0 and Humanoid:GetAttribute("Downed") and Humanoid.Health > 0 do

		--		if Humanoid:GetAttribute("Reviving") == 0 then
		--			TweenService:Create(DownedProgress,TweenInfo.new(waitTime,Enum.EasingStyle.Linear),{Value = DownedProgress.Value-Increment}):Play()
		--		end
		--		task.wait(waitTime)
		--	end
		--	DownedFrame.GroupTransparency = 1
		--	DownedProgress.Value = 100
		--	DownedFrame.Visible = false
		--	droneNoise:Destroy()
		--	heartbeatNoise:Destroy()
		--	DownedCC:Destroy()
		--	if Humanoid:GetAttribute("Downed") then
		--		DownedEvent:FireServer(Humanoid)
		--	end
		--end)

	end)
	
	local RenderStepLoop = RunService.RenderStepped:Connect(function(dt)
		local CurrentCamCF = Camera.CFrame

		local deltaCF = LastCamCF:ToObjectSpace(CurrentCamCF)
		local rx, ry, rz = deltaCF:ToOrientation()
		local targetOffset = Vector2.new(-math.deg(ry), math.deg(rx))

		local ShakeStrength = 0.6
		targetOffset *= ShakeStrength

		-- Clamp
		targetOffset = Vector2.new(
			math.clamp(targetOffset.X, -12, 12),
			math.clamp(targetOffset.Y, -12, 12)
		)

		local Smoothness = 6
		shakeOffset = shakeOffset:Lerp(targetOffset, math.clamp(dt * Smoothness, 0, 1))
		Bars.Position = Bars:GetAttribute("OriginalPosition")
			+ UDim2.fromOffset(shakeOffset.X, shakeOffset.Y)
		RightFrame.Position = RightFrame:GetAttribute("OriginalPosition")
			+ UDim2.fromOffset(shakeOffset.X, shakeOffset.Y)

		LastCamCF = CurrentCamCF
	end)

	Humanoid.Died:Once(function()
		for _, connection in {
			staminaChanged,
			maxStaminaChanged,
			healthChanged,
			backpackAdded,
			backpackRemoved,
			charAdded,charRemoved,
			DownedEventFunction,
			absorptionChanged,
			GradientChange,
			LowHealthMuffleSettingChanged,
			RenderStepLoop
			} 
		do
			connection:Disconnect()
		end
	end)

	Character.AncestryChanged:Once(function()
		for _, connection in {
			staminaChanged,
			maxStaminaChanged,
			healthChanged,
			backpackAdded,
			backpackRemoved,
			charAdded,charRemoved,
			DownedEventFunction,
			absorptionChanged,
			GradientChange,
			LowHealthMuffleSettingChanged,
			RenderStepLoop
			} 
		do
			connection:Disconnect()
		end
	end)
end

return module
