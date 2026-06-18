-- SoundManager: procedural audio synthesis using love.audio
-- Ports SoundManager.swift — generates waveforms at runtime, no asset files

local Audio = {}

Audio.muted = false
Audio.ambientSource = nil
Audio.sampleRate = 44100

-- Generate a short whoosh sound (card deal)
function Audio.playCardDeal()
    if Audio.muted then return end
    if not love or not love.audio then return end

    -- Generate a short filtered noise burst (120ms)
    local duration = 0.12
    local samples = math.floor(Audio.sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, Audio.sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / samples
        -- Noise with envelope
        local env = math.exp(-t * 8) * (1 - t * 0.3)
        local noise = (math.random() * 2 - 1) * env * 0.15
        -- Low-pass filter approximation (simple moving average)
        if i > 2 then
            local prev = soundData:getSample(i - 1) or 0
            noise = (noise + prev * 0.6) / 1.6
        end
        soundData:setSample(i, noise)
    end

    local source = love.audio.newSource(soundData)
    source:setVolume(0.4)
    source:play()
end

-- Generate a chip clink (1200 Hz + 2880 Hz overtone, 250ms)
function Audio.playChipClink()
    if Audio.muted then return end
    if not love or not love.audio then return end

    local duration = 0.25
    local samples = math.floor(Audio.sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, Audio.sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / Audio.sampleRate
        local env = math.exp(-t * 6)
        -- Fundamental 1200 Hz + overtone 2880 Hz
        local fundamental = math.sin(2 * math.pi * 1200 * t) * 0.3
        local overtone = math.sin(2 * math.pi * 2880 * t) * 0.1
        local sample = (fundamental + overtone) * env * 0.5
        soundData:setSample(i, sample)
    end

    local source = love.audio.newSource(soundData)
    source:setVolume(0.3)
    source:play()
end

-- Ambient bass drone (E2 82.4 Hz, 4s loop)
function Audio.startAmbient()
    if Audio.muted then return end
    if not love or not love.audio then return end
    if Audio.ambientSource then return end  -- already playing

    local duration = 4.0
    local samples = math.floor(Audio.sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, Audio.sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / Audio.sampleRate
        -- E2 82.4 Hz with slow amplitude modulation
        local fundamental = math.sin(2 * math.pi * 82.4 * t) * 0.5
        local subharmonic = math.sin(2 * math.pi * 41.2 * t) * 0.2
        local am = 0.7 + 0.3 * math.sin(2 * math.pi * 0.25 * t)  -- slow tremolo
        local sample = (fundamental + subharmonic) * am * 0.08
        soundData:setSample(i, sample)
    end

    Audio.ambientSource = love.audio.newSource(soundData)
    Audio.ambientSource:setLooping(true)
    Audio.ambientSource:setVolume(0.15)
    Audio.ambientSource:play()
end

function Audio.stopAmbient()
    if Audio.ambientSource then
        Audio.ambientSource:stop()
        Audio.ambientSource = nil
    end
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