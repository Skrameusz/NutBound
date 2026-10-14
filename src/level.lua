local config = require("src.config")
local GFX = require("src.graphics")
local Audio = require("src.audio")
local LevelData = require("src.level_data")
local Collision = require("src.collision")

local Level = {}
Level.__index = Level

function Level.new(particles, camera)
    local ts = config.TILE_SIZE
    local self = setmetatable({
        particles = particles, camera = camera,
        ts = ts, width = LevelData.WIDTH_TILES * ts, height = LevelData.HEIGHT,
        solidTiles = {}, platforms = {}, movingPlatforms = {}, spikes = {}, collectibles = {},
        enemies = {}, plants = {}, dressing = {}, visualTime = 0,
        arenaLeft = LevelData.ARENA_LEFT_TILE * ts, arenaRight = LevelData.ARENA_RIGHT_TILE * ts,
        arenaStarted = false, leftGateActive = false, rightGateActive = true, inHollowZone = false,
    }, Level)

    LevelData.build(self)
    LevelData.populateFoliage(self)
    self:lowerPlatforms()
    self:populateDressing()
    return self
end

function Level:lowerPlatforms()
    local floorY = LevelData.GROUND_ROW * self.ts
    for _, platform in ipairs(self.platforms) do
        local oldY = platform.y
        local reduction = 0
        if platform.x < 23 * self.ts then
            reduction = 0.10
        elseif oldY < 9 * self.ts then
            reduction = 0.20
        end
        local offset = (floorY - oldY) * reduction
        if offset > 0 then
            platform.y = oldY + offset
            for _, item in ipairs(self.collectibles) do
                if item.x >= platform.x and item.x < platform.x + platform.width
                    and math.abs(item.y - (oldY - self.ts)) < 0.01 then
                    item.y = item.y + offset
                end
            end
            for _, plant in ipairs(self.plants) do
                if plant.x >= platform.x and plant.x < platform.x + platform.width
                    and math.abs(plant.y + plant.height - oldY) < 0.01 then
                    plant.y = plant.y + offset
                end
            end
        end
    end
end

function Level:setTile(tx, ty, tileType)
    self.solidTiles[tx .. "_" .. ty] = tileType
end

function Level:getTile(tx, ty)
    return self.solidTiles[tx .. "_" .. ty]
end

function Level:setArenaGate(side, active)
    local tx
    if side == "left" then
        tx = LevelData.ARENA_LEFT_TILE
        self.leftGateActive = active
    elseif side == "right" then
        tx = LevelData.ARENA_RIGHT_TILE
        self.rightGateActive = active
    else
        error("Unknown arena gate: " .. tostring(side))
    end

    for ty = LevelData.GROUND_ROW - 6, LevelData.GROUND_ROW - 1 do
        self:setTile(tx, ty, active and "stone" or nil)
    end
end

function Level:resetArena()
    if not self.arenaStarted or self.boss.defeated then return false end
    self:setArenaGate("left", false)
    self.arenaStarted = false
    self.boss = LevelData.createBoss(self)
    self.camera:unlockArena()
    return true
end

function Level:addPlatform(tx, ty, length)
    length = length or 1
    table.insert(self.platforms, {
        x = tx * self.ts,
        y = ty * self.ts,
        width = length * self.ts,
        height = 18
    })
end

function Level:addMovingPlatform(startX, endX, y, width)
    table.insert(self.movingPlatforms, {
        x = startX,
        y = y,
        startX = startX,
        endX = endX,
        width = width,
        height = 18,
        speed = 80,
        dir = 1
    })
end

function Level:populateDressing()
    for tx = 1, LevelData.WIDTH_TILES - 2 do
        local top = self:getTile(tx, LevelData.GROUND_ROW)
        if top then
            local seed = (tx * 173 + 41) % 997
            local kind = top == "stone" and "stone" or ({"mushroom", "stone", "tuft", "leaves", "root"})[seed % 5 + 1]
            self.dressing[#self.dressing + 1] = {
                x = tx * self.ts + 8 + seed % 26,
                y = LevelData.GROUND_ROW * self.ts,
                kind = kind,
                size = 0.72 + (seed % 9) * 0.07,
                phase = seed * 0.2,
            }
        end
    end
end

function Level:isSolid(x, y)
    local tx = math.floor(x / self.ts)
    local ty = math.floor(y / self.ts)
    return self:getTile(tx, ty) ~= nil
end

function Level:isPlatform(x, y)
    for _, platforms in ipairs({self.platforms, self.movingPlatforms}) do
        for _, p in ipairs(platforms) do
            if x >= p.x and x <= p.x + p.width and y >= p.y and y <= p.y + p.height then
                return true
            end
        end
    end
    return false
