local module = {}
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

-- Modules
local CodeNameHandler = require(script.CodeNameHandler)
local HairColorsList = require(script.HairColors)
local SkinColorsList = require(script.SkinColors)
local NamesList = require(script.Names)

-- Other
local PlayerAssets = ReplicatedStorage.PlayerAssets
local Looks = PlayerAssets.Looks
local PrimeChatBubble = PlayerAssets.Chat.ChatBubble
local HumanLooks = Looks.Humans
local HairLooks = HumanLooks.Hair
local TeamLooks = HumanLooks.Teams
local Voices = ReplicatedStorage.Sounds.Chat.Voices

local function weldClothing(Base: BasePart, Part: BasePart | Model)
	if Part:IsA("Model") then
		for _, v in Part:GetChildren() do
			if v:IsA("BasePart") or v:IsA("Model") then
				weldClothing(Base, v)
			end
		end
	else
		if Part ~= Base then
			local Weld = Instance.new("WeldConstraint")
			Weld.Name = Part.Name
			Weld.Parent = Base
			Weld.Part0 = Base
			Weld.Part1 = Part
		end
		-- Part.Name = TargetPart.Name
		Part.CanCollide = false
		Part.Anchored = false
		Part.Massless = true
		Part.CollisionGroup = "Character"
		Part:AddTag("CharPart")
	end
end

local function Clothingify(Character: Model, Article: Model | BasePart, isClone: boolean?, reName: string, color: Color3)
	assert(Article, "No clothing piece provided")
	assert(Article:GetAttribute("Welded") ~= true, "Provided clothing piece is already welded")
	assert(Article:GetAttribute("TargetPart"), "Provided clothing piece has no TargetPart set")
	assert(Character:FindFirstChild(Article:GetAttribute("TargetPart")), "Provided clothing piece has an invalid TargetPart")

	if not isClone then
		Article = Article:Clone()
	end
	local TargetPart = Character[Article:GetAttribute("TargetPart")]

	local PrimaryPart = nil
	if Article:IsA("Model") then
		assert(Article.PrimaryPart, "Provided clothing piece is a Model that has no PrimaryPart set")
		PrimaryPart = Article.PrimaryPart

		if color then -- Set color of article, particularly for the hair
			for _,part in pairs(Article:GetChildren()) do
				if part:IsA("BasePart") then
					part.Color = color
				end
			end
		end

	else
		PrimaryPart = Article
		if color then  -- Set color of article, particularly for the hair
			Article.Color = color
		end
	end
	weldClothing(PrimaryPart, Article)

	Article:PivotTo(TargetPart.CFrame)
	local BodyWeld = Instance.new("Weld")
	BodyWeld.Name = "BodyWeld"
	BodyWeld.Part0 = TargetPart
	BodyWeld.Part1 = PrimaryPart
	BodyWeld.Parent = Article
	if reName then Article.Name = reName end -- rename the clothing model to the reName
	Article.Parent = Character
	local ori = Article:GetAttribute("OffsetOri") or Vector3.new()
	BodyWeld.C0 = ((CFrame.new(Article:GetAttribute("Offset")) or CFrame.new())) * CFrame.fromOrientation(math.rad(ori.X), math.rad(ori.Y), math.rad(ori.Z))

	Article:SetAttribute("Welded", true)
end

