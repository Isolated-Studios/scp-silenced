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
[7] = lol this guy died from a stun grenade
[8] = Bled out
[9] = Fall damage
]]

function Deathnotes.Messages (Observer: Player, Profile: Configuration, AddedWords: table)
	local Role = Profile:GetAttribute("Role")
	local Gender = Profile:GetAttribute("Gender")
	local Deathnote = Profile:GetAttribute("Deathnote")
	
	local Pronouns = {
		[0] = {"he", "his", "him"},
		[1] = {"she", "her", "her"},
		[2] = {"it", "its", "it"}
	}
	local ChosenPronouns = Pronouns[Gender]
	
	local ChosenDialoguePath = RoleToDialogue[Role] or "Default"
	
	local Dialogue = {
		["Default"] = {
			[0] = "[REDACTED]",
			[1] = ChosenPronouns[2]:gsub("^%l", string.upper).. " body is covered in bullet wounds.",
			[2] = "Deeply embedded fragments cover " ..ChosenPronouns[2].. " body.",
			[3] = "Large portions of " ..ChosenPronouns[2].. " body are missing with deep burns.",
			[4] = ChosenPronouns[2]:gsub("^%l", string.upper).. " body is charred.",
			[5] = "Deep lacerations cover " ..ChosenPronouns[2].. " body.",
			[6] = "Large bruises cover " ..ChosenPronouns[2].. " body.",
			[7] = ChosenPronouns[2]:gsub("^%l", string.upper).. " eyes are pale white.",
			[8] = "Lacerations cover " ..ChosenPronouns[2].. " body. " ..ChosenPronouns[1]:gsub("^%l", string.upper).. " must have bled to death.",
			[9] = ChosenPronouns[2]:gsub("^%l", string.upper).. " body is a mess of broken bones and blood."
		},
	}
	
	return Dialogue[ChosenDialoguePath][Deathnote]
end

return Deathnotes