end

function Level:checkPlayerGrounded(px, py, pw, ph)
    local footY = py + ph + 2
    local samplePoints = { px + 6, px + pw * 0.5, px + pw - 6 }

    for _, sx in ipairs(samplePoints) do
        if self:isSolid(sx, footY) then return true end
    end

    for _, sx in ipairs(samplePoints) do
        for _, platforms in ipairs({self.platforms, self.movingPlatforms}) do
            for _, p in ipairs(platforms) do
                if sx >= p.x and sx <= p.x + p.width and (py + ph) >= p.y - 2 and (py + ph) <= p.y + 6 then
                    return true
                end
            end
        end
    end

    return false
end

function Level:moveAndCollide(player, dt)
    local ts = self.ts

    player.x = player.x + player.vx * dt

    local minTX = math.floor(player.x / ts)
    local maxTX = math.floor((player.x + player.width) / ts)
    local minTY = math.floor((player.y + 4) / ts)
    local maxTY = math.floor((player.y + player.height - 4) / ts)

    for ty = minTY, maxTY do
        for tx = minTX, maxTX do
            if self:getTile(tx, ty) then
                local tileL = tx * ts
                local tileR = tileL + ts
                if player.vx > 0 and (player.x + player.width) > tileL and player.x < tileL then
                    player.x = tileL - player.width
                    player.vx = 0
                elseif player.vx < 0 and player.x < tileR and (player.x + player.width) > tileR then
                    player.x = tileR
                    player.vx = 0
                end
            end
        end
    end

    local prevY = player.y
    player.y = player.y + player.vy * dt

    minTX = math.floor((player.x + 4) / ts)
    maxTX = math.floor((player.x + player.width - 4) / ts)
    minTY = math.floor(player.y / ts)
    maxTY = math.floor((player.y + player.height) / ts)

    for ty = minTY, maxTY do
        for tx = minTX, maxTX do
            if self:getTile(tx, ty) then
                local tileT = ty * ts
                local tileB = tileT + ts
                if player.vy > 0 and (player.y + player.height) > tileT and prevY + player.height <= tileT + 14 then
                    player.y = tileT - player.height
                    player.vy = 0
                    player.onGround = true
                elseif player.vy < 0 and player.y < tileB and prevY >= tileB - 14 then
                    player.y = tileB
                    player.vy = 0
                end
            end
        end
    end

    if player.vy >= 0 then
        local footY = player.y + player.height
        local prevFootY = prevY + player.height

        local function checkPlat(p)
            local pL = p.x
            local pR = p.x + p.width
            local pT = p.y

            if player.x + player.width > pL + 4 and player.x < pR - 4
                and prevFootY <= pT + 6 and footY >= pT - 2 then
                player.y = pT - player.height
                player.vy = 0
                player.onGround = true
                if p.speed and p.dir then
                    player.x = player.x + p.speed * p.dir * dt
                end
            end
        end

        for _, p in ipairs(self.platforms) do checkPlat(p) end
        for _, p in ipairs(self.movingPlatforms) do checkPlat(p) end
    end
end

function Level:updateFoliage(dt, player)
    for _, plant in ipairs(self.plants) do
        plant.swayTimer = plant.swayTimer + dt * 2.5
        plant.bendOffset = plant.bendOffset * math.exp(-dt * 6.0)
        if plant.rustleCooldown > 0 then
            plant.rustleCooldown = plant.rustleCooldown - dt
        end

        if player and player.alive and Collision.overlaps(player, plant) then
            local pushDir = (player.vx >= 0) and 1 or -1
            plant.bendOffset = pushDir * 14

            if plant.rustleCooldown <= 0 and math.abs(player.vx) > 35 then
                plant.rustleCooldown = 0.22
                Audio.play("rustle")
                self.particles:spawnLeafBurst(plant.x + plant.width * 0.5, plant.y + 10, 4)
            end
        end
    end
end

function Level:updateMovingPlatforms(dt)
    for _, p in ipairs(self.movingPlatforms) do
        p.x = p.x + p.speed * p.dir * dt
        if p.x >= p.endX then
            p.x = p.endX
            p.dir = -1
        elseif p.x <= p.startX then
            p.x = p.startX
            p.dir = 1
        end
    end
end

