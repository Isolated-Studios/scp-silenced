local module = {}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Tools = ReplicatedStorage.Tooling.Tools
local Events = ReplicatedStorage.Events

local Trove = require(ReplicatedStorage.Packages.Trove)
local KeybindHandler = require(Modules.UI.KeybindHandler)

local ViewmodelEvents = Events.Viewmodel
local ResetIcons = ViewmodelEvents.ResetIcons
local UnequipTool = ViewmodelEvents.UnequipTool

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
	local Inventory = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		[6] = {},
	}
	local scrollSave = {
		[1] = 1,
		[2] = 1,
		[3] = 1,
		[4] = 1,
		[5] = 1,
		[6] = 1,
	}
	local function resetHotbar ()
		for _,cell in pairs(Hotbar:GetChildren()) do
			if cell:IsA("Frame") then
				local index = tonumber(cell.Name)
				local toolIndex = scrollSave[index]
				if Inventory[index] then
					local actualTool = Inventory[index][toolIndex]
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
			if resetImage and  Inventory[Tool:GetAttribute("ToolType")][scrollSave[Tool:GetAttribute("ToolType")]] then
				local nextTool = Inventory[Tool:GetAttribute("ToolType")][scrollSave[Tool:GetAttribute("ToolType")]]
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
	local function checkScrollCells (toolType)
		if Inventory[toolType] and #Inventory[toolType] > 0 and toolType <= 3 then
			local scrollFrame = Hotbar[tostring(toolType)].Scroll
			for _,othercell in pairs(scrollFrame:GetChildren()) do
				if othercell:IsA("Frame") then
					othercell.BackgroundColor3 = Color3.fromRGB(150,150,150)
				end
			end
			scrollFrame[tostring(scrollSave[toolType])].BackgroundColor3 = Color3.fromRGB(255,255,255)
		end
	end
	local function resetScrollCell (Tool)
		local index = Tool:GetAttribute("ToolType")
		if index > 3 then return end
		for _,deadCell in pairs(Hotbar[tostring(index)].Scroll:GetChildren()) do
			if deadCell:IsA("Frame") then
				deadCell:Destroy()
			end
		end
		local value = #Inventory[index]
		if value > 0 then
			local HotbarCell = Hotbar[tostring(index)]
			local PrimeCell = HotbarCell.Cell
			for i=1,value do
				local Cell = PrimeCell:Clone()
				Cell.Name = tostring(i)
				HotbarCell.Scroll.UIGridLayout.CellSize = UDim2.new(1/value,-1,1,0)
				Cell.Parent = HotbarCell.Scroll
			end
		else
			for _,deadCell in pairs(Hotbar[tostring(index)].Scroll:GetChildren()) do
				if deadCell:IsA("Frame") then
					deadCell:Destroy()
				end
			end
		end
		checkScrollCells(index)
	end

	local function resetScrollCells (destroyTool)
		if destroyTool then
			if destroyTool:GetAttribute("ToolType") > 3 then return end

			for _,deadCell in pairs(Hotbar[tostring(destroyTool:GetAttribute("ToolType"))].Scroll:GetChildren()) do
				if deadCell:IsA("Frame") then
					deadCell:Destroy()
				end
			end
		end
		for index,_ in pairs(Inventory) do
			local value = #Inventory[index]
			if index > 3 then return end
			if value > 0 then
				local HotbarCell = Hotbar[tostring(index)]
				local PrimeCell = HotbarCell.Cell
				for i=1,value do
					local Cell = PrimeCell:Clone()
					Cell.Name = tostring(i)
					HotbarCell.Scroll.UIGridLayout.CellSize = UDim2.new(1/value,-1,1,0)
					Cell.Parent = HotbarCell.Scroll
				end
			else
				for _,deadCell in pairs(Hotbar[tostring(index)].Scroll:GetChildren()) do
					if deadCell:IsA("Frame") then
						deadCell:Destroy()
					end
				end
			end
			checkScrollCells(index)
		end
	end
	local function addScrollCell (Tool)
		local index = Tool:GetAttribute("ToolType")
		if index > 3 then return end
		local HotbarCell = Hotbar[tostring(index)]
		local PrimeCell = HotbarCell.Cell
		local scrollIndex = 1
		if index > 3 then return end
		if Inventory[index] then
			scrollIndex = #Inventory[index]
		end
		local Cell = PrimeCell:Clone()
		Cell.Name = tostring(scrollIndex)
		HotbarCell.Scroll.UIGridLayout.CellSize = UDim2.new(1/scrollIndex,-1,1,0)
		Cell.Parent = HotbarCell.Scroll
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
			if unequipSpeed then
				Tool:SetAttribute("Unequipping",true)
				UnequipTool:Fire(Tool)
				Unequipping = true
				task.wait(unequipSpeed)
				Humanoid:UnequipTools()
				Unequipping = false
			else
				Humanoid:UnequipTools()
			end
			Unequipping = false
		end
	end
	local function addTool (Tool)
		if Inventory[Tool:GetAttribute("ToolType")] then
			table.insert(Inventory[Tool:GetAttribute("ToolType")],Tool)
		end
	end
	local function removeTool (Tool)
		if Inventory[Tool:GetAttribute("ToolType")] and table.find(Inventory[Tool:GetAttribute("ToolType")],Tool) then
			if scrollSave[Tool:GetAttribute("ToolType")] > 1 then
				scrollSave[Tool:GetAttribute("ToolType")] += -1
			end
			table.remove(Inventory[Tool:GetAttribute("ToolType")],table.find(Inventory[Tool:GetAttribute("ToolType")],Tool))
			resetCell(Tool,true)
			resetScrollCell(Tool)
		end
	end
	local function actOnTool (Tool,scroll)
		local activatedTool = false
		for _,tool in pairs(Player.Backpack:GetChildren()) do
			if tool:GetAttribute("Activated") then
				activatedTool = true
				return
			end
		end

		if activatedTool or Unequipping or Tool:GetAttribute("Removing") or UserInputService:IsKeyDown(KeybindHandler.Keybind("Drop",Player)) or Humanoid:GetAttribute("DisableEquip") or Humanoid:GetAttribute("Downed") or Acting then return end
		task.defer(function()
			if Character:FindFirstChildOfClass("Tool") and Tool:GetAttribute("ToolType") == Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolType") and not scroll then
				unequipTool(Tool)
			else

				unequipTool(Tool)
				--Humanoid:UnequipTools()
				Acting = true
				scrollSave[Tool:GetAttribute("ToolType")] = table.find(Inventory[Tool:GetAttribute("ToolType")],Tool)
				resetHotbar()
				setCell(Tool)
				Humanoid:EquipTool(Tool)
				checkScrollCells(Tool:GetAttribute("ToolType"))
				local Settings = require(Tools[Tool:GetAttribute("ToolName")].Settings)
				if Settings.EquipSpeed then
					task.wait(Settings.EquipSpeed)
				end
				Acting = false
			end
		end)
	end
	local function scrollTool (direction)
		if not Unequipping and Character:FindFirstChildOfClass("Tool") and Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolType") and Inventory[Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolType")] and table.find(Inventory[Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolType")],Character:FindFirstChildOfClass("Tool")) and #Inventory[Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolType")] > 1 and not Humanoid:GetAttribute("Aiming") then
			local Tool = Character:FindFirstChildOfClass("Tool")
			local ToolTable = Inventory[Character:FindFirstChildOfClass("Tool"):GetAttribute("ToolType")]
			local index = table.find(ToolTable,Tool)
			local targetIndex = index+direction
			if targetIndex > #ToolTable then
				targetIndex = 1
			elseif targetIndex < 1 then
				targetIndex = #ToolTable
			end
			if ToolTable[targetIndex] then
				actOnTool(ToolTable[targetIndex],true)
			end
		end
	end
	local Backpack = Player.Backpack
	for _,Tool in pairs(Backpack:GetChildren()) do
		addTool(Tool)
	end
	characterTrove:Connect(Backpack.ChildAdded, function(Tool)
		if Tool:GetAttribute("NewTool") then
			Tool:SetAttribute("NewTool",nil)
			addTool(Tool)
			addScrollCell(Tool)
			resetHotbar()
			checkScrollCells(Tool:GetAttribute("ToolType"))
		end
	end)
	characterTrove:Connect(Backpack.ChildRemoved, function(Tool)
		if Tool:IsA("Tool") and Tool:GetAttribute("Removing") then
			removeTool(Tool)
			resetScrollCell(Tool)
		end
	end)
	characterTrove:Connect(Character.ChildRemoved, function(Tool)
		if Tool:IsA("Tool") then
			resetCell(Tool, nil, 0)
		end
	end)
	resetHotbar()
	resetScrollCells()
	Humanoid = Character:WaitForChild("Humanoid")
	RootPart = Character.PrimaryPart

	characterTrove:Connect(UserInputService.InputBegan, function(Input, gpe)
		if gpe then return end
		if AcceptedKeys[Input.KeyCode.Name] and Inventory[AcceptedKeys[Input.KeyCode.Name]] and Inventory[AcceptedKeys[Input.KeyCode.Name]][1] then
			local pickedTool = Inventory[AcceptedKeys[Input.KeyCode.Name]][1]
			if scrollSave[AcceptedKeys[Input.KeyCode.Name]] then
				pickedTool = Inventory[AcceptedKeys[Input.KeyCode.Name]][scrollSave[AcceptedKeys[Input.KeyCode.Name]]]
			end
			actOnTool(pickedTool)
		end
	end)

	characterTrove:Connect(Mouse.WheelForward, function()
		scrollTool(1)
	end)

	characterTrove:Connect(Mouse.WheelBackward, function()
		scrollTool(-1)
	end)

	Humanoid.Died:Once(function()
		Humanoid:UnequipTools()
		Inventory = {}
		resetHotbar()
		characterTrove:Clean()
	end)
end

return module
