local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local module = {}

local Modules = ReplicatedStorage.Modules
local Tools = ReplicatedStorage.Tooling.Tools

local Trove = require(ReplicatedStorage.Packages.Trove)
local KeybindHandler = require(Modules.UI.KeybindHandler)
local ToolHandler = require(script.Parent.ToolHandler)
local CommonFuncs = require(Modules.CommonFuncs)
local ToolClass = require(Modules.Tool)

local Player = game.Players.LocalPlayer

local HUD: ScreenGui
local ListFrame: Frame
local Hotbar: Frame
local ConsumablesFrame: Frame

local Humanoid: Humanoid = nil
local Debounce = false
local NextTool

local AcceptedKeys = {
	["One"]   =	1,
	["Two"]   = 2,
	["Three"] = 3,
	["Four"]  = 4,
	["Five"]  = 5,
}

module.InventoryToolTypeSlotIndex = {} -- is to be loaded by Inventory, used for checking equipped tools.
local Inventory = {}
local NextToolSlot = nil

local function RefreshHotbar ()
	for _, Cell in pairs(Hotbar:GetChildren()) do
		if Cell:IsA("Frame") then
			local index = tonumber(Cell.Name)
			if Inventory[index] and Inventory[index].Metadata then
				if not Cell.Icon:GetAttribute("DisplayImage") then
					TweenService:Create(Cell.Icon, TweenInfo.new(0.1), {ImageTransparency = 0}):Play()
					TweenService:Create(Cell.Icon.Inner, TweenInfo.new(0.1), {ImageTransparency = 0}):Play()
					Cell.Icon:SetAttribute("DisplayImage", true)
				end
				Cell.Icon.Image = Inventory[index].Metadata.Image
				Cell.Icon.Inner.Image = Inventory[index].Metadata.Image
			else
				if Cell.Icon:GetAttribute("DisplayImage") == true then
					TweenService:Create(Cell.Icon, TweenInfo.new(0.1), {ImageTransparency = 1}):Play()
					TweenService:Create(Cell.Icon.Inner, TweenInfo.new(0.1), {ImageTransparency = 1}):Play()
					Cell.Icon:SetAttribute("DisplayImage", false)
				end
			end
			Cell.UIStroke.Thickness = 1.5
			Cell.UIStroke.Color = Color3.fromRGB(150, 150, 150)
		end
	end
end

local function resetCell(Tool, resetImage, unequipSpeed)
	if Tool:GetAttribute("ToolType") == 4 or Tool:GetAttribute("ToolType") == 6 then
		local cell = ConsumablesFrame[tostring(Tool:GetAttribute("ToolType"))]
		if unequipSpeed then
			TweenService:Create(cell:WaitForChild("UIStroke"),TweenInfo.new(unequipSpeed,Enum.EasingStyle.Linear),{Thickness = 1.5,Color = Color3.fromRGB(150,150,150)}):Play()
		else
			cell.UIStroke.Thickness = 1.5
			cell.UIStroke.Color = Color3.fromRGB(150,150,150)
		end
	elseif Tool:GetAttribute("ToolType") <= 3 then
		local cell = Hotbar[tostring(Tool:GetAttribute("ToolType"))]
		if resetImage and Inventory[Tool:GetAttribute("ToolType")] then
			local nextTool = Inventory[Tool:GetAttribute("ToolType")].Metadata.Tool
			cell.Icon.Image = nextTool.TextureId
			cell.Icon.Inner.Image = nextTool.TextureId
		elseif resetImage then
			cell.Icon.Image = ""
			cell.Icon.Inner.Image = ""
		end
		if unequipSpeed then
			TweenService:Create(cell:WaitForChild("UIStroke"),TweenInfo.new(unequipSpeed,Enum.EasingStyle.Linear),{Thickness = 1.5,Color = Color3.fromRGB(150,150,150)}):Play()
		else
			cell.UIStroke.Thickness = 1.5
			cell.UIStroke.Color = Color3.fromRGB(150,150,150)
		end
	end
end

