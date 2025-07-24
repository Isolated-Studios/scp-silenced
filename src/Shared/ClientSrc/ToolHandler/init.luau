local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolModule = ReplicatedStorage.Modules.Tool
local ToolClass = require(ToolModule)
local GunClass = require(ToolModule.Gun)
local MeleeeClass = require(ToolModule.Melee)
local LemonSignal = require(ReplicatedStorage.Packages.lemonsignal)
-- local GrenadeClass = require(ToolModule.Grenade)

local TOOL_SRC_TO_CLASS = {
	Gun = GunClass;
	Melee = MeleeeClass;
}

local module = {
	ToolStateChanged = LemonSignal.new();
	ToolEquipping = LemonSignal.new();
	ToolUnequipping = LemonSignal.new();
}

local Character: Model? = nil
local Backpack: Backpack? = nil

local LoadedTools: {[Tool]: ToolClass.ClassType} = {}
local CurrentTool: ToolClass.ClassType? = nil

local function loadTool(Tool: Instance): ToolClass.ClassType?
	if not ToolClass.isReady() then return end
	if Tool == nil or not Tool:IsA("Tool") then return end
	if LoadedTools[Tool] == nil then
		LoadedTools[Tool] = (TOOL_SRC_TO_CLASS[Tool:GetAttribute("ToolSource")] or ToolClass).new(Tool)
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
		module.ToolEquipping:Fire(CurrentTool, CurrentTool.Settings.EquipCancel)
		module.ToolStateChanged:Fire(CurrentTool, ToolClass.State.Equipping)
		CurrentTool:Equip()
		module.ToolStateChanged:Fire(CurrentTool, ToolClass.State.Equipped)
	end
end

function module.UnequipTools()
	if CurrentTool then
		module.ToolUnequipping:Fire(CurrentTool, CurrentTool.Settings.UnequipSpeed)
		module.ToolStateChanged:Fire(CurrentTool, ToolClass.State.Unequipping)
		CurrentTool:Unequip()
		module.ToolStateChanged:Fire(CurrentTool, ToolClass.State.Unequipped)
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