function Level:updateCollectibles(dt, player)
    for _, c in ipairs(self.collectibles) do
        if not c.collected then
            c.floatTimer = (c.floatTimer or 0) + dt * 4
            c.floatOffset = math.sin(c.floatTimer) * 4

            local cx = c.x + 13
            local cy = c.y + 15 + c.floatOffset
            if player.alive and player.x < cx + 18 and player.x + player.width > cx - 18
                and player.y < cy + 18 and player.y + player.height > cy - 18 then
                c.collected = true
                if c.type == "acorn" then
                    player.acorns = player.acorns + 1
                    Audio.play("acorn")
                    self.particles:spawnSparkle(cx, cy, 8, { 1.0, 0.85, 0.2 })
                elseif c.type == "chestnut" then
                    player.chestnutAmmo = player.chestnutAmmo + 3
                    player.activeAmmo = "chestnut"
                    Audio.play("chestnut_pickup")
                    self.particles:spawnSparkle(cx, cy, 14, { 0.4, 0.9, 0.3 })
                end
            end
        end
    end
end

function Level:updateCheckpoint(player)
    if self.checkpoint and not self.checkpoint.active and player.alive then
        local cp = self.checkpoint
        if Collision.overlaps(player, cp) then
            cp.active = true
            player:setCheckpoint(cp.x, cp.y + cp.height - player.height)
            Audio.play("checkpoint")
            self.particles:spawnSparkle(cp.x + cp.width * 0.5, cp.y + cp.height * 0.5, 20, { 0.2, 0.95, 0.85 })
        end
    end
end

function Level:updateContactDamage(player)
    if player.alive and player.hurtTimer <= 0 then
        for _, s in ipairs(self.spikes) do
            if player.x + player.width > s.x + 6 and player.x < s.x + s.width - 6
                and player.y + player.height > s.y + 8 and player.y < s.y + s.height then
                player:takeDamage(1, s.x + s.width * 0.5, self.particles, self.camera)
                break
            end
        end
    end

    if player.alive and player.hurtTimer <= 0 then
        for _, enemy in ipairs(self.enemies) do
            if enemy.alive and Collision.overlaps(player, enemy, 4) then
                player:takeDamage(enemy.damage, enemy.x + enemy.width * 0.5, self.particles, self.camera)
                break
            end
        end
    end

    if self.boss and self.boss.active and self.boss.alive and not self.boss.defeated and player.alive and player.hurtTimer <= 0 then
        local b = self.boss
        if Collision.overlaps(player, b, 10) then
            player:takeDamage(b.damage, b.x + b.width * 0.5, self.particles, self.camera)
        end
    end
end

function Level:updateArena(player)
    if player.x >= self.arenaLeft and not self.arenaStarted then
        self.arenaStarted = true
        self:setArenaGate("left", true)
        self.camera:lockArena(self.arenaLeft, self.arenaRight)
        self.boss:activate()
        self.particles:spawnDust(self.arenaLeft, (LevelData.GROUND_ROW - 3) * self.ts, 12)
        self.camera:addShake(6, 0.3)
    end

    if self.boss and self.boss.defeated and self.rightGateActive then
        self:setArenaGate("right", false)

        self:setArenaGate("left", false)
        self.camera:unlockArena()
        self.particles:spawnHitSparks(self.arenaRight, (LevelData.GROUND_ROW - 3) * self.ts, 24)
        self.camera:addShake(8, 0.4)
    end
end

function Level:updateHollowZone(player)
    self.inHollowZone = false
    if self.hollow and player.alive then
        local h = self.hollow
        if player.x + player.width > h.x + 20 and player.x < h.x + h.width - 20
            and player.y + player.height > h.y + 20 and player.y < h.y + h.height then
            self.inHollowZone = true
        end
    end
end

function Level:update(dt, player)
    self.visualTime = self.visualTime + dt
    self:updateFoliage(dt, player)
    self:updateMovingPlatforms(dt)
    self:updateCollectibles(dt, player)
    self:updateCheckpoint(player)
    self:updateContactDamage(player)
    self:updateArena(player)
    self:updateHollowZone(player)
end

local function glow(x, y, radius, color, strength)
    love.graphics.setColor(color[1], color[2], color[3], strength / 0.1)
    love.graphics.draw(GFX.get("glow"), x, y, 0, radius / 90, radius / 90, 91, 91)
end

local function sparkle(x, y, size, alpha)
    love.graphics.setColor(1, 0.94, 0.69, alpha)
    love.graphics.draw(GFX.get("sparkle"), x, y, 0, size / 4, size / 4, 5, 5)
end

local function drawDressing(d, time)
    local name = "dressing_" .. d.kind
    if d.kind == "tuft" then
        name = name .. "_" .. math.floor(math.sin(time * 1.6 + d.phase) * 3 + 3.5)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(GFX.get(name), d.x, d.y, 0, d.size, d.size, 24, 40)
