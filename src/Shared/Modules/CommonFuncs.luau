--[[
    --==--==-- Common functions used by multiple scripts --==--==--
    ---------------------------------------------------------------

    -- Documentation is written before each function --

    - FormattedError(err)
    - SafeCall(f: (...any) -> (...any), ...): ...any
    - SafeCallOrNil(f: (...any) -> (...any), ...): ...any
]]

local CommonFuncs = {}
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

--[=[
    Prints an error and a stacktrace using `warn()` function to keep
    the current thread running.
]=]
function CommonFuncs.FormattedError(err, traceback)
    warn(`<ERROR> {err}`)
	local stacktrace = string.split(traceback, "\n")
	for i, line in stacktrace do
		if i == 1 or i > #stacktrace - 1 then continue end
		warn("└>", line)
	end
	return err
end

--[=[
    Like pcall except it prints the error message to output.
]=]
function CommonFuncs.SafeCall(f: (...any) -> (...any), ...): ...any
	return xpcall(f, function(err) CommonFuncs.FormattedError(err, debug.traceback()) end, ...)
end

--[=[
    Like SafeCall, except it only returns the result value if the function
    ran successfully, no success code or errors returned.
]=]
function CommonFuncs.SafeCallOrNil(f: (...any) -> (...any), ...): ...any?
    local success, result = CommonFuncs.SafeCall(f, ...)

    -- only returns `result` if `success` is true
    return success and result
end

--[=[
	returns ancestor of object by checking if the ancestor has an attribute
	of the given name or has it and its value is [attributeValue].
	
	keep attributeValue empty if you only want to check for the presence of the attribute.
]=]
function CommonFuncs.GetAncestorFromAttribute(object: Instance, attributeName: string, attributeValue: any?)
	local parent = object.Parent
	while true do
		if parent == nil then return nil end
		if (parent:GetAttribute(attributeName) == attributeValue)
			or (attributeValue == nil and parent:GetAttribute(attributeName) ~= nil)
		then
			return parent
		end
		parent = parent.Parent
	end
end

--[=[
	returns the descendant of object by finding a descendant with the given descendantName.
]=]
function CommonFuncs.FindFirstDescendant(object: Instance, descendantName: string)
	local pickedDescendant = nil
	for _, descendant in pairs(object:GetDescendants()) do
		if descendant.Name == descendantName then
			pickedDescendant = descendant
		end 
	end
	return pickedDescendant
end

--[=[
	returns true if any major input UI (Chat, Settings, Inventory) is on.
	`exception` is the name of an input UI to be excepted from the check.
]=]
function CommonFuncs.AreInputUIsActive(exception: string)
	local Player = Players.LocalPlayer
	if (TextChatService.ChatInputBarConfiguration.IsFocused and exception ~= "Chat")
		or (Player.PlayerGui:WaitForChild("Inventory").Main.GroupTransparency < 1 and exception ~= "Inventory")
		or (Player.PlayerGui:WaitForChild("Settings").Main.GroupTransparency < 1 and exception ~= "Settings")
	then
		return true
	end
end

--[=[
	creates a new interaction for the given InteractiveObject.
	InteractiveVariables is a table of variables that are set.
	Format:
	InteractiveVariables = {
		["Interactable"] = boolean,
		["InteractId"] = number,
		["interactTime"] = number,
		["InteractText"] = string,
		["interactRange"] = number,
		["InteractAnimationId"] = number,
		["doorType"] = string,
		["FreezePlayer"] = boolean,
	}
]=]
function CommonFuncs.CreateInteraction(InteractiveObject: Model, InteractiveVariables: table)
	InteractiveObject:SetAttribute("Interactable", InteractiveVariables["Interactable"] or nil)
	InteractiveObject:SetAttribute("InteractId", InteractiveVariables["InteractId"] or 0)
	InteractiveObject:SetAttribute("InteractTime", InteractiveVariables["interactTime"] or nil)
	InteractiveObject:SetAttribute("InteractText", InteractiveVariables["InteractText"] or nil)
	InteractiveObject:SetAttribute("Range", InteractiveVariables["interactRange"] or 10)
	InteractiveObject:SetAttribute("InteractAnimationId", InteractiveVariables["InteractAnimationId"] or 0)
	InteractiveObject:SetAttribute("DoorType", InteractiveVariables["doorType"] or nil)
	InteractiveObject:SetAttribute("FreezePlayer", InteractiveVariables["FreezePlayer"] or false)
end

return CommonFuncs
