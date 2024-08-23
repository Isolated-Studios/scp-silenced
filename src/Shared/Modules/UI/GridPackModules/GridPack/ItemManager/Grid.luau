--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local CTF = require(Modules:WaitForChild("Tool"):WaitForChild("CommonToolFunctions"))
local ToolingTools = ReplicatedStorage:WaitForChild("Tooling"):WaitForChild("Tools")

--// Packages
local Signal = require(script.Parent.Parent.Parent.signal)

--// Classes
local ItemManager = require(script.Parent)

--// Types
local Types = require(script.Parent.Parent.Types)

--// Grid Class
local Grid = setmetatable({}, ItemManager)
Grid.__index = Grid

--[=[
	@class Grid
]=]
--[=[
	@prop GuiElement GuiObject
	@readonly
	@within Grid
]=]
--[=[
	@prop SlotElements { GuiObject }
	@readonly
	@within Grid
]=]
--[=[
	@prop GridSize Vector2
	@readonly
	@within Grid
]=]
--[=[
	@prop SlotAspectRatio number
	@readonly
	@within Grid
]=]
--[=[
	@prop Items { ItemObject }
	@readonly
	@within Grid
]=]
--[=[
	@prop ItemAdded RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time a new Item is added to the Grid.

	@within Grid
]=]
--[=[
	@prop ItemRemoved RBXScriptSignal
	@readonly
	@tag Signal
	An event signal that fires every time an Item is removed from the Grid.

	@within Grid
]=]

--[=[
	Create a new Grid ItemManager object.

	@within Grid
]=]
function Grid.new(properties: Types.GridProperties): Types.GridObject
	local self = setmetatable(ItemManager.new(properties), Grid)
	self.GuiElement, self.SlotElements = self:_createGuiElement(properties)
	
	self.GridSize = properties.GridSize
	self.SlotAspectRatio = properties.SlotAspectRatio
	
	self.Items = {}
	self.ItemAdded = Signal.new()
	self.ItemRemoved = Signal.new()
	
	self:_updateGuiGrid()
	
	self._trove:Add(RunService.RenderStepped:Connect(function()
		local InventoryHover = game.Players.LocalPlayer.PlayerGui:WaitForChild("MouseUI").Dot.InventoryHover
		local HoveredTool = game.Players.LocalPlayer.PlayerGui:WaitForChild("Inventory").Main.HoveredTool
		InventoryHover.Label.Text = ""
		InventoryHover.SecondLabel.Text = ""
		local pickeditem = nil
		for _,item in pairs(game.Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(game.Players.LocalPlayer:GetMouse().X,game.Players.LocalPlayer:GetMouse().Y)) do
			if item.Parent == self.GuiElement.Parent and item.Name == "ItemTemplate" and self.GuiElement.Parent.Interactable then
				InventoryHover.Label.Text = item:GetAttribute("ToolName") or "item"
				local secondLabelText = ""
				pickeditem = item.Tool.Value
				if item.Tool.Value and item.Tool.Value:FindFirstChild("Holder") then
					local Settings = require(ToolingTools[item.Tool.Value:GetAttribute("ToolName")].Settings)
					if item.Tool.Value.Holder:FindFirstChild("Mag") then
						secondLabelText = "Mag: "..tostring(item.Tool.Value.Holder.Mag.Value).." / "..tostring(Settings.MagSize)
					elseif item.Tool.Value.Holder:FindFirstChild("Durability") then
						secondLabelText = "Durability: "..tostring(item.Tool.Value.Holder.Durability.Value).." / "..tostring(Settings.MaxDurability)
					elseif item.Tool.Value.Holder:FindFirstChild("Capacity") then
						secondLabelText = "Capacity: "..tostring(item.Tool.Value.Holder.Capacity.Value).." / "..tostring(Settings.MaxAmmo)
					end
				end
				InventoryHover.SecondLabel.Text = secondLabelText
			end
		end
		HoveredTool.Value = pickeditem
		
		local updateList = {}
		local highlightList = {}
		for priority, highlight in self.Highlights do
			for xPosition = highlight.Position.X + 1, highlight.Position.X + highlight.Size.X do
				for yPosition = highlight.Position.Y + 1, highlight.Position.Y + highlight.Size.Y do
					local slotElement = self.SlotElements[xPosition .. ", " .. yPosition]
					if not slotElement then continue end
					table.insert(updateList, slotElement)
					table.insert(highlightList, highlight)
					if slotElement:GetAttribute("AppliedHighlight") == priority then continue end
					slotElement:SetAttribute("AppliedHighlight", priority)
				end
			end
		end
		
		for i, slotElement in updateList do
			local color = highlightList[i].Color
			TweenService:Create(slotElement.Vignette, TweenInfo.new(0.1), {ImageColor3 = color}):Play()
			TweenService:Create(slotElement.Vignette.UIStroke, TweenInfo.new(0.1), {Color = color}):Play()
		end
		
		for _, slotElement in pairs(self.SlotElements) do
			if slotElement:GetAttribute("AppliedHighlight") and not table.find(updateList, slotElement) then
				slotElement:SetAttribute("AppliedHighlight", nil)
				TweenService:Create(slotElement.Vignette, TweenInfo.new(0.1), {ImageColor3 = Color3.fromRGB(64, 64, 64)}):Play()
				TweenService:Create(slotElement.Vignette.UIStroke, TweenInfo.new(0.1), {Color = Color3.fromRGB(64, 64, 64)}):Play()
			end
		end
	end))

	return self