end

function Level:draw()
    local g = love.graphics
    local ts, time = self.ts, self.visualTime
    local camX = self.camera and self.camera.x or 0
    local left, right = camX - 90, camX + config.VIRTUAL_WIDTH + 90
    local function visible(x, width)
        return x + (width or 48) >= left and x <= right
    end
    g.push("all")
    g.setColor(1, 1, 1)

    for tx = math.max(0, math.floor(left / ts)), math.min(104, math.floor(right / ts)) do
        for ty = 0, 14 do
            local tileType = self:getTile(tx, ty)
            if tileType and not ((tx == 0 or tx == 104) and ty < 12) then
                local sprName = tileType == "dirt" and "tile_dirt" or tileType == "stone" and "tile_stone" or "tile_grass_top"
                g.setColor(1, 1, 1)
                g.draw(GFX.get(sprName), tx * ts, ty * ts)
                if ty > 12 then
                    g.setColor(0.08, 0.13, 0.11, (ty - 12) * 0.15)
                    GFX.rect(tx * ts, ty * ts, ts, ts)
                end
            end
        end
    end

    for _, tx in ipairs({0, 104}) do
        if visible(tx * ts, ts) then
            local x = tx * ts
            g.setColor(1, 1, 1)
            g.draw(GFX.get("border_trunk"), x, 0)
        end
    end

    local platSpr = GFX.get("tile_platform")
    local platLeft = GFX.get("platform_left") or platSpr
    local platMid = GFX.get("platform_mid") or platSpr
    local platRight = GFX.get("platform_right") or platSpr
    local hasCustomCaps = (platLeft ~= platSpr)

    local function drawPlatform(p, moving)
        if not visible(p.x, p.width) then return end

        for i = 1, math.floor(p.width / ts) do
            local x = p.x + (i - 0.6) * ts
            local length = 19 + (i * 13 + math.floor(p.x)) % 17
            local sway = math.sin(time * 1.4 + i + p.x * 0.01) * 3
            local height = length - 11
            g.setColor(0.31, 0.42, 0.24, 0.9)
            g.draw(GFX.get("vine_stem"), x, p.y + 11, -math.atan2(sway, height),
                1, math.sqrt(sway * sway + height * height) / 24, 1.5, 1)
            g.setColor(0.51, 0.57, 0.30)
            g.draw(GFX.get("vine_leaf"), x + sway - 2, p.y + length - 7, 0, 1, 1, 5, 3)
            g.draw(GFX.get("vine_leaf"), x + sway + 2, p.y + length - 1, 0, 1, 1, 5, 3)
        end
        g.setColor(1, 1, 1)
        local numTiles = math.max(1, math.floor(p.width / ts))
        for i = 1, numTiles do
            local sx = p.x + (i - 1) * ts
            local spr = platMid
            if numTiles > 1 and i == 1 then
                spr = platLeft
            elseif numTiles > 1 and i == numTiles then
                spr = platRight
            end
            local yOffset = (spr:getHeight() == 24) and 7 or 0
            g.draw(spr, sx, p.y - yOffset)
        end
        if not hasCustomCaps then
            g.setColor(0.28, 0.22, 0.14)
            g.draw(GFX.get("platform_cap"), p.x + 3, p.y + 10, 0, 1, 1, 5, 8)
            g.draw(GFX.get("platform_cap"), p.x + p.width - 3, p.y + 10, 0, 1, 1, 5, 8)
        end
        if moving then
            g.setColor(1, 1, 1)
            for _, x in ipairs({p.x + 9, p.x + p.width - 13}) do
                g.draw(GFX.get("platform_band"), x, p.y + 2)
            end
        end
    end
    for _, p in ipairs(self.platforms) do drawPlatform(p, false) end
    for _, p in ipairs(self.movingPlatforms) do
        if visible(p.startX, p.endX - p.startX + p.width) then
            g.setColor(0.91, 0.80, 0.52, 0.3)
            local y = p.y + 39
            for x = p.startX + p.width * 0.5, p.endX + p.width * 0.5, 12 do
                g.draw(GFX.get("guide_dash"), x, y, 0, 1, 1, 1, 1.5)
            end
            g.draw(GFX.get("guide_end"), p.startX + p.width * 0.5, y, 0, 1, 1, 4, 4)
            g.draw(GFX.get("guide_end"), p.endX + p.width * 0.5, y, 0, 1, 1, 4, 4)
            drawPlatform(p, true)
        end
    end

    for _, d in ipairs(self.dressing) do
        if visible(d.x, 32) then drawDressing(d, time) end
    end
    for _, plant in ipairs(self.plants) do
        if visible(plant.x, plant.width) then
            local spr = GFX.get(plant.type)
            if spr then
                local sway = math.sin(plant.swayTimer) * 0.06
                local bend = plant.bendOffset / plant.height
                g.setColor(1, 1, 1)
                local sw, sh = spr:getWidth(), spr:getHeight()
                g.draw(spr, plant.x + plant.width * 0.5, plant.y + plant.height, sway + bend, 1, 1, sw * 0.5, sh)
            end
        end
    end

    if self.signboard and visible(self.signboard.x, self.signboard.width) then
        local s = self.signboard
        local spr = GFX.get("tablica")
        if spr then
            g.setColor(1, 1, 1)
            g.draw(GFX.get("sign_leg"), s.x + 14, s.y + s.height - 4)
            g.draw(GFX.get("sign_leg"), s.x + s.width - 20, s.y + s.height - 4)
            g.draw(spr, s.x, s.y)
        end
    end

    g.setColor(1, 1, 1)
    for _, s in ipairs(self.spikes) do
        if visible(s.x, s.width) then
            local spr = GFX.get("spikes")
            if spr then
                local yOffset = (spr:getHeight() < s.height) and (s.height - spr:getHeight()) or 0
                g.draw(spr, s.x, s.y + yOffset)
            end
        end
    end
    for _, c in ipairs(self.collectibles) do
        if not c.collected and visible(c.x, 32) then
            local cx, cy = c.x + 13, c.y + 15 + (c.floatOffset or 0)
            local pulse = 0.8 + math.sin(time * 2 + c.x) * 0.2
            local color = c.type == "acorn" and {1, 0.76, 0.26} or {0.66, 0.91, 0.49}
            glow(cx, cy, 30 * pulse, color, 0.055)
            local a = time * 1.4 + c.x
            sparkle(cx + math.cos(a) * 21, cy + math.sin(a) * 18, 3.2, 0.65)
            sparkle(cx - math.cos(a + 1.1) * 20, cy - math.sin(a + 1.1) * 17, 2, 0.45)
            g.setColor(1, 1, 1)
            local itemSpr = GFX.get(c.type == "acorn" and "acorn" or "chestnut_pickup")
            if itemSpr then
                if c.type == "acorn" and itemSpr:getHeight() > 50 then
                    g.draw(itemSpr, c.x + 13, c.y + 15 + (c.floatOffset or 0), 0, 0.48, 0.48, itemSpr:getWidth() * 0.5, itemSpr:getHeight() * 0.5)
                else
                    g.draw(itemSpr, c.x, c.y + (c.floatOffset or 0))
                end
            end
        end
    end

    if self.checkpoint and visible(self.checkpoint.x, self.checkpoint.width) then
        local cp = self.checkpoint
        local color = cp.active and {0.46, 0.93, 0.75} or {1, 0.78, 0.38}
        glow(cp.x + 18, cp.y + 17, cp.active and 52 or 31, color, cp.active and 0.06 or 0.035)
        g.setColor(color[1], color[2], color[3], cp.active and 0.32 or 0.12)
        g.draw(GFX.get("checkpoint_ring"), cp.x + 18, cp.y + 59, 0,
            (29 + math.sin(time * 2) * 3) / 32, 1, 33, 8)
        if cp.active then
            for i = 1, 5 do
                local y = (time * 13 + i * 17) % 75
                g.setColor(color[1], color[2], color[3], (1 - y / 75) * 0.7)
                GFX.disc(cp.x + 18 + math.sin(i * 3 + time) * 23, cp.y + 48 - y, 1.4)
            end
        end
        g.setColor(1, 1, 1)
        g.draw(GFX.get(cp.active and "checkpoint_on" or "checkpoint_off"), cp.x, cp.y)
    end

    if self.hollow and visible(self.hollow.x, self.hollow.width) then
        local h = self.hollow
        glow(h.x + 55, h.y + 90, 85, {1, 0.73, 0.33}, 0.033 + math.sin(time * 1.7) * 0.005)
        g.setColor(1, 0.78, 0.40, 0.08)
        g.draw(GFX.get("hollow_glow"), h.x + 55, h.y + h.height, 0, 1, 1, 64, 13)
        g.setColor(1, 1, 1)
        g.draw(GFX.get("hollow_tree"), h.x, h.y)
        glow(h.x + 75, h.y + 82, 25, {1, 0.82, 0.44}, 0.05)
    end
    g.pop()
end

return Level
