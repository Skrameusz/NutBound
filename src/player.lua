local config = require("src.config")
local GFX = require("src.graphics")
local Audio = require("src.audio")
local Viewport = require("src.viewport")

local Player = {}
Player.__index = Player

function Player.new(x, y)
    return setmetatable({
        x = x, y = y, width = 34, height = 42, vx = 0, vy = 0,
        checkpointX = x, checkpointY = y,
        hp = config.PLAYER_MAX_HP, maxHp = config.PLAYER_MAX_HP,
        alive = true, hurtTimer = 0, knockbackTimer = 0,
        activeAmmo = "stone", chestnutAmmo = config.CHESTNUT_INITIAL_AMMO,
        acorns = 0, shootCooldown = 0,
        onGround = false, coyoteTimer = 0, jumpBufferTimer = 0,
        facing = 1, aimAngle = 0, runPhase = 0, visualTime = 0,
        landingTimer = 0, recoilTimer = 0,
    }, Player)
end

function Player:setCheckpoint(x, y)
    self.checkpointX = x
    self.checkpointY = y
end

local function returnToCheckpoint(self)
    self.x = self.checkpointX
    self.y = self.checkpointY
    self.vx = 0
    self.vy = 0
    self.onGround = false
    self.coyoteTimer = 0
    self.jumpBufferTimer = 0
    self.runPhase = 0
end

function Player:respawn()
    returnToCheckpoint(self)
    self.hp = self.maxHp
    self.alive = true
    self.hurtTimer = 0.5
    self.knockbackTimer = 0
    self.shootCooldown = 0
    self.landingTimer = 0
    self.recoilTimer = 0
end

function Player:switchAmmo()
    if self.activeAmmo == "stone" then
        if self.chestnutAmmo > 0 then
            self.activeAmmo = "chestnut"
            Audio.play("chestnut_pickup")
        end
    else
        self.activeAmmo = "stone"
    end
end

function Player:takeDamage(dmg, fromX, particles, camera)
    if not self.alive or self.hurtTimer > 0 then return end

    self.hp = self.hp - dmg
    self.hurtTimer = config.PLAYER_HURT_IFRAME
    self.knockbackTimer = 0.22

    local kx = (self.x > (fromX or self.x)) and 1 or -1
    self.vx = kx * config.PLAYER_KNOCKBACK_X
    self.vy = config.PLAYER_KNOCKBACK_Y

    Audio.play("hurt")
    if camera then camera:addShake(7, 0.3) end
    if particles then
        particles:spawnHitSparks(self.x + self.width * 0.5, self.y + self.height * 0.5, 10)
        particles:spawnDust(self.x + self.width * 0.5, self.y + self.height, 6)
    end

    if self.hp <= 0 then
        self.hp = 0
        self.alive = false
    end
end

function Player:update(dt, level, camera, weapons, particles)
    if not self.alive then return end

    self.visualTime = self.visualTime + dt
    self.landingTimer = math.max(0, self.landingTimer - dt)
    self.recoilTimer = math.max(0, self.recoilTimer - dt)
    if self.hurtTimer > 0 then self.hurtTimer = self.hurtTimer - dt end
    if self.knockbackTimer > 0 then self.knockbackTimer = self.knockbackTimer - dt end
    if self.shootCooldown > 0 then self.shootCooldown = self.shootCooldown - dt end

    local wasOnGround = self.onGround
    self.onGround = level:checkPlayerGrounded(self.x, self.y, self.width, self.height)

    if self.onGround then
        self.coyoteTimer = config.COYOTE_TIME
    else
        self.coyoteTimer = math.max(0, self.coyoteTimer - dt)
    end

    if self.jumpBufferTimer > 0 then
        self.jumpBufferTimer = self.jumpBufferTimer - dt
    end

    if self.knockbackTimer <= 0 then
        local moveInput = 0
        if love.keyboard.isDown("a", "left") then moveInput = moveInput - 1 end
        if love.keyboard.isDown("d", "right") then moveInput = moveInput + 1 end

        if moveInput ~= 0 then
            self.vx = self.vx + moveInput * config.PLAYER_ACCEL * dt
            if math.abs(self.vx) > config.PLAYER_SPEED then
                self.vx = (self.vx > 0) and config.PLAYER_SPEED or -config.PLAYER_SPEED
            end

            if self.onGround and math.random() < 0.25 and particles then
                particles:spawnDust(self.x + self.width * 0.5, self.y + self.height, 1)
            end
        else

            if self.vx > 0 then
                self.vx = math.max(0, self.vx - config.PLAYER_DECEL * dt)
            elseif self.vx < 0 then
                self.vx = math.min(0, self.vx + config.PLAYER_DECEL * dt)
            end
        end
    end

    if self.jumpBufferTimer > 0 and self.coyoteTimer > 0 then
        self.vy = config.PLAYER_JUMP_FORCE
        self.coyoteTimer = 0
        self.jumpBufferTimer = 0
        self.onGround = false
        Audio.play("jump")
        if particles then
            particles:spawnDust(self.x + self.width * 0.5, self.y + self.height, 4)
        end
    end

    if not love.keyboard.isDown("space", "w", "up") and self.vy < -200 then
        self.vy = self.vy * 0.55
    end

    self.vy = math.min(self.vy + config.GRAVITY * dt, config.MAX_FALL_SPEED)

    level:moveAndCollide(self, dt)

    if not wasOnGround and self.onGround then
        self.landingTimer = 0.18
        if particles then particles:spawnDust(self.x + self.width * 0.5, self.y + self.height, 4) end
    end

    if self.y > level.height + 60 then
        self:takeDamage(1, self.x, particles, camera)
        if not self.alive then return end
        returnToCheckpoint(self)
    end

    if self.onGround and math.abs(self.vx) > 20 then
        local walkSpeed = math.abs(self.vx) / config.PLAYER_SPEED
        self.runPhase = self.runPhase + dt * 10 * walkSpeed
    else
        self.runPhase = 0
    end

    local mouseScreenX, mouseScreenY = Viewport.getMousePosition()
    local mouseWorldX, mouseWorldY = camera:toWorld(mouseScreenX, mouseScreenY)
    local centerX = self.x + self.width * 0.5
    local centerY = self.y + self.height * 0.4
    self.aimAngle = math.atan2(mouseWorldY - centerY, mouseWorldX - centerX)

    if mouseWorldX > centerX + 10 then
        self.facing = 1
    elseif mouseWorldX < centerX - 10 then
        self.facing = -1
    end

    if love.mouse.isDown(1) and self.shootCooldown <= 0 then
        self.shootCooldown = config.SLINGSHOT_COOLDOWN
        self.recoilTimer = 0.13
        local spawnX = centerX + math.cos(self.aimAngle) * 20
        local spawnY = centerY + math.sin(self.aimAngle) * 20

        if self.activeAmmo == "chestnut" and self.chestnutAmmo > 0 then
            self.chestnutAmmo = self.chestnutAmmo - 1
            weapons:spawnChestnut(spawnX, spawnY, mouseWorldX, mouseWorldY)
            if self.chestnutAmmo <= 0 then
                self.activeAmmo = "stone"
            end
        else
            weapons:spawnStone(spawnX, spawnY, mouseWorldX, mouseWorldY)
        end
    end
