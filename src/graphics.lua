local GFX = {sprites = {}, initialized = false}
local fillQuad, discFrames, ringFrames

function GFX.init()
    if GFX.initialized then return end
    local function load(name, path, filter)
        local image = love.graphics.newImage(path)
        image:setFilter(filter or "nearest", filter or "nearest")
        GFX.sprites[name] = image
    end
    local function frames(name, path, count)
        for frame = 0, count - 1 do
            load(name .. "_" .. frame, "assets/animations/" .. path .. "_" .. frame .. ".png")
        end
    end
    frames("player_idle", "maincharacter/idle/idle", 4)
    frames("player_run", "maincharacter/walking/chodzenie", 6)
    frames("hedgehog", "jez/chodzenie", 5)
    load("player_jump", "assets/animations/maincharacter/jump/podskok.png")
    GFX.sprites.player_fall = GFX.sprites.player_jump
    GFX.sprites.player_hurt = GFX.sprites.player_jump
    local images = {
        trawa = "tile_grass_top", ziemia = "tile_dirt", ["kamień"] = "tile_stone",
        kolce = "spikes", krzak = "plant_bush", zoladz = "acorn",
        ["platforma lewo"] = "platform_left", ["platforma środek"] = "platform_mid",
        ["platforma prawo"] = "platform_right",
    }
    local directories = {
        "animations/crow", "animations/beetle", "animations/boss", "animations/plants",
        "backgrounds", "environment", "effects", "ui", "tiles", "items", "weapons",
    }
    for _, directory in ipairs(directories) do
        for _, file in ipairs(love.filesystem.getDirectoryItems("assets/" .. directory)) do
            local name = file:match("^(.*)%.png$")
            if name then
                load(images[name] or name, "assets/" .. directory .. "/" .. file,
                    name:match("^forest_") and "linear" or "nearest")
            end
        end
    end
    GFX.sprites.tile_platform = GFX.sprites.platform_mid
    local function atlas(image, count, columns, size)
        local quads = {}
        for i = 0, count - 1 do
            quads[i + 1] = love.graphics.newQuad(i % columns * size, math.floor(i / columns) * size,
                size, size, image:getDimensions())
        end
        return quads
    end
    discFrames = atlas(GFX.sprites.discs, 40, 7, 84)
    ringFrames = atlas(GFX.sprites.rings, 81, 9, 184)
    fillQuad = love.graphics.newQuad(0, 0, 1, 1, GFX.sprites.fill:getDimensions())
    GFX.initialized = true
end

function GFX.get(name)
    if not GFX.initialized then GFX.init() end
    return GFX.sprites[name]
end

function GFX.rect(x, y, width, height)
    if width <= 0 or height <= 0 then return end
    fillQuad:setViewport(0, 0, width, height)
    love.graphics.draw(GFX.sprites.fill, fillQuad, x, y)
end

function GFX.disc(x, y, radius)
    local frame = math.max(1, math.min(40, math.floor(radius + 0.5)))
    love.graphics.draw(GFX.sprites.discs, discFrames[frame], x, y, 0, 1, 1, 42, 42)
end

function GFX.ring(x, y, radius)
    local frame = math.max(1, math.min(81, math.floor(radius + 0.5) - 9))
    love.graphics.draw(GFX.sprites.rings, ringFrames[frame], x, y, 0, 1, 1, 92, 92)
end

return GFX
