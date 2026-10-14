local config = require("src.config")
local GFX = require("src.graphics")
local i18n = require("src.i18n")
local Theme = require("src.theme")

local UI = {}
UI.__index = UI

function UI.new()
    return setmetatable({notifTimer = 0, notifDuration = 0}, UI)
end

function UI:showNotification(text, duration)
    self.notification = text
    self.notifDuration = duration or 2.5
    self.notifTimer = self.notifDuration
end

function UI:update(dt)
    self.notifTimer = math.max(0, self.notifTimer - dt)
    if self.notifTimer == 0 then self.notification = nil end
end

function UI:drawHUD(player, boss, level)
    love.graphics.push("all")
    local g = love.graphics
    local screenW, screenH = config.VIRTUAL_WIDTH, config.VIRTUAL_HEIGHT
    local bossActive = boss and boss.active and not boss.defeated

    Theme.panel(24, 24, 340, 84, 0.96)
    Theme.text(i18n.get("hp"), 44, 35, 15, "muted")
    local heart = GFX.get("serce")
    for n = 1, player.maxHp do
        local x = 57 + (n - 1) * 35
        if n <= player.hp then
            Theme.image(heart, x, 78, 26)
        else
            Theme.color("line", 0.55)
            local scale = 26 / math.max(heart:getWidth(), heart:getHeight())
            g.draw(heart, x, 78, 0, scale, scale, heart:getWidth() / 2, heart:getHeight() / 2)
        end
    end
    Theme.color("line", 0.65)
    GFX.rect(170, 42, 1, 46)

    Theme.text(i18n.get("acorns"), 190, 35, 15, "muted")
    Theme.image(GFX.get("acorn"), 207, 78, 32)
    Theme.text(tostring(player.acorns), 234, 61, 30,
        player.acorns >= config.REQUIRED_ACORNS and "mint" or "ivory", nil, nil, true)
    Theme.text("/ " .. config.REQUIRED_ACORNS, 287, 72, 18, "muted")

    local chestnut = player.activeAmmo == "chestnut"
    local ammoX, ammoY = screenW - 300, screenH - 94
    Theme.panel(ammoX, ammoY, 276, 70, 0.96)
    Theme.text(i18n.get("ammo_label"), ammoX + 18, ammoY + 10, 14, "muted")
    Theme.image(GFX.get(chestnut and "chestnut_proj" or "stone"), ammoX + 26, ammoY + 47, 24)
    Theme.text(i18n.get(chestnut and "ammo_chestnut" or "ammo_stone"), ammoX + 48, ammoY + 35, 20, "ivory")
    Theme.text(chestnut and tostring(player.chestnutAmmo) or "∞", ammoX + 167, ammoY + 30, 26, "ivory", 36, "right", true)
    Theme.keycap("Q", ammoX + 224, ammoY + 23, 32)
    local objective = i18n.get("objective_gather", config.REQUIRED_ACORNS)
    if player.acorns >= config.REQUIRED_ACORNS then
        objective = i18n.get(boss and not boss.defeated and "objective_boss" or "objective_home")
    end
    local objectiveX = screenW - 386
    Theme.panel(objectiveX, 24, 362, 84, 0.97)
    Theme.text(i18n.get("journey"), objectiveX + 20, 35, 15, "accent")
    Theme.text(objective, objectiveX + 20, 58, 18, "ivory", 322)
    local fraction = math.max(0, math.min(1, player.x / ((level and level.width or 5040) - 170)))
    Theme.color("line")
    GFX.rect(objectiveX + 20, 94, 322, 3)
    Theme.color("accent")
    GFX.rect(objectiveX + 20, 94, 322 * fraction, 3)

    if bossActive then
        local barX, barY, barW = (screenW - 560) / 2, screenH - 90, 560
        Theme.panel(barX - 20, barY - 12, barW + 40, 78)
        Theme.text(i18n.get("boss_name"), barX, barY, 16, "accent", nil, nil, true)
        Theme.text(string.format("%d / %d", boss.hp, boss.maxHp), barX, barY, 18, "ivory", barW, "right")
        Theme.color("line")
        GFX.rect(barX, barY + 32, barW, 18)
        Theme.color("ink")
        GFX.rect(barX + 2, barY + 34, barW - 4, 14)
        Theme.color("copper")
        GFX.rect(barX + 2, barY + 34, (barW - 4) * math.max(0, boss.hp / boss.maxHp), 14)
    end

    if level and level.inHollowZone then
        local text = player.acorns >= config.REQUIRED_ACORNS and i18n.get("hollow_enter")
            or i18n.get("hollow_need_more", config.REQUIRED_ACORNS - player.acorns)
        local y = bossActive and screenH - 170 or screenH - 98
        Theme.panel(320, y, 640, 62)
        Theme.text(text, 340, y + 19, 20, player.acorns >= config.REQUIRED_ACORNS and "accent" or "ivory", 600, "center")
    end

    if self.notification then
        local font = Theme.font(20)
        local width = math.min(780, math.max(360, font:getWidth(self.notification) + 64))
        local _, lines = font:getWrap(self.notification, width - 44)
        local height = #lines * font:getHeight() + 32
        local rise = math.max(0, 1 - (self.notifDuration - self.notifTimer) / 0.2)
        local y = 128 - rise * 8
        Theme.panel((screenW - width) / 2, y, width, height, math.min(0.98, self.notifTimer / 0.3))
        Theme.text(self.notification, (screenW - width) / 2 + 22, y + 16, 20, "ivory", width - 44, "center")
    end

    if not bossActive then
        Theme.panel(24, screenH - 58, 146, 36, 0.96)
        Theme.keycap("ESC", 28, screenH - 54, 45)
        Theme.text(i18n.get("control_pause"), 83, screenH - 49, 16, "ivory")
    end
    Theme.cursor()
    g.pop()
end

return UI
