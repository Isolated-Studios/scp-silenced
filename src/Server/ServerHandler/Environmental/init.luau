local Environmental = {}

function Environmental.Init()
	task.defer(function()
		require(script.AutomaticDoor).Init()
	end)
	
	task.defer(function()
		require(script.Detector).Init()
	end)
end


return Environmental