end

--[=[
	@private
	Creates a new Grid GUI element.

	@within Grid
]=]
function Grid:_createGuiElement(properties: Types.GridProperties): (CanvasGroup, { CanvasGroup })
	local slots = {}

	local container = self._trove:Add(Instance.new("CanvasGroup"))
	container.Name = "GridContainer"

	container.BackgroundTransparency = 1

	container.AnchorPoint = properties.AnchorPoint
	container.Position = properties.Position
	container.Size = properties.Size

	local gridLayout = self._trove:Add(Instance.new("UIGridLayout"))
	gridLayout.CellPadding = UDim2.fromOffset(0, 0)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local currentCellNumber = 1
	for gridY = 1, properties.GridSize.Y do
		for gridX = 1, properties.GridSize.X do
			local newGridCell = self._trove:Add(self.Assets.Slot:Clone())
			newGridCell.Name = currentCellNumber
			newGridCell.LayoutOrder = currentCellNumber

			slots[gridX .. ", " .. gridY] = newGridCell

			newGridCell.Parent = container

			currentCellNumber += 1
		end
	end
	
	container.Visible = self.Visible

	gridLayout.Parent = container
	container.Parent = properties.Parent

	return container, slots
end

--[=[
	@private
	Updates all slot GUI elements in the grid.

	@within Grid
]=]
function Grid:_updateGuiGrid()
	self.GuiElement.UIGridLayout.CellSize = UDim2.fromScale(1 / self.GridSize.X, 1 / self.GridSize.Y)
	
	if self.SlotAspectRatio then
		local aspectRatioConstraint = self.GuiElement:FindFirstChildOfClass("UIAspectRatioConstraint")
		if aspectRatioConstraint then
			aspectRatioConstraint.AspectRatio = self.GridSize.X / self.GridSize.Y * self.SlotAspectRatio
		else
			local newAspectRatio = Instance.new("UIAspectRatioConstraint")
			newAspectRatio.AspectRatio = self.GridSize.X / self.GridSize.Y * self.SlotAspectRatio
			
			newAspectRatio.Parent = self.GuiElement
		end
	else
		local aspectRatioConstraint = self.GuiElement:FindFirstChildOfClass("UIAspectRatioConstraint")
		if aspectRatioConstraint then
			aspectRatioConstraint:Destroy()
		end
	end
end

--[=[
	Gets the AbsoluteSize of one slot.

	@tag ItemManager Override
	@within Grid
]=]
function Grid:GetSizeScale(): Vector2
	return self.GuiElement.UIGridLayout.AbsoluteCellSize
end

--[=[
	Gets the AbsoluteSize of an Item with the ItemManager's size scale.

	@tag ItemManager Override
	@within Grid
]=]
function Grid:GetAbsoluteSizeFromItemSize(itemSize: Vector2, itemRotation: number): Vector2
	local sizeScale = self:GetSizeScale()
	
	return Vector2.new(math.round(sizeScale.X), math.round(sizeScale.Y)) * itemSize
end

