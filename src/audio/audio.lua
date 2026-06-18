-- SoundManager: procedural audio synthesis (no asset files)
-- Ports SoundManager.swift

local Audio = {}

Audio.muted = false
Audio.ambientSource = nil

-- Generate a short whoosh for card deal
function Audio.playCardDeal()
    if Audio.muted then return end
    -- TODO: implement with love.audio when running in LÖVE2D
    -- For now, this is a stub that works headless
end

-- Generate a chip clink (1200 Hz + 2880 Hz overtone, 250ms)
function Audio.playChipClink()
    if Audio.muted then return end
end

-- Ambient bass drone (E2 82.4 Hz, 4s loop)
function Audio.startAmbient()
    if Audio.muted then return end
end

function Audio.stopAmbient()
end

function Audio.toggleMute()
    Audio.muted = not Audio.muted
    if Audio.muted then
        Audio:stopAmbient()
    else
        Audio:startAmbient()
    end
    return Audio.muted
end

return Audio