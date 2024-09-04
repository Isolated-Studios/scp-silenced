local ReplicatedStorage = game:GetService("ReplicatedStorage")
local module = {}

local PlayerAssets  = ReplicatedStorage.PlayerAssets
local Looks = PlayerAssets.Looks
local HumanLooks = Looks.Humans
local HairLooks = HumanLooks.Hair
local TeamLooks = HumanLooks.Teams

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

local function Clothingify(Character: Model, Article: Model | BasePart, isClone: boolean?)
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
	else
		PrimaryPart = Article
	end
	weldClothing(PrimaryPart, Article)

	Article:PivotTo(TargetPart.CFrame)
	local BodyWeld = Instance.new("Weld")
	BodyWeld.Name = "BodyWeld"
	BodyWeld.Part0 = TargetPart
	BodyWeld.Part1 = PrimaryPart
	BodyWeld.Parent = Article
	Article.Parent = Character
	local ori = Article:GetAttribute("OffsetOri") or Vector3.new()
	BodyWeld.C0 = ((CFrame.new(Article:GetAttribute("Offset")) or CFrame.new())) * CFrame.fromOrientation(math.rad(ori.X), math.rad(ori.Y), math.rad(ori.Z))

	Article:SetAttribute("Welded", true)
end

function module.Init(Character)
	local PickedFolder = TeamLooks.Scientist.Male.Standard

	for _, primeArticle in pairs(PickedFolder:GetChildren()) do
		Clothingify(Character, primeArticle)
	end
	Clothingify(Character, HairLooks.Male.Hair)

	Character.ChildAdded:Connect(function(Model)
		if Model:IsA("Model") then
			Clothingify(Character, Model, true)
		end
	end)
end

return module
