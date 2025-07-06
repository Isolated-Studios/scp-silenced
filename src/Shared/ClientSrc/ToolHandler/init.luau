local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolClass = require(ReplicatedStorage.Modules.Tool)

local module = {}

local Tools = ReplicatedStorage.Tooling.Tools

local Character: Model? = nil
local Backpack: Backpack? = nil

local LoadedTools: {[Tool]: ToolClass.ClassType} = {}
local CurrentTool: ToolClass.ClassType? = nil

local function loadTool(Tool: Instance): ToolClass.ClassType?
	if not ToolClass.isReady() then return end
	if Tool == nil or not Tool:IsA("Tool") then return end
	if LoadedTools[Tool] == nil then
		local ToolObjects = Tools:FindFirstChild(Tool:GetAttribute("ToolName") or "undefined tool name") or error(`Failed to find ToolObjects for {Tool:GetFullName()}`)
		local Settings = require(ToolObjects.Settings)
		Settings.Animations = {}
		for _, v in ToolObjects.VMAnimations:GetChildren() do
			Settings.Animations[v.Name] = v
		end
		LoadedTools[Tool] = ToolClass.new(Tool, Settings)
	end
	LoadedTools[Tool]:Init()
	return LoadedTools[Tool]
end

function module.LoadChar(Char)
	Character = Char
	Backpack = Players.LocalPlayer:WaitForChild("Backpack")
	
	while not ToolClass.isReady() do
		task.wait()
	end
	
	Backpack.ChildAdded:Connect(loadTool)
	Character.ChildAdded:Connect(loadTool)
	for _, tool in Backpack:GetChildren() do
		loadTool(tool)
	end
	for _, tool in Character:GetChildren() do
		loadTool(tool)
	end
end

function module.UnloadChar(_char)
	Character = nil
	-- clean loaded tools to avoid memory leaks
	for _, v in LoadedTools do
		v:Destroy()
	end
	LoadedTools = {}
end

function module.getTool(Tool: Tool): ToolClass.ClassType?
	return loadTool(Tool)
end

function module.getCurrentTool(): ToolClass.ClassType?
	return CurrentTool
end

function module.getCurrentToolState(): number
	if CurrentTool then
		return CurrentTool.State
	else
		return ToolClass.State.Unequipped
	end
end

function module.EquipTool(Tool: Tool)
	local toolObject = loadTool(Tool)
	if toolObject then
		CurrentTool = toolObject
		CurrentTool:Equip()
	end
end

function module.UnequipTools()
	if CurrentTool then
		CurrentTool:Unequip()
		CurrentTool = nil
	end
end

--[=[
	Same as UnequipTools() except it will only do so
	if the tool provided is the currently equipped tool.
]=]
function module.UnequipTool(Tool: Tool)
	if LoadedTools[Tool] == CurrentTool then
		module.UnequipTools()
	end
end

function module.DropTool(Tool: Tool)
	if LoadedTools[Tool] == CurrentTool then
		module.UnequipTool(Tool)
	end
end

return module
