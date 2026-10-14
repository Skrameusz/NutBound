local config = require("src.config")
local Audio = require("src.audio")
local i18n = require("src.i18n")
local Theme = require("src.theme")
local MenuNavigation = require("src.menu_navigation")
local GFX = require("src.graphics")

local PauseState = {}
PauseState.__index = PauseState

function PauseState.new(stateManager)
    return setmetatable({stateManager = stateManager, selected = 1}, PauseState)
end

function PauseState:enter(params)
    self.playState = params and params.playState or self.playState
    self.selected = 1
end

function PauseState:buttons()
    return {
        {id = "resume", label = i18n.get("resume"), x = 212, y = 224, w = 340, h = 56},
        {id = "restart", label = i18n.get("restart"), x = 212, y = 296, w = 340, h = 56, size = 20},
        {id = "options", label = i18n.get("options"), x = 212, y = 368, w = 340, h = 56},
        {id = "menu", label = i18n.get("back_to_menu"), x = 212, y = 440, w = 340, h = 56},
    }
end

PauseState.update = MenuNavigation.update

function PauseState:activate(id)
    Audio.play("jump")
    if id == "resume" then
        self.stateManager:pop()
    elseif id == "restart" then
        if self.playState then self.playState:respawnPlayer() end
        self.stateManager:pop()
    elseif id == "options" then
        self.stateManager:push("options", {background = self})
    elseif id == "menu" then
        self.stateManager:switch("menu")
    end
end

PauseState.mousepressed = MenuNavigation.mousepressed

function PauseState:keypressed(key)
    if key == "escape" then
        self.stateManager:pop()
    elseif key == "r" then
        self:activate("restart")
    elseif key == "l" then
        i18n.toggleLanguage()
    else
        MenuNavigation.keypressed(self, key)
    end
end

function PauseState:draw()
    if self.playState then self.playState:draw() end
    love.graphics.push("all")
    Theme.dim(0.78)
    Theme.panel(168, 92, 944, 536)
    Theme.text(i18n.get("paused"), 212, 124, 40, "ivory", nil, nil, true)
    Theme.rule(212, 188, 856)

    Theme.text(i18n.get("controls_title"), 644, 224, 21, "ivory")
    local controls = {
        {"A / D", "control_move"}, {i18n.get("key_space") .. " / W", "control_jump"},
        {i18n.get("key_mouse"), "control_aim"}, {i18n.get("key_lmb"), "control_shoot"},
        {"Q / " .. i18n.get("key_rmb"), "control_ammo"}, {"ESC", "control_pause"},
    }
    for index, c in ipairs(controls) do
        local y = 264 + (index - 1) * 41
        Theme.keycap(c[1], 644, y, 121)
        Theme.text(i18n.get(c[2]), 784, y + 3, 20, "ivory")
    end
    Theme.color("line", 0.5)
    GFX.rect(604, 224, 1, 278)
    MenuNavigation.drawButtons(self)

    Theme.rule(212, 534, 856)
    if self.playState then
        local p = self.playState.player
        local acorn = GFX.get("acorn")
        love.graphics.setColor(1, 1, 1)
        Theme.image(acorn, 228, 578, 32)
        Theme.text(string.format("%d / %d", p.acorns, config.REQUIRED_ACORNS), 258, 565, 24, "accent")
        local saved = self.playState.level.checkpoint and self.playState.level.checkpoint.active
        Theme.text(i18n.get(saved and "checkpoint_ready" or "checkpoint_pending"), 410, 570, 18, "muted")
        local seconds = self.playState.gameTime or 0
        Theme.text(string.format("%02d:%02d", math.floor(seconds / 60), math.floor(seconds % 60)), 929, 563, 27, "ivory", 135, "right")
    end
    Theme.cursor()
    love.graphics.pop()
end

return PauseState