--[=[
	Gets the next position in a Grid where the item doesn't collide with anything.

	@within Grid
]=]
function Grid:GetNextFreePositionForItem(item: Types.ItemObject): Vector2?
	for gridY = 0, self.GridSize.Y - 1 do
		for gridX = 0, self.GridSize.X - 1 do
			local currentPosition = Vector2.new(gridX, gridY)
			local insideBounds = self:IsRegionInBounds(currentPosition, item.Size, item.Rotation)
			local collidingItems = self:GetItemsInRegion(currentPosition, item.Size, item.Rotation, { item })
			if #collidingItems == 0 and insideBounds then
				return currentPosition
			end
		end
	end
	
	return nil
end
--[=[
	Converts an AbsolutePosition to a ItemManager position.

	@tag ItemManager Override
	@within Grid
]=]
function Grid:GetItemManagerPositionFromAbsolutePosition(absolutePosition: Vector2, itemSize: Vector2, itemRotation: number, originalPosition: Vector2): Vector2
	local itemManagerOffset = self.GuiElement.AbsolutePosition
	local sizeScale = self:GetSizeScale()

	local rotationOffset = Vector2.zero
	if itemRotation % 2 == 1 then
		rotationOffset = Vector2.new(itemSize.Y, itemSize.X) / 2 - itemSize / 2
		itemSize = Vector2.new(itemSize.Y, itemSize.X)
	end

	local gridPosX = math.floor((absolutePosition.X - itemManagerOffset.X) / sizeScale.X - rotationOffset.X + 0.5)
	local gridPosY = math.floor((absolutePosition.Y - itemManagerOffset.Y) / sizeScale.Y - rotationOffset.Y + 0.5)
	gridPosX = if self.GridSize.X - itemSize.X < 0 then 0 else math.clamp(gridPosX, 0, self.GridSize.X - itemSize.X)
	gridPosY = if self.GridSize.Y - itemSize.Y < 0 then 0 else math.clamp(gridPosY, 0, self.GridSize.Y - itemSize.Y)

	return Vector2.new(gridPosX, gridPosY)
end

--[=[
	Gets all of the Items in the secified region.

	@within Grid
]=]
function Grid:GetItemsInRegion(position: Vector2, size: Vector2, rotation: number, ignoredItems: { Types.ItemObject }): { Types.ItemObject }
	local regionEnd = position + size
	if rotation % 2 == 1 then
		regionEnd = position + Vector2.new(size.Y, size.X)
	end

	local collidingItems = {}
	for _, item in ipairs(self.Items) do
		if table.find(ignoredItems, item) == nil then
			local itemStart = item.Position
			local itemSize = item.Size
			if item.Rotation % 2 == 1 then
				itemSize = Vector2.new(item.Size.Y, item.Size.X)
			end
			
			if itemStart == true then print(item) end
			local itemEnd = itemStart + itemSize

			local xOverlapping = (position.X < itemEnd.X) and (regionEnd.X > itemStart.X)
			local yOverlapping = (position.Y < itemEnd.Y) and (regionEnd.Y > itemStart.Y)
			if xOverlapping and yOverlapping then
				table.insert(collidingItems, item)
			end
		end
	end

	return collidingItems
end

--[=[
	Checks if an Item is colliding. Use the `at` parameter to override the collision check position, else it will use the Item's position.

	@tag ItemManager Override
	@within Grid
]=]
function Grid:IsColliding(item: Types.ItemObject, ignoredItems: { Types.ItemObject }, at: Vector2?, withRotation: number?): boolean
	local collidingItems = self:GetItemsInRegion(at or item.Position, item.Size, withRotation or item.Rotation, ignoredItems)
	return #collidingItems > 0
end

--[=[
	Checks if a region is in the bounds of the Grid.

	@within Grid
]=]
function Grid:IsRegionInBounds(position: Vector2, size: Vector2, rotation: number): boolean
	local regionEnd = position + size
	if rotation % 2 == 1 then
		regionEnd = position + Vector2.new(size.Y, size.X)
	end
	local isNotInBoundsX = position.X < 0 or regionEnd.X > self.GridSize.X
	local isNotInBoundsY = position.Y < 0 or regionEnd.Y > self.GridSize.Y
	if isNotInBoundsX or isNotInBoundsY then
		return false
	else
		return true
	end
end

