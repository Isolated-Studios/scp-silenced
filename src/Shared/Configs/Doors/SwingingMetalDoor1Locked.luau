return {
	LeftDoorOpen = {"LookVector",0,Vector3.new(0,0,0)};
	RightDoorOpen = {"LookVector",0,Vector3.new(0,0,0)};

	OpenSpeed = 0.1;
	CloseSpeed = 0.1;
	Cooldown = 0;
	OpenEasingStyle = Enum.EasingStyle.Quint;
	CloseEasingStyle = Enum.EasingStyle.Bounce;

	LightColors = {
		Color3.fromRGB(107, 154, 96),
		Color3.fromRGB(107, 154, 154),
		Color3.fromRGB(154, 107, 108),
	};
}
