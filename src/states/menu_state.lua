local Audio = require("src.audio")
local i18n = require("src.i18n")
local Theme = require("src.theme")
local MenuNavigation = require("src.menu_navigation")
local Scene = require("src.menu_scene")
local Viewport = require("src.viewport")

local MenuState = {}
MenuState.__index = MenuState
local lg = love.graphics

function MenuState.new(stateManager)
    return setmetatable({stateManager = stateManager, selected = 1, timer = 0,
        parallaxX = 0, parallaxY = 0}, MenuState)
end

function MenuState:enter()
    self.selected, self.timer = 1, 0
    Audio.playMusic()
end

function MenuState:buttons()
    return {
        {id = "start", label = i18n.get("start_game"), x = 88, y = 306, w = 360, h = 58, size = 24},
        {id = "options", label = i18n.get("options"), x = 88, y = 378, w = 360, h = 58, size = 24},
        {id = "lang", label = i18n.get("language_name"), x = 88, y = 450, w = 360, h = 58, size = 24},
        {id = "quit", label = i18n.get("quit"), x = 88, y = 522, w = 360, h = 58, size = 24},
    }
end

function MenuState:update(dt)
    self.timer = self.timer + dt
    MenuNavigation.update(self)
    local mx, my = Viewport.getMousePosition()
    local targetX = math.max(-1, math.min(1, (mx - 640) / 640)) * 11
    local targetY = math.max(-1, math.min(1, (my - 360) / 360)) * 7
    local drift = 1 - math.exp(-dt * 2.5)
    self.parallaxX = self.parallaxX + (targetX - self.parallaxX) * drift
    self.parallaxY = self.parallaxY + (targetY - self.parallaxY) * drift
end

function MenuState:activate(id)
    Audio.play("jump")
    if id == "start" then
        self.stateManager:switch("play")
    elseif id == "options" then
        self.stateManager:push("options", {background = self})
    elseif id == "lang" then
        i18n.toggleLanguage()
    elseif id == "quit" then
        love.event.quit()
    end
end

MenuState.mousepressed = MenuNavigation.mousepressed

function MenuState:keypressed(key)
    if key == "l" then
        i18n.toggleLanguage()
    elseif key == "escape" then
        love.event.quit()
    else
        MenuNavigation.keypressed(self, key)
    end
end

function MenuState:draw()
    lg.push("all")
    Scene.draw(self.timer, self.parallaxX, self.parallaxY)

    Theme.text("NUTBOUND", 84, 181, 78, "ink", nil, nil, true)
    Theme.text("NUTBOUND", 84, 177, 78, "ivory", nil, nil, true)
    MenuNavigation.drawButtons(self)

    local entrance = math.exp(-self.timer * 4)
    if entrance > 0.001 then
        Theme.dim(entrance * 0.82)
    end
    Theme.cursor()
    lg.pop()
end

return MenuState
