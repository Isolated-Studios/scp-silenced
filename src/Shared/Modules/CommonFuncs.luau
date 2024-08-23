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

return CommonFuncs
