local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserSettings = UserSettings():GetService("UserGameSettings")

local EvilDeathCC = Lighting.EvilDeathCC
local respawnFadeTime = 1

local module = {}

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Character: Model = nil
local Humanoid: Humanoid = nil
local HumanoidRootPart: BasePart = nil
local Head: BasePart = nil

local ROTATION_SPEED_MOUSE = Vector2.new(1, 0.77)*math.rad(0.5) -- (rad/inputdelta)
local MIN_Y = math.rad(-70)
local MAX_Y = math.rad(80)

module.BASE_NUM_LERP = 0.25
module.BASE_VIEWBOB_ROTATION = 8
module.SET_VIEWBOB_ROTATION = 0.5

--local cutscene_transition = 0
--module.CUTSCENE_TRANSITION_SPEED = 0.3
--module.CUTSCENE_MODE = false

local CurrentVel = 0
local t = 0
local MouseDelta = Vector2.new()

local CameraModifiers = {}

--[[
	Adds a camera modifier for the next frame frame.
	perm => if false/nil, the modifiation will be reversed next frame.
]]
function module.AddModifier(cframe: CFrame, perm: boolean)
	table.insert(CameraModifiers, {cframe, perm == true})
end

local function initializeCamera()
	Camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function CalculateCurve(Base : number, Set : number) : number
	return math.sin(t * Base) * Set
end

local function GetVelMag() : number
	return math.round(Vector3.new(HumanoidRootPart.AssemblyLinearVelocity.X, HumanoidRootPart.AssemblyLinearVelocity.Y, HumanoidRootPart.AssemblyLinearVelocity.Z).Magnitude)
end

local function NumLerp(num1: number, num2: number, rate: number) : number
	return num1 + (num2-num1)*rate
end

local function updateCamera(dt)
	if Humanoid.Health <= 0 or Humanoid:GetAttribute("DownedRagdolling") then
		if Character:FindFirstChild("Ragdoll") and Character.Ragdoll.Value:FindFirstChild("Head") then
			Head = Character.Ragdoll.Value.Head
		else
			Head = Character.Head
		end
		Camera.CFrame = Head.CFrame * CFrame.new(0, 0, -0.5)
		return
	end

	if Humanoid.Health <= 0 and Character:FindFirstChild("Ragdoll") then
		local charHead = Character["Ragdoll"].Value:FindFirstChild("Head")
		if charHead then
			Camera.CFrame = charHead.CFrame
		end
	else
		Camera.CameraSubject = Humanoid
	end

	local Vel = NumLerp(CurrentVel, GetVelMag(), module.BASE_NUM_LERP)
	t += dt * Vel * 0.05

	CurrentVel = Vel
	local base = module.BASE_VIEWBOB_ROTATION
	local set = module.SET_VIEWBOB_ROTATION * 0.01
	module.AddModifier(
		--Camera.CFrame:ToObjectSpace(Head.CFrame * CFrame.new(0, 0, -0.5)) *
		CFrame.fromEulerAnglesYXZ(
			CalculateCurve(base * 2, set * 1),
			CalculateCurve(base, set * 2),
			-CalculateCurve(base * 2, set * 0.3)
		)
	)
end

