local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--- // SETTINGS // ---
local FADE_TIME = 0.1
local SCROLL_TIME = 0.05

local initialized = false

local ItemSelectorFrame: CanvasGroup = nil
local ItemTemplate: TextLabel = nil
local ListLayout: UIListLayout = nil

type ItemSelector = {
	Name: string;
	AutoClose: boolean; -- default: true; automatically hide the selector after selecting an item.
	Options: {string};
	SelectCallback: (string) -> ();
}

local ActiveSelector: ItemSelector = nil
local currentOptionIndex = -1
local Selectors: {ItemSelector} = {}

local function renderSelector(selector: ItemSelector)
	ListLayout.Parent = nil
	ItemSelectorFrame:ClearAllChildren()
	ItemSelectorFrame.Position = UDim2.fromOffset(20, -10)
	ListLayout.Parent = ItemSelectorFrame
	
	for i, option in selector.Options do
		local Item = ItemTemplate:Clone()
		Item.Name = tostring(i)
		Item.Text = option
		Item.LayoutOrder = i
		Item.Parent = ItemSelectorFrame
	end
end

local scrollSelectorTweenInfo = TweenInfo.new(SCROLL_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function scrollSelector(previousIndex: number?)
	TweenService:Create(ItemSelectorFrame, scrollSelectorTweenInfo, {Position = UDim2.fromOffset(20, currentOptionIndex * -20 + 10)}):Play()
	if previousIndex then
		TweenService:Create(ItemSelectorFrame[tostring(previousIndex)], scrollSelectorTweenInfo, {
			BackgroundTransparency = 0.8,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			BorderColor3 = Color3.fromRGB(0, 0, 0)
		}):Play()
	end
	TweenService:Create(ItemSelectorFrame[tostring(currentOptionIndex)], scrollSelectorTweenInfo, {
		BackgroundTransparency = 0.5,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(255, 255, 255)
	}):Play()
end

local function deactivateSelector()
	if not initialized or ActiveSelector == nil then return end
	ActiveSelector = nil
	ItemSelectorFrame:SetAttribute("Active", false)
	currentOptionIndex = -1
	TweenService:Create(ItemSelectorFrame, TweenInfo.new(FADE_TIME), {GroupTransparency = 1}):Play()
end

local debounce = false
local function updateSelector()
	if debounce == true or ActiveSelector == nil then return end
	debounce = true
	renderSelector(ActiveSelector)
	scrollSelector()
	TweenService:Create(ItemSelectorFrame, TweenInfo.new(FADE_TIME), {GroupTransparency = 0}):Play()
	ItemSelectorFrame:SetAttribute("Active", true)
	task.wait(FADE_TIME)
	debounce = false
end

local function activateSelector(selector: ItemSelector, startingIndex: number?)
	if debounce or not initialized then return end
	if #selector.Options == 0 then return end
	if ActiveSelector and ActiveSelector ~= selector then
		deactivateSelector()
		ActiveSelector = selector
		currentOptionIndex = startingIndex or 1
		if currentOptionIndex > #selector.Options then
			currentOptionIndex = #selector.Options
		end
		task.delay(FADE_TIME, updateSelector)
	else
		ActiveSelector = selector
		currentOptionIndex = startingIndex or 1
		if currentOptionIndex > #selector.Options then
			currentOptionIndex = #selector.Options
		end
		updateSelector()
	end
end

local function handleScrollInput(Input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or ActiveSelector == nil or ItemSelectorFrame:GetAttribute("Active") == false then return end
	if Input.UserInputType == Enum.UserInputType.MouseWheel then
		local previousIndex = currentOptionIndex
		if Input.Position.Z > 0 then
			currentOptionIndex = math.clamp(currentOptionIndex - 1, 1, #ActiveSelector.Options)
			scrollSelector(previousIndex)
		elseif Input.Position.Z < 0 then
			currentOptionIndex = math.clamp(currentOptionIndex + 1, 1, #ActiveSelector.Options)
			scrollSelector(previousIndex)
		end
	end
end

local function handleMouseInput(Input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent or ActiveSelector == nil or ItemSelectorFrame:GetAttribute("Active") == false then return end
	if Input.UserInputType == Enum.UserInputType.MouseButton1 then
		if ActiveSelector.SelectCallback then
			ActiveSelector.SelectCallback(ActiveSelector.Options[currentOptionIndex])
		end
		if ActiveSelector.AutoClose then
			deactivateSelector()
		end
	elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then -- close selector
		deactivateSelector()
	end
end

local module = {}

function module.createSelector(name: string, AutoClose: boolean?, options: {string}, onSelect: (string) -> ())
	if onSelect == nil then
		warn(`"onSelect" is nil so the selector "{name}" will have no function.`)
	elseif typeof(onSelect) ~= "function" then
		error(`"onSelect" must be a function.`)
	end
	local selector = {
		Name = name;
		AutoClose = if AutoClose == nil then true else AutoClose;
		Options = options or {};
		SelectCallback = onSelect;
	}
	
	for i, option in selector.Options do
		if typeof(i) ~= "number" or i <= 0 or i%1 ~= 0 then
			error(`Selector Options must be an array with only positive-integer indices. Found index of type "typeof(i)".`)
		end
		if typeof(option) ~= "string" then
			table.remove(selector.Options, i)
			warn(`Automatically removed invalid option of type "{typeof(option)}" instead of "string" in selector: "{selector.Name}".`)
		end
	end
	
	Selectors[name] = selector
end

function module.changeAutoClose(name: string, setting: boolean)
	if Selectors[name] then
		Selectors[name].AutoClose = setting
	end
end

function module.changeSelectorOptions(name: string, options: {string})
	assert(typeof(options) == "table", `Type of 'options' must be 'table'. Instead, got: '{typeof(options)}'.`)
	
	for i, option in options do
		if typeof(i) ~= "number" or i <= 0 or i%1 ~= 0 then
			error(`Selector Options must be an array with only positive-integer indices. Found index of type "typeof(i)".`)
		end
		if typeof(option) ~= "string" then
			table.remove(options, i)
			warn(`Automatically removed invalid option of type "{typeof(option)}" instead of "string" in selector: "{name}".`)
		end
	end
	
	if Selectors[name] then
		Selectors[name].Options = options
	end
end

function module.changeOnSelectCallback(name: string, callback: (string) -> ())
	if callback == nil then
		warn(`"onSelect" is nil so the selector "{name}" will have no function.`)
	elseif typeof(callback) ~= "function" then
		error(`"onSelect" must be a function.`)
	end
	if Selectors[name] then
		Selectors[name].SelectCallback = callback
	end
end

function module.activateSelector(name: string, startingIndex: number?)
	assert(startingIndex == nil or typeof(startingIndex) ~= "number" or startingIndex < 1 or startingIndex%1 ~= 0, `"startingIndex" must be a positive integer.`)
	if Selectors[name] then
		activateSelector(Selectors[name], startingIndex)
	else
		error(`No ItemSelector of name "{name}" exists.`)
	end
end

--[=[
	Deactivates the active selector.
	If selector name is specificed, only deactivates if that selector is active.
]=]
function module.deactivateSelector(name: string?)
	if name ~= nil and ActiveSelector ~= nil and ActiveSelector.Name ~= name then return end
	deactivateSelector()
end

function module.Init()
	local Container = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MouseUI"):WaitForChild("Dot")
	ItemSelectorFrame = Container:WaitForChild("ItemSelector")
	ItemTemplate = ItemSelectorFrame:WaitForChild("ItemTemplate")
	ListLayout = ItemSelectorFrame:WaitForChild("UIListLayout")
	ItemTemplate.Parent = nil
	ItemSelectorFrame.Visible = true
	
	UserInputService.InputChanged:Connect(handleScrollInput)
	UserInputService.InputBegan:Connect(handleMouseInput)
	initialized = true
end

return module
