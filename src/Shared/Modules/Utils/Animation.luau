local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local AnimationUtils = {}

function AnimationUtils.getAllEventNames(Animation: Animation): table
	local markers: table = {}
	local KeyframeSequence: KeyframeSequence = KeyframeSequenceProvider:GetKeyframeSequenceAsync(Animation.AnimationId)
	local function recurse(parent: Instance)
		for _, child in pairs(parent:GetChildren()) do
			if (child:IsA("KeyframeMarker")) then
				table.insert(markers, tostring(child))
			end
			if (#child:GetChildren() > 0) then
				recurse(child)
			end
		end
	end
	recurse(KeyframeSequence)
	return markers
end

return AnimationUtils
