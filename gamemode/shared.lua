AddCSLuaFile()

-- Global Table for The Hunt
theHunt = theHunt or {}

-- Different states in a given round
theHunt.ROUND_INIT = 1      -- When the server first loads, before minPlayers is met
theHunt.ROUND_WAIT = 2      -- When the server first loads, and minPlayers has been met, waiting for other players to load
theHunt.ROUND_SETUP = 3     -- When a round has been decided, and people are reading their instructions etc
theHunt.ROUND_ACTIVE = 4    -- When a round is happening
theHunt.ROUND_OVER = 5      -- When a round has finished, and people are waiting for the next round to start

--[[ So it would go like this:
    ROUND_INIT
    ROUND_WAIT
    ROUND_SETUP
    ROUND_ACTIVE
    ROUND_OVER
    ROUND_ACTIVE
    ROUND_OVER
    etc
]]

-- Load language stuff
include('sh_lang.lua')

-- Settings
include('sh_settings.lua')

-- How many bits to use when sending info on the current sort (this will be calcualted automatically evenutally)
theHunt.ROUND_SORT_BITCOUNT = 4

-- Set inital values when the server/client first loads
hook.Add("Initialize", "SharedInit", function()
    -- Start at the init round
    theHunt.round = theHunt.ROUND_INIT

    -- Round start time
    theHunt.roundEnd = CurTime()

    -- The sort of round this is
    theHunt.roundSort = 0
end)


-- Setup teams
