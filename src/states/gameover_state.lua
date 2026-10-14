local Audio = require("src.audio")
local i18n = require("src.i18n")
local Theme = require("src.theme")
local MenuNavigation = require("src.menu_navigation")
local GFX = require("src.graphics")

local GameOverState = {}
GameOverState.__index = GameOverState

function GameOverState.new(stateManager)
    return setmetatable({stateManager = stateManager, selected = 1}, GameOverState)
end

function GameOverState:enter(params)
    self.playState = params and params.playState or nil
    self.selected = 1
end

function GameOverState:buttons()
    return {
        {id = "respawn", label = i18n.get("respawn_prompt"), x = 448, y = 402, w = 384, h = 58},
        {id = "menu", label = i18n.get("back_to_menu"), x = 448, y = 478, w = 384, h = 50},
    }
end

GameOverState.update = MenuNavigation.update

function GameOverState:respawnPlayer()
    if self.playState then
        self.playState:respawnPlayer()
        self.stateManager:pop()
    else
        self.stateManager:switch("play")
    end
end

function GameOverState:activate(id)
    Audio.play("jump")
    if id == "respawn" then
        self:respawnPlayer()
    elseif id == "menu" then
        self.stateManager:switch("menu")
    end
end

GameOverState.mousepressed = MenuNavigation.mousepressed

function GameOverState:keypressed(key)
    if key == "escape" then
        self.stateManager:switch("menu")
    else
        MenuNavigation.keypressed(self, key)
    end
end

function GameOverState:draw()
    if self.playState then self.playState:draw() end
    love.graphics.push("all")
    Theme.dim(0.86)
    Theme.panel(330, 125, 620, 454)
    local squirrel = GFX.get("player_hurt")
    love.graphics.setColor(1, 1, 1)
    local isCustom = squirrel:getHeight() > 50
    local scale = isCustom and (1.65 * 0.25) or 1.65
    local ox = isCustom and 106 or squirrel:getWidth() / 2
    love.graphics.draw(squirrel, 640, 236, 0, scale, scale, ox, squirrel:getHeight())
    Theme.text(i18n.get("game_over"), 354, 269, 40, "ivory", 572, "center", true)
    Theme.text(i18n.get("respawn_note"), 354, 335, 20, "muted", 572, "center")
    MenuNavigation.drawButtons(self)
    Theme.cursor()
    love.graphics.pop()
end

return GameOverState
