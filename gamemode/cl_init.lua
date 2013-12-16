AddCSLuaFile()

include('shared.lua')
include('cl_rounds.lua')
include('cl_fonts.lua')

if(SERVER) then return end

-- Global Table for The Hunt
theHunt = theHunt or {}

-- Free Attack Table
theHunt.freeAttack = theHunt.freeAttack or {}

-- Stores what we are drawing as the enemies health (used to do that white shit)
local enemyHealth = 0
if theHunt.myTarget and theHunt.myTarget:IsValid() then
    enemyHealth = theHunt.myTarget:Health()
end

-- Used to draw the circle to indicate a new target
local updatingTarget = 0

local LastCamPos = LastCamPos or Vector(0,0,0)
local LastCamAng = LastCamAng or Angle(0, 0, 0)

local drawingMiniMap = false

local targetSize = 256
local targetPadding = 8
local targetx = ScrW() - targetSize - targetPadding
local targety = targetPadding

local targetFrame = theHunt.targetFrame
local targetFrameModel = theHunt.targetFrameModel
local targetFrameText = theHunt.targetFrameText
local targetKilledImage = theHunt.targetKilledImage
function BuildTargetPanel()
    -- Create new frame if it doesn't exist
    if not targetFrame or not targetFrame:IsValid() then
        targetFrame = vgui.Create('DPanel')
        targetFrame:SetPos(targetx, targety)
        targetFrame:SetSize(targetSize, targetSize)
        targetFrame:SetVisible(false)

        -- Create model panel
        targetFrameModel = vgui.Create('DModelPanel', targetFrame)
        targetFrameModel:Dock(FILL)
        targetFrameModel:SetCamPos(Vector(0, 0, 0))
        targetFrameModel:SetLookAt(Vector(-100, 0, 0))
        targetFrameModel:SetFOV(36)

        -- Stop rotation of target
        function targetFrameModel:LayoutEntity(ent)end

        -- Target Name Text
        targetFrameText = vgui.Create('DLabel', targetFrame)
        targetFrameText:SetFont('theHuntTarget')
        targetFrameText:SetTextColor(Color(100, 255, 100, 255))

        -- The image to render when a target is killed
        targetKilledImage = vgui.Create('DPanel', targetFrame)
        targetKilledImage:Dock(FILL)
        function targetKilledImage:Paint()
            -- Check if the hit is completed
            if(theHunt.hitComplete) then
                surface.SetDrawColor(0, 0, 0, 255)
                surface.DrawLine(0, 0, targetSize, targetSize)
            end
        end

        -- Store globally
        theHunt.targetFrame = targetFrame
        theHunt.targetFrameModel = targetFrameModel
        theHunt.targetFrameText = targetFrameText
    end
end
-- Build the frame
BuildTargetPanel()

function UpdateTargetPanel()
   if theHunt.myTarget and theHunt.myTarget:IsValid() then
        -- Update text
        targetFrameText:SetText(theHunt.targetName)
        targetFrameText:SizeToContents()
        targetFrameText:CenterHorizontal()
        targetFrameText:AlignBottom()

        -- Size it, stick the model in, etc
        targetFrameModel:SetModel(theHunt.targetModel)
        targetFrameModel.Entity:SetPos(Vector( -30, 0, -62 ))
        targetFrameModel.Entity:SetAngles(Angle(0, 0, 0))

        local realColor = theHunt.targetColor
        -- Update the color of the model in the frame
        function targetFrameModel.Entity:GetPlayerColor()
            return realColor
        end

        -- Make the frame visible
        targetFrame:SetVisible(true)
    else
        -- Not a valid target, make target pain invisible
        targetFrame:SetVisible(false)
    end
end

local function ActuallyUpdateTargetPanel()

end

-- Server just sent us a new target
net.Receive('NewTarget', function(len)
    -- Read in our new target
    theHunt.myTarget = net.ReadEntity()
    theHunt.targetName = net.ReadString()
    theHunt.targetModel = net.ReadString()
    theHunt.targetColor = net.ReadVector()

    -- Null it out if we got the world
    if theHunt.myTarget and theHunt.myTarget:IsWorld() then
        theHunt.myTarget = null
    end

    -- Check for enemy health
    if theHunt.myTarget and theHunt.myTarget:IsValid() then
        enemyHealth = theHunt.myTarget:Health()
    end

    -- Update the target panel
    UpdateTargetPanel()

    -- Hit is no longer completed
    theHunt.hitComplete = false
end)

