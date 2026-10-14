local config = require("src.config")
local Theme = require("src.theme")
local GFX = require("src.graphics")

local AMBIENT_COLORS = {
    { 0.88, 0.35, 0.12 },
    { 0.95, 0.72, 0.18 },
    { 0.76, 0.22, 0.15 },
    { 0.62, 0.40, 0.18 },
}
local LEAF_COLORS = {
    { 0.38, 0.65, 0.22 },
    { 0.88, 0.55, 0.15 },
    { 0.52, 0.72, 0.25 },
}
local EXPLOSION_COLORS = {
    { 1.0, 0.3, 0.1 },
    { 1.0, 0.7, 0.1 },
    { 0.9, 0.9, 0.2 },
}

local Particles = {}
Particles.__index = Particles

function Particles.new()
    local self = setmetatable({particles = {}}, Particles)
    self:initAmbientLeaves(60)
    return self
end

function Particles:initAmbientLeaves(count)
    self.ambientLeaves = {}
    for _ = 1, count do
        table.insert(self.ambientLeaves, {
            x = math.random(0, config.VIRTUAL_WIDTH),
            y = math.random(-50, config.VIRTUAL_HEIGHT),
            vx = math.random(25, 60),
            vy = math.random(20, 50),
            rot = math.random() * math.pi * 2,
            vrot = (math.random() * 2 - 1) * 2.5,
            size = math.random(2, 5),
            depth = 0.3 + math.random() * 0.5,
            color = AMBIENT_COLORS[math.random(1, #AMBIENT_COLORS)]
        })
    end
end

function Particles:spawnDust(x, y, count)
    count = count or 4
    for _ = 1, count do
        local angle = math.random() * math.pi + math.pi
        local speed = math.random(20, 70)
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed * 0.4 - math.random(10, 30),
            size = math.random(3, 5),
            color = { 0.75, 0.70, 0.62 },
            alpha = 0.8,
            life = 0.2 + math.random() * 0.25,
            maxLife = 0.45,
            shape = "circle"
        })
    end
end

function Particles:spawnLeafBurst(x, y, count)
    count = count or 5
    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(30, 90)
        local c = LEAF_COLORS[math.random(1, #LEAF_COLORS)]
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed * 0.6 - math.random(15, 35),
            size = math.random(3, 6),
            color = c,
            alpha = 1.0,
            life = 0.35 + math.random() * 0.3,
            maxLife = 0.65,
            shape = "leaf"
        })
    end
end

function Particles:spawnHitSparks(x, y, count)
    count = count or 8
    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(80, 220)
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = math.random(2, 4),
            color = { 1.0, 0.9, 0.3 },
            alpha = 1.0,
            life = 0.15 + math.random() * 0.15,
            maxLife = 0.3,
            shape = "spark"
        })
    end
end

function Particles:spawnSparkle(x, y, count, color)
    count = count or 6
    color = color or { 1.0, 0.85, 0.2 }
    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(40, 120)
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 20,
            size = math.random(3, 5),
            color = color,
            alpha = 1.0,
            life = 0.3 + math.random() * 0.3,
            maxLife = 0.6,
            shape = "star"
        })
    end
end

function Particles:spawnExplosion(x, y)
    table.insert(self.particles, {
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        size = 35,
        color = { 1.0, 0.95, 0.8 },
        alpha = 1.0,
        life = 0.18,
        maxLife = 0.18,
        shape = "flash"
    })

    for _ = 1, 24 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(100, 320)
        local c = EXPLOSION_COLORS[math.random(1, #EXPLOSION_COLORS)]

        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            size = math.random(4, 9),
            color = c,
            alpha = 1.0,
            life = 0.25 + math.random() * 0.3,
            maxLife = 0.55,
            shape = "circle"
        })
    end

    for _ = 1, 14 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(40, 140)
        table.insert(self.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 25,
            size = math.random(8, 16),
            color = { 0.35, 0.32, 0.30 },
            alpha = 0.8,
            life = 0.4 + math.random() * 0.4,
            maxLife = 0.8,
            shape = "smoke"
        })
    end
end

function Particles:spawnShockwave(x, y, radius)
    radius = radius or 60
    table.insert(self.particles, {
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        size = 10,
        targetSize = radius,
        color = { 0.95, 0.85, 0.65 },
        alpha = 0.9,
        life = 0.35,
        maxLife = 0.35,
        shape = "ring"
    })
end

function Particles:spawnFloatingText(x, y, text)
    table.insert(self.particles, {
        x = x, y = y, vx = 0, vy = -38, text = text,
        color = { 1, 0.87, 0.48 }, alpha = 1,
        life = 0.85, maxLife = 0.85, shape = "text",
    })
end

function Particles:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.alpha = (p.life / p.maxLife)

            if p.shape == "ring" and p.targetSize then
                local prog = 1.0 - (p.life / p.maxLife)
                p.size = 10 + (p.targetSize - 10) * prog
            elseif p.shape == "smoke" then
                p.size = p.size + 8 * dt
                p.vy = p.vy - 15 * dt
            end
        end
    end

    for _, leaf in ipairs(self.ambientLeaves) do
        leaf.x = leaf.x + leaf.vx * dt + math.sin(leaf.y * 0.02) * 15 * dt
        leaf.y = leaf.y + leaf.vy * dt
        leaf.rot = leaf.rot + leaf.vrot * dt

        if leaf.y > config.VIRTUAL_HEIGHT + 30 then
            leaf.y = -20
            leaf.x = math.random(0, config.VIRTUAL_WIDTH)
        end
        if leaf.x > config.VIRTUAL_WIDTH + 30 then
            leaf.x = -50
        end
    end
end

function Particles:drawAmbientLeaves(camX)
    love.graphics.push("all")
    for _, leaf in ipairs(self.ambientLeaves) do
        love.graphics.push()
        local x = (leaf.x - (camX or 0) * leaf.depth + 30) % (config.VIRTUAL_WIDTH + 60) - 30
        love.graphics.translate(x, leaf.y)
        love.graphics.rotate(leaf.rot)
        love.graphics.setColor(leaf.color[1], leaf.color[2], leaf.color[3], 0.48)
        love.graphics.draw(GFX.get("ambient_leaf"), 0, 0, 0, leaf.size / 5, leaf.size / 5, 6, 4)
        love.graphics.pop()
    end
    love.graphics.pop()
end

function Particles:draw()
    love.graphics.push("all")
    for _, p in ipairs(self.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        if p.shape == "text" then
            love.graphics.setFont(Theme.font(20))
            love.graphics.print(p.text, p.x, p.y)
        elseif p.shape == "circle" or p.shape == "flash" or p.shape == "smoke" then
            GFX.disc(p.x, p.y, p.size)
        elseif p.shape == "spark" then
            GFX.rect(p.x - p.size * 0.5, p.y - p.size * 0.5, p.size, p.size)
        elseif p.shape == "star" then
            love.graphics.draw(GFX.get("star_" .. p.size), p.x, p.y, 0, 1, 1, 6, 6)
        elseif p.shape == "ring" then
            GFX.ring(p.x, p.y, p.size)
        elseif p.shape == "leaf" then
            love.graphics.draw(GFX.get("leaf"), p.x, p.y, 0, p.size / 6, p.size / 6, 7, 4)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return Particles
