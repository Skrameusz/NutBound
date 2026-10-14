local config = require("src.config")

local Camera = {}
Camera.__index = Camera

function Camera.new()
    return setmetatable({
        x = 0, y = 0, targetX = 0, targetY = 0,
        minX = 0, maxX = 4000, minY = 0, maxY = 720 - config.VIRTUAL_HEIGHT,
        locked = false, lockMinX = 0, lockMaxX = 0,
        shakeMag = 0, shakeDuration = 0, shakeTimer = 0,
        shakeOffsetX = 0, shakeOffsetY = 0,
    }, Camera)
end

function Camera:setBounds(minX, maxX, minY, maxY)
    self.minX = minX
    self.maxX = maxX
    self.minY = minY
    self.maxY = math.max(minY, maxY - config.VIRTUAL_HEIGHT)
end

function Camera:lockArena(minX, maxX)
    self.locked = true
    self.lockMinX = minX
    self.lockMaxX = maxX
end

function Camera:unlockArena()
    self.locked = false
end

function Camera:addShake(magnitude, duration)
    if not config.screenShakeEnabled then return end
    self.shakeMag = math.max(self.shakeMag, magnitude)
    self.shakeDuration = duration or 0.25
    self.shakeTimer = self.shakeDuration
end

function Camera:update(dt, targetX, targetY)
    self.targetX = targetX - config.VIRTUAL_WIDTH * 0.45
    self.targetY = targetY - config.VIRTUAL_HEIGHT * 0.6

    local effMinX = self.locked and self.lockMinX or self.minX
    local effMaxX = self.locked and (self.lockMaxX - config.VIRTUAL_WIDTH) or (self.maxX - config.VIRTUAL_WIDTH)
    if effMaxX < effMinX then effMaxX = effMinX end

    if self.targetX < effMinX then self.targetX = effMinX end
    if self.targetX > effMaxX then self.targetX = effMaxX end
    if self.targetY < self.minY then self.targetY = self.minY end
    if self.targetY > self.maxY then self.targetY = self.maxY end

    local lerpFactor = 1 - math.exp(-8.0 * dt)
    self.x = self.x + (self.targetX - self.x) * lerpFactor
    self.y = self.y + (self.targetY - self.y) * lerpFactor

    self.shakeTimer = math.max(0, self.shakeTimer - dt)
    if self.shakeTimer > 0 and config.screenShakeEnabled then
        local progress = self.shakeTimer / self.shakeDuration
        local currentMag = self.shakeMag * progress
        self.shakeOffsetX = (math.random() * 2 - 1) * currentMag
        self.shakeOffsetY = (math.random() * 2 - 1) * currentMag
    else
        self.shakeMag = 0
        self.shakeOffsetX = 0
        self.shakeOffsetY = 0
    end
end

function Camera:attach()
    love.graphics.push()
    love.graphics.translate(-math.floor(self.x + self.shakeOffsetX), -math.floor(self.y + self.shakeOffsetY))
end

function Camera:detach()
    love.graphics.pop()
end

function Camera:toWorld(screenX, screenY)
    return screenX + self.x + self.shakeOffsetX, screenY + self.y + self.shakeOffsetY
end

return Camera