local function setCell(Tool)
	if Tool:GetAttribute("ToolType") == 4 or Tool:GetAttribute("ToolType") == 6 then
		local cell = ConsumablesFrame[tostring(Tool:GetAttribute("ToolType"))]
		local tweenTime = require(Tools[Tool:GetAttribute("ToolName")].Settings).EquipSpeed
		TweenService:Create(cell:WaitForChild("UIStroke"),TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Thickness = 2,Color = Color3.fromRGB(255,255,255)}):Play()
	elseif Tool:GetAttribute("ToolType") <= 3 then
		local cell = Hotbar[tostring(Tool:GetAttribute("ToolType"))]
		local tweenTime = require(Tools[Tool:GetAttribute("ToolName")].Settings).EquipSpeed
		TweenService:Create(cell:WaitForChild("UIStroke"),TweenInfo.new(tweenTime,Enum.EasingStyle.Linear),{Thickness = 2,Color = Color3.fromRGB(255,255,255)}):Play()
		cell:WaitForChild("Icon").Image = Tool.TextureId
		cell:WaitForChild("Icon"):WaitForChild("Inner").Image = Tool.TextureId
	end
end

local function unequipTools()
	local tool = ToolHandler:getCurrentTool()
	if tool then
		local unequipSpeed = require(Tools[tool.Instance:GetAttribute("ToolName")].Settings).UnequipSpeed
		resetCell(tool.Instance, nil, unequipSpeed)
	else
		-- !! NOTE: ADD resetCell(nil, nil, 0.5) <- 0.3 is an arbitrary number
	end
	ToolHandler.UnequipTools()
end

local function equipTool()
	if Debounce then return end
	if ToolHandler.getCurrentToolState() == ToolClass.State.Equipped then
		unequipTools()
		if NextTool then
			-- dumb debounce because otherwise the tool might disappear into the void if directly equipped after the other unequip
			Debounce = true
			task.wait()
			Debounce = false
			equipTool()
		end
	elseif ToolHandler.getCurrentToolState() == ToolClass.State.Unequipped and NextTool then
		RefreshHotbar()
		setCell(NextTool)
		ToolHandler.EquipTool(NextTool)
	end
end

local function handleInput(Input, gameProcessedEvent)
	if gameProcessedEvent then return end
	if AcceptedKeys[Input.KeyCode.Name]
		and Inventory[AcceptedKeys[Input.KeyCode.Name]]
		and not CommonFuncs.AreInputUIsActive()
	then
		local PickedTool = Inventory[AcceptedKeys[Input.KeyCode.Name]].Metadata.Tool
		NextTool = if ToolHandler.getTool(PickedTool) == ToolHandler.getCurrentTool() then nil else PickedTool
		NextToolSlot = if NextTool ~= nil then AcceptedKeys[Input.KeyCode.Name] else nil
		equipTool()
	end
end

function module.Init()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	-- wait for UI to load
	HUD = Player.PlayerGui:WaitForChild("HUD")
	ListFrame = HUD:WaitForChild("RightFrame"):WaitForChild("ListFrame")
	Hotbar = ListFrame:WaitForChild("Hotbar")
	ConsumablesFrame = ListFrame:WaitForChild("InfoFrame"):WaitForChild("Consumables"):WaitForChild("Frame")

	RunService.RenderStepped:Connect(function()
		for i, v in module.InventoryToolTypeSlotIndex do
			Inventory[i] = v.Item
		end
		RefreshHotbar()
		
		if NextToolSlot and (Inventory[NextToolSlot] == nil or Inventory[NextToolSlot].Metadata.Tool ~= NextTool) then
			NextToolSlot = nil
			NextTool = nil
			equipTool()
		end
	end)

	AcceptedKeys[KeybindHandler.Keybind("Grenade", Player).Name] = 6
	UserInputService.InputBegan:Connect(handleInput)
end

function module.LoadChar(Character: Model)
	local characterTrove = Trove.new()
	characterTrove:AttachToInstance(Character)

	Character.ChildAdded:Connect(function(Tool)
		if Tool:IsA("Tool") and Tool:GetAttribute("ToolType") and NextTool ~= Tool then
			NextTool = Tool
			equipTool()
		end
	end)

	RefreshHotbar()
	Humanoid = Character:WaitForChild("Humanoid")

	Humanoid.Died:Once(function()
		ToolHandler.UnequipTools()
		RefreshHotbar()
		Humanoid = nil
	end)
end

return module
