local Deathnotes = {}

local RoleToDialogue = {
	["Lobby"] = "Default",
	["Tester"] = "Default",
	["CD"] = "Default",
	["SCPF"] = "Default",
	["SCP"] = "Default",
	["CI"] = "Default",
	["GOC"] = "Default",
	["Pentagram"] = "Default",
	["D9"] = "Default",
}

--[[DICTIONARY
[0] = Unknown
[1] = Bullet wounds
[2] = Fragmentation Grenade
[3] = Explosion/HE
[4] = Burned to death
[5] = Stabbed
[6] = Bludgeoned
]]

function Deathnotes.Messages (Observer: Player, DeadPlayer: Player, Profile: Configuration, AddedWords: table)
	local Role = Profile:GetAttribute("Role")
	local Gender = Profile:GetAttribute("Gender")
	local Deathnote = Profile:GetAttribute("Deathnote")
	
	local Pronouns = {
		[0] = {"he", "his", "him"},
		[1] = {"she", "her", "her"},
		[2] = {"The Creature", "The Creature's", "The Creature"}
	}
	local ChosenPronouns = Pronouns[Gender]
	
	local ChosenDialoguePath = RoleToDialogue[Role] or "Default"
	
	local Dialogue = {
		["Default"] = {
			[0] = "[REDACTED]",
			[1] = string.upper(string.sub(ChosenPronouns[2], 1, 1)).. " body is covered in bullet wounds."
		},
	}
	
	return Dialogue[ChosenDialoguePath][Deathnote]
end

return Deathnotes
