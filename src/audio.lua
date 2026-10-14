local config = require("src.config")

local CHECKPOINT_NOTES = { 440.0, 554.37, 659.25, 880.0 }
local VICTORY_NOTES = { 523.25, 659.25, 783.99, 1046.5, 880.0, 1046.5 }

local Audio = {
    sounds = {},
    musicSource = nil,
    sampleRate = 44100,
    initialized = false,
}

local function clamp(val, min_v, max_v)
    if val < min_v then return min_v end
    if val > max_v then return max_v end
    return val
end

local function createSound(generator, duration, volume)
    volume = volume or 0.6
    local sampleRate = Audio.sampleRate
    local totalSamples = math.floor(sampleRate * duration)
    local sd = love.sound.newSoundData(totalSamples, sampleRate, 16, 1)

    for i = 0, totalSamples - 1 do
        local t = i / sampleRate
        local p = i / totalSamples
        local s = generator(t, p)
        s = clamp(s * volume, -0.99, 0.99)
        sd:setSample(i, s)
    end

    return love.audio.newSource(sd)
end

function Audio.init()
    if Audio.initialized then return end

    Audio.sounds.jump = createSound(function(t, p)
        local freq = 260 + p * 380
        local env = (1.0 - p) ^ 1.4
        return math.sin(2 * math.pi * freq * t) * env
    end, 0.14, 0.45)

    Audio.sounds.shoot = createSound(function(t, p)
        local freq = 820 * (1.0 - p * 0.7)
        local noise = (math.random() * 2 - 1) * 0.4
        local env = math.exp(-p * 9)
        return (math.sin(2 * math.pi * freq * t) * 0.6 + noise) * env
    end, 0.12, 0.5)

    Audio.sounds.hit = createSound(function(t, p)
        local thump = math.sin(2 * math.pi * 140 * t) * 0.7
        local noise = (math.random() * 2 - 1) * 0.5
        local env = math.exp(-p * 14)
        return (thump + noise) * env
    end, 0.11, 0.55)

    Audio.sounds.acorn = createSound(function(t, p)
        local freq = (p < 0.45) and 659.25 or 987.77
        local env = (1.0 - p) ^ 1.2
        return math.sin(2 * math.pi * freq * t) * env
    end, 0.22, 0.45)

    Audio.sounds.chestnut_pickup = createSound(function(t, p)
        local f1 = 523.25
        local f2 = 659.25
        local f3 = 783.99
        local env = (1.0 - p) ^ 1.5
        local s = (math.sin(2 * math.pi * f1 * t) + math.sin(2 * math.pi * f2 * t) + math.sin(2 * math.pi * f3 * t)) / 3
        return s * env
    end, 0.35, 0.5)

    Audio.sounds.explosion = createSound(function(t, p)
        local boom = math.sin(2 * math.pi * (90 * (1.0 - p * 0.8)) * t) * 0.8
        local noise = (math.random() * 2 - 1) * 0.7
        local env = math.exp(-p * 5.5)
        return (boom + noise) * env
    end, 0.42, 0.7)

    Audio.sounds.hurt = createSound(function(t, p)
        local freq = 200 * (1.0 - p * 0.6)
        local sqr = (math.sin(2 * math.pi * freq * t) > 0) and 0.5 or -0.5
        local noise = (math.random() * 2 - 1) * 0.4
        local env = (1.0 - p) ^ 2
        return (sqr + noise) * env
    end, 0.22, 0.55)

    Audio.sounds.checkpoint = createSound(function(t, p)
        local step = math.floor(p * 4)
        local f = CHECKPOINT_NOTES[step + 1] or 880.0
        local env = math.sin(p * math.pi)
        return math.sin(2 * math.pi * f * t) * env
    end, 0.45, 0.5)

    Audio.sounds.boss_roar = createSound(function(t, p)
        local mod = math.sin(2 * math.pi * 32 * t)
        local base = math.sin(2 * math.pi * (85 + mod * 25) * t)
        local noise = (math.random() * 2 - 1) * 0.45
        local env = math.sin(p * math.pi)
        return (base * 0.6 + noise * 0.4) * env
    end, 0.5, 0.65)

    Audio.sounds.boss_slam = createSound(function(t, p)
        local sub = math.sin(2 * math.pi * 55 * t) * 0.8
        local noise = (math.random() * 2 - 1) * 0.6
        local env = math.exp(-p * 9)
        return (sub + noise) * env
    end, 0.35, 0.7)

    Audio.sounds.victory = createSound(function(t, p)
        local noteIdx = math.floor(p * 6)
        local f = VICTORY_NOTES[noteIdx + 1] or 1046.5
        local subP = (p * 6) % 1.0
        local env = (1.0 - subP) ^ 1.5
        return math.sin(2 * math.pi * f * t) * env * 0.8
    end, 1.2, 0.55)

    Audio.sounds.rustle = createSound(function(t, p)
        local noise = (math.random() * 2 - 1)
        local mod = math.sin(2 * math.pi * 35 * t)
        local env = math.sin(p * math.pi) * (1.0 - p)
        return (noise * 0.75 + mod * 0.25) * env
    end, 0.13, 0.28)

    Audio._generateMusic()

    Audio.initialized = true
