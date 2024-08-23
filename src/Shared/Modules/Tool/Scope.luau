--!nonstrict
--Module is written by TheArturZh

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Camera = workspace.CurrentCamera

local function UpdateScope(Scope)
	local Texture = Scope:WaitForChild("Texture")
	local Grid = Scope:WaitForChild("Grid") 
	local CameraCF = Camera.CFrame

	local ScopeViewEndCF = Scope.CFrame * CFrame.new(-Scope.Size.X/2,0,0)
	local ScopeFarEndCF = Scope.CFrame * CFrame.new(Scope.Size.X/2,0,0)

	local ViewToCam = CameraCF:ToObjectSpace(ScopeViewEndCF)
	local FarEndToCam = CameraCF:ToObjectSpace(ScopeFarEndCF)

	local DistFromClipPlane = ViewToCam.Z
	local CylinderSize = math.min(Scope.Size.Y, Scope.Size.Z)

	local TextureStuds = CylinderSize * 2
	local CenterOffset = (TextureStuds-CylinderSize)/2

	Texture.StudsPerTileU = TextureStuds
	Texture.StudsPerTileV = TextureStuds
	if Grid then
		Grid.StudsPerTileU = TextureStuds
		Grid.StudsPerTileV = TextureStuds
	end

	local MaxOffsetFromCenter = TextureStuds/2
	local MaxOffset = CenterOffset + MaxOffsetFromCenter
	local MinOffset = CenterOffset - MaxOffsetFromCenter

	local U_OFFSET = FarEndToCam.X/FarEndToCam.Z * DistFromClipPlane - ViewToCam.X
	local V_OFFSET = FarEndToCam.Y/FarEndToCam.Z * DistFromClipPlane - ViewToCam.Y

	local OffsetCFrame = CFrame.lookAt(ScopeViewEndCF.Position, ScopeViewEndCF.Position+ScopeViewEndCF.RightVector) * CFrame.new(Vector3.new(U_OFFSET, V_OFFSET, 0))
	local OffsetCFrameLocalized = ScopeViewEndCF:ToObjectSpace(OffsetCFrame)

	Texture.OffsetStudsU = math.clamp(CenterOffset - OffsetCFrameLocalized.Z, MinOffset, MaxOffset)
	Texture.OffsetStudsV = math.clamp(CenterOffset + OffsetCFrameLocalized.Y, MinOffset, MaxOffset)
	if Grid then
		Grid.OffsetStudsU = math.clamp(CenterOffset - OffsetCFrameLocalized.Z, MinOffset, MaxOffset)
		Grid.OffsetStudsV = math.clamp(CenterOffset + OffsetCFrameLocalized.Y, MinOffset, MaxOffset)
	end
end

local function UpdateSight(Scope)
	local ScopeGUI = Scope:WaitForChild("Sight")
	local SightImageLabel = ScopeGUI:WaitForChild("SightImage")
	local CameraCF = Camera.CFrame

	local ScopeViewEndCF = Scope.CFrame * CFrame.new(-Scope.Size.X/2,0,0)
	local ScopeFarEndCF = ScopeViewEndCF * CFrame.new(10000,0,0)

	local ViewToCam = CameraCF:ToObjectSpace(ScopeViewEndCF)
	local FarEndToCam = CameraCF:ToObjectSpace(ScopeFarEndCF)

	local DistFromClipPlane = ViewToCam.Z

	local U_OFFSET = FarEndToCam.X/FarEndToCam.Z * DistFromClipPlane - ViewToCam.X
	local V_OFFSET = FarEndToCam.Y/FarEndToCam.Z * DistFromClipPlane - ViewToCam.Y

	local OffsetCFrame = CFrame.lookAt(ScopeViewEndCF.Position, ScopeViewEndCF.Position+ScopeViewEndCF.RightVector) * CFrame.new(Vector3.new(U_OFFSET, V_OFFSET, 0))
	local OffsetCFrameLocalized = ScopeViewEndCF:ToObjectSpace(OffsetCFrame)

	local pps = ScopeGUI.PixelsPerStud
	SightImageLabel.Position = UDim2.new(0.5, OffsetCFrameLocalized.Z * pps, 0.5, -OffsetCFrameLocalized.Y * pps)
end

local module = {}

local Connection

module.SetEnabled = function(Enabled: boolean, Scope)
	print(Scope)
	if Enabled then
		if not Connection then
			Connection = RunService.RenderStepped:Connect(function()
				if Scope:GetAttribute("Sight") then
					UpdateSight(Scope)
				else
					UpdateScope(Scope)
				end
			end)
		end
	elseif Connection then
		Connection:Disconnect()
		Connection = nil
	end
end

return module