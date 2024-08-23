local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerAssets  = ReplicatedStorage.PlayerAssets
local CollectionService = game:GetService("CollectionService")
local Looks = PlayerAssets.Looks
local HumanLooks = Looks.Humans
local HairLooks = HumanLooks.Hair
local TeamLooks = HumanLooks.Teams
function module.Init(Character)
	local function Clothingify (primeArticle,isClone)
		if primeArticle and primeArticle:IsA("Model") and primeArticle.PrimaryPart and primeArticle:GetAttribute("TargetPart") and not primeArticle:GetAttribute("Welded") and Character:FindFirstChild(primeArticle:GetAttribute("TargetPart")) then
			local Article = primeArticle
			if not isClone then 
				Article = primeArticle:Clone()
			end
			local TargetPart = Character[Article:GetAttribute("TargetPart")]
			for _,Part in pairs(Article:GetChildren()) do
				if Part:IsA("BasePart") then
					if Part ~= Article.PrimaryPart then
						local Weld = Instance.new("WeldConstraint") 
						Weld.Parent = Article.PrimaryPart
						Weld.Part0 = Article.PrimaryPart
						Weld.Part1 = Part
					end
					Part.Name = TargetPart.Name
					Part.CanCollide = false
					Part.Anchored = false
					Part.Massless = true
					Part.CollisionGroup = "Character"
					CollectionService:AddTag(Part,"CharPart")
				end
			end
			local BodyWeld = Instance.new("Weld")
			BodyWeld.Parent = Article
			BodyWeld.Name = "BodyWeld"
			BodyWeld.Part0 = Article.PrimaryPart
			BodyWeld.Part1 = TargetPart
			Article:PivotTo(TargetPart.CFrame)
			Article.Parent = Character
			local ori = Article:GetAttribute("OffsetOri") or Vector3.new()
			BodyWeld.C1 = ((CFrame.new(Article:GetAttribute("Offset")) or CFrame.new())) * CFrame.Angles(math.rad(ori.X), math.rad(ori.Y), math.rad(ori.Z))
			Article:SetAttribute("Welded",true)
		end
	end

	local PickedFolder = TeamLooks.Scientist.Male.Standard
	for _,primeArticle in pairs(PickedFolder:GetChildren()) do
		Clothingify(primeArticle)
	end
	Clothingify(HairLooks.Male.Hair)
	Character.ChildAdded:Connect(function(Model)
		if Model:IsA("Model") then
			Clothingify(Model,true)
		end
	end)
end
return module
