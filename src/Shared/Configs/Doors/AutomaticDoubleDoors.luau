return {
	LeftDoorOpen = {"RightVector",-3.2,Vector3.new(0,0,0)};
	RightDoorOpen = {"RightVector",3.2,Vector3.new(0,0,0)};
	
	LightColors = {
		Open = Color3.fromRGB(107, 154, 96),
		Moving = Color3.fromRGB(107, 154, 154),
		Closed = Color3.fromRGB(154, 107, 108),
	};
	DoorSettings = {
		OpenSpeed = 2;
		CloseSpeed = 2;
		Cooldown = 1;
		OpenEasingStyle = Enum.EasingStyle.Quad;
		CloseEasingStyle = Enum.EasingStyle.Quad;
	}
}
