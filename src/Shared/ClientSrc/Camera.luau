local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local UserSettings = UserSettings():GetService("UserGameSettings")

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
function module.AddModifier(cframe: CFrame, permanent: boolean)
	table.insert(CameraModifiers, {cframe, permanent == true})
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
		if Character:FindFirstChild("Ragdoll") then
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
	Character = char
	local ViewbobConfig = Player.PlayerScripts:WaitForChild("ViewbobConfig")
	Camera.CameraType = Enum.CameraType.Scriptable
	Player.CameraMode = Enum.CameraMode.LockFirstPerson
	Camera.CFrame = Character:WaitForChild("Head").CFrame

	Humanoid = Character:WaitForChild("Humanoid")
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
	Head = Character:WaitForChild("Head")

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
end

function module.UnloadChar(Character)
	RunService:UnbindFromRenderStep("ReverseTempCameraModifier")
	RunService:UnbindFromRenderStep("UpdateCamera")
end

return module
