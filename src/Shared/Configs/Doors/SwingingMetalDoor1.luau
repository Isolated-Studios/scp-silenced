return {
	LeftDoorOpen = {
		Vector = "LookVector", 
		Distance = 0, 
		Rotation = Vector3.new(0,90,0)
	};
	RightDoorOpen = {
		Vector = "LookVector", 
		Distance = 0, 
		Rotation = Vector3.new(0,90,0)
	};

	OpenSpeed = 1;
	CloseSpeed = 0.1;
	Cooldown = 1;
	OpenEasingStyle = Enum.EasingStyle.Quint;
	CloseEasingStyle = Enum.EasingStyle.Bounce;

	LightColors = {
		Open = Color3.fromRGB(107, 154, 96),
		Moving = Color3.fromRGB(107, 154, 154),
		Close = Color3.fromRGB(154, 107, 108),
	};
}
