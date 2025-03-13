local module = {}

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Service Objects
local Events = ReplicatedStorage:WaitForChild("Events")
local Tooling = ReplicatedStorage:WaitForChild("Tooling")
local Tools = Tooling:WaitForChild("Tools")

--// Event Folders
local ViewmodelEvents = Events:WaitForChild("Viewmodel")
local ToolEvents = Events:WaitForChild("Tool")

--//Events
local ResetIcons = ViewmodelEvents:WaitForChild("ResetIcons")
local SetItemHolder = ToolEvents:WaitForChild("SetItemHolder")
local Itemize = ToolEvents:WaitForChild("Itemize")

local DropParams = RaycastParams.new()
DropParams.FilterType = Enum.RaycastFilterType.Exclude

function module.dropItem (Character,Tool)
	DropParams.FilterDescendantsInstances = {Character}
	local HRP = Character:WaitForChild("HumanoidRootPart")
	local Humanoid = Character:WaitForChild("Humanoid")
	if Humanoid:GetAttribute("inAir") or Humanoid:GetAttribute("DisableEquip") then return end
	if Tool:GetAttribute("ToolName") and Tools:FindFirstChild(Tool:GetAttribute("ToolName")) then
		local ToolObjects = Tools[Tool:GetAttribute("ToolName")]
		require(script.Parent).playSound(ToolObjects.Sounds,"Drop",HRP,true,true) --/ the game explodes if i try to define CTF in the variables section
	end
	if Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool") == Tool then
		Humanoid:UnequipTools()
	end
	ResetIcons:Fire(Tool)

	if Tool:GetAttribute("ToolType") == 12 then
		SetItemHolder:FireServer(Tool,"Capacity",Tool.Holder.Capacity.Value)
	end

	local Origin = HRP.Position
	local HRPCFrame = HRP.CFrame
	local CastFailed = true
	local HorizontalRange = 3
	local VerticalRange = 5
	local raycast = workspace:Raycast(Origin,HRPCFrame.LookVector*HorizontalRange,DropParams)
	if raycast then
		local raycast2nd = workspace:Raycast(Vector3.new(raycast.Position.X+(Tool.Hitbox.Size.X/2)*raycast.Normal.X,raycast.Position.Y,raycast.Position.Z+(Tool.Hitbox.Size.Z/2)*raycast.Normal.Z),-HRPCFrame.UpVector*VerticalRange,DropParams)
		if raycast2nd then
			CastFailed = false
			Itemize:FireServer(Tool,Vector3.new(raycast2nd.Position.X,raycast2nd.Position.Y+(Tool.Hitbox.Size.Y/2),raycast2nd.Position.Z),HRP.Orientation.Y)
		end
	else
		local raycast2nd = workspace:Raycast((HRPCFrame+HRPCFrame.LookVector*HorizontalRange).Position,-HRPCFrame.UpVector*VerticalRange,DropParams)
		if raycast2nd then
			CastFailed = false
			Itemize:FireServer(Tool,Vector3.new(raycast2nd.Position.X,raycast2nd.Position.Y+(Tool.Hitbox.Size.Y/2),raycast2nd.Position.Z),HRP.Orientation.Y)
		end
	end
	if CastFailed then
		local raycast = workspace:Raycast(Origin,-HRPCFrame.UpVector*VerticalRange,DropParams)
		if raycast then
			Itemize:FireServer(Tool,Vector3.new(raycast.Position.X,raycast.Position.Y+(Tool.Hitbox.Size.Y/2),raycast.Position.Z),HRP.Orientation.Y)
		else
			Itemize:FireServer(Tool,Origin,HRP.Orientation.Y)
		end
	end
end

return module
