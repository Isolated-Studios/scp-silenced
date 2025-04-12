local module = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local Modules = ReplicatedStorage.Modules
local Events = ReplicatedStorage.Events
local CharacterEvents = Events.Character

local BloodEvent = CharacterEvents.BloodEvent
local GoreEvent = CharacterEvents.GoreEvent

local CTF = require(Modules.Tool.CommonToolFunctions)
local BloodMod = require(Modules.Character.BloodHandler)
local TeamHandler = require(Modules.Interaction.TeamHandler)

local BloodHandler = BloodMod.create(8,20,3,3)
local twitchAnimTable = {10215956796, 10215963096, 10215967452}

local function ArmorDamage (HitHumanoid, Health, Damage, Halve)
	Damage = Damage/(Halve and 2 or 1)
	HitHumanoid:SetAttribute(Health,HitHumanoid:GetAttribute(Health)-Damage)
	if HitHumanoid:GetAttribute(Health) < 0 then
		Damage = Damage+(-HitHumanoid:GetAttribute(Health))
		HitHumanoid:SetAttribute(Health,0)
	end
	return Damage / (Halve and 1 or 2)
end

local function getLimb (HitPart)
	local HitLimb = "Torso"
    if string.find(HitPart.Name,"Leg") or string.find(HitPart.Name,"Foot") then
		HitLimb = "Leg"
	elseif string.find(HitPart.Name,"Head") then
		HitLimb = "Head"
	end
    return HitLimb
end

