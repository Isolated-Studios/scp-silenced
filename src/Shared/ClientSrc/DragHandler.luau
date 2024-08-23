local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local module = {}
module.RANGE = 50
module.MAX_FORCE = 2000
module.HIGHLIGHT_SPEED = 8
module.TARGET_VELOCITY = 20
module.RESPONSIVENESS = 50

function module.Init()
	local Modules = ReplicatedStorage:WaitForChild("Modules")
	local Events = ReplicatedStorage:WaitForChild("Events")
	local DragEvent = Events:WaitForChild("Interaction"):WaitForChild("Drag")
	local UIModules = Modules:WaitForChild("UI")
	local CommonFunctions = require(Modules:WaitForChild("Tool"):WaitForChild("CommonToolFunctions"))
	local KeybindHandler = require(UIModules:WaitForChild("KeybindHandler"))

	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.fromRGB(255, 255, 255)
	Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	Highlight.FillTransparency = 1
	Highlight.OutlineTransparency = 1
	Highlight.Adornee = nil
	local Highlights: {Highlight} = {}

	local Attachment = Instance.new("Attachment")
	local Aligner = Instance.new("AlignPosition")
	Aligner.Mode = Enum.PositionAlignmentMode.OneAttachment
	Aligner.Attachment0 = Attachment
	Aligner.Responsiveness = module.RESPONSIVENESS

	local LocalPlayer = Players.LocalPlayer
	local Mouse = LocalPlayer:GetMouse()
	local Camera = workspace.CurrentCamera

	local Character = LocalPlayer.Character
	while Character == nil or Character.Parent == nil do
		Character = LocalPlayer.Character
		task.wait(.2)
	end
	local Humanoid = Character:WaitForChild("Humanoid")

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	rayParams.FilterDescendantsInstances = {Character, Camera}

	local Holding = false
	local Current: BasePart = nil
	local Distance = 0

	RunService.RenderStepped:Connect(function(dt)
		if Character and Humanoid and Humanoid.Health > 0 and not Humanoid:GetAttribute("Downed") then
			if not Holding then
				local RayHit = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * module.RANGE, rayParams)
				if RayHit and RayHit.Instance:HasTag("Draggable") and not RayHit.Instance:HasTag("Dragging") then
					Distance = RayHit.Distance
					Current = RayHit.Instance
					Aligner.Parent = Current
					Aligner.MaxForce = module.MAX_FORCE
					Aligner.MaxVelocity = module.TARGET_VELOCITY
					Attachment.Parent = Current
					Attachment.WorldCFrame = CFrame.new(RayHit.Position)

					local h = nil
					for _, v in Highlights do
						if v.Adornee == Current then
							h = v
							break
						end
					end
					if not h then
						h = Highlight:Clone()
						h.Adornee = RayHit.Instance
						h.Parent = script
						table.insert(Highlights, h)
					end
				else
					Current = nil
				end
			end
		elseif Holding then
			if Current and Current.Parent then
				DragEvent:FireServer(false, Current)
				Current = nil
			end
			Holding = false
		end

		local i, h = 0, nil
		while true do
			i += 1
			h = Highlights[i]
			if h == nil then break end


			if h.Adornee == Current then	
				h.OutlineTransparency = math.max(0, h.OutlineTransparency - module.HIGHLIGHT_SPEED * dt) -- /4 Since FillTransparency is 0.8 and OutlineTransparency is 0.2
				h.FillTransparency = math.max(0.7, h.FillTransparency - module.HIGHLIGHT_SPEED / 3 * dt)
			else
				h.OutlineTransparency = math.min(1, h.OutlineTransparency + module.HIGHLIGHT_SPEED * dt)
				h.FillTransparency = math.min(1, h.FillTransparency + module.HIGHLIGHT_SPEED / 3 * dt)
				if h.OutlineTransparency == 1 then
					h:Destroy()
					table.remove(Highlights, i)
					i -= 1
				end
			end
		end
	end)
	
	RunService.Heartbeat:Connect(function(dt)
		if Holding == true then
			Aligner.Parent = Current
			Attachment.Parent = Current
			Aligner.Position = Camera.CFrame.Position + Camera.CFrame.LookVector * Distance
			if Current:HasTag("Lever") and Current:FindFirstChild("LeverHinge") then
				-- project the target position onto the hinge's plane of rotation
				local Hinge = Current.LeverHinge
				local p0 = Hinge.Attachment0.WorldPosition
				local n = Hinge.Attachment0.WorldAxis
				local p1 = Aligner.Position - p0
				p1 = p1 - p1:Dot(n) * n
				Aligner.Position = p0 + p1
			else
				Current.AssemblyAngularVelocity = Vector3.zero
			end
			Aligner.Enabled = true
		else
			Aligner.Enabled = false
			Aligner.Parent = nil
			Attachment.Parent = nil
		end
	end)

	local beginningInput = nil
	UserInputService.InputBegan:Connect(function(Input, gameProcessed)
		if gameProcessed or Holding then return end
		if Input.KeyCode == KeybindHandler.Keybind("Interact",LocalPlayer) or (Input.UserInputType == Enum.UserInputType.MouseButton1 and (not Character:FindFirstChildOfClass("Tool") or (Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool"):GetAttribute("CanInteractWithTool")))) then
			if Current then
				beginningInput = Input
				Holding = true
				DragEvent:FireServer(true, Current)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(Input, gameProcessed)
		if gameProcessed then return end
		if Holding and Input == beginningInput then
			Holding = false
			if Current:HasTag("Lever") then
				Current.Anchored = true
			end
			DragEvent:FireServer(false, Current)
			Current = nil
		end
	end)
end

return module