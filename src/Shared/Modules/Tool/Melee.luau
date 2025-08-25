local ToolClass = require(script.Parent)

--[[
	====== TYPE DEFINITIONS ======
	
	This section defines the custom type for 'Tool', and some other
	useful definitions such as the custom Enum 'Tool.State'.
]]

export type ClassType = ToolClass.ClassType & {
	
}

local Melee = setmetatable({}, ToolClass)
Melee.__index = Melee
Melee.ClassName = "Melee"

--[[
	====== FUNCTION DEFINITIONS ======

	Functions defined here are statically accessible; they are not linked
	to any particular object. This includes the new object function and
	other utilities.
]]

function Melee.new(Tool: Tool): ClassType
	local self: ClassType = setmetatable(ToolClass.new(Tool), Melee)

	return self
end

--[[
	====== METHOD DEFINITIONS ======

	Functions defined here are associated with unique objects.
	This includes functions for animation handling, default methods, etc.
]]

return Melee