end

function Audio._generateMusic()
    local sampleRate = Audio.sampleRate
    local duration = 12.0
    local totalSamples = math.floor(sampleRate * duration)
    local sd = love.sound.newSoundData(totalSamples, sampleRate, 16, 2)

    local scale = { 261.63, 329.63, 392.00, 440.00, 493.88, 523.25, 587.33, 659.25 }
    local melodyPattern = {
        1, 3, 4, 6,  4, 3, 2, 1,
        3, 4, 6, 8,  7, 6, 4, 3,
        4, 6, 7, 8,  6, 4, 3, 1,
    }
    local chordBases = { 130.81, 164.81, 110.00, 174.61 }

    for i = 0, totalSamples - 1 do
        local t = i / sampleRate
        local noteDuration = 0.5
        local noteIdx = math.floor(t / noteDuration) % #melodyPattern + 1
        local noteTime = t % noteDuration
        local noteProgress = noteTime / noteDuration

        local freq = scale[melodyPattern[noteIdx]] or 440.0
        local noteEnv = math.exp(-noteProgress * 5) * (1.0 - noteProgress)

        local pluck = math.sin(2 * math.pi * freq * t) * 0.6
            + math.sin(2 * math.pi * freq * 2 * t) * 0.25
            + math.sin(2 * math.pi * freq * 3 * t) * 0.1
        pluck = pluck * noteEnv

        local chordIdx = math.floor(t / 3.0) % #chordBases + 1
        local bassFreq = chordBases[chordIdx]
        local bass = (math.sin(2 * math.pi * bassFreq * t) + math.sin(2 * math.pi * bassFreq * 1.5 * t) * 0.3) * 0.2

        local breeze = (math.sin(t * 1.5) * 0.5 + 0.5) * (math.random() * 2 - 1) * 0.04

        local left = clamp((pluck * 0.7 + bass * 0.6 + breeze) * 0.35, -0.99, 0.99)
        local right = clamp((pluck * 0.5 + bass * 0.7 + breeze) * 0.35, -0.99, 0.99)

        sd:setSample(i, 1, left)
        sd:setSample(i, 2, right)
    end

    local musicSrc = love.audio.newSource(sd)
    musicSrc:setLooping(true)
    Audio.musicSource = musicSrc
    Audio.updateMusicVolume()
end

function Audio.play(soundName)
    if not Audio.initialized then Audio.init() end
    local src = Audio.sounds[soundName]
    if src then
        local vol = config.masterVolume * config.sfxVolume
        src:setVolume(vol)

        if src:isPlaying() then
            src:stop()
        end
        src:play()
    end
end

function Audio.playMusic()
    if not Audio.initialized then Audio.init() end
    if Audio.musicSource and not Audio.musicSource:isPlaying() then
        Audio.updateMusicVolume()
        Audio.musicSource:play()
    end
end

function Audio.updateMusicVolume()
    if Audio.musicSource then
        local vol = config.masterVolume * config.musicVolume
        Audio.musicSource:setVolume(vol)
    end
end

return Audio
