--!nonstrict

-- // Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- // Debug
local DEBUG:boolean = true -- prints debug statements
local gameStatus: string = "" -- shows what the script is doing
local checkForVictory: boolean = false -- check for victory (Self explanatory)
local intermissionTime: number = 30 -- time between rounds
local roundStartTime: number = 5 -- time it takes for the game to start checking for wins after the round has started

-- // Team settings
local CD_FRACTION: number = 2.1 -- you can change this during runtime
local SCPF_FRACTION: number = 2 -- you can change this during runtime
-- keep in mind that SCP players are assigned based on whoever is left, see the assignTeams functions for more info

-- // Important
local gameInProgress: boolean = false -- whether or not the game is in progress
local gameOver: boolean = false -- whether or not the game is over

-- // Functions
local function printDebug(msg: string)
	if DEBUG then
		print("[DEBUG] "..script.Name": "..msg)
	end
end

local function assignTeams()
	gameStatus = "assigning teams"
	printDebug("Assigning teams...")
	
	local numberOfPlayers: number = #Teams.Lobby:GetPlayers()

	local CD_Players = math.floor(numberOfPlayers / CD_FRACTION)
	numberOfPlayers -= CD_FRACTION
	
	local SCPF_Players = math.floor(numberOfPlayers / SCPF_FRACTION)
	numberOfPlayers -= SCPF_FRACTION

	local SCP_Players = numberOfPlayers -- everyone else

	local Players = Teams.Lobby:GetPlayers()
	
	-- assign CD
	for i = 1, CD_Players do
		local ChosenPlr = math.random(#Players)
		local AssignedPlr = Players[ChosenPlr]
		table.remove(Players, ChosenPlr)	
		
		AssignedPlr.Team = game.Teams.CD
	end
	
	-- assign SCPF
	for i = 1, SCPF_Players do
		local ChosenPlr = math.random(#Players)
		local AssignedPlr = Players[ChosenPlr]
		table.remove(Players, ChosenPlr)	

		AssignedPlr.Team = game.Teams.SCPF
	end

	-- assign SCP
	for i = 1, SCP_Players do
		local ChosenPlr = math.random(#Players)
		local AssignedPlr = Players[ChosenPlr]
		table.remove(Players, ChosenPlr)	

		AssignedPlr.Team = game.Teams.SCP
	end
	
	printDebug("Teams assigned!")
	gameStatus = "finished assigning teams"
end

local function checkForVictory()
	local PentagramRemaining: number = Teams.Pentagram:GetPlayers()
	local D9Remaining: number = Teams.D9:GetPlayers()
	local CDRemaining: number = Teams.CD:GetPlayers()
	local GOCRemaining: number = Teams.GOC:GetPlayers()
	local SCPRemaining: number = Teams.SCP:GetPlayers()
	local SCPFRemaining: number = Teams.SCPF:GetPlayers()
	local CIRemaining: number = Teams.CI:GetPlayers()

	

end