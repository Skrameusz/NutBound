local config = require("src.config")
local GFX = require("src.graphics")
local lg = love.graphics
local Scenery = {}
local STRIP_WIDTH = 2560

local function layer(depth, camX, camY, factor)
    local offset = (camX * factor) % STRIP_WIDTH
    lg.setColor(1, 1, 1)
    lg.setBlendMode("alpha", "premultiplied")
    for x = -offset, config.VIRTUAL_WIDTH, STRIP_WIDTH do
        lg.draw(GFX.get("forest_" .. depth), x, -camY * factor)
    end
    lg.setBlendMode("alpha")
end

function Scenery.draw(camX, camY, time)
    camX, camY, time = camX or 0, camY or 0, time or 0
    lg.push("all")
    lg.setColor(1, 1, 1)
    lg.setBlendMode("alpha", "premultiplied")
    lg.draw(GFX.get("sky"), 0, 0)
    lg.setBlendMode("alpha")
    local sunX = 910 - camX * 0.025
    lg.setColor(1, 0.93, 0.72, 0.70)
    GFX.disc(sunX, 153, 37)
    layer(1, camX, camY, 0.10)
    for i = 1, 5 do
        local x = sunX - 155 + i * 83 + math.sin(time * 0.14 + i) * 14
        lg.setColor(1, 0.92, 0.64, 0.026 + math.sin(time * 0.23 + i) * 0.009)
        lg.draw(GFX.get("sun_ray"), x - 315, 0)
    end
    layer(2, camX, camY, 0.26)
    lg.setColor(1, 1, 1)
    lg.draw(GFX.get("mist"), 0, 390)
    layer(3, camX, camY, 0.47)
    for i = 1, 23 do
        local x = (i * 173.7 - camX * 0.35 + math.sin(time * 0.19 + i) * 24) % (config.VIRTUAL_WIDTH + 40) - 20
        local y = 140 + ((i * 89.3 - time * (3 + i % 3)) % 420)
        local alpha = 0.14 + (math.sin(time * 0.7 + i * 1.4) + 1) * 0.12
        lg.setColor(1, 0.92, 0.65, alpha)
        GFX.disc(x, y, i % 3 == 0 and 1.6 or 1)
    end
    lg.pop()
end

return Scenery
