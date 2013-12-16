-- Genders
local gender_male = 1
local gender_female = 2

local models = {
    [gender_female] = {
        'models/player/Group01/Female_01.mdl',
        'models/player/Group01/Female_02.mdl',
        'models/player/Group01/Female_03.mdl',
        'models/player/Group01/Female_04.mdl',
        'models/player/Group01/Female_05.mdl',
        'models/player/Group01/Female_06.mdl'
    },
    [gender_male] = {
        'models/player/Group01/Male_01.mdl',
        'models/player/Group01/Male_02.mdl',
        'models/player/Group01/Male_03.mdl',
        'models/player/Group01/Male_04.mdl',
        'models/player/Group01/Male_05.mdl',
        'models/player/Group01/Male_06.mdl',
        'models/player/Group01/Male_07.mdl',
        'models/player/Group01/Male_08.mdl'
    }
}

function GM:PlayerInitialSpawn(ply)
    -- Reset their vars
    ply.killTarget = NULL   -- Their actual target
    ply.hitmen = {}         -- List of hitmen after them
    ply.freeAttack = {}     -- List of players that can free attack this player

    -- Do round related shit with this player
    RoundPlayerConnect(ply)

    -- Give a new identiy
    IdentityNew(ply)
end

function GM:PlayerSpawn(ply)
    -- Check if they need a new identity
    if ply.needsNewIdentity then
        -- They don't anymore
        ply.needsNewIdentity = false

        -- Give them a new identity
        IdentityNew(ply)
    end

    IdentityApply(ply)
end

function GM:PlayerDeath(ply, wep, killer)
    -- Check if it was RDM
    if ply == killer then
        -- Noob, lose a point

    elseif ply.hitmen[killer] then
        -- Hit was successful!

        -- Give points

        -- Remove points etc

        -- Remove this killer from the list of valid hitmen for the player
        ply.hitmen[killer] = nil

        -- Tell the player they are done
        HitCompleted(ply, wep, killer)
    elseif ply.freeAttack[killer] then
        -- It is a free kill if the killer was attacked by the player

        -- This player can't be free killed by the same dude again
        SetFreeAttack(killer, ply, false)

        -- Award a point, remove a point etc

    else
        -- RDM
        print('RDM')

        -- Remove points

        -- Time to ban this user?

        -- Call RDM Hook
        hook.Call('RDMKill', nil, ply, wep, killer)
    end

    ply.forceSpawn = CurTime() + theHunt.respawnTime
end

function GM:PlayerDeathThink(ply)
    -- Check if it's time to respawn yet
    if CurTime() >= (ply.forceSpawn or CurTime()) then
         -- Queue them for a new identity
         ply.needsNewIdentity = true

        -- Respawn Them
        ply:Spawn()
    end

    -- Stop default respawn
    return false
end

function GM:PlayerDisconnected(ply)
    -- Mark this player as an invalid target
    ply.disconnecting = true

    for k,v in pairs(ply.hitmen) do
        -- Check if this is still our target
        if(k.killTarget == ply) then
            -- Hit Completed
            HitFailed(k)
        end
    end
end

function GM:EntityTakeDamage(target, dmginfo)
    local attacker = dmginfo:GetAttacker()

    -- We only care about PvP damage
    if target:IsPlayer() and attacker:IsPlayer() then
        -- Check if it's RDM
        if (not target.hitmen[attacker]) and (not target.freeAttack[attacker]) then
            -- The target can FreeAttack attacker
            SetFreeAttack(target, attacker, true)

            -- Call the RDM hook
            hook.Call('RDMHurt', nil, target, dmginfo)
        end
    end
end

-- The `target` can kill `freeKill` without it being RDM
function SetFreeAttack(target, freeKill, state)
    -- Check if we are changing the state
    if state and (not freeKill.freeAttack[target]) then
        -- Store the change
        freeKill.freeAttack[target] = true

        -- Notify the player
        net.Start('freeAttack')
        net.WriteEntity(freeKill)
        net.WriteBit(true)
        net.Send(target)

        print('a')
    elseif (not state) and freeKill.freeAttack[target] then
        -- Store the change
        freeKill.freeAttack[target] = false

        -- Notify the player
        net.Start('freeAttack')
        net.WriteEntity(freeKill)
        net.WriteBit(false)
        net.Send(target)

        print('b')
    end

    print('c')
    print(state)
    print(freeKill.freeAttack[target])
