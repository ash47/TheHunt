-- Round related code can go here

-- Table of the different sorts of rounds
local rounds = {}

rounds[1] = {
    hooks = {
        -- Give random targets (overlapping) on start
        RoundStart = function()
            AssignRandomTargets()
        end,

        -- When a hit is completed, give the killer a new target
        HitComplete = function(ply, wep, killer)
            AssignRandomTarget(killer)
        end,

        -- If they failed their hit, give them a new target
        HitFailed = function(ply)
            AssignRandomTarget(ply)
        end,

        -- If someone connects, give them a random target
        PlayerInitialSpawn = function(ply)
            -- Check if the round has started
            if(IsRoundActive()) then
                -- Give them a random target
                AssignRandomTarget(ply)
            end
        end
    }
}

function RoundPlayerConnect(ply)
    if theHunt.round == theHunt.ROUND_INIT then
        if #player.GetAll() >= theHunt.minPlayers then
            RoundBeginWait()
            return
        end
    end

    -- Send them the round shit to this player
    SendRoundShit(self)
end

function RoundBeginWait()
    -- Change to the waiting round
    theHunt.round = theHunt.ROUND_WAIT

    -- Workout when the round will end
    theHunt.roundEnd = CurTime() + theHunt.waitTime

    -- Clear all targets
    ClearAllTargets()

    -- Cleanup any old hooks
    RemoveRoundHooks()

    -- Send everyone the update
    SendRoundShit()
end

function RemoveRoundHooks()
    -- Remove any old hooks
    if rounds[theHunt.roundSort] then
        for k,v in pairs(rounds[theHunt.roundSort].hooks) do
            hook.Remove(k, 'theHuntRound'..k)
        end
    end
end

function NewRound(data)
    -- Validate data
    data = data or {}
    data.roundLength = data.roundLength or theHunt.roundLength
    data.roundSort = data.roundSort or 1    -- Default to 1 for now, we will evenutally have a round sort generator

    -- Clear all targets
    ClearAllTargets()

    -- Remove any old hooks
    RemoveRoundHooks()

    -- Enter setup time
    theHunt.round = theHunt.ROUND_SETUP
    theHunt.roundEnd = CurTime() + theHunt.roundSetupLength
    theHunt.roundSort = data.roundSort

    -- Hook new hooks
    if rounds[theHunt.roundSort] then
        for k,v in pairs(rounds[theHunt.roundSort].hooks) do
            hook.Add(k, 'theHuntRound'..k, v)
        end
    end

    -- Call the setup hook
    hook.Call('RoundSetup')

    -- Send everyone the updated round shit
    SendRoundShit()
end

function BeginRound()
    -- Make sure we are in the setup phase
    if theHunt.round ~= theHunt.ROUND_SETUP then
        print(theHunt.lang.roundBeginFailure)
        return
    end

    -- Activate the round
    theHunt.round = theHunt.ROUND_ACTIVE
    theHunt.roundEnd = CurTime() + theHunt.roundLength

    -- Call the round Begin Hook
    hook.Call('RoundStart')

    -- Tell everyone
    SendRoundShit()
end

function EndRound()
     -- End the round
    theHunt.round = theHunt.ROUND_OVER
    theHunt.roundEnd = CurTime() + theHunt.roundOverLength

    -- Call the end round hook
    hook.Call('RoundOver')

    -- Clear all targets
    ClearAllTargets()

    -- Cleanup any old hooks
    RemoveRoundHooks()

    -- Tell everyone
    SendRoundShit()
end

function IsRoundActive()
    return theHunt.round == theHunt.ROUND_ACTIVE
end

function SendRoundShit(ply)
    net.Start('RoundShit')
    net.WriteInt(theHunt.round, 4)
    net.WriteFloat(theHunt.roundEnd)
    net.WriteInt(theHunt.roundSort, theHunt.ROUND_SORT_BITCOUNT)

    -- Check if it is being sent to one, or all
    if ply then
        net.Send(ply)
    else
        net.Broadcast()
    end
end