local WhiteHairColors = HairColorsList.WhiteHairColors
local BlackHairColors = HairColorsList.BlackHairColors
local WhiteSkinColors = SkinColorsList.WhiteSkinColors
local BlackSkinColors = SkinColorsList.BlackSkinColors
local AlienSkinColors = SkinColorsList.AlienSkinColors
local MaleNames = NamesList.MaleNames
local FemaleNames = NamesList.FemaleNames
local LastNames = NamesList.LastNames
local AlienNames = NamesList.AlienNames
local AlienLastNames = NamesList.AlienLastNames
function module.Init(Character)
	local Player = game:GetService("Players"):GetPlayerFromCharacter(Character)
	local ChatBubble = PrimeChatBubble:Clone()
	ChatBubble.Parent = Character:WaitForChild("UpperTorso")
	ChatBubble.Adornee = Character.UpperTorso
	ChatBubble.PlayerToHideFrom = Player

	local Profile = Character:WaitForChild("Profile")

	-- Role and RoleColor will just be set as the Team and TeamColor for now
	Profile:SetAttribute("Role", Player.Team.Name)
	Profile:SetAttribute("RoleColor", Player.TeamColor.Color)

	local ChosenSkinColor = math.random(0,1)
	local AlienChance = math.random(1,100)

	if AlienChance == 1 then -- Alien chance overrides skin color
		ChosenSkinColor = 2
	end

	local raceTable = {
		[0] = {WhiteSkinColors,WhiteHairColors}, -- group white
		[1] = {BlackSkinColors,BlackHairColors}, -- group black
		[2] = {AlienSkinColors,AlienSkinColors} -- group alien
	}

	local SkinColor = raceTable[ChosenSkinColor][1][math.random(1,#raceTable[ChosenSkinColor][1])] -- get skin color
	local HairColor = raceTable[ChosenSkinColor][2][math.random(1,#raceTable[ChosenSkinColor][2])] -- get hair color

	Character.BodyColor.HeadColor3 = SkinColor -- Set the skin color
	Character.BodyColor.LeftArmColor3 = SkinColor
	Character.BodyColor.LeftLegColor3 = SkinColor
	Character.BodyColor.RightArmColor3 = SkinColor
	Character.BodyColor.RightLegColor3 = SkinColor
	Character.BodyColor.TorsoColor3 = SkinColor

	local Gender = math.random(0,1)
	local genderTable = {
		[0] = "Male",
		[1] = "Female",
	}
	Profile:SetAttribute("Gender",Gender)
	Profile:SetAttribute("LastName",LastNames[math.random(1,#LastNames)])

	if Gender == 1 then
		-- Changes torso to be "woman" and gives a female first name.
		Character.UpperTorso.Mesh.MeshId = Character.UpperTorso.Mesh:GetAttribute("MeshId")
		Profile:SetAttribute("FirstName",FemaleNames[math.random(1,#FemaleNames)])
	else
		-- Gives male name.
		Profile:SetAttribute("FirstName",MaleNames[math.random(1,#MaleNames)])
	end
	
	-- Set code name.
	CodeNameHandler.SetCodeName(Player, Profile)

	local optionVoices = {}
	-- gather potential voices
	for _,voice in pairs(Voices:GetChildren()) do
		if voice:GetAttribute("Type") == Gender then
			table.insert(optionVoices,voice.Name)
		end
	end
	Profile:SetAttribute("Voice",optionVoices[math.random(1,#optionVoices)]) -- assign a voice

	local PickedFolder = if Player.Team == Teams["Facility Personnel"] then 
		TeamLooks.Scientist[genderTable[Profile:GetAttribute("Gender")]].Standard
		else TeamLooks["Class-D"][genderTable[Profile:GetAttribute("Gender")]].Standard

	for _, primeArticle in pairs(PickedFolder:GetChildren()) do
		Clothingify(Character, primeArticle)
	end

	local HairFolder = HairLooks[genderTable[Profile:GetAttribute("Gender")]]

	if AlienChance == 1 then -- Pick alien "hair"
		HairFolder = HairLooks["Alien"]
		HairColor = SkinColor

		Profile:SetAttribute("FirstName",AlienNames[math.random(1,#AlienNames)])
		Profile:SetAttribute("LastName",AlienNames[math.random(1,#AlienNames)])
	end

	local pickedHair = HairFolder:GetChildren()[math.random(1,#HairFolder:GetChildren())]

	Clothingify(Character, pickedHair, nil, "Hair",HairColor)

	Character.ChildAdded:Connect(function(Child)
		if Child:GetAttribute("TargetPart") then
			Clothingify(Character, Child, true)
		end
	end)
end

return module
