local module = {}

--//Services
local SequenceProvider = game:GetService("KeyframeSequenceProvider")

function module.getAllAnimationEventNames(animation): table
	local markers: table = {}
	if animation then
		local ks: KeyframeSequence = SequenceProvider:GetKeyframeSequenceAsync(animation.Animation.AnimationId)
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
		recurse(ks)
	end
	return markers
end

return module
