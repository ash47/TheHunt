AddCSLuaFile()

-- Global Table for The Hunt
theHunt = theHunt or {}

-- Round length (in seconds)
theHunt.roundLength = 120

-- Round setup phase (Where it gives instructions) (in seconds)
theHunt.roundSetupLength = 5

-- How long does the 'round over' bit last (time between rounds)
theHunt.roundOverLength = 5

-- The amount of time to wait for players to connect (in seconds)
theHunt.waitTime = 1

-- The minimal number of players before the wait period begins (shit might get real if you set to < 2)
theHunt.minPlayers = 2

-- How close players have to be to see other players names
theHunt.nameShowDistance = 300

-- How long before a player respawns
theHunt.respawnTime = 3