-- Server said we completed the hit
net.Receive('HitComplete', function(len)
    -- Set the hit to completed
    theHunt.hitComplete = true
end)

-- Server said we failed the hit
net.Receive('HitFailed', function(len)
    -- Set the hit to complete (for now)
    theHunt.hitComplete = true
end)

-- Server said we can free kill someone
net.Receive('freeAttack', function(len)
    -- Set the hit to completed
    theHunt.freeAttack[net.ReadEntity()] = tobool(net.ReadBit())
end)

function GM:HUDPaint()
    DrawMiniMap()

    local roundState = theHunt.lang.roundName[theHunt.round] or ''
    local roundSort = theHunt.lang.roundSort[theHunt.roundSort] or ''

    surface.SetFont('theHuntHudText')
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.SetTextPos(4, 4);
    surface.DrawText(roundState..', '..math.ceil(theHunt.roundEnd-CurTime())..' - '..roundSort);

    -- Check if we have a target
    if (not theHunt.hitComplete) and theHunt.myTarget and theHunt.myTarget:IsValid() then
        local x = targetx
        local y = targety + targetSize + targetPadding
        local hpWidth = targetSize
        local hpHeight = 32
        local hpOutlineColor = Color(0, 0, 0, 255)
        local colorHPTop = Color(255, 128, 128, 255)
        local colorHPBot = Color(255, 64, 64, 255)
        local colorHPFade = Color(255, 255, 255, 255)

        -- Draw a HP Bar for them
        enemyHealth = DuelBox(1, x, y, hpWidth, hpHeight, hpOutlineColor, colorHPTop, colorHPBot, colorHPFade, enemyHealth or theHunt.myTarget:Health(), theHunt.myTarget:Health(), 100)
    end
end

function DrawMiniMap()
    -- Draw minimap
    drawingMiniMap = true

    local ply = LocalPlayer()
    local pos = ply:GetPos() + Vector(0, 0, 100)

    local CamData = {}
    CamData.angles = Angle(90, ply:EyeAngles().yaw, 0)
    CamData.origin = pos--camPos
    CamData.x = targetPadding
    CamData.y = targetPadding
    CamData.w = ScrW() / 4
    CamData.h = ScrH() / 4
    local m = 2
    CamData.ortholeft = -CamData.w*m
    CamData.orthoright = CamData.w*m
    CamData.orthotop = -CamData.h*m
    CamData.orthobottom = CamData.h*m
    CamData.ortho = true
    CamData.drawviewmodel = false

    LastCamPos = CamData.origin
    LastCamAng = CamData.angles

    local matOutline = Material("vgui/black")

    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
    render.SetStencilZFailOperation( STENCILOPERATION_REPLACE )
    render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
    render.SetStencilReferenceValue( 1 )

    render.RenderView(CamData)

    render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
    render.SetMaterial( matOutline )
    render.DrawScreenQuad()
    render.SetStencilEnable( false )

    for k,v in pairs(player.GetAll()) do
        local pos = v:GetPos():ToMiniMap()

        local maxWidth = ScrW() / 4
        local maxHeight = ScrH() / 4

        if pos.x < 0 then pos.x = 0 end
        if pos.x > maxWidth then pos.x = maxWidth end

        if pos.y < 0 then pos.y = 0 end
        if pos.y > maxHeight then pos.y = maxHeight end


        local w = 32
        local h = 32
        local x = targetPadding + pos.x - w/2
        local y = targetPadding + pos.y - h/2

        surface.SetDrawColor(Color(0, 255, 0, 255))
        surface.DrawRect(x, y, w, h)
    end

    drawingMiniMap = false
end

-- Name Tag Colors
local COLOR_PLAYER_SAFE = Color(255, 255, 255, 255) -- Killing this player will count as RDM
local COLOR_PLAYER_KOS = Color(255, 0, 0, 255)      -- Killing this player will earn you a point

