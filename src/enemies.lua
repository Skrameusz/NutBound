local config = require("src.config")
local GFX = require("src.graphics")
local Collision = require("src.collision")

local enemies = {}

local function drawGroundEnemy(enemy, sprite, phase)
    local cx, feet = enemy.x + enemy.width * 0.5, enemy.y + enemy.height
    love.graphics.setColor(0.09, 0.15, 0.13, 0.23)
    love.graphics.draw(GFX.get("shadow_" .. enemy.width), cx, feet, 0, 1, 1, 20, 4)
    local bounce = math.sin(phase * math.pi * 2) * 0.025
    love.graphics.setColor(1, enemy.hurtTimer > 0 and 0.62 or 1, enemy.hurtTimer > 0 and 0.48 or 1, 1)
    local isCustom = sprite:getHeight() > 50
    local scale = isCustom and 0.25 or 1
    local facingMul = isCustom and -1 or 1
    love.graphics.draw(sprite, cx, feet, 0, enemy.facing * facingMul * (1 - bounce) * scale, (1 + bounce) * scale,
        sprite:getWidth() * 0.5, sprite:getHeight())
    love.graphics.setColor(1, 1, 1, 1)
end

local BaseEnemy = {}
BaseEnemy.__index = BaseEnemy

function BaseEnemy:new(x, y, width, height, hp, damage)
    return setmetatable({
        x = x, y = y, startX = x, startY = y, width = width, height = height,
        hp = hp, maxHp = hp, damage = damage, alive = true, facing = 1, hurtTimer = 0,
    }, self)
end

function BaseEnemy:checkHit(px, py, radius)
    if not self.alive then return false end
    return Collision.circleRect(self, px, py, radius)
end

local function newGroundEnemy(class, x, y, width, height, hp, damage, speed, patrolRange)
    local self = BaseEnemy.new(class, x, y, width, height, hp, damage)
    self.patrolRange = patrolRange
    self.minX, self.maxX = x - patrolRange, x + patrolRange
    self.speed, self.vx = speed, speed
    self.walkTimer, self.frame = 0, 0
    return self
end

function BaseEnemy:takeDamage(dmg, particles)
    if not self.alive then return end
    self.hp = self.hp - dmg
    self.hurtTimer = 0.18

    if self.hp <= 0 then
        self.alive = false
        if particles then
            particles:spawnSparkle(self.x + self.width * 0.5, self.y + self.height * 0.5, 12, { 0.95, 0.7, 0.2 })
            particles:spawnDust(self.x + self.width * 0.5, self.y + self.height * 0.5, 8)
        end
    end
end

local function updateGroundPatrol(enemy, dt, level, animationSpeed, maxFrames)
    if not enemy.alive then return end

    enemy.hurtTimer = math.max(0, enemy.hurtTimer - dt)
    enemy.walkTimer = enemy.walkTimer + dt * animationSpeed
    enemy.frame = math.floor(enemy.walkTimer) % maxFrames

    local nextX = enemy.x + enemy.vx * dt
    local frontX = enemy.facing == 1 and (nextX + enemy.width + 4) or (nextX - 4)
    local footY = enemy.y + enemy.height + 4

    if nextX > enemy.maxX then
        enemy.vx, enemy.facing = -enemy.speed, -1
    elseif nextX < enemy.minX then
        enemy.vx, enemy.facing = enemy.speed, 1
    elseif level:isSolid(frontX, enemy.y + enemy.height * 0.5)
        or (not level:isSolid(frontX, footY) and not level:isPlatform(frontX, footY)) then
        enemy.vx, enemy.facing = -enemy.vx, -enemy.facing
    else
        enemy.x = nextX
    end
end

local Hedgehog = setmetatable({}, { __index = BaseEnemy })
Hedgehog.__index = Hedgehog

function Hedgehog.new(x, y, patrolRange)
    return newGroundEnemy(Hedgehog, x, y, 36, 26, config.HEDGEHOG_HP,
        config.HEDGEHOG_DAMAGE, config.HEDGEHOG_SPEED, patrolRange or 140)
end

function Hedgehog:update(dt, level)
    updateGroundPatrol(self, dt, level, 6, 5)
end

function Hedgehog:draw()
    if not self.alive then return end
    local sprName = "hedgehog_" .. (self.frame or 0)
    local spr = GFX.get(sprName) or GFX.get("hedgehog_0")

    drawGroundEnemy(self, spr, self.walkTimer)
