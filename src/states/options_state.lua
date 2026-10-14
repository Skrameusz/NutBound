local GFX = require("src.graphics")
local config = require("src.config")
local Audio = require("src.audio")
local i18n = require("src.i18n")
local Theme = require("src.theme")
local Viewport = require("src.viewport")

local OptionsState = {}
OptionsState.__index = OptionsState
local slider = {x = 604, width = 266, hitPadding = 17, step = 0.05}
local optionRows = {
    {id = "masterVolume", labelKey = "master_vol", kind = "volume", y = 174, h = 44},
    {id = "sfxVolume", labelKey = "sfx_vol", kind = "volume", y = 222, h = 44},
    {id = "musicVolume", labelKey = "music_vol", kind = "volume", y = 270, h = 44},
    {id = "fullscreen", labelKey = "fullscreen", kind = "toggle", setting = "fullscreen", y = 332},
    {id = "smoothing", labelKey = "surface_smoothing", kind = "toggle", setting = "surfaceSmoothing", y = 380},
    {id = "shake", labelKey = "screen_shake", kind = "toggle", setting = "screenShakeEnabled", y = 428},
    {id = "lang", labelKey = "language", kind = "language", y = 476},
    {id = "back", labelKey = "back", kind = "button", x = 294, y = 560, w = 180, h = 52},
}
local optionsById = {}
for _, item in ipairs(optionRows) do
    optionsById[item.id] = item
end

function OptionsState.new(stateManager)
    return setmetatable({stateManager = stateManager, selected = 1}, OptionsState)
end

function OptionsState:enter(params)
    self.background = params and params.background or self.stateManager.stack[#self.stateManager.stack - 1]
    self.dragging = nil
    self.selected = 1
end

function OptionsState:items()
    local items = {}
    for index, row in ipairs(optionRows) do
        items[index] = {
            id = row.id, label = i18n.get(row.labelKey), kind = row.kind, setting = row.setting,
            x = row.x or 282, y = row.y, w = row.w or 716, h = row.h or 42,
        }
    end
    return items
end

function OptionsState:setVolume(key, value)
    config[key] = math.max(0, math.min(1, value))
    Audio.updateMusicVolume()
end

function OptionsState:setVolumeFromMouse(key, x)
    self:setVolume(key, (x - slider.x) / slider.width)
end

function OptionsState:update()
    Theme.trackSelection(self, self:items())
    if self.dragging then
        if love.mouse.isDown(1) then
            local mx = Viewport.getMousePosition()
            self:setVolumeFromMouse(self.dragging, mx)
        else self.dragging = nil end
    end
end

function OptionsState:activate(id)
    local item = optionsById[id]
    if not item then return end

    if item.kind == "toggle" then
        config[item.setting] = not config[item.setting]
        if id == "fullscreen" then
            love.window.setFullscreen(config.fullscreen, "desktop")
            local w, h = love.graphics.getDimensions()
            love.resize(w, h)
        elseif id == "smoothing" then
            Viewport.updateSurfaceFilter()
        end
    elseif item.kind == "language" then
        i18n.toggleLanguage()
    elseif id == "back" then
        self.stateManager:pop()
    else
        return
    end
    Audio.play("jump")
end

function OptionsState:mousepressed(x, y, button)
    if button ~= 1 then return end
    for index, item in ipairs(self:items()) do
        if Theme.hit(item, x, y) then
            self.selected = index
            if item.kind == "volume" then
                if x >= slider.x - slider.hitPadding and x <= slider.x + slider.width + slider.hitPadding then
                    self.dragging = item.id
                    self:setVolumeFromMouse(item.id, x)
                end
            else
                self:activate(item.id)
            end
            return
        end
    end
end

function OptionsState:mousereleased(x, y, button)
    if button == 1 then self.dragging = nil end
end

function OptionsState:keypressed(key)
    if key == "escape" then
        self.stateManager:pop()
    elseif key == "l" then
        i18n.toggleLanguage()
    else
        local items = self:items()
        local item = items[self.selected]
        if key == "left" or key == "right" then
            if item.kind == "volume" then
                self:setVolume(item.id, config[item.id] + (key == "right" and slider.step or -slider.step))
            elseif item.kind ~= "button" then
                self:activate(item.id)
            end
        elseif Theme.navigate(self, key, #items) then
            self:activate(items[self.selected].id)
        end
    end
end

function OptionsState:draw()
    if self.background and self.background ~= self then self.background:draw() end
    love.graphics.push("all")
    Theme.dim(0.72)
    Theme.panel(250, 64, 780, 584)
    Theme.text(i18n.get("options_title"), 294, 96, 38, "ivory", nil, nil, true)
    Theme.rule(294, 150, 692)
    local items = self:items()
    for index = 1, #items - 1 do
        local item = items[index]
        if self.selected == index then
            Theme.color("raised", 0.7)
            GFX.rect(item.x, item.y, item.w, item.h)
            Theme.color("accent")
            GFX.rect(item.x, item.y + 10, 2, item.h - 20)
        end
        Theme.text(item.label, 302, item.y + 11, 20, "ivory")
        if item.kind == "volume" then
            Theme.slider(slider.x, item.y + 22, slider.width, config[item.id], self.selected == index)
            Theme.text(string.format("%d%%", math.floor(config[item.id] * 100 + 0.5)), 906, item.y + 12, 19, "muted", 72, "right")
        elseif item.kind == "toggle" then
            local enabled = config[item.setting]
            Theme.text(i18n.get(enabled and "enabled" or "disabled"), 754, item.y + 11, 20, "muted", 184, "right")
            Theme.color(enabled and "accent" or "line")
            GFX.rect(958, item.y + 12, 20, 20)
            Theme.color("ink")
            GFX.rect(960, item.y + 14, 16, 16)
            if enabled then
                Theme.color("mint")
                GFX.rect(964, item.y + 18, 8, 8)
            end
        else
            local value = i18n.getLanguage() == "pl" and "Polski" or "English"
            Theme.text(value, 754, item.y + 11, 20, "ivory", 184, "right")
            Theme.text("›", 961, item.y + 8, 24, "muted")
        end
    end
    Theme.rule(294, 322, 692)
    Theme.rule(294, 538, 692)
    Theme.button(items[#items], self.selected == #items, false)
    Theme.cursor()
    love.graphics.pop()
end
return OptionsState
