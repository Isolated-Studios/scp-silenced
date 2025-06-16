local module = {}
local RunService = game:GetService("RunService")

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Tools = ReplicatedStorage.Tooling.Tools
local Events = ReplicatedStorage.Events

local Trove = require(ReplicatedStorage.Packages.Trove)
local KeybindHandler = require(Modules.UI.KeybindHandler)
local ToolHandler = require(script.Parent.ToolHandler)

local ViewmodelEvents = Events.Viewmodel
local ResetIcons = ViewmodelEvents.ResetIcons

local Player = game.Players.LocalPlayer
local initialized = false
local charAddLoaded = false
local characterTrove = Trove.new()

local Mouse = Player:GetMouse()
local Humanoid = nil
local RootPart = nil
local firstTool = nil
local Unequipping = false
local Acting = false

local AcceptedKeys = {
	["One"]   =	1,
	["Two"]   = 2,
	["Three"] = 3,
	["Four"]  = 4,
	["Five"]  = 5,
}

module.InventoryToolTypeSlotIndex = {} -- is to be loaded by Inventory, used for checking equipped tools.

function module.Init()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	AcceptedKeys[KeybindHandler.Keybind("Grenade", Player).Name] = 6
	initialized = true
end

function module.LoadChar(Character)
	charAddLoaded = true
	local HUD = Player.PlayerGui:WaitForChild("HUD")
	local ListFrame = HUD:WaitForChild("RightFrame"):WaitForChild("ListFrame")
	local Hotbar = ListFrame:WaitForChild("Hotbar")
	local ConsumablesFrame = ListFrame:WaitForChild("GunFrame"):WaitForChild("Consumables"):WaitForChild("Frame")
	local Inventory = {}
	local function RefreshHotbar ()
		for _,cell in pairs(Hotbar:GetChildren()) do
			if cell:IsA("Frame") then
				local index = tonumber(cell.Name)
				if Inventory[index] then
					local actualTool = Inventory[index]
					if actualTool then
						cell.Icon.Image = actualTool.TextureId
						cell.Icon.Inner.Image = actualTool.TextureId
					end
				end
				cell.UIStroke.Thickness = 1.5
				cell.UIStroke.Color = Color3.fromRGB(150,150,150)
			end
		end
	end
	local function resetCell (Tool,resetImage,unequipSpeed)
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
			if resetImage and  Inventory[Tool:GetAttribute("ToolType")] then
				local nextTool = Inventory[Tool:GetAttribute("ToolType")]
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

	local function setCell (Tool)
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

	local function unequipTool (Tool)
		if Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool") == Tool and Tool:GetAttribute("Activated") then
			Unequipping = true
			local unequipSpeed = require(Tools[Tool:GetAttribute("ToolName")].Settings).UnequipSpeed
			resetCell(Character:FindFirstChildOfClass("Tool"),nil,unequipSpeed)
			ToolHandler.UnequipTool(Tool)
			Unequipping = false
		end
	end

	local function actOnTool(Tool)
		local activatedTool = false
		for _,tool in pairs(Player.Backpack:GetChildren()) do
			if tool:GetAttribute("Activated") then
				activatedTool = true
				return
			end
		end

		if activatedTool or Unequipping or Tool:GetAttribute("Removing") or UserInputService:IsKeyDown(KeybindHandler.Keybind("Drop",Player)) or Humanoid:GetAttribute("DisableEquip") or Humanoid:GetAttribute("Downed") or Acting then return end
		if Character:FindFirstChildOfClass("Tool") and Tool:GetAttribute("ToolType") == Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolType") then
			unequipTool(Tool)
		else
			Acting = true
			ToolHandler.UnequipTools()
			task.wait() --/ I put this here because the function Clean()
			if not Inventory[Tool:GetAttribute("ToolType")] then Acting = false warn("could not table.find tooltype in inventory") return end
			--/ this line above fixes a bug where equipping after dying breaks the script
			RefreshHotbar()
			setCell(Tool)
			pcall(ToolHandler.EquipTool, Tool)
			Acting = false
		end
	end

	RunService.Stepped:Connect(function(time, deltaTime)
		if module.InventoryToolTypeSlotIndex then
			for i = 1, 3 do
				Inventory[i] = module.InventoryToolTypeSlotIndex[i].Item and module.InventoryToolTypeSlotIndex[i].Item.Metadata.Tool
			end
		end
		RefreshHotbar()
		local Tool = Character:FindFirstChildOfClass("Tool")
		if Tool and Tool:GetAttribute("ToolType") and Inventory[Tool:GetAttribute("ToolType")] ~= Tool then
			actOnTool(Tool)
		end
	end)

	RefreshHotbar()
	Humanoid = Character:WaitForChild("Humanoid")
	RootPart = Character.PrimaryPart

	characterTrove:Connect(UserInputService.InputBegan, function(Input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if AcceptedKeys[Input.KeyCode.Name] and Inventory[AcceptedKeys[Input.KeyCode.Name]] and not Humanoid:GetAttribute("Equipping") then
			local pickedTool = Inventory[AcceptedKeys[Input.KeyCode.Name]]
			actOnTool(pickedTool)
		end
	end)

	Humanoid.Died:Once(function()
		ToolHandler.UnequipTools()
		Inventory = {}
		RefreshHotbar()
		characterTrove:Clean()
	end)
end

return module
