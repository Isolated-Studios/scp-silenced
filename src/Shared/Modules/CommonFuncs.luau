--[[
    --==--==-- Common functions used by multiple scripts --==--==--
    ---------------------------------------------------------------

    -- Documentation is written before each function --

    - FormattedError(err)
    - SafeCall(f: (...any) -> (...any), ...): ...any
    - SafeCallOrNil(f: (...any) -> (...any), ...): ...any
]]

local CommonFuncs = {}

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

return CommonFuncs
