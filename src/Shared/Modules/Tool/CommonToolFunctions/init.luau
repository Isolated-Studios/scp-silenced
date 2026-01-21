local module = {}

--//Modules
local BulletHandler = require(script.BulletHandler)
local DropItem = require(script.DropItem)
local SoundsAndEffects = require(script.SoundsAndEffects)
local AnimationEvent = require(script.AnimationEvent)
local Distance = require(script.Distance)
local MovementChanger = require(script.MovementChanger)

-- BulletHandler.createBulletHole(raycastResult, hitPerson, isPellet, randomValue)
module.createBulletHole = BulletHandler.createBulletHole

-- BulletHandler.castBullet(Tool, Origin, Direction, TravelSpeed, MaxDistance, Acceleration, BulletTemplate, Character, isPellet, randomValue, replicate)
module.castBullet = BulletHandler.castBullet

-- BulletHandler.breakGlass(HitPosition, HitPart, CasterCFrame, noevent)
module.breakGlass = BulletHandler.breakGlass

-- BulletHandler.applyForce(HitPart, Force, Time)
module.applyForce = BulletHandler.applyForce

-- SoundsAndEffects.playSound(Sounds, SoundName, parent, replicate, ApplyRandomPitch, Properties)
module.playSound = SoundsAndEffects.playSound

-- SoundsAndEffects.flashGun(FlashPoint, flashLight, sendToServer)
module.flashGun = SoundsAndEffects.flashGun

-- DropItem.dropItem(Character, Tool)
module.dropItem = DropItem.dropItem

-- AnimationEvent.getAllAnimationEventNames(animation)
module.getAllAnimationEventNames = AnimationEvent.getAllAnimationEventNames

-- SoundsAndEffects.HideParts(Hive, Transparency)
module.HideParts = SoundsAndEffects.HideParts

-- Distance.getDistance(point1, point2)
module.getDistance = Distance.getDistance

-- MovementChanger.stopRunning(DoesNotAffectInput)
module.stopRunning = MovementChanger.stopRunning

return module