function GM:PostDrawOpaqueRenderables()
    -- Check if this is for the minimap
    if drawingMiniMap then
        return
    end

    -- Render player names above their heads
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetFont("theHuntPlayerTag")
    surface.SetTextPos(0, 0)

    local plyPos = LocalPlayer():EyePos()

    -- Render player names above their heads (if close enough)
    for k,v in pairs(player.GetAll()) do
        -- Make sure it isn't our local player
        if v ~= LocalPlayer() and v:Alive() then
            local pos = v:EyePos()

            -- Check if they are in range
            if plyPos:Distance(pos) < theHunt.nameShowDistance then
                -- Workout the angle so we can see it
                local ang = LocalPlayer():EyeAngles()
                ang:RotateAroundAxis( ang:Forward(), 90 )
                ang:RotateAroundAxis( ang:Right(), 90 )

                -- Grab the text color
                local textColor

                if theHunt.freeAttack[v] then
                    textColor = COLOR_PLAYER_KOS
                else
                    textColor = COLOR_PLAYER_SAFE
                end

                -- Render the label
                cam.Start3D2D(pos+Vector(0, 0, 12), Angle( 0, ang.y, 90 ), 0.1);
                    draw.DrawText(v:GetNetworkedString('fakeName'), 'theHuntPlayerTag', 0, 0, textColor, TEXT_ALIGN_CENTER)
                cam.End3D2D();
            end
        end
    end
end

local shitToHide = {
    CHudHealth = true,
    CHudBattery = true,
    CHudAmmo = true,
    CHudWeapon = true
}
function GM:HUDShouldDraw(name)
    if shitToHide[name] then
        return false
    end
    return true
end

-- Draws a two colour sexy looking bar:
function DuelBox(border, x, y, width, height, bg, top, bottom, fade, display_value, actual_value, max_value)
    -- Calculate the new display value:
    display_value = math.min(number_moveto(display_value, actual_value, max_value * FrameTime()), max_value)

    -- Workout drawing:
    local _width = (width - 2*border)*math.Clamp(display_value/max_value, 0, 1)
    local _width2 = (width - 2*border)*math.Clamp(actual_value/max_value, 0, 1)

    -- Draw the background:
    draw.RoundedBox(border, x, y, width, height, bg)

    if _width > _width2 then
        -- Draw the fading section:
        draw.RoundedBox(border, x+border, y+border, _width, height-2*border, fade)
    end

    if actual_value > 0 then
        -- Draw the coloured section:
        Gradient(x+border, y+border, math.min(_width, _width2), height - border*2, bottom, top)
        --draw.RoundedBoxEx(border, x+border, y+border, math.min(_width, _width2), height/2 - border, top, true, true, false, false)
        --draw.RoundedBoxEx(border, x+border, y + height/2, math.min(_width, _width2), height/2 - border, bottom, false, false, true, true)
    end

    -- Return the new display value:
    return display_value
end

-- Draws a gradient:
local mat_grad = Material("vgui/gradient-u")
function Gradient(x, y, w, h, col1, col2)
    -- Background segment:
    surface.SetDrawColor(col1)
    surface.DrawRect(x, y, w, h)

    -- Gradient segment:
    surface.SetDrawColor(col2)
    surface.SetMaterial(mat_grad)
    surface.DrawTexturedRect(x, y, w, h)
end

-- returns a number that is moved partially towards another number:
function number_moveto(start, aim, move)
    if start ~= aim then
        if start < aim then
            start = start + move
            if start > aim then
                start = aim
            end
        else
            start = start - move
            if start < aim then
                start = aim
            end
        end
    end

    return start
end


-- Vector Extensions:
local meta = FindMetaTable("Vector")

function meta:ToMiniMap()
    local scrW = ScrW() / 4
    local scrH = ScrH() / 4

    local vDir = LastCamPos - self + Vector(0, 0, 850)

    local fdp = LastCamAng:Forward():Dot( vDir )

    if ( fdp == 0 ) then
        return {x=0, y=0}--, false, false
    end

    local d = 4 * scrH / (6 * math.tan(math.rad( 0.5 * LocalPlayer():GetFOV())))
    local vProj = ( d / fdp ) * vDir

    local x = 0.5 * scrW + LastCamAng:Right():Dot( vProj )
    local y = 0.5 * scrH - LastCamAng:Up():Dot( vProj )

    return {x=x, y=y}--, ( 0 < x && x < scrW && 0 < y && y < scrH ) && fdp < 0, fdp > 0
end