end

-- Creates a bew identity for a player
function IdentityNew(ply)
    -- Pick a gender
    if math.random() > 0.5 then
        ply.gender = gender_male
        ply.fakeName = GetMaleName()..' '..GetSurname()
    else
        ply.gender = gender_female
        ply.fakeName = GetFemaleName()..' '..GetSurname()
    end

    -- Build new identity
    ply.playerModel = table.Random(models[ply.gender])
    ply.playerColor = Vector(math.random(), math.random(), math.random())

    -- Apply their identity
    IdentityApply(ply)
end

function IdentityApply(ply)
    -- Apply new identity
    ply:SetModel(ply.playerModel)
    ply:SetPlayerColor(ply.playerColor)

    -- Tell everyone this player's name
    ply:SetNetworkedString('fakeName', ply.fakeName)

    -- Update all the hitmen of this player
    UpdateHitmen(ply)
end

function AssignTarget(ply, target)
    -- Make sure both are valid
    if (not ply) or (not target) then return end

    -- Remove this player as a hitman of the old target
    if ply.killTarget and ply.killTarget:IsValid() then
        ply.killTarget.hitmen[ply] = nil
    end

    -- Add to the new hitman's list
    target.hitmen[ply] = true

    -- Update to the new players target
    ply.killTarget = target

    -- Only bother telling the player about their new hit, if their target is alive
    -- Once their target respawns, they will be told the updated info anyways
    if target:Alive() and target:Health() > 0 then
        -- Tell the player
        net.Start('NewTarget')
        net.WriteEntity(target)
        net.WriteString(target.fakeName or '')
        net.WriteString(target.playerModel or '')
        net.WriteVector(target.playerColor or Vector(1, 1, 1))
        net.Send(ply)
    end
end

-- When a player gets a new identity, we need to tell the hitmen
function UpdateHitmen(target)
    -- Build the message
    net.Start('NewTarget')
    net.WriteEntity(target)
    net.WriteString(target.fakeName or '')
    net.WriteString(target.playerModel or '')
    net.WriteVector(target.playerColor or Vector(1, 1, 1))

    for k,v in pairs(target.hitmen) do
        net.Send(k)
    end
end

function ClearAllTargets()
    for k, v in pairs(player.GetAll()) do
        -- Reset Hitmen List
        v.hitmen = {}

        -- Reset Kill Target
        v.killTarget = NULL
    end

    -- Update all targets
    net.Start('NewTarget')
    net.WriteEntity(NULL)
    net.Broadcast()
end

function AssignRandomTargets()
    local playerList = GetValidHitList()
    if #playerList < 2 then return end

    for k,v in pairs(playerList) do
        -- Pick a target for each player (NOTE: Targets can overlap, but can never be the player itself)
        local target
        repeat
            target = table.Random(playerList)
        until target ~= v

        AssignTarget(v, target)
    end
end

function AssignRandomTarget(ply)
    local playerList = GetValidHitList()
    if #playerList < 2 then return end

    -- Pick a target for this player
    local target
    repeat
        target = table.Random(playerList)
    until target ~= ply

    -- Assign the new target
    AssignTarget(ply, target)
end

function GetValidHitList()
    local hitList = {}
    for k,v in pairs(player.GetAll()) do
        if not v.disconnecting then
            table.insert(hitList, v)
        end
    end

    return hitList
end

function HitCompleted(ply, wep, killer)
    net.Start('HitComplete')
    net.Send(killer)

    -- Call Hit Complete hook
    hook.Call('HitComplete', nil, ply, wep, killer)
end

function HitFailed(ply)
    net.Start('HitFailed')
    net.Send(ply)

    -- Call Hit Complete hook
    hook.Call('HitFailed', nil, ply)
end