end

function Player:keypressed(key)
    if key == "space" or key == "w" or key == "up" then
        self.jumpBufferTimer = config.JUMP_BUFFER
    elseif key == "q" then
        self:switchAmmo()
    end
end

function Player:mousepressed(x, y, button)
    if button == 2 then
        self:switchAmmo()
    end
end

function Player:draw()
    if not self.alive then return end

    if self.onGround then
        love.graphics.setColor(0.10, 0.14, 0.12, 0.26)
        love.graphics.draw(GFX.get("shadow_player"), self.x + self.width * 0.5, self.y + self.height, 0, 1, 1, 16, 4)
    end
    local alpha = self.hurtTimer > 0 and (math.floor(self.hurtTimer * 20) % 2 == 1) and 0.35 or 1

    local sprName = "player_idle_0"
    if self.hurtTimer > 0 and self.knockbackTimer > 0 then
        sprName = "player_hurt"
    elseif not self.onGround then
        sprName = (self.vy < 0) and "player_jump" or "player_fall"
    elseif math.abs(self.vx) > 20 then
        local runIdx = math.floor(self.runPhase) % 6
        sprName = "player_run_" .. runIdx
    else
        local idleIdx = math.floor((self.visualTime or 0) * 3) % 4
        sprName = "player_idle_" .. idleIdx
    end

    local spr = GFX.get(sprName) or GFX.get("player_idle_0")
    love.graphics.setColor(1, 1, 1, alpha)

    local sx, sy = 1, 1
    if self.onGround then
        local breath = math.sin(self.visualTime * 3.2) * 0.014
        sx, sy = 1 - breath * 0.5, 1 + breath
        if math.abs(self.vx) > 20 then
            local stride = math.sin((self.runPhase / 6) * math.pi * 4) * 0.025
            sx, sy = 1 - stride, 1 + stride
        end
        if self.landingTimer > 0 then
            local squash = math.sin(self.landingTimer / 0.18 * math.pi) * 0.13
            sx, sy = sx + squash, sy - squash
        end
    else
        local stretch = math.min(math.abs(self.vy) / 1800, 0.07)
        sx, sy = 1 - stretch * 0.5, 1 + stretch
    end
    local recoil = (self.recoilTimer / 0.13) * 2
    local tilt = self.onGround and self.vx / config.PLAYER_SPEED * 0.025 or 0
    local isCustom = spr:getHeight() > 50
    local scale = isCustom and 0.25 or 1
    local ox = isCustom and 106 or 20
    local oy = isCustom and 168 or 44

    love.graphics.draw(spr, self.x + self.width * 0.5 - math.cos(self.aimAngle) * recoil,
        self.y + self.height, tilt, sx * self.facing * scale, sy * scale, ox, oy)
    love.graphics.setColor(1, 1, 1, 1)
end

return Player
