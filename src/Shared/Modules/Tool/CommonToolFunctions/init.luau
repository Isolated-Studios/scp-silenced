local module = {}

--//Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Modules
local BulletHandler = require(script.BulletHandler)
local DropItem = require(script.DropItem)
local SoundsAndEffects = require(script.SoundsAndEffects)
local AnimationEvent = require(script.AnimationEvent)
local Distance = require(script.Distance)
local MovementChanger = require(script.MovementChanger)



function module.createBulletHole (raycastResult,hitPerson,isPellet,randomValue)
	BulletHandler.createBulletHole(raycastResult,hitPerson,isPellet,randomValue)
end

function module.castBullet (Tool,Origin,Direction,TravelSpeed,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue,replicate)
	BulletHandler.castBullet(Tool,Origin,Direction,TravelSpeed,MaxDistance,Acceleration,BulletTemplate,Character,isPellet,randomValue,replicate)
end

function module.breakGlass (HitPosition,HitPart,CasterCFrame,noevent)
	BulletHandler.breakGlass(HitPosition,HitPart,CasterCFrame,noevent)
end

function module.applyForce (HitPart, Force, Time)
	BulletHandler.applyForce(HitPart,Force,Time)
end



function module.playSound (Sounds: Sound | Instance, SoundName: string?, parent: Instance, replicate: boolean, ApplyRandomPitch: boolean | table, Properties: table?)
	SoundsAndEffects.playSound(Sounds,SoundName,parent,replicate,ApplyRandomPitch,Properties)
end

function module.flashGun (FlashPoint, flashLight, sendToServer)
	SoundsAndEffects.flashGun(FlashPoint,flashLight,sendToServer)
end



function module.dropItem (Character,Tool)
	DropItem.dropItem(Character,Tool)
end

function module.getAllAnimationEventNames (animation): table
	return AnimationEvent.getAllAnimationEventNames(animation)
end

function module.HideParts (Hive,Transparency)
	SoundsAndEffects.HideParts(Hive,Transparency)
end

function module.getDistance(point1: Vector3, point2: Vector3)
	return Distance.getDistance(point1, point2)
end

function module.stopRunning (DoesNotAffectInput: boolean)
	MovementChanger.stopRunning(DoesNotAffectInput)
end

return module
