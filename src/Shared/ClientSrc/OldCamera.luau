local module = {}
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RenderStep = nil
local CurrentVel = 0
local Drift = 0
local Limiter = 0
local Vel,t,x,y : number
t = 0
local sway : CFrame
local MouseDelta : Vector2
local Camera = workspace.CurrentCamera

local CameraModifiers = {}

--[[
	Adds a camera modifier for the next frame frame.
	perm => if false/nil, the modifiation will be reversed next frame.
]]
function module.AddModifier(cframe: CFrame, perm: boolean)
	table.insert(CameraModifiers, {cframe, perm == true})
end

function module.LoadChar(Character)
	local ViewbobConfig = Player.PlayerScripts:WaitForChild("ViewbobConfig")
	Camera.CameraType = Enum.CameraType.Custom
	Player.CameraMode = Enum.CameraMode.LockFirstPerson
	Camera.CFrame = Character:WaitForChild("Head").CFrame
	local function NumLerp(num1: number, num2: number, rate: number) : number
		return num1 + (num2-num1)*rate
	end

	local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
	local HRP = Character:WaitForChild("HumanoidRootPart")

	local function CalculateCurve(Base : number, Set : number) : number
		return math.sin(t * Base) * Set
	end

	local function GetVelMag() : number
		return math.round(Vector3.new(HRP.AssemblyLinearVelocity.X, HRP.AssemblyLinearVelocity.Y, HRP.AssemblyLinearVelocity.Z).Magnitude)
	end

	local function GetMouseDrift(Drift : number, MouseDelta : Vector2, dt : number) : number
		return NumLerp(Drift, math.clamp(MouseDelta.X, ViewbobConfig.DriftMin.Value, ViewbobConfig.DriftMax.Value), (ViewbobConfig.BaseMult.Value * dt))
	end

	local function GetSwayVal(x:number, y:number) : CFrame
		return CFrame.new(Vector3.new(x, y, 0), Vector3.new(x*.95, y*.95, ViewbobConfig.CustomSwayZVal.Value)) + Camera.CFrame.Position
	end

	local function ConvCFrameToOrientation(_CFrame: CFrame)
		local setX, setY, setZ = _CFrame:ToOrientation()
		return Vector3.new(math.deg(setX), math.deg(setY), math.deg(setZ))
	end

	local function CameraUpdt(dt)
		--if Character:FindFirstChildOfClass("Tool") then return end

		local Head = Character:FindFirstChild("Head")
		if Humanoid.Health <= 0 or Humanoid:GetAttribute("DownedRagdolling") then
			if Character:FindFirstChild("Ragdoll") then
				Head = Character.Ragdoll.Value.Head
			end
			Camera.CFrame = Head.CFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(0, 0, -0.5)
			return
		end

		if Humanoid.Health <= 0 and Character:FindFirstChild("Ragdoll") then
			local charHead = Character["Ragdoll"].Value:FindFirstChild("Head")
			if charHead then
				Camera.CameraType = "Scriptable"
				Camera.CFrame = charHead.CFrame
			end
		else
			Camera.CameraSubject = Humanoid
		end

		--Limiter += dt
		--if Limiter >= 1/ViewbobConfig.FPSRate.Value then
			MouseDelta = UIS:GetMouseDelta()

			Vel = NumLerp(CurrentVel, GetVelMag(), ViewbobConfig.BaseNumLerp.Value)
			t += dt * Vel * 0.05

			x = math.cos(t * ViewbobConfig.BaseSway.Value) * ViewbobConfig.SetSway.Value
			y = math.sin(t * ViewbobConfig.BaseSway.Value) * ViewbobConfig.SetSway.Value
			sway = GetSwayVal(x,y)

			Drift = GetMouseDrift(Drift, MouseDelta, dt)
			CurrentVel = Vel

		--module.AddModifier(
		--	CFrame.new(0, CalculateCurve(ViewbobConfig.BaseFreq.Value, ViewbobConfig.SetFreq.Value) * Vel / ViewbobConfig.BaseMult.Value, 0)
		--		* CFrame.Angles(0, 0, math.rad(CalculateCurve(ViewbobConfig.BaseRot.Value, ViewbobConfig.SetRot.Value) * Vel / ViewbobConfig.BaseMult.Value) + math.rad(Drift))
		--)

		local base = ViewbobConfig.BaseRot.Value
		local set = ViewbobConfig.SetRot.Value * 0.01
		module.AddModifier(
			--Camera.CFrame:ToObjectSpace(Head.CFrame * CFrame.Angles(0, math.rad(-90), 0) * CFrame.new(0, 0, -0.5)) *
			CFrame.fromEulerAnglesYXZ(
				CalculateCurve(base * 2, set * 1),
				CalculateCurve(base, set * 2),
				-CalculateCurve(base * 2, set * 0.3)
			)
		)

			--Humanoid.CameraOffset = ConvCFrameToOrientation(sway)

		--	Limiter -= 1/ViewbobConfig.FPSRate.Value
		--end
	end

	local tempInverse = CFrame.new()
	local cameraModifier = CFrame.new()
	local tempCameraModifier = CFrame.new()
	RunService:BindToRenderStep("ReverseTempCameraModifier", Enum.RenderPriority.Camera.Value - 2, function()
		Camera.CFrame *= tempInverse

		cameraModifier = CFrame.new()
		tempCameraModifier = CFrame.new()
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
	RunService:BindToRenderStep("UpdateCameraBobbing", Enum.RenderPriority.Camera.Value + 1, function(dt)
		CameraUpdt(dt)
	end)
	RunService:BindToRenderStep("ApplyCameraModifiers", Enum.RenderPriority.Camera.Value + 3, function(dt)
		Camera.CFrame *= cameraModifier * tempCameraModifier
	end)
end

function module.UnloadChar(Character)
	RunService:UnbindFromRenderStep("ReverseTempCameraModifier")
	RunService:UnbindFromRenderStep("UpdateCameraBobbing")
	RunService:UnbindFromRenderStep("ApplyCameraModifiers")
end

return module
