local config = require("src.config")
local GFX = require("src.graphics")
local Audio = require("src.audio")

local Weapons = {}
Weapons.__index = Weapons

function Weapons.new(particles, camera)
    return setmetatable({particles = particles, camera = camera, projectiles = {}}, Weapons)
end

local function spawnProjectile(self, kind, x, y, targetX, targetY)
    local stone = kind == "stone"
    local speed = stone and config.STONE_SPEED or config.CHESTNUT_SPEED
    local dx = targetX - x
    local dy = targetY - y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 0.001 then dist = 1 end
    local vx, vy = (dx / dist) * speed, (dy / dist) * speed

    table.insert(self.projectiles, {
        type = kind, x = x, y = y, vx = vx, vy = vy, rot = 0, trail = {},
        gravity = stone and config.STONE_GRAVITY or config.CHESTNUT_GRAVITY,
        radius = stone and 7 or 10,
        damage = stone and config.STONE_DAMAGE or nil,
        life = stone and config.STONE_LIFETIME or 3.0,
        spin = stone and vx / 35 or nil,
    })
    Audio.play("shoot")
end

function Weapons:spawnStone(x, y, targetX, targetY)
    spawnProjectile(self, "stone", x, y, targetX, targetY)
end

function Weapons:spawnChestnut(x, y, targetX, targetY)
    spawnProjectile(self, "chestnut", x, y, targetX, targetY)
end

function Weapons:triggerExplosion(x, y, enemies, boss)
    self.particles:spawnExplosion(x, y)
    self.particles:spawnShockwave(x, y, config.CHESTNUT_RADIUS)
    self.camera:addShake(9, 0.35)
    Audio.play("explosion")

    local radius = config.CHESTNUT_RADIUS
    local rSq = radius * radius

    local function damageTarget(target)
        if not target.alive then return end
        local dx = target.x + target.width * 0.5 - x
        local dy = target.y + target.height * 0.5 - y
        if dx * dx + dy * dy <= rSq then
            target:takeDamage(config.CHESTNUT_DAMAGE_AOE, self.particles)
        end
    end
    for _, enemy in ipairs(enemies or {}) do damageTarget(enemy) end
    if boss and boss.active then damageTarget(boss) end
end

local function worldContact(level, x, y, radius)
    local best
    local function rectangle(rx, ry, rw, rh, platform)
        local nearX = math.max(rx, math.min(x, rx + rw))
        local nearY = math.max(ry, math.min(y, ry + rh))
        local dx, dy = x - nearX, y - nearY
        local distanceSq = dx * dx + dy * dy
        if distanceSq >= radius * radius then return end
        local nx, ny, depth
        if distanceSq > 0.000001 then
            local distance = math.sqrt(distanceSq)
            nx, ny, depth = dx / distance, dy / distance, radius - distance
        else
            local distances = {x - rx, rx + rw - x, y - ry, ry + rh - y}
            local face = 1
            for n = 2, 4 do if distances[n] < distances[face] then face = n end end
            nx = face == 1 and -1 or face == 2 and 1 or 0
            ny = face == 3 and -1 or face == 4 and 1 or 0
            depth = radius + distances[face]
        end
        if not best or depth > best.depth then
            best = {nx = nx, ny = ny, depth = depth, platform = platform}
        end
    end

    local ts = level.ts or config.TILE_SIZE
    for tx = math.floor((x - radius) / ts), math.floor((x + radius) / ts) do
        for ty = math.floor((y - radius) / ts), math.floor((y + radius) / ts) do
            if level:isSolid((tx + 0.5) * ts, (ty + 0.5) * ts) then
                rectangle(tx * ts, ty * ts, ts, ts)
            end
        end
    end
    for _, platform in ipairs(level.platforms or {}) do
        rectangle(platform.x, platform.y, platform.width, platform.height, platform)
    end
    for _, platform in ipairs(level.movingPlatforms or {}) do
        rectangle(platform.x, platform.y, platform.width, platform.height, platform)
    end
    return best
end

local function approach(value, target, amount)
    if value < target then return math.min(value + amount, target) end
    return math.max(value - amount, target)
end

function Weapons:hitTarget(p, enemies, boss)
    if p.type == "stone" and (p.resting or
        p.vx * p.vx + p.vy * p.vy < config.STONE_MIN_DAMAGE_SPEED ^ 2) then
        return false
    end
    local target
    for _, enemy in ipairs(enemies or {}) do
        if enemy.alive and enemy:checkHit(p.x, p.y, p.radius) then target = enemy; break end
    end
    if not target and boss and boss.active and boss.alive and boss:checkHit(p.x, p.y, p.radius) then
        target = boss
    end
    if not target then return false end
    if p.type == "chestnut" then
        self:triggerExplosion(p.x, p.y, enemies, boss)
    else
        target:takeDamage(p.damage, self.particles)
        self.particles:spawnHitSparks(p.x, p.y, 8)
        Audio.play("hit")
    end
    return true
