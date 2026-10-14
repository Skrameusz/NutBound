local config = require("src.config")
local GFX = require("src.graphics")
local Audio = require("src.audio")
local i18n = require("src.i18n")
local Theme = require("src.theme")
local MenuNavigation = require("src.menu_navigation")
local Scenery = require("src.scenery")

local VictoryState = {}
VictoryState.__index = VictoryState

function VictoryState.new(stateManager)
    return setmetatable({stateManager = stateManager, selected = 1, timer = 0, stats = {}}, VictoryState)
end

function VictoryState:enter(params)
    self.stats = params or {}
    self.selected = 1
    self.timer = 0
    Audio.play("victory")
end

function VictoryState:buttons()
    return {
        {id = "replay", label = i18n.get("play_again"), x = 126, y = 502, w = 280, h = 58},
        {id = "menu", label = i18n.get("back_to_menu"), x = 426, y = 502, w = 250, h = 58},
    }
end

function VictoryState:update(dt)
    self.timer = self.timer + dt
    MenuNavigation.update(self)
end

function VictoryState:activate(id)
    Audio.play("jump")
    self.stateManager:switch(id == "replay" and "play" or "menu")
end

VictoryState.mousepressed = MenuNavigation.mousepressed

function VictoryState:keypressed(key)
    if key == "escape" then
        self.stateManager:switch("menu")
    elseif key == "left" or key == "right" then
        self.selected = self.selected == 1 and 2 or 1
    else
        MenuNavigation.keypressed(self, key)
    end
end

function VictoryState:draw()
    love.graphics.push("all")
    Scenery.draw(550, 0, self.timer)
    Theme.dim(0.58)
    Theme.panel(82, 121, 1116, 478, 0.96)
    Theme.text(i18n.get("victory_title"), 126, 176, 46, "ivory", 680, "left", true)
    Theme.rule(126, 266, 550)

    local seconds = self.stats.time or 0
    local stats = {
        {label = "stat_time", value = string.format("%02d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))},
        {label = "stat_acorns", value = string.format("%d / %d", self.stats.acorns or 0, self.stats.maxAcorns or config.REQUIRED_ACORNS)},
        {label = "stat_enemies", value = tostring(self.stats.enemies or 0)},
    }
    for index, stat in ipairs(stats) do
        local x = 127 + (index - 1) * 190
        Theme.text(i18n.get(stat.label), x, 311, 17, "muted")
        Theme.text(stat.value, x, 347, 38, index == 2 and "accent" or "ivory", nil, nil, true)
    end

    love.graphics.setColor(1, 1, 1)
    local hollow = GFX.get("hollow_tree")
    love.graphics.draw(hollow, 987, 469, 0, 1.65, 1.65, hollow:getWidth() / 2, hollow:getHeight())
    local squirrel = GFX.get("player_idle_0")
    local isCustom = squirrel:getHeight() > 50
    local scale = isCustom and (2.3 * 0.25) or 2.3
    local ox = isCustom and 106 or squirrel:getWidth() / 2
    love.graphics.draw(squirrel, 890, 475, 0, scale, scale, ox, squirrel:getHeight())
    local acorn = GFX.get("acorn")
    for index = 1, 5 do
        Theme.image(acorn, 945 + index * 24, 471 - (index % 2) * 5, 29)
    end
    MenuNavigation.drawButtons(self)
    Theme.cursor()
    love.graphics.pop()
end

return VictoryState
