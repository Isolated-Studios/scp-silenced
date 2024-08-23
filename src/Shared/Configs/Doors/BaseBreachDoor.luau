return {
	LeftDoorOpen = {"LookVector",4,Vector3.new(0,0,0)};
	RightDoorOpen = {"LookVector",-4,Vector3.new(0,0,0)};
	
	OpenSpeed = 3.5;
	CloseSpeed = 0.4;
	Cooldown = 0.2;
	CloseEasingStyle = Enum.EasingStyle.Bounce;

	LightColors = {
		Color3.fromRGB(107, 154, 96),
		Color3.fromRGB(107, 154, 154),
		Color3.fromRGB(154, 107, 108),
	};
}