function module.LoadChar(char)
	
	local HUD = Player.PlayerGui:WaitForChild("HUD")
	
	task.defer(function()
		EvilDeathCC.Brightness = -1 -- Darkness
		HUD.EffectFrame.GroupTransparency = 1
		HUD.RightFrame.GroupTransparency = 1
		HUD.Bars.GroupTransparency = 1
		
		task.wait(0.1)
		
		TweenService:Create(EvilDeathCC,TweenInfo.new(respawnFadeTime),{Brightness = 0}):Play() -- Fade in back to normal brightness
		TweenService:Create(HUD.EffectFrame,TweenInfo.new(respawnFadeTime),{GroupTransparency = 0}):Play()
		TweenService:Create(HUD.RightFrame,TweenInfo.new(respawnFadeTime),{GroupTransparency = 0}):Play()
		TweenService:Create(HUD.Bars,TweenInfo.new(respawnFadeTime),{GroupTransparency = 0}):Play()
	end)
	
	Character = char
	local ViewbobConfig = Player.PlayerScripts:WaitForChild("ViewbobConfig")
	Camera.CameraType = Enum.CameraType.Scriptable
	Player.CameraMode = Enum.CameraMode.LockFirstPerson
	Camera.CFrame = Character:WaitForChild("Head").CFrame

	Humanoid = Character:WaitForChild("Humanoid")
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	Head = Character:WaitForChild("Head")
	
	local MouseUI = Player.PlayerGui.MouseUI
	MouseUI.Enabled = true
	
	local DeathMessage = Player.PlayerGui.HUD.DeathMessage
	DeathMessage.BeginningText.TextTransparency = 1
	DeathMessage.NameText.TextTransparency = 1
	DeathMessage.NameText.Text = "YOURSELF" -- Default death name text

	local tempInverse = CFrame.new()
	local cameraModifier = CFrame.new()
	local tempCameraModifier = CFrame.new()
	
	-- // The temporary camera modifiers must be reversed before the camera
	-- // update is done so that they do not interfere with mouse movement.
	RunService:BindToRenderStep("ReverseTempCameraModifier", Enum.RenderPriority.Camera.Value - 2, function(dt)
		Camera.CFrame *= tempInverse
		updateCamera(dt)

		--if module.CUTSCENE_MODE then
		--	cutscene_transition = math.min(1, cutscene_transition + dt / module.CUTSCENE_TRANSITION_SPEED)
		--else
		--	cutscene_transition = math.max(0, cutscene_transition - dt / module.CUTSCENE_TRANSITION_SPEED)
		--end

		local HeadTransform = Head.Neck.Transform * CFrame.new(0, 0, -0.5)
		HeadTransform -= HeadTransform.Position

		cameraModifier = CFrame.new()
		tempCameraModifier = CFrame.new() --CFrame.new(0, 0, -0.5):Lerp(HeadTransform, cutscene_transition)
		for _, modifier in CameraModifiers do
			if modifier[2] then
				cameraModifier *= modifier[1]
			else
				tempCameraModifier *= modifier[1]
			end
		end
		CameraModifiers = {}

		tempInverse = tempCameraModifier:Inverse()
	end)

	-- << TAKEN FROM BUILT-IN ROBLOX CAMERA CODE FOR CONSISTENCY >>
	local function CalculateNewLookCFrame(rotateInput: Vector2): CFrame
		local currLookVector: Vector3 = Camera.CFrame.LookVector
		local currPitchAngle = math.asin(currLookVector.Y)
		local yTheta = math.clamp(rotateInput.Y, -MAX_Y + currPitchAngle, -MIN_Y + currPitchAngle)
		local constrainedRotateInput = Vector2.new(rotateInput.X, yTheta)
		local startCFrame = CFrame.new(Vector3.zero, currLookVector)
		local newLookCFrame = CFrame.Angles(0, -constrainedRotateInput.X, 0) * startCFrame * CFrame.Angles(-constrainedRotateInput.Y,0,0)
		return newLookCFrame
	end

	local lockcutscenecam = false
	local lastVerticalTransformation = CFrame.new()
	RunService:BindToRenderStep("UpdateCamera", Enum.RenderPriority.Camera.Value, function(dt)
		initializeCamera()

		--lockcutscenecam = lockcutscenecam or cutscene_transition == 1
		--if cutscene_transition == 0 then
		--	lockcutscenecam = false

		-- // PLAYER-CONTROLLED CAMERA
		local NewLookCFrame = CalculateNewLookCFrame(MouseDelta * ROTATION_SPEED_MOUSE)
		HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.new(Vector3.zero, NewLookCFrame.LookVector * Vector3.new(1, 0, 1))
		Camera.CFrame = CFrame.new(HumanoidRootPart.CFrame:PointToWorldSpace(HumanoidRootPart.CFrame:PointToObjectSpace(Head.CFrame.Position) + Vector3.new(0, 0, -Head.Size.Y / 2))) * NewLookCFrame
		Camera.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.new(Vector3.zero, Camera.CFrame.LookVector * Vector3.new(1, 0, 1)):ToWorldSpace(HumanoidRootPart.CFrame:ToObjectSpace(Camera.CFrame))

		--else
		--	-- // CUTSCENE-CONTROLLED CAMERA
		--	if lockcutscenecam then
		--		Camera.CFrame = Head.CFrame * CFrame.new(0, 0, -0.5)
		--	else
		--		local lookDirection = CalculateNewLookCFrame(Vector2.zero)
		--		Camera.CFrame = (CFrame.new(HumanoidRootPart.CFrame:PointToWorldSpace(HumanoidRootPart.CFrame:PointToObjectSpace(Head.CFrame.Position) + Vector3.new(0, 0, -0.5))) * lookDirection):Lerp(Head.CFrame * CFrame.new(0, 0, -0.5), cutscene_transition)
		--	end
		--end

		MouseDelta = Vector2.zero
		Camera.CFrame *= cameraModifier * tempCameraModifier
	end)

	-- // Get mouse input like internal camera scripts do.
	UserInputService.InputChanged:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			MouseDelta = Vector2.new(input.Delta.X, input.Delta.Y)
		end
	end)
	
	Humanoid.Died:Once(function() -- Play death screen
		
		local Ragdoll = Character
		if Character:FindFirstChild("Ragdoll") then -- Check if player is already ragdolled
			Ragdoll = Character.Ragdoll.Value
		end
		for _,part in pairs(Ragdoll:GetDescendants()) do -- This fixes the invisible head bug
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 0
			end
		end
		
		task.defer(function()
			-- turn main HUD and mouse ui invisible
			MouseUI.Enabled = false
			HUD.EffectFrame.GroupTransparency = 1
			HUD.RightFrame.GroupTransparency = 1
			HUD.Bars.GroupTransparency = 1
			
			if Humanoid:GetAttribute("Killer") and Humanoid:GetAttribute("Killer") ~= Player.Name then -- display Killer's name if Killer exist
				DeathMessage.NameText.Text = string.upper(Humanoid:GetAttribute("Killer"))
			end
			
			if HUD:FindFirstChild("BloodScreen") then
				TweenService:Create(HUD.BloodScreen,TweenInfo.new(Players.RespawnTime/6),{ImageTransparency = 1}):Play()
			end
			
			EvilDeathCC.Brightness = 1 -- Flash of white
			task.wait(Players.RespawnTime/20)
			TweenService:Create(EvilDeathCC,TweenInfo.new(Players.RespawnTime/20),{Brightness = 0}):Play() -- Back to normal brightness
			task.wait(Players.RespawnTime/20)
			TweenService:Create(EvilDeathCC,TweenInfo.new(Players.RespawnTime/2),{Brightness = -1}):Play() -- Fade to black
			task.wait(Players.RespawnTime/3)
			TweenService:Create(DeathMessage.BeginningText,TweenInfo.new(Players.RespawnTime/6),{TextTransparency = 0}):Play() -- Display beginning message
			task.wait(Players.RespawnTime/6)
			TweenService:Create(DeathMessage.NameText,TweenInfo.new(Players.RespawnTime/6),{TextTransparency = 0}):Play() -- Display killer name
		end)
	end)
end

function module.UnloadChar(Character)
	RunService:UnbindFromRenderStep("ReverseTempCameraModifier")
	RunService:UnbindFromRenderStep("UpdateCamera")
end

return module
