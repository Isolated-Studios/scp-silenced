local CodeNameHandler = {}
local Players = game:GetService("Players")

local GetCodeName = {
	["Class-D"] = function(Player, Profile)
		local CodeName = "D-"..tostring(string.format("%04d", math.random(1, 9999)))
		return CodeName
	end,
	
	["Facility Personnel"] = function(Player, Profile)
		local CodeName = "Dr. "..Profile:GetAttribute("LastName")
		return CodeName
	end,
}

function CodeNameHandler.SetCodeName (Player: Player, Profile: Configuration)
	if GetCodeName[Player.Team.Name] then
		local CodeName = GetCodeName[Player.Team.Name](Player, Profile)
		Profile:SetAttribute("CodeName", CodeName)
	end
end

return CodeNameHandler