--[=[
	Sorts all of the items by volume (Volume = Size.X * Size.Y).

	@within Grid
]=]
function Grid:SortItemsByVolume()
	local itemsSortedByVolume = table.clone(self.Items)
	table.sort(itemsSortedByVolume, function(a, b)
		local aVolume = a.Size.X * a.Size.Y
		local bVolume = b.Size.X * b.Size.Y

		return aVolume > bVolume
	end)

	for _, item in ipairs(itemsSortedByVolume) do
		self:RemoveItem(item)
	end

	task.wait()

	for _, item in ipairs(itemsSortedByVolume) do
		local nextFreePosition = self:GetNextFreePositionForItem(item)
		self:AddItem(item, nextFreePosition, true)
	end
end

--[=[
	Adds an item to the grid. Use optional `at` parameter for overriding the Item's position.

	@within Grid
]=]

local function findPosition (selfItem, item, itemPosition, transfer)
	local foundSpot = false
	assert(item.ItemManager == nil, "Could not add item: Item is already in another ItemManager")
	if transfer then
		assert(selfItem:IsColliding(item, { item }, itemPosition) == false, "Could not add item: Item is colliding with an already added item")
	else
		for gridY = 0, selfItem.GridSize.Y - 1 do
			if foundSpot then break end
			for gridX = 0, selfItem.GridSize.X - 1 do
				local gridPosition = Vector2.new(gridX, gridY)
				if selfItem:IsRegionInBounds(gridPosition, item.Size, item.Rotation) and selfItem:IsColliding(item, { item }, gridPosition) == false then
					itemPosition = gridPosition
					foundSpot = true
					break
				end
			end
		end
		if not foundSpot then
			local originalRotation = item.Rotation
			if originalRotation == 0 or 2 then
				item.PotentialRotation = 1
				item.Rotation = 1
				item.ItemElement.Rotation = 90
			else
				item.PotentialRotation = 0
				item.Rotation = 0
				item.ItemElement.Rotation = 0
			end
			for gridY = 0, selfItem.GridSize.Y - 1 do
				if foundSpot then break end
				for gridX = 0, selfItem.GridSize.X - 1 do
					local gridPosition = Vector2.new(gridX, gridY)
					if selfItem:IsRegionInBounds(gridPosition, item.Size, item.Rotation) and selfItem:IsColliding(item, { item }, gridPosition) == false then
						itemPosition = gridPosition
						foundSpot = true
						break
					end
				end
			end
			if not foundSpot then
				item.PotentialRotation = originalRotation
				item.Rotation = originalRotation
				item.ItemElement.Rotation = originalRotation * 90
			end
		end
		assert(selfItem:IsColliding(item, { item }, itemPosition) == false, "Could not add item: Item is colliding with an already added item")
	end
	assert(selfItem:IsRegionInBounds(itemPosition, item.Size, item.Rotation) == true,  "Could not add item: Item is out of the grid's bounds")

	return itemPosition
end

function Grid:AddItem(item: Types.ItemObject, at: Vector2?, useTween: boolean?, transfer: boolean?)
	local s, itemPosition = pcall(findPosition, self, item, at or item.Position, transfer)
	if not s then return true, itemPosition end -- if not successful, return "true" indicating that the function failed.
	item.Position = itemPosition
	table.insert(self.Items, item)
	self.ItemAdded:Fire(item)	
	item.ItemManagerChanged:Fire(self, useTween)
end

--[=[
	Removes an item from the Grid.

	@tag ItemManager Override
	@within Grid
]=]
function Grid:RemoveItem(item: Types.ItemObject, ...)
	local foundItemIndex = table.find(self.Items, item)
	if foundItemIndex then
		table.remove(self.Items, foundItemIndex)
		self.ItemRemoved:Fire(item, ...)

		item.ItemManagerChanged:Fire(nil)
	else
		error("Unable to remove item: Item could not be found in ItemManager")
	end
end

--[=[
	Removes all of the Items in the grid.

	@within Grid
]=]
function Grid:ClearItems(destroyItems: boolean?)
	for index, item in ipairs(self.Items) do
		if destroyItems then
			item:Destroy()
		end

		self.Items[index] = nil
		self.ItemRemoved:Fire(item)
		
		item.ItemManagerChanged:Fire(nil)
	end
end

return Grid