local function pickRandomLimbsToGib (Character,Amount) --/ picks random "natural limbs" (no feet/hands/clothes/hrp/collisionbox) for gibbing
	local Limbs = {}
	local NaturalGibParts = {}
	if not Amount then
		Amount = {1,5}
	end
	
	for _,charPart in pairs(Character:GetChildren()) do --/ put natural gib parts into a table
		if CollectionService:HasTag(charPart,"NaturalGibPart") then
			table.insert(NaturalGibParts,charPart)
		end
	end
	
	if #NaturalGibParts == 0 then print("No natural gib parts present in ".. Character.Name) return false end
	for i=1,math.random(Amount[1],Amount[2]),1 do
		if #NaturalGibParts <= 0 then break end
		local randomIndex = math.random(1,#NaturalGibParts)
		local potentialLimb = NaturalGibParts[randomIndex]
		
		table.remove(NaturalGibParts,randomIndex)
		table.insert(Limbs,potentialLimb)
	end
	
	return Limbs
end

function module.Damage(
	Damage: number,
	HitHumanoid: Humanoid,
	HitPart: Instance,
	Killer: Player,
	CanDown: number,
	Twitch: boolean,
	HeadshotFactor: number,
	AP: number,
	Blood: boolean,
	Direction: Vector3,
	GibChance: number,
	Sever: boolean,
	noLimbDamageAdjust: boolean,
	LegMultiplier: number,
	AnnihilationRange: table
)
	if not Damage or not HitHumanoid or HitHumanoid:GetAttribute("DownedRagdolling") then return end
   	local originalDamage = Damage
	local HitLimb = "Torso"
	if not LegMultiplier then LegMultiplier = 0.75 end
	--if Killer and Killer.Character and Killer.Character == HitHumanoid.Parent then return end
    if Killer and not HitHumanoid.Parent:GetAttribute("TestRig") then
		HitHumanoid.Parent:SetAttribute("InCombat", true)
		HitHumanoid:SetAttribute("InCombat", true)
		HitHumanoid:SetAttribute("Killer", Killer.Name)

		local hitPlayer = game.Players:GetPlayerFromCharacter(HitHumanoid.Parent)
		if Killer ~= hitPlayer and TeamHandler.Check(Killer,hitPlayer) == 0 then return end
	end

	local Absorption = HitHumanoid:GetAttribute("Absorption") or 0

    if HitPart then
        HitLimb = getLimb(HitPart)
        if HeadshotFactor and HitLimb == "Head" then
			--if HelmetHit and HitHumanoid:GetAttribute("HelmetHealth") and HitHumanoid:GetAttribute("HelmetHealth") > 0 then
			--	Damage = ArmorDamage(HitHumanoid, "HelmetHealth", Damage, false)
			--	Damage = Damage+(originalDamage*HeadshotFactor)
			--else
			Damage = Damage + (originalDamage * HeadshotFactor)
			--end
		elseif HitLimb == "Leg" and not noLimbDamageAdjust then
			Damage = Damage * LegMultiplier
		end
    end
  --  if VestHit and HitHumanoid:GetAttribute("VestHealth") > 0 and HitHumanoid:GetAttribute("VestType") > 0 then
   --     if HitHumanoid:GetAttribute("VestType") == 1 and HitLimb == "Torso" or
   --         HitHumanoid:GetAttribute("VestType") == 2 and (HitLimb == "Torso" or HitLimb == "Arm") or
   --         HitHumanoid:GetAttribute("VestType") == 3 and (HitLimb == "Torso" or HitLimb == "Arm" or HitLimb == "Leg") then
   --         Damage = ArmorDamage(HitHumanoid, "VestHealth", Damage, true)
   --     end
   -- end
	if Blood and Direction and HitPart then
		BloodEvent:FireAllClients(Direction, HitPart.Position, HitHumanoid.Parent, HitPart.Parent, Damage)
	end -- CAUSES LAG

	if Absorption > Damage and Absorption > 0 then
		HitHumanoid:SetAttribute("Absorption", math.abs(Damage - Absorption))
	else
		HitHumanoid:SetAttribute("Absorption", 0)
	end

	Damage = math.clamp(Damage - Absorption, 0, math.huge)
	Damage = math.round(Damage)
	
	if Damage >= HitHumanoid.Health then -- Disabled downing until it works properly
		--if CanDown and HitLimb ~= "Head" and not HitHumanoid:GetAttribute("DownedOnce") and HitHumanoid.Health > 0 then
		--	HitHumanoid:SetAttribute("DownStart", CanDown)
		--	HitHumanoid.Health = 0.001
		--else
			HitHumanoid.Health = 0
		--end
    else
        HitHumanoid:TakeDamage(Damage)
	end
	
	if HitHumanoid.Health <= 0 then
		if HitHumanoid.Parent:FindFirstChildOfClass("Tool") then
			HitHumanoid:UnequipTools()
		end
		if HitPart and Direction and not HitPart.Anchored and HitHumanoid.Health <= 0 then
			HitPart:SetNetworkOwner()
			CTF.applyForce(HitPart,Direction*3*Damage,0.2)
		end
		if GibChance and HitPart and Direction and math.random(1, 100) <= GibChance * 100 then
			
			if GibChance * 100  >= 200 then --/ Annihilation gib will now take place
				if pickRandomLimbsToGib(HitHumanoid.Parent,{0,0}) then
					for _,AnnihilationHitPart in pairs(pickRandomLimbsToGib(HitHumanoid.Parent,AnnihilationRange)) do
						GoreEvent:FireAllClients(AnnihilationHitPart, HitHumanoid.Parent, Sever, Direction)
					end
				end
			else --/ Normal gib
				GoreEvent:FireAllClients(HitPart, HitHumanoid.Parent, Sever, Direction)
			end
			
		end
	end
	
    if Twitch then
        local twitchAnim = Instance.new("Animation")
		twitchAnim.AnimationId = "rbxassetid://" .. twitchAnimTable[Random.new():NextInteger(1, #twitchAnimTable)]
		local twitch = HitHumanoid:LoadAnimation(twitchAnim)
		twitch.Priority = Enum.AnimationPriority.Action4
	    twitch:Play(0, 0.3, 1)
		twitchAnim:Destroy()
    end
end
return module
