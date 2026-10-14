local config = require("src.config")
local Camera = require("src.camera")
local Particles = require("src.particles")
local Level = require("src.level")
local Player = require("src.player")
local Weapons = require("src.weapons")
local UI = require("src.ui")
local Audio = require("src.audio")
local i18n = require("src.i18n")
local Scenery = require("src.scenery")

local PlayState = {}
PlayState.__index = PlayState

function PlayState.new(stateManager)
    local self = setmetatable({}, PlayState)
    self.stateManager = stateManager
    self:resetGame()
    return self
end

function PlayState:resetGame()
    self.camera = Camera.new()
    self.particles = Particles.new()
    self.level = Level.new(self.particles, self.camera)
    self.player = Player.new(4 * config.TILE_SIZE, 11 * config.TILE_SIZE)
    self.weapons = Weapons.new(self.particles, self.camera)
    self.ui = UI.new()

    self.camera:setBounds(0, self.level.width, 0, self.level.height)

    self.gameTime = 0
    self.enemiesDefeated = 0
    self.bossNotifShown = false
    self.bossDefeatNotifShown = false

    self.lastAcorns = 0
    self.checkpointNotifShown = false
end

function PlayState:enter()
    self:resetGame()
    Audio.playMusic()
end

function PlayState:respawnPlayer()
    local level = self.level
    if level:resetArena() then
        self.bossNotifShown = false
    end
    self.player:respawn()
    self.weapons.projectiles = {}
    self.camera.x = math.max(0, math.min(level.width - config.VIRTUAL_WIDTH, self.player.x - config.VIRTUAL_WIDTH * 0.45))
    self.camera.y = 0
end

function PlayState:updateBoss(dt)
    local boss = self.level.boss
    if not boss then return end

    if boss.active and not self.bossNotifShown then
        self.bossNotifShown = true
        self.ui:showNotification(i18n.get("boss_appeared"), 3)
    end

    boss:update(dt, self.player, self.particles, self.camera)

    if boss.defeated and not self.bossDefeatNotifShown then
        self.bossDefeatNotifShown = true
        self.ui:showNotification(i18n.get("boss_defeated"), 4)
    end
end

function PlayState:updateProgress()
    local boss = self.level.boss
    self.enemiesDefeated = boss and boss.defeated and 1 or 0
    for _, enemy in ipairs(self.level.enemies) do
        if not enemy.alive then self.enemiesDefeated = self.enemiesDefeated + 1 end
    end
    if self.player.acorns > self.lastAcorns then
        self.particles:spawnFloatingText(self.player.x + 17, self.player.y - 8, "+" .. (self.player.acorns - self.lastAcorns))
        self.lastAcorns = self.player.acorns
    end
    local checkpoint = self.level.checkpoint
    if checkpoint and checkpoint.active and not self.checkpointNotifShown then
        self.checkpointNotifShown = true
        self.ui:showNotification(i18n.get("checkpoint_active"), 3)
    end
end

function PlayState:checkGameEnd()
    if not self.player.alive then
        self.stateManager:push("gameover", { playState = self })
        return
    end

    local boss = self.level.boss
    if not (boss and boss.defeated and self.level.inHollowZone
        and self.player.acorns >= config.REQUIRED_ACORNS) then
        return
    end

    if love.keyboard.isDown("w", "space", "up") then
        self.stateManager:switch("victory", {
            time = self.gameTime,
            acorns = self.player.acorns,
            maxAcorns = config.REQUIRED_ACORNS,
            enemies = self.enemiesDefeated
        })
    end
end

function PlayState:update(dt)
    self.gameTime = self.gameTime + dt
    self.particles:update(dt)
    self.player:update(dt, self.level, self.camera, self.weapons, self.particles)
    self.camera:update(dt, self.player.x + self.player.width * 0.5, self.player.y + self.player.height * 0.5)
    self.level:update(dt, self.player)

    for _, enemy in ipairs(self.level.enemies) do
        if enemy.alive then
            enemy:update(dt, self.level, self.player)
        end
    end

    self:updateBoss(dt)
    self.weapons:update(dt, self.level, self.level.enemies, self.level.boss)
    self:updateProgress()
    self.ui:update(dt)
    self:checkGameEnd()
end

function PlayState:keypressed(key)
    if key == "escape" then
        self.stateManager:push("pause", { playState = self })
    elseif key == "l" then
        i18n.toggleLanguage()
    else
        self.player:keypressed(key)
    end
end

function PlayState:mousepressed(x, y, button)
    self.player:mousepressed(x, y, button)
end

function PlayState:draw()
    Scenery.draw(self.camera.x, self.camera.y, self.level.visualTime)

    self.particles:drawAmbientLeaves(self.camera.x)

    self.camera:attach()

    self.level:draw()

    for _, enemy in ipairs(self.level.enemies) do
        enemy:draw()
    end

    if self.level.boss then
        self.level.boss:draw()
    end

    self.player:draw()

    self.weapons:draw()

    self.particles:draw()

    self.camera:detach()

    self.ui:drawHUD(self.player, self.level.boss, self.level)
end

return PlayState
