local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CameraModule = require(script.Parent.Camera)

local PlayerAssets = ReplicatedStorage.PlayerAssets
local Animations = PlayerAssets.Animations
local Events = ReplicatedStorage.Events
local VaultEvent = Events.Character.VaultEvent

local StaminaUse = 10

--local KeybindHandler = require(ReplicatedStorage:WaitForChild("Common"):WaitForChild("KeybindHandler"))
local Player = game.Players.LocalPlayer
local module = {}
local function findPartInFrontTorso(char)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {char}
	local Humanoid = char.Humanoid
	local VaultStart = char.LowerTorso
	local origin = (VaultStart.Position)
	local direction = VaultStart.CFrame.LookVector
	local rayLength = 4 or Humanoid:GetAttribute("Running") and 8
	local result = game.Workspace:Raycast(origin, direction * rayLength, rayParams)
	if result then
		return result.Instance
	end
	return nil
end
local function findPartInFront(char)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {char}
 --   local VaultStart = char["CollisionBox"]["VaultStart"]
	--local origin = (VaultStart.WorldPosition)
	--local direction = VaultStart.WorldCFrame.LookVector
	local VaultStart = char.LowerTorso
	local origin = (VaultStart.Position)
	local direction = VaultStart.CFrame.LookVector
	local rayLength = 1 
	local result = game.Workspace:Raycast(origin, direction * rayLength, rayParams)
	if result then
		return result.Instance
	end
	return findPartInFrontTorso(char)
end
function module.LoadChar(Character)
	local Humanoid = Character:WaitForChild('Humanoid')
	local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')
	local LowerTorso = Character:WaitForChild("LowerTorso")
	local CollisionBox = Character:WaitForChild('CollisionBox')

	local VaultSlow: AnimationTrack = Humanoid.Animator:LoadAnimation(Animations.Character.Movement.VaultSlow)
	local VaultFast: AnimationTrack = Humanoid.Animator:LoadAnimation(Animations.Character.Movement.VaultFast)
	local VMVaultSlow: AnimationTrack = Humanoid.Animator:LoadAnimation(Animations.Character.Movement.VaultSlow)
	local VMVaultFast: AnimationTrack = Humanoid.Animator:LoadAnimation(Animations.Character.Movement.VaultFast)
	
	local VaultSlowMovementAnimation = {}
	for _, keyframe in Animations.Character.Movement.VaultSlow.MovementKeyframes:GetChildren() do
		table.insert(VaultSlowMovementAnimation, {tonumber(keyframe.Name), keyframe.CFrame})
	end
	table.sort(VaultSlowMovementAnimation, function(a0: {number?}, a1: {number?}): boolean
		return a1[1] > a0[1]
	end)

	local inputBegan =  UIS.InputBegan:Connect(function(Key,gpe)
		if CameraModule.CUTSCENE_MODE or Humanoid:GetAttribute("Vaulting") then return end
		if not gpe and Key.KeyCode == Enum.KeyCode.Space and findPartInFront(Character) then
			--local VaultEnd = Character["CollisionBox"]["VaultEnd"]
            local part = findPartInFront(Character)
            local playerHeadPosition = HumanoidRootPart.Position.Y + 1 --VaultEnd.WorldPosition.Y
			local wallTopPosition = part.Position + part.Size/2  
			if playerHeadPosition and wallTopPosition and part:GetAttribute("Vaultable") then
				if playerHeadPosition >= wallTopPosition.Y and Humanoid:GetAttribute("Stamina") and Humanoid:GetAttribute("Stamina")-StaminaUse>0 then
					local Running = Humanoid:GetAttribute("Running")
					Humanoid:SetAttribute("Vaulting", true)
					Humanoid:SetAttribute("Stamina", math.clamp(Humanoid:GetAttribute("Stamina")-StaminaUse,0,Humanoid:GetAttribute("MaxStamina")))
                    VaultEvent:FireServer(CollisionBox, Running)
					
					HumanoidRootPart.Anchored = true
					local LocalHRPPos = part.CFrame:ToObjectSpace(HumanoidRootPart.CFrame).Position
					local TargetCF = part.CFrame * CFrame.new(Vector3.new(LocalHRPPos.X, LocalHRPPos.Y, (0.8 + HumanoidRootPart.Size.Z / 2 + part.Size.Z / 2) * math.sign(LocalHRPPos.Z)), LocalHRPPos * Vector3.new(1, 1, 0))
					local transition_time = Running and 0.1 or (TargetCF.Position - HumanoidRootPart.Position).Magnitude / 8
					TweenService:Create(HumanoidRootPart, TweenInfo.new(transition_time, Enum.EasingStyle.Linear), {CFrame = TargetCF}):Play()
					CameraModule.CUTSCENE_MODE = true
					
					for _,viewmodel in pairs(workspace.CurrentCamera:GetChildren()) do
						if viewmodel:IsA("Model") and viewmodel:GetAttribute("Viewmodel") then
							local vmAnimator = viewmodel:WaitForChild("Humanoid"):WaitForChild("Animator")
							if Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool"):FindFirstChild("ViewModelAnimations") and Character:FindFirstChildOfClass("Tool")["ViewModelAnimations"]:FindFirstChild("Vault")  then
								local vaultanim = vmAnimator:LoadAnimation(Character:FindFirstChildOfClass("Tool")["ViewModelAnimations"]["Vault"])
								vaultanim:Play()
							end
							break
						end
					end
					
					task.wait(transition_time)
					local Animation = Running and VaultFast or VaultSlow
					
					HumanoidRootPart.Anchored = false
					Animation:Play()
					local InitialCF = LowerTorso.CFrame
					local LTOffset = HumanoidRootPart.CFrame:ToObjectSpace(InitialCF):Inverse()
					local chosenKeyframe = nil
					RunService:BindToRenderStep("VaultAnimationApplier", Enum.RenderPriority.Camera.Value - 1, function(dt)
						local nextKeyframe = nil
						for i, v in VaultSlowMovementAnimation do
							if v[1] > Animation.TimePosition then
								chosenKeyframe = v
								nextKeyframe = VaultSlowMovementAnimation[i + 1]
								break
							end
						end
						
						if nextKeyframe then
							chosenKeyframe = chosenKeyframe[2]:Lerp(nextKeyframe[2], (Animation.TimePosition - chosenKeyframe[1]) / (nextKeyframe[1] - chosenKeyframe[1]))
						elseif chosenKeyframe and type(chosenKeyframe) == "table" then
							chosenKeyframe = chosenKeyframe[2]
						end
						
						if chosenKeyframe then
							HumanoidRootPart.CFrame = InitialCF * chosenKeyframe * LTOffset
						end
					end)
					--Animation.Stopped:Once(function()
					--	local LowerTorsoCF = LowerTorso.CFrame
					--	RunService:BindToRenderStep("VaultAnimationApplier", Enum.RenderPriority.Camera.Value - 1, function(dt)
					--		local HRPOffset = LowerTorso.CFrame:ToObjectSpace(HumanoidRootPart.CFrame)
					--		HumanoidRootPart.CFrame = LowerTorsoCF:ToWorldSpace(HRPOffset)
					--	end)
					--end)
					Animation.Ended:Once(function()
						RunService:UnbindFromRenderStep("VaultAnimationApplier")
						Humanoid:SetAttribute("Vaulting", false)
						HumanoidRootPart.Anchored = false
						CameraModule.CUTSCENE_MODE = false
					end)
                end
            end
        end
    end)
end
return module