local config = require("src.config")
local GFX = require("src.graphics")
local Audio = require("src.audio")
local Collision = require("src.collision")

local CatBoss = {}
CatBoss.__index = CatBoss

function CatBoss.new(x, y, arenaLeft, arenaRight)
    return setmetatable({
        x = x, y = y, baseY = y, width = 100, height = 70,
        arenaLeft = arenaLeft, arenaRight = arenaRight,
        hp = config.BOSS_MAX_HP, maxHp = config.BOSS_MAX_HP, damage = config.BOSS_DAMAGE,
        alive = true, active = false, defeated = false,
        state = "idle", stateTimer = 1.2, facing = -1, vx = 0, vy = 0,
        hurtCooldown = 0, hurtFlash = 0, animTimer = 0, frame = 0,
        targetLandingX = 0, attackCount = 0,
    }, CatBoss)
end

function CatBoss:activate()
    if not self.active and self.alive then
        self.active = true
        self.state = "idle"
        self.stateTimer = 1.0
        Audio.play("boss_roar")
    end
end

function CatBoss:checkHit(px, py, radius)
    if not self.active or not self.alive or self.defeated then return false end

    if self.state == "jumping" then return false end

    return Collision.circleRect(self, px, py, radius)
end

function CatBoss:takeDamage(dmg, particles)
    if not self.active or not self.alive or self.defeated then return end
    if self.hurtCooldown > 0 then return end

    self.hp = self.hp - dmg
    self.hurtCooldown = config.BOSS_HURT_COOLDOWN
    self.hurtFlash = 0.22

    if particles then
        particles:spawnHitSparks(self.x + self.width * 0.5, self.y + self.height * 0.5, 14)
    end

    if self.hp <= 0 then
        self.hp = 0
        self.alive = false
        self.defeated = true
        self.state = "flee"
        self.stateTimer = 3.0
        Audio.play("victory")
        if particles then
            particles:spawnSparkle(self.x + self.width * 0.5, self.y + self.height * 0.5, 25, { 1.0, 0.85, 0.2 })
        end
    end
end

function CatBoss:update(dt, player, particles, camera)
    if not self.active then return end

    if self.hurtCooldown > 0 then self.hurtCooldown = self.hurtCooldown - dt end
    if self.hurtFlash > 0 then self.hurtFlash = self.hurtFlash - dt end

    self.animTimer = self.animTimer + dt * 5
    self.frame = (math.floor(self.animTimer) % 2)

    self.stateTimer = self.stateTimer - dt

    if player and player.alive and (self.state == "idle" or self.state == "telegraph_charge" or self.state == "telegraph_jump") then
        self.facing = (player.x + player.width * 0.5 < self.x + self.width * 0.5) and -1 or 1
    end

    if self.state == "idle" then
        self.vx = 0
        self.vy = 0
        if self.stateTimer <= 0 then
            self.attackCount = self.attackCount + 1

            if self.attackCount % 2 == 1 then
                self.state = "telegraph_charge"
                self.stateTimer = 1.1
            else
                self.state = "telegraph_jump"
                self.stateTimer = 1.0
            end
            Audio.play("boss_roar")
        end

    elseif self.state == "telegraph_charge" then
        self.vx = 0
        if self.stateTimer <= 0 then
            self.state = "charge"
            self.stateTimer = 1.8
            self.vx = self.facing * config.BOSS_CHARGE_SPEED
        end

    elseif self.state == "charge" then
        self.x = self.x + self.vx * dt

        if particles and math.random() < 0.6 then
            particles:spawnDust(self.x + self.width * 0.5, self.y + self.height, 2)
        end

        local hitLeftWall = (self.x <= self.arenaLeft + 20)
        local hitRightWall = (self.x + self.width >= self.arenaRight - 20)

        if hitLeftWall or hitRightWall or self.stateTimer <= 0 then
            if hitLeftWall then self.x = self.arenaLeft + 20 end
            if hitRightWall then self.x = self.arenaRight - 20 - self.width end
            self.state = "vulnerable_charge"
            self.stateTimer = 1.6
            self.vx = 0
            if camera then camera:addShake(6, 0.25) end
            if particles then particles:spawnDust(self.x + self.width * 0.5, self.y + self.height, 8) end
        end

    elseif self.state == "vulnerable_charge" or self.state == "vulnerable_pounce" then
        self.vx = 0
        if self.stateTimer <= 0 then
            self.state = "idle"
            self.stateTimer = 0.8
        end

    elseif self.state == "telegraph_jump" then
        self.vx = 0
        if self.stateTimer <= 0 then
            if player and player.alive then
                self.targetLandingX = player.x + player.width * 0.5 - self.width * 0.5

                if self.targetLandingX < self.arenaLeft + 40 then self.targetLandingX = self.arenaLeft + 40 end
                if self.targetLandingX > self.arenaRight - 40 - self.width then self.targetLandingX = self.arenaRight - 40 - self.width end
            else
                self.targetLandingX = self.x
            end

            self.state = "jumping"
            self.stateTimer = 0.75
            self.vy = -750
        end

    elseif self.state == "jumping" then
        self.y = self.y + self.vy * dt
        self.vy = self.vy + 1200 * dt

        local dx = self.targetLandingX - self.x
        self.x = self.x + dx * 4 * dt

        if self.stateTimer <= 0 then
            self.state = "pounce_fall"
            self.vy = 950
        end

    elseif self.state == "pounce_fall" then
        self.y = self.y + self.vy * dt
        if self.y >= self.baseY then
            self.y = self.baseY
            self.vy = 0
            self.state = "vulnerable_pounce"
            self.stateTimer = 1.5

            Audio.play("boss_slam")
            if camera then camera:addShake(10, 0.4) end
            if particles then
                particles:spawnShockwave(self.x + self.width * 0.5, self.y + self.height, 85)
                particles:spawnDust(self.x + self.width * 0.5, self.y + self.height, 14)
            end
        end

    elseif self.state == "flee" then
        self.facing = 1
        self.x = self.x + 350 * dt
        self.y = self.baseY
        if particles and math.random() < 0.4 then
            particles:spawnSparkle(self.x, self.y + self.height * 0.5, 2, { 1.0, 0.9, 0.3 })
        end
    end
end

function CatBoss:draw()
    if not self.active then return end

    local cx, feet = self.x + self.width * 0.5, self.baseY + self.height
    local airHeight = math.max(0, self.baseY - self.y)
    local shadowScale = math.max(0.4, 1 - airHeight / 700)
    love.graphics.setColor(0.09, 0.15, 0.13, 0.26 * shadowScale)
    love.graphics.draw(GFX.get("shadow_boss"), cx, feet, 0, shadowScale, shadowScale, 45, 7)
    love.graphics.setColor(1, 1, 1, 1)

    if self.state == "jumping" or self.state == "pounce_fall" then
        local targetSpr = GFX.get("boss_target")
        local pulse = 1 + math.sin(self.animTimer * 10) * 0.07
        love.graphics.draw(targetSpr, self.targetLandingX + self.width * 0.5, feet - 2, 0, pulse, pulse, 45, 12)
    end

    if self.state == "telegraph_charge" then
        local pulse = 0.6 + math.sin(self.animTimer * 11) * 0.2
        for i = 1, 3 do
            local ax = cx + self.facing * (48 + i * 24)
            love.graphics.setColor(1, 0.58, 0.27, pulse * (1 - i * 0.16))
            love.graphics.draw(GFX.get("charge_arrow"), ax, feet - 4, 0, self.facing, 1, 2, 6)
        end
    end
    if self.state == "telegraph_charge" or self.state == "telegraph_jump" then
        local badgeX, badgeY = cx + self.facing * 28, self.y - 14
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(GFX.get("boss_alert"), badgeX, badgeY, 0, 1, 1, 13, 13)
    end

    local sprName = "boss_idle"
    if self.state == "telegraph_charge" or self.state == "telegraph_jump" then
        sprName = "boss_telegraph"
    elseif self.state == "charge" then
        sprName = (self.frame == 1) and "boss_charge_1" or "boss_charge_0"
    elseif self.state == "jumping" or self.state == "pounce_fall" then
        sprName = "boss_pounce"
    elseif self.state == "vulnerable_charge" or self.state == "vulnerable_pounce" or self.state == "flee" then
        sprName = "boss_dazed"
    end

    local spr = GFX.get(sprName)

    love.graphics.setColor(1, 1, 1, 1)
    if self.hurtFlash > 0 then
        love.graphics.setColor(1, 0.3, 0.3, 1)
    end

    local sx, sy = 1, 1
    local offsetX = 0
    if self.state == "idle" then
        sy = 1 + math.sin(self.animTimer * 0.6) * 0.015
    elseif self.state == "telegraph_charge" or self.state == "telegraph_jump" then
        offsetX = math.sin(self.animTimer * 23) * 1.3
    elseif self.state == "charge" then
        sx, sy = 1.04, 0.97
    elseif self.state == "vulnerable_charge" or self.state == "vulnerable_pounce" then
        sy = 0.97 + math.sin(self.animTimer * 1.4) * 0.01
    end
    love.graphics.draw(spr, cx + offsetX, self.y + self.height, 0,
        sx * self.facing, sy, 57.5, 76)
    love.graphics.setColor(1, 1, 1, 1)
end

return CatBoss
