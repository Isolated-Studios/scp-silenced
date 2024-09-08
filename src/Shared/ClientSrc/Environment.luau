local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}

function module.Init ()
	local MaxDistance = 50
	local MinDistance = 4
	local Camera = workspace.CurrentCamera
	local BeamSettingsFolder = ReplicatedStorage.Configs.LightBeams
	local PrimeLightBeam = ReplicatedStorage.Objects.Environment.LightBeam
	local evilLightingPart = ReplicatedStorage.EvilLightingPart:Clone()
	evilLightingPart.Parent = Camera
	local LightParams = RaycastParams.new()
	LightParams.FilterType = Enum.RaycastFilterType.Exclude
	local VolumetricBeams = {}

	local function UpdateVolumetricBeams()
		evilLightingPart:PivotTo(Camera.CFrame)
		for Beam, Details in VolumetricBeams do
			local NormalizedSourcePartPosition = Vector3.new(Details.SourcePart.Position.X, 0, Details.SourcePart.Position.Z)
			local NormalizedSubjectPosition
			NormalizedSubjectPosition = Vector3.new(Camera.CFrame.Position.X, 0, Camera.CFrame.Position.Z)
			local StartTransparency = Details.InitialTransparency.Keypoints[1]
			local EndTransparency = Details.InitialTransparency.Keypoints[#Details.InitialTransparency.Keypoints]
			local Magnitude = (NormalizedSubjectPosition - NormalizedSourcePartPosition).Magnitude - MinDistance
			local NormalizedValue = math.max(StartTransparency.Value, 1 - math.min(1, Magnitude / MaxDistance))
			Beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, NormalizedValue),
				NumberSequenceKeypoint.new(1, EndTransparency.Value),
			})
		end
	end

	for _, LightPart in pairs(CollectionService:GetTagged("BeamLight")) do
		if LightPart:IsA("BasePart") and (LightPart:FindFirstChildOfClass("PointLight") or LightPart:FindFirstChildOfClass("SpotLight") or LightPart:FindFirstChildOfClass("SurfaceLight")) then
			local Attachment0 = Instance.new("Attachment")
			local Attachment1 = Instance.new("Attachment")
			local LightBeam = PrimeLightBeam:Clone()
			LightBeam.Parent = LightPart
			Attachment0.Name = "Attachment0"
			Attachment1.Name = "Attachment1"
			Attachment0.Parent = LightPart
			Attachment1.Parent = LightPart
			LightBeam.Attachment0 = Attachment0
			LightBeam.Attachment1 = Attachment1
			LightParams.FilterDescendantsInstances = {LightPart.Parent,CollectionService:GetTagged("Ignore"),CollectionService:GetTagged("BeamIgnore")}
			local Light = LightPart:FindFirstChildOfClass("SpotLight") or LightPart:FindFirstChildOfClass("SurfaceLight") or LightPart:FindFirstChildOfClass("PointLight")
			LightBeam.Color = ColorSequence.new(Light.Color)
			local direction = -LightPart.CFrame.UpVector
			if LightPart:GetAttribute("BeamType") and BeamSettingsFolder:FindFirstChild(LightPart:GetAttribute("BeamType")) then
				local Configs = require(BeamSettingsFolder[LightPart:GetAttribute("BeamType")])
				LightBeam.Width0 = Configs.Width0 or 1
				LightBeam.Width1 = Configs.Width1 or 50
				if Configs.Direction then
					direction = LightPart.CFrame[Configs.Direction] or -LightPart.CFrame.UpVector
					if Configs.Reverse then direction = -direction end
				end
			end
			local lightRaycast = workspace:Raycast(LightPart.Position,direction*200,LightParams)
			if lightRaycast then
				Attachment1.WorldPosition = lightRaycast.Position
			else
				Attachment1.Position = Vector3.new(0,50,0)
			end
			LightBeam.TextureLength = math.abs(Attachment1.Position.Y)+math.abs(Attachment1.Position.Y/10)
			VolumetricBeams[LightBeam] = {SourcePart = LightPart, InitialTransparency = LightBeam.Transparency}
			LightBeam.Destroying:Once(function()
				--print(VolumetricBeams)
				--table.remove(VolumetricBeams,table.find(VolumetricBeams,LightBeam))
			end)
		end
	end

	RunService.RenderStepped:Connect(UpdateVolumetricBeams)
end
return module
