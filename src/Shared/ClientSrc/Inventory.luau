local module = {}
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Player = game:GetService("Players").LocalPlayer

local function loadCharacter(Character)
	local Events = ReplicatedStorage.Events
	local Modules = ReplicatedStorage.Modules
	local Objects = ReplicatedStorage.Objects
	local UIModules = Modules.UI

	local ManageAmmoBox = Events:WaitForChild("Tool"):WaitForChild("ManageAmmoBox")

	local Ammo = Character:WaitForChild("Ammo")

	local Tooling = ReplicatedStorage:WaitForChild("Tooling")
	local Tools = Tooling:WaitForChild("Tools")

	local InventoryUI = Player.PlayerGui:WaitForChild("Inventory")
	local Main = InventoryUI:WaitForChild("Main")
	local Container = Main:WaitForChild("Container")
	local ModalFrame = InventoryUI:WaitForChild("ModalFrame")
	local SlotTemplate = Container:WaitForChild("SlotTemplate")
	local ItemTemplate = Container:WaitForChild("ItemTemplate")

	local InventoryHover = Player.PlayerGui.MouseUI.Dot.InventoryHover
	local MouseHighlight = Container.MouseHighlighter

	local ViewportFrame = Container:WaitForChild("ViewportFrame")
	local ViewportCharacter = ViewportFrame:WaitForChild("WorldModel"):WaitForChild("Character")
	local ViewportHumanoid = ViewportCharacter:WaitForChild("Humanoid")
	local ViewportAnimator = ViewportHumanoid:WaitForChild("Animator")
	local ViewportIdle = ViewportAnimator:LoadAnimation(ViewportAnimator.Idle)

	local ToolList = {}
	local ItemList = {}
	local ToolTypeToTable = {
		[1] = {"Primary"},
		[2] = {"Secondary"},
		[3] = {"Melee"},
		[8] = {"Helmet"},
		[9] = {"Head"},
		[10] = {"Armor"},
		[11] = {"Torso"},
	}

	local CTF = require(Modules.Tool.CommonToolFunctions)
	local KeybindHandler = require(UIModules.KeybindHandler)
	local HotbarHandler = require(script.Parent.HotbarHandler)
	local GridPack = require(UIModules.GridPackModules.GridPack)
	require(UIModules.GridPackModules.GridPack.Item).InventoryKeyCode = KeybindHandler.Keybind("Open Inventory", game.Players.LocalPlayer)

	local Humanoid = Character:WaitForChild("Humanoid")

	local function createGrid(Template, sizex, sizey)
		local grid = GridPack.createGrid(
			{
				Parent = Template.Parent,
				Visible = true,
				Assets = {
					Slot = SlotTemplate,
				},
				GridSize = Vector2.new(sizex, sizey),
				SlotAspectRatio = 1,

				AnchorPoint = Template.AnchorPoint,
				Position = Template.Position,
				Size = Template.Size,

				Metadata = {

				},
			}
		)

		local function connect(event, transparency)
			transparency = 1 - transparency -- turn it to opacity
			event:Connect(function(Item)
				local sizeX, sizeY = Item.Size.X, Item.Size.Y
					if Item.Rotation % 2 == 1 then
						sizeX, sizeY = sizeY, sizeX
					end
					for xPosition = Item.Position.X + 1, Item.Position.X + sizeX do
						for yPosition = Item.Position.Y + 1, Item.Position.Y + sizeY do
						local slotElement = grid.SlotElements[xPosition .. ", " .. yPosition]
						if not slotElement then return end
						TweenService:Create(slotElement.Vignette, TweenInfo.new(0.2), {ImageTransparency = 1 - (transparency * 0.1)}):Play()
						TweenService:Create(slotElement.Vignette.UIStroke, TweenInfo.new(0.2), {Transparency = 1 - (transparency * 0.4)}):Play()
					end
				end
			end)
		end

		connect(grid.ItemMoved, 1)
		connect(grid.ItemAdded, 1)
		connect(grid.ItemHeld, 0)
		grid.ItemRemoved:Connect(function(Item, Position, Rotation, Size)
			if not Position then
				Position, Rotation, Size = Item.Position, Item.Rotation, Item.Size
			end
			local sizeX, sizeY = Size.X, Size.Y
			if Rotation % 2 == 1 then
				sizeX, sizeY = sizeY, sizeX
			end
			for xPosition = Position.X + 1, Position.X + sizeX do
				for yPosition = Position.Y + 1, Position.Y + sizeY do
					local slotElement = grid.SlotElements[xPosition .. ", " .. yPosition]
					if not slotElement then return end
					TweenService:Create(slotElement.Vignette, TweenInfo.new(0.2), {ImageTransparency = 0.9}):Play()
					TweenService:Create(slotElement.Vignette.UIStroke, TweenInfo.new(0.2), {Transparency = 0.6}):Play()
				end
			end
		end)
		return grid
	end

	local function createUniqueSlot(Type: string, Template)
		local slot = GridPack.createSingleSlot(
			{
				Parent = Container, -- Parent of the slot container

				Visible = true, -- If the slot is visible, changes the containers visible property. Also disables item interaction on the item inside.

				Assets = {
					Slot = Template, -- Add your own CanvasGroup here to customize the slot.
				},

				AnchorPoint = Template.AnchorPoint, -- Anchor point of the slot container
				Position = Template.Position, -- Position of the slot container
				Size = Template.Size, -- Size of the slot container

				Metadata = {
					Type = Type;
				},
			}
		)
		Template.Visible = false

		slot.ItemChanged:Connect(function(Item)
			if slot.Item == nil then
				TweenService:Create(slot.GuiElement.Vignette, TweenInfo.new(0.2), {ImageTransparency = 0.9}):Play()
				TweenService:Create(slot.GuiElement.Vignette.UIStroke, TweenInfo.new(0.2), {Transparency = 0.6}):Play()
				TweenService:Create(slot.GuiElement.Label, TweenInfo.new(0.2), {TextTransparency = 0.9}):Play()
			else
				TweenService:Create(slot.GuiElement.Vignette, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
				TweenService:Create(slot.GuiElement.Vignette.UIStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
				TweenService:Create(slot.GuiElement.Label, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
			end
		end)
		slot.ItemHeld:Connect(function(Item)
			TweenService:Create(slot.GuiElement.Vignette, TweenInfo.new(0.2), {ImageTransparency = 0.9}):Play()
			TweenService:Create(slot.GuiElement.Vignette.UIStroke, TweenInfo.new(0.2), {Transparency = 0.6}):Play()
			TweenService:Create(slot.GuiElement.Label, TweenInfo.new(0.2), {TextTransparency = 0.9}):Play()
		end)
		slot.ItemMoved:Connect(function(Item)
			TweenService:Create(slot.GuiElement.Vignette, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
			TweenService:Create(slot.GuiElement.Vignette.UIStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
			TweenService:Create(slot.GuiElement.Label, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		end)
		return slot
	end

	local InventoryGrid = createGrid(Container.InventorySize, 5, 6)
	local ExtraGrid = createGrid(Container.ExtraSize, 5, 3)
	local ProximityGrid = createGrid(Container.ProximityCanvasGroup.ProximityScrollFrame.Framing, 7, 21)

	local PrimarySlot = createUniqueSlot("Primary", Container.PrimarySize)
	local SecondarySlot = createUniqueSlot("Secondary", Container.SecondarySize)
	local MeleeSlot = createUniqueSlot("Melee", Container.MeleeSize)
	local HelmetSlot = createUniqueSlot("Helmet", Container.HelmetSize)
	local HeadSlot = createUniqueSlot("Head", Container.HeadSize)
	local ArmorSlot = createUniqueSlot("Armor", Container.ArmorSize)
	local TorsoSlot = createUniqueSlot("Torso", Container.TorsoSize)

	HotbarHandler.InventoryToolTypeSlotIndex[1] = PrimarySlot
	HotbarHandler.InventoryToolTypeSlotIndex[2] = SecondarySlot
	HotbarHandler.InventoryToolTypeSlotIndex[3] = MeleeSlot

	local ToolTypeToSlot = {
		[1] = PrimarySlot,
		[2] = SecondarySlot,
		[3] = MeleeSlot,
		[8] = HelmetSlot,
		[9] = HeadSlot,
		[10] = ArmorSlot,
		[11] = TorsoSlot,
	}
	local ToolTypeToListing = {
		[1] = {
			Repair = false,
			EmptyMag = true,
			Attachments = true,
			Properties = true,
			Drop = true,
		};
		[2] = {
			Repair = false,
			EmptyMag = true,
			Attachments = true,
			Properties = true,
			Drop = true,
		};
		[3] = {
			Repair = true,
			EmptyMag = false,
			Attachments = false,
			Properties = true,
			Drop = true,
		};
	}

	local function createTool (tool)
		local toolFolder = Tools[tool:GetAttribute("ToolName")]
		local Settings = require(toolFolder["Settings"])
		local slotList = ToolTypeToTable[tool:GetAttribute("ToolType")]
		local targetSlot = ToolTypeToSlot[tool:GetAttribute("ToolType")]
		local listingToUse = {
			Repair = false,
			EmptyMag = false,
			Attachments = false,
			Properties = true,
			Drop = true,
		}

		--//Make Ammo
		if tool:GetAttribute("ToolType") == 12 then
			Ammo[Settings.AmmoType].Value += tool.Holder.Capacity.Value
		end
		--\\

		if ToolTypeToListing[tool:GetAttribute("ToolType")] then
			listingToUse = ToolTypeToListing[tool:GetAttribute("ToolType")]
		end

		local itemUI = GridPack.createItem({
			--Position = Vector2.new(0, 0),
			Size = Settings.Size or Vector2.new(1, 1),

			Assets = {
				Item = ItemTemplate,
			},

			Metadata = {
				Image = Settings.Image;
				Color = Settings.HighlightColor;
				AllowedSingleSlots = slotList;
				Name = tool.Name;
				Tool = tool;
				Character = Character;
				Listing = listingToUse;
			},
		})

		itemUI.MouseClicked:Connect(function()
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then
				local invalid = false
				local originalPlacement = {itemUI.Position, itemUI.Rotation, itemUI.Size}
				if slotList then
					if itemUI.ItemManager == targetSlot then
						local invalid, res = itemUI:SetItemManager(InventoryGrid, false, originalPlacement)
						if invalid then
							invalid, res = itemUI:SetItemManager(ExtraGrid, false, originalPlacement)
							if invalid then
								itemUI:SetItemManager(targetSlot, false, originalPlacement)
							end
						end
					else
						local originalPlace = {itemUI.Position, itemUI.Rotation, itemUI.ItemManager}
						local replaceItem = targetSlot.Item

						if replaceItem then
							itemUI.ItemManager:RemoveItem(itemUI)
							if replaceItem:SetItemManager(InventoryGrid, false) then
								if replaceItem:SetItemManager(ExtraGrid, false) then
									replaceItem:SetItemManager(targetSlot, false)
									itemUI.Position = originalPlace[1]
									itemUI.Rotation = originalPlace[2]
									itemUI:SetItemManager(originalPlace[3], false)
									return
								end
							end
						end
						itemUI.Position = Vector2.zero
						itemUI.Rotation = 0
						itemUI:SetItemManager(targetSlot, false, originalPlacement)
					end
				else
					if itemUI.ItemManager == InventoryGrid then
						InventoryGrid:RemoveItem(itemUI)
						if ExtraGrid:AddItem(itemUI, nil, true) then
							InventoryGrid:AddItem(itemUI, itemUI.Position, false, true)
						end
					else
						ExtraGrid:RemoveItem(itemUI)
						if InventoryGrid:AddItem(itemUI, nil, true) then
							ExtraGrid:AddItem(itemUI, itemUI.Position, false, true)
						end
					end
				end
			end
		end)

		table.insert(ToolList,tool)
		table.insert(ItemList,itemUI)
		if slotList then
			if targetSlot:IsColliding(itemUI, { itemUI }, itemUI.Position, itemUI.PotentialRotation) then
				local invalid = InventoryGrid:AddItem(itemUI)
				if invalid then
					local invalid2 = ExtraGrid:AddItem(itemUI)
					if invalid2 then
						CTF.dropItem(Character,tool)
					end
				end
			else
				targetSlot:ChangeItem(itemUI, nil, true)
				itemUI:Drop(true)
			end
		else
			local invalid = InventoryGrid:AddItem(itemUI)
			if invalid then
				local invalid2 = ExtraGrid:AddItem(itemUI)
				if invalid2 then
					CTF.dropItem(Character,tool)
				end
			end
		end
	end

	local function removeTool (tool)
		for _,validItemUI in pairs(ItemList) do
			if validItemUI.Metadata.Tool == tool then

				--//Remove Ammo
				if tool:GetAttribute("ToolType") == 12 and tool:GetAttribute("Dropping") then
					local toolFolder = Tools[tool:GetAttribute("ToolName")]
					local Settings = require(toolFolder["Settings"])
					Ammo[Settings.AmmoType].Value -= tool.Holder.Capacity.Value
				end
				--\\

				table.remove(ToolList,table.find(ToolList,tool))
				table.remove(ItemList,table.find(ItemList,validItemUI))
				validItemUI:Destroy()
				break
			end
		end
	end

	--//Startup
	local startTools = {}
	for _,tool in pairs(Player.Backpack:GetChildren()) do
		if tool:GetAttribute("ToolType") and not table.find(ToolList,tool) then
			--createTool(tool)
			local toolFolder = Tools[tool:GetAttribute("ToolName")]
			local Settings = require(toolFolder["Settings"])
			local size = 1
			if Settings.Size then
				size = Settings.Size.X*Settings.Size.Y
			end
			table.insert(startTools, {size, tool})
		end
	end
	table.sort(startTools,function(a , b)
		return a[1] > b[1]
	end)
	for _,toolValues in pairs(startTools) do
		local tool = toolValues[2]
		if tool:GetAttribute("ToolType") and not table.find(ToolList,tool) then
			createTool(tool)
		end
	end
	--\\

	--//Functions
	local function disconnectFunctions (FunctionList)
		for _,Function in pairs(FunctionList) do
			if Function then
				for _,f in pairs(Function) do
					f:Disconnect()
				end
			end
		end
	end

	local childAdded = Player.Backpack.ChildAdded:Connect(function(tool)
		if tool:GetAttribute("ToolType") and not table.find(ToolList,tool) then
			createTool(tool)
		end
	end)

	local childRemoved = Player.Backpack.ChildRemoved:Connect(function(tool)
		if tool:GetAttribute("ToolType") and table.find(ToolList,tool) and tool.Parent ~= Player.Backpack and tool:GetAttribute("Removing") then
			removeTool(tool)
		end
	end)

	--//Manage Ammo Boxes
	local ammoFunctionsList = {}
	local ammoTypeToBox = {
		["Pistol"] = "Pistol Ammo",
		["Rifle"] = "Rifle Ammo",
		["PDW"] = "PDW Ammo",
		["LMG"] = "LMG Ammo",
		["Shotgun"] = "Shotgun Shells",
		["Handcannon"] = "Handcannon Ammo",
	}

	for _,ammoValue in pairs(Ammo:GetChildren()) do
		local beginningValue = ammoValue.Value
		local beginningTools = 0
		for _, ammoTool in pairs(Player.Backpack:GetChildren()) do
			if ammoTool:GetAttribute("ToolType") == 12 then
				local toolFolder = Tools[ammoTool:GetAttribute("ToolName")]
				local Settings = require(toolFolder["Settings"])
				if Settings.AmmoType == ammoValue.Name then
					beginningTools+=1
				end
			end
		end

		local ammoFunction = ammoValue:GetPropertyChangedSignal("Value"):Connect(function()
			local ammoToPass = beginningValue - ammoValue.Value
			local ValidTools = {}
			for _,ammoTool in pairs(Player.Backpack:GetChildren()) do
				if ammoTool:GetAttribute("ToolType") == 12 then
					local toolFolder = Tools[ammoTool:GetAttribute("ToolName")]
					local Settings = require(toolFolder["Settings"])
					if Settings.AmmoType == ammoValue.Name then
						table.insert(ValidTools,{ammoTool,Settings.MaxAmmo})
					end
				end
			end
			if beginningTools > #ValidTools  then
				local total = 0
				for _,v in pairs(ValidTools) do
					if v[1].Holder.Capacity.Value > 0 then
						total += v[1].Holder.Capacity.Value
					end
				end
				ammoValue.Value = total
				beginningValue = ammoValue.Value
				return
			end
			local function findLowestTool ()
				local lT = nil
				local index = 1
				local low = math.huge
				for i, v in pairs(ValidTools) do
					if v[1].Holder.Capacity.Value < low and v[1].Holder.Capacity.Value > 0 then
						low = v[1].Holder.Capacity.Value
						lT = v[1]
						index = i
					end
				end
				return lT,index
			end

			local function findHighestTool ()
				local hT = nil
				local index = 1
				local high = -math.huge
				for i, v in pairs(ValidTools) do
					if v[1].Holder.Capacity.Value > high and v[1].Holder.Capacity.Value < v[2] then
						high = v[1].Holder.Capacity.Value
						hT = v[1]
						index = i
					end
				end
				return hT,index
			end
			if ammoToPass > 0 then
				--Ammo must be subtracted from boxes
				repeat
				local lowestTool,lowestIndex = findLowestTool()
				if not lowestTool then break end
				lowestTool.Holder.Capacity.Value = lowestTool.Holder.Capacity.Value - ammoToPass
				if lowestTool.Holder.Capacity.Value < 0 then
					ammoToPass = -lowestTool.Holder.Capacity.Value
				else
					ammoToPass = 0
				end
				if lowestTool.Holder.Capacity.Value <= 0 then
					ManageAmmoBox:FireServer(lowestTool)
					table.remove(ValidTools,lowestIndex)
				end
				until ammoToPass <= 0 or not lowestTool
			else
				--Ammo must be added to boxes
				while ammoToPass < 0 do
					local highestTool,highetToolIndex = findHighestTool()
					local total = 0
					for _,v in pairs(ValidTools) do
						if v[1].Holder.Capacity.Value > 0 then
							total += v[1].Holder.Capacity.Value
						end
					end
					if total == ammoValue.Value then break end
					if not highestTool and ammoToPass < 0 then
						--Create an ammo box
						ManageAmmoBox:FireServer(ammoToPass,ammoTypeToBox[ammoValue.Name])
						ammoToPass = 0
					elseif ammoToPass < 0 then
						local check = highestTool.Holder.Capacity.Value + -ammoToPass
						if check >= ValidTools[highetToolIndex][2] then
							highestTool.Holder.Capacity.Value = ValidTools[highetToolIndex][2]
							ammoToPass = -(check-ValidTools[highetToolIndex][2])
						else
							highestTool.Holder.Capacity.Value = check
							ammoToPass = 0
						end
					end
				end
			end

			local total = 0
			for _,v in pairs(ValidTools) do
				if v[1].Holder.Capacity.Value > 0 then
					total += v[1].Holder.Capacity.Value
				end
			end
			ammoValue.Value = total
			beginningValue = ammoValue.Value
			beginningTools = #ValidTools
		end)
		table.insert(ammoFunctionsList,ammoFunction)
	end
	--\\

	--\\

	local TransferLink = GridPack.createTransferLink({})
	InventoryGrid:ConnectTransferLink(TransferLink)
	ExtraGrid:ConnectTransferLink(TransferLink)
	ProximityGrid:ConnectTransferLink(TransferLink)
	PrimarySlot:ConnectTransferLink(TransferLink)
	SecondarySlot:ConnectTransferLink(TransferLink)
	MeleeSlot:ConnectTransferLink(TransferLink)
	HelmetSlot:ConnectTransferLink(TransferLink)
	HeadSlot:ConnectTransferLink(TransferLink)
	ArmorSlot:ConnectTransferLink(TransferLink)
	TorsoSlot:ConnectTransferLink(TransferLink)

	local inputBegan = UIS.InputBegan:Connect(function(input,gpe)
		if gpe or Humanoid.Health <= 0 then return end
		if input.KeyCode == KeybindHandler.Keybind("Open Inventory", game.Players.LocalPlayer) then
			Main.Interactable = not Main.Interactable
			ModalFrame.Modal = not ModalFrame.Modal
			for _,item in pairs(ItemList) do
				item:Drop()
			end
			if Main.Interactable then
				Humanoid:SetAttribute("InventoryOpen",true)
				TweenService:Create(Main, TweenInfo.new(0.2), {GroupTransparency = 0}):Play()
				TweenService:Create(InventoryHover.Label, TweenInfo.new(0.2), {TextTransparency = 0, TextStrokeTransparency = 0.7}):Play()
				TweenService:Create(InventoryHover.SecondLabel, TweenInfo.new(0.2), {TextTransparency = 0, TextStrokeTransparency = 0.7}):Play()
			else
				Humanoid:SetAttribute("InventoryOpen",nil)
				TweenService:Create(Main, TweenInfo.new(0.2), {GroupTransparency = 1}):Play()
				TweenService:Create(InventoryHover.Label, TweenInfo.new(0.2), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
				TweenService:Create(InventoryHover.SecondLabel, TweenInfo.new(0.2), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
			end
		end

		if input.KeyCode == KeybindHandler.Keybind("Drop",game.Players.LocalPlayer) then
			local HoveredTool = Main.HoveredTool
			if HoveredTool.Value then
				CTF.dropItem(Character,HoveredTool.Value)
			end
		end
	end)

	-- // Mouse Background Glow (Visually broken for some reason)
	--local HighlightMiddle = MouseHighlight.Middle
	--local HighlightLeft = MouseHighlight.Left
	--local HighlightRight = MouseHighlight.Right
	--local HighlightTop = MouseHighlight.Top
	--local HighlightBottom = MouseHighlight.Bottom
	--local updateMouseHighlight = RunService.RenderStepped:Connect(function(dt: number)
	--	local mousePosition = UIS:GetMouseLocation()
	--	local GuiOffset = MouseHighlight.AbsolutePosition
	--	local GUIInset = GuiService:GetGuiInset()
	--	mousePosition -= GuiOffset + GUIInset -- get the local position
	--	HighlightMiddle.Position = UDim2.fromOffset(mousePosition.X - HighlightMiddle.AbsoluteSize.X / 2, mousePosition.Y - HighlightMiddle.AbsoluteSize.Y / 2)
	--	HighlightLeft.Position = UDim2.new(-2, HighlightMiddle.Position.X.Offset + 1, 0, 0)
	--	HighlightRight.Position = UDim2.new(0, HighlightMiddle.Position.X.Offset + HighlightMiddle.AbsoluteSize.X - 1, 0, 0)
	--	HighlightTop.Position = UDim2.new(0, 0, -2, HighlightMiddle.Position.Y.Offset + 1)
	--	HighlightBottom.Position = UDim2.new(0, 0, 0, HighlightMiddle.Position.Y.Offset + HighlightMiddle.AbsoluteSize.Y - 1)
	--end)

	--// Inventory Person
	ViewportIdle:Play()
	--\\

	Humanoid.Died:Once(function()
		inputBegan:Disconnect()
		--updateMouseHighlight:Disconnect()
		disconnectFunctions{ammoFunctionsList}
		Main.Interactable = false
		ModalFrame.Modal = false
		--myFirstItem:Drop()
		Humanoid:SetAttribute("InventoryOpen",nil)
		TweenService:Create(Main,TweenInfo.new(0.2),{GroupTransparency = 1}):Play()

		InventoryGrid:ClearItems()
		ExtraGrid:ClearItems()
		ProximityGrid:ClearItems()
		PrimarySlot:RemoveItem()
		SecondarySlot:RemoveItem()
		MeleeSlot:RemoveItem()
		HelmetSlot:RemoveItem()
		HeadSlot:RemoveItem()
		ArmorSlot:RemoveItem()
		TorsoSlot:RemoveItem()
		HotbarHandler.InventoryToolTypeSlotIndex = {}
	end)
end

function module.Init()
	Player.CharacterAdded:Connect(loadCharacter)
	if Player.Character then
		loadCharacter(Player.Character)
	end
end

return module