end

local Crow = setmetatable({}, { __index = BaseEnemy })
Crow.__index = Crow

function Crow.new(x, y)
    local self = BaseEnemy.new(Crow, x, y, 36, 30, config.CROW_HP, config.CROW_DAMAGE)
    self.state = "perch"
    self.diveTargetY = 0
    self.diveVx, self.diveVy = 0, 0
    self.flapTimer = 0
    self.perchCooldown = 0
    return self
end

function Crow:update(dt, level, player)
    if not self.alive then return end

    if self.hurtTimer > 0 then
        self.hurtTimer = self.hurtTimer - dt
    end

    self.flapTimer = self.flapTimer + dt * 6

    if self.state == "perch" then
        self.y = self.startY + math.sin(self.flapTimer * 0.8) * 6

        if player and player.alive then
            local px = player.x + player.width * 0.5
            local py = player.y + player.height * 0.5
            local dx = px - (self.x + self.width * 0.5)
            local dy = py - (self.y + self.height * 0.5)
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < config.CROW_DETECT_RANGE and dy > 20 and self.perchCooldown <= 0 then
                self.state = "dive"
                self.diveTargetY = py
                local divSpeed = config.CROW_DIVE_SPEED
                self.diveVx = (dx / dist) * divSpeed
                self.diveVy = (dy / dist) * divSpeed
                self.facing = (dx > 0) and 1 or -1
            end
        end

        if self.perchCooldown > 0 then
            self.perchCooldown = self.perchCooldown - dt
        end

    elseif self.state == "dive" then
        self.x = self.x + self.diveVx * dt
        self.y = self.y + self.diveVy * dt

        if self.y >= self.diveTargetY - 10 or level:isSolid(self.x + self.width * 0.5, self.y + self.height + 6) then
            self.state = "return"
        end

    elseif self.state == "return" then
        local dx = self.startX - self.x
        local dy = self.startY - self.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < 12 then
            self.x = self.startX
            self.y = self.startY
            self.state = "perch"
            self.perchCooldown = 1.8
        else
            local retSpeed = config.CROW_RETURN_SPEED
            self.x = self.x + (dx / dist) * retSpeed * dt
            self.y = self.y + (dy / dist) * retSpeed * dt
            self.facing = (dx > 0) and 1 or -1
        end
    end
end

function Crow:draw()
    if not self.alive then return end

    local sprName
    if self.state == "dive" then
        sprName = "crow_glide"
    else
        local flap = math.floor(self.flapTimer) % 2
        sprName = (flap == 1) and "crow_flap_up" or "crow_flap_down"
    end

    local spr = GFX.get(sprName)
    love.graphics.setColor(1, 1, 1, 1)
    if self.hurtTimer > 0 then
        love.graphics.setColor(1, 0.4, 0.4, 1)
    end

    local tilt = self.state == "dive" and self.facing * 0.28 or math.sin(self.flapTimer) * 0.035
    love.graphics.draw(spr, self.x + self.width * 0.5, self.y + self.height * 0.5,
        tilt, self.facing, 1, 19, 16)
    if self.state == "dive" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(GFX.get("crow_alert"), self.x + self.width * 0.5, self.y - 8, 0, 1, 1, 7, 7)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

local Beetle = setmetatable({}, { __index = BaseEnemy })
Beetle.__index = Beetle

function Beetle.new(x, y, patrolRange)
    return newGroundEnemy(Beetle, x, y, 44, 30, config.BEETLE_HP,
        config.BEETLE_DAMAGE, config.BEETLE_SPEED, patrolRange or 160)
end

function Beetle:update(dt, level)
    updateGroundPatrol(self, dt, level, 3, 2)
end

function Beetle:draw()
    if not self.alive then return end
    local sprName = (self.frame == 1) and "beetle_1" or "beetle_0"
    local spr = GFX.get(sprName)

    drawGroundEnemy(self, spr, self.walkTimer)

    if self.hp < self.maxHp then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(GFX.get("beetle_hp_" .. self.hp), self.x + (self.width - 36) * 0.5, self.y - 10)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

enemies.Hedgehog = Hedgehog
enemies.Crow = Crow
enemies.Beetle = Beetle

return enemies
