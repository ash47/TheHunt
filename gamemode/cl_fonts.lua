AddCSLuaFile()
if(SERVER) then return end

-- Font for general hud shit
surface.CreateFont( "theHuntHudText", {
    font = "coolvetica",
    size = 32,
    weight = 0,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = true,
    additive = false,
    outline = false,
})

-- The font for the target in the top right corner
surface.CreateFont( "theHuntTarget", {
    font = "coolvetica",
    size = 32,
    weight = 0,
    blursize = 0,
    scanlines = 0,
    antialias = false,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = true,
    additive = false,
    outline = false,
})

-- Font for player name tags
surface.CreateFont( "theHuntPlayerTag", {
    font = "coolvetica",
    size = 48,
    weight = 0,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = true,
    additive = false,
    outline = false,
})