end

function Weapons:update(dt, level, enemies, boss)
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        p.life = p.life - dt
        p.impactCooldown = math.max(0, (p.impactCooldown or 0) - dt)
        table.insert(p.trail, 1, {x = p.x, y = p.y})
        if #p.trail > 7 then table.remove(p.trail) end

        if p.resting then
            if p.support then
                p.x = p.x + p.support.x - p.supportX
                p.supportX = p.support.x
            end
            local floor = worldContact(level, p.x, p.y + 0.15, p.radius)
            if not floor or floor.ny > -0.5 then
                p.resting, p.support = false, nil
            end
        end

        local destroyed = p.life <= 0

        local speedBound = math.abs(p.vx) + math.abs(p.vy) + p.gravity * dt
        local steps = math.max(1, math.ceil(speedBound * dt / (p.radius * 0.5)))
        local step = dt / steps
        for _ = 1, steps do
            if destroyed or p.resting then break end
            p.vy = p.vy + p.gravity * step
            p.x, p.y = p.x + p.vx * step, p.y + p.vy * step
            p.rot = (p.rot or 0) + (p.type == "stone" and p.spin or 12) * step

            for _ = 1, 3 do
                local contact = worldContact(level, p.x, p.y, p.radius)
                if not contact then break end
                p.x = p.x + contact.nx * (contact.depth + 0.001)
                p.y = p.y + contact.ny * (contact.depth + 0.001)
                if p.type == "chestnut" then
                    self:triggerExplosion(p.x, p.y, enemies, boss)
                    destroyed = true
                    break
                end

                local surface = contact.platform
                local surfaceVX = surface and (surface.speed or 0) * (surface.dir or 0) or 0
                local relativeVX = p.vx - surfaceVX
                local normalSpeed = relativeVX * contact.nx + p.vy * contact.ny
                if normalSpeed < 0 then
                    local impact = -normalSpeed
                    local bounce = impact >= config.STONE_MIN_BOUNCE_SPEED and config.STONE_RESTITUTION or 0
                    relativeVX = relativeVX - (1 + bounce) * normalSpeed * contact.nx
                    p.vy = p.vy - (1 + bounce) * normalSpeed * contact.ny

                    if impact >= config.STONE_MIN_BOUNCE_SPEED then
                        local tangentSpeed = relativeVX * -contact.ny + p.vy * contact.nx
                        relativeVX = relativeVX + tangentSpeed * contact.ny * 0.18
                        p.vy = p.vy - tangentSpeed * contact.nx * 0.18
                    end
                    p.vx = relativeVX + surfaceVX
                    p.spin = p.vx / p.radius * 0.45
                    if impact > 120 and p.impactCooldown <= 0 then
                        self.particles:spawnHitSparks(p.x, p.y, math.min(6, math.ceil(impact / 100)))
                        Audio.play("hit")
                        p.impactCooldown = 0.09
                    end
                    if contact.ny < -0.5 and bounce == 0 then
                        p.vx = approach(p.vx, surfaceVX, config.STONE_SURFACE_FRICTION * step)
                        p.spin = (p.vx - surfaceVX) / p.radius
                        if math.abs(p.vx - surfaceVX) < config.STONE_REST_SPEED then
                            p.vx, p.vy, p.spin = 0, 0, 0
                            p.resting, p.support = true, surface
                            p.supportX = surface and surface.x
                            p.life = math.min(p.life, 1.5)
                        end
                    end
                end
            end

            if not destroyed then destroyed = self:hitTarget(p, enemies, boss) end
            if p.y > level.height + 100 or p.x < -100 or p.x > level.width + 100 then
                destroyed = true
            end
        end
        if destroyed then table.remove(self.projectiles, i) end
    end
end

function Weapons:draw()
    love.graphics.push("all")
    for _, p in ipairs(self.projectiles) do
        local warm = p.type == "chestnut"
        for i = #p.trail, 1, -1 do
            local point = p.trail[i]
            local strength = 1 - i / (#p.trail + 1)
            love.graphics.setColor(warm and 1 or 0.82, warm and 0.65 or 0.88, warm and 0.24 or 0.82, strength * 0.45)
            GFX.disc(point.x, point.y, (warm and 6 or 3) * strength)
        end
        if warm then
            love.graphics.setColor(1, 0.58, 0.17, 0.13)
            GFX.disc(p.x, p.y, 17)
        end
        love.graphics.setColor(1, 1, 1, math.min(1, p.life / 0.45))
        local spr = GFX.get(warm and "chestnut_proj" or "stone")
        love.graphics.draw(spr, p.x, p.y, p.rot or 0, 1, 1, p.radius, p.radius)
    end
    love.graphics.pop()
end

return Weapons
