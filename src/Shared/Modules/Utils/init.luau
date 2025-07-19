--[[
	Generally useful util functions, idk why I previously created CommonFuncs lol.
	
	I'll gradually move all general util functions here.
	
	CURRENT METHODS:
	
	Utils.wrapMethod(object, method) -> returns a function that wraps object:method().
]]

local Utils = {
	Animation = require(script.Animation);
}

--[=[
	Returns a function that wraps the method provided of the given object.
	
	This is useful for connecting function methods to Roblox events using the ":Connect()" function.
	
	For example, let Person be an arbitrary class with a string field "Name" and a method "Greet(person)",
	and let the following be the calling script.
	```lua
	local Person = require(script.Person)
	local person1 = Person.new("Dave")
	local person2 = Person.new("Gerald")
	
	local greeting = person1:Greet(person2) -- prints and returns "Dave: Hello, Gerald!"
	```
	The function called at the end would be equivalent to
	```lua
	local wrappedGreet = Utils.wrapMethod(person1, person1.Greet)
	local greeting = wrappedGreet(person2)
	```
]=]
function Utils.wrapMethod<T>(object: T, method: (T, ...any) -> (any...)): (...any) -> (any...)
	return function(...)
		return method(object, ...)
	end
end

return Utils
