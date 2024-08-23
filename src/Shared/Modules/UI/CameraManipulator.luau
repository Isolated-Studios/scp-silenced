local module = {}
local Camera = workspace.CurrentCamera
local Player = game.Players.LocalPlayer
function module.ZoomOut (Zoom)
	Player.CameraMode = Enum.CameraMode.Classic
	Player.CameraMaxZoomDistance = Zoom
	Player.CameraMinZoomDistance = Zoom
end
function module.ZoomFP ()
	Player.CameraMinZoomDistance = 0.5
	Player.CameraMaxZoomDistance = 0.5
	Player.CameraMode = Enum.CameraMode.LockFirstPerson
end
return module
