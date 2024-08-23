return function (registry)
	registry:RegisterHook("BeforeRun", function(context)
		--if context.Group == "DefaultAdmin" and context.Executor.UserId ~= game.CreatorId then
		--	return "You don't have permission to run this command"
		--end
		return nil -- this is a developer-only place anyways, so no need to check permissions.
	end)
end