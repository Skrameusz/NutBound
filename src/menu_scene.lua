local GFX = require("src.graphics")
local Scenery = require("src.scenery")
local Scene = {}
local lg = love.graphics

local function floorY(x)
    return 614 + math.sin(x * 0.009) * 11 + math.sin(x * 0.021) * 4
end

local function leaf(x, y, size, angle, color)
    lg.setColor(color)
    lg.draw(GFX.get("menu_leaf"), x, y, angle, size / 32, size / 32, 33, 19)
end

function Scene.draw(time, parallaxX, parallaxY)
    parallaxX, parallaxY = parallaxX or 0, parallaxY or 0
    lg.push("all")
    Scenery.draw(450 + parallaxX * 2, parallaxY * 0.3, time)
    lg.setColor(1, 1, 1)
    lg.draw(GFX.get("menu_light"), 0, 0)
    for i = 1, 5 do
        local x = 1080 + i * 24 + math.sin(time * 0.12 + i) * 6
        lg.setColor(1, 0.77, 0.37, 0.026)
        lg.draw(GFX.get("menu_ray"), x - 475, -20)
    end
    lg.push()
    lg.translate(parallaxX * 0.45, parallaxY * 0.3)
    lg.setColor(1, 1, 1)
    lg.draw(GFX.get("menu_ground"), -48, 0)
    local hollow = GFX.get("hollow_tree")
    lg.draw(hollow, 1062, 626, 0, 3.05, 3.05, hollow:getWidth() / 2, hollow:getHeight())
    lg.setColor(1, 0.70, 0.24, (0.014 + math.sin(time * 2) * 0.001) / 0.02)
    lg.draw(GFX.get("menu_glow_62"), 1063, 478, 0, 1, 1, 63, 63)
    lg.setColor(1, 0.71, 0.27, 0.017 / 0.02)
    lg.draw(GFX.get("menu_glow_48"), 1123, 414, 0, 1, 1, 49, 49)
    lg.setColor(1, 1, 1)
    lg.draw(GFX.get("menu_door_light"), 877, 528)
    local squirrel = GFX.get("player_idle_" .. math.floor(time * 3) % 4)
    local breath = math.sin(time * 2.2) * 0.009
    local custom = squirrel:getHeight() > 50
    local scale = custom and 0.86 or 3.3
    lg.draw(squirrel, 814, floorY(814) + 7, 0, scale, scale + breath,
        custom and 106 or squirrel:getWidth() / 2, squirrel:getHeight())
    local acorn = GFX.get("acorn")
    local acScale = acorn:getHeight() > 50 and 0.6 or 1.3
    for i = 1, 3 do
        local x = 878 + i * 25
        lg.draw(acorn, x, floorY(x) + 12, (i - 2) * 0.3, acScale, acScale, acorn:getWidth() / 2, acorn:getHeight())
    end
    lg.draw(GFX.get("menu_ferns"), 0, 540)
    lg.pop()
    for i = 1, 12 do
        local x = 620 + ((i * 127.9 + math.sin(time * 0.19 + i) * 32) % 645)
        local y = 226 + ((i * 77.4 - time * (1 + i % 4)) % 370)
        local alpha = 0.20 + (math.sin(time * 1.1 + i * 2.8) + 1) * 0.23
        lg.setColor(1, 0.76, 0.36, alpha * 0.09)
        GFX.disc(x, y, 7)
        lg.setColor(1, 0.87, 0.53, alpha)
        GFX.disc(x, y, i % 3 == 0 and 1.9 or 1.1)
    end
    for i = 1, 9 do
        local x = 600 + (i * 133.9 - time * (6 + i % 4)) % 800
        local y = 60 + (i * 63.4 + time * (8 + i % 3)) % 570
        leaf(x + math.sin(time * 0.9 + i) * 19, y, 4 + i % 3, time * 0.3 + i, {0.70, 0.43, 0.18, 0.50})
    end
    lg.setColor(1, 1, 1)
    lg.draw(GFX.get("menu_branches"), 0, 0)
    for i = 1, 22 do
        leaf(776 + (i * 97.1) % 527, (i * 27.9) % 92 - 18, 17 + i % 4 * 5,
            i * 1.29 + math.sin(time * 0.25 + i) * 0.025, {0.025, 0.061, 0.051, 0.92})
    end
    lg.setColor(1, 1, 1)
    lg.draw(GFX.get("menu_front"), parallaxX - 48, 640)
    lg.draw(GFX.get("menu_vignette"), 0, 0)
    lg.pop()
end

return Scene
