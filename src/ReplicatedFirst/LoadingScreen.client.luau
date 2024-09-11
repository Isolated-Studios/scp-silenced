local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
print("TEMPORARY LOADING SCRIPT")
if not game:IsLoaded() then
	game.Loaded:Wait()
end
ContentProvider:PreloadAsync(ReplicatedStorage:GetDescendants())
print("loaded all assets (probably) and all animations :D")
