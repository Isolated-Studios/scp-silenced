return {
	LeftDoorOpen = {
		Vector = "LookVector", 
		Distance = 0, 
		Rotation = Vector3.new(0,0,0)
	};
	RightDoorOpen = {
		Vector = "LookVector", 
		Distance = 0, 
		Rotation = Vector3.new(0,0,0)
	};

	OpenSpeed = 0.1;
	CloseSpeed = 0.1;
	Cooldown = 0.1;
	OpenEasingStyle = Enum.EasingStyle.Linear;
	CloseEasingStyle = Enum.EasingStyle.Linear;

	LightColors = {
		Color3.fromRGB(107, 154, 96),
		Color3.fromRGB(107, 154, 154),
		Color3.fromRGB(154, 107, 108),
	};
}
