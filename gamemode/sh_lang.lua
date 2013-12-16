AddCSLuaFile()

-- Ensure we have a hunt table
theHunt = theHunt or {}

local english = {
    -- When BeginRound() is called outside of the setup phase
    roundBeginFailure = 'WARNING: BeginRound() was called while the game was not in setup phase.',

    -- Names of each given round
    roundName = {
        -- When there aren't enough players to start
        [theHunt.ROUND_INIT] = 'Waiting for Players',

        -- Once enough players join, the waiting period for more to join
        [theHunt.ROUND_WAIT] = 'Waiting for Loaders',

        -- When a round is starting (people are reading what to do)
        [theHunt.ROUND_SETUP] = 'Round is Starting',

        -- When a round is underway
        [theHunt.ROUND_ACTIVE] = 'Round in Progress',

        -- When a round has finished and the next one is waiting to start
        [theHunt.ROUND_OVER] = 'Waiting for Next Round'
    },

    roundSort = {
        [1] = 'The Hunt'
    }
}

-- Apply a language
theHunt.lang = english
