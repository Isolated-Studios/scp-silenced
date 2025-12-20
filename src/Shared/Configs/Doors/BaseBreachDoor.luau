return {
	LeftDoorOpen = {
		Vector = "LookVector", 
		Distance = 4, 
		Rotation = Vector3.new(0,0,0)
	};
	RightDoorOpen = {
		Vector = "LookVector", 
		Distance = -4, 
		Rotation = Vector3.new(0,0,0)
	};
	
	OpenSpeed = 3.5;
	CloseSpeed = 0.4;
	Cooldown = 0.2;
	CloseEasingStyle = Enum.EasingStyle.Bounce;

	LightColors = {
		Open = Color3.fromRGB(107, 154, 96),
		Moving = Color3.fromRGB(107, 154, 154),
		Close = Color3.fromRGB(154, 107, 108),
	};
}
