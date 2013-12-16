-- Client Shit (for reloading perposes)
include('cl_init.lua')

-- Shared Files
include('shared.lua')

-- Server shit
include('sv_netshit.lua')
include('sv_rounds.lua')
include('sv_player.lua')
include('sv_names.lua')

function GM:Think()
    -- WAITING FOR PLAYERS
    if theHunt.round == theHunt.ROUND_WAIT then
        -- Check if the game should start
        if CurTime() > theHunt.roundEnd then
            -- Create a new round (the default one)
            NewRound()
        end
    -- ROUND SETUP
    elseif theHunt.round == theHunt.ROUND_SETUP then
        -- Check if the round should start
        if CurTime() > theHunt.roundEnd then
            -- Start the round
            BeginRound()
        end
    elseif theHunt.round == theHunt.ROUND_ACTIVE then
        -- Check if the round should end
        if CurTime() > theHunt.roundEnd then
            -- End the round
            EndRound()
        end
    elseif theHunt.round == theHunt.ROUND_OVER then
        -- Check if it's time for a new round
        if CurTime() > theHunt.roundEnd then
            -- Create a new round
            NewRound()
        end
    end
end
