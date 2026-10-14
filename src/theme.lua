local Viewport = require("src.viewport")
local GFX = require("src.graphics")

local Theme = {}
Theme.colors = {
    ink = {0.09, 0.065, 0.055}, panel = {0.18, 0.125, 0.10},
    raised = {0.29, 0.20, 0.14}, ivory = {1, 0.94, 0.79},
    muted = {0.78, 0.70, 0.56}, accent = {0.96, 0.78, 0.39},
    copper = {0.83, 0.42, 0.22}, line = {0.44, 0.32, 0.20},
    red = {0.85, 0.36, 0.31}, mint = {0.73, 0.82, 0.43},
}
local fonts = {}
local board, boardSlices

local function woodFrame(x, y, w, h, tint, fill, alpha)
    if not board then
        board = GFX.get("tablica")
        boardSlices = {}
        local xs, ys, widths, heights = {2, 8, 72}, {3, 9, 31}, {6, 64, 6}, {6, 22, 6}
        for row = 1, 3 do
            for col = 1, 3 do
                boardSlices[#boardSlices + 1] = love.graphics.newQuad(
                    xs[col], ys[row], widths[col], heights[row], board:getDimensions())
            end
        end
    end
    x, y = math.floor(x), math.floor(y)
    Theme.color(fill, alpha)
    GFX.rect(x + 6, y + 6, w - 12, h - 12)
    local xs, ys = {x, x + 12, x + w - 12}, {y, y + 12, y + h - 12}
    local widths, heights = {12, w - 24, 12}, {12, h - 24, 12}
    love.graphics.setColor(tint[1], tint[2], tint[3], alpha or 1)
    for row = 1, 3 do
        for col = 1, 3 do
            if row ~= 2 or col ~= 2 then
                local quad = boardSlices[(row - 1) * 3 + col]
                local _, _, qw, qh = quad:getViewport()
                love.graphics.draw(board, quad, xs[col], ys[row], 0, widths[col] / qw, heights[row] / qh)
            end
        end
    end
end

function Theme.font(size, bold)
    size = size or 18
    local key = size .. (bold and "bold" or "regular")
    if not fonts[key] then
        local face = bold and "Bold" or "Regular"
        fonts[key] = love.graphics.newFont("assets/fonts/LiberationSans-" .. face .. ".ttf", size)
        fonts[key]:setFilter("linear", "linear")
    end
    return fonts[key]
end

function Theme.color(name, alpha)
    local c = type(name) == "table" and name or Theme.colors[name or "ivory"]
    love.graphics.setColor(c[1], c[2], c[3], alpha or c[4] or 1)
end

function Theme.text(text, x, y, size, color, width, align, bold)
    love.graphics.setFont(Theme.font(size, bold))
    Theme.color(color or "ivory")
    if width then
        love.graphics.printf(text, math.floor(x), math.floor(y), width, align or "left")
    else
        love.graphics.print(text, math.floor(x), math.floor(y))
    end
end

function Theme.panel(x, y, w, h, alpha)
    Theme.color("ink", 0.45 * (alpha or 1))
    GFX.rect(x + 4, y + 6, w - 8, h)
    woodFrame(x, y, w, h, {0.60, 0.52, 0.42}, "panel", alpha or 0.98)
end
function Theme.rule(x, y, w)
    Theme.color("line", 0.7)
    GFX.rect(x, y, w, 2)
end

function Theme.button(b, focused, primary)
    local tint = focused and {1, 0.91, 0.72} or {0.69, 0.60, 0.48}
    local fill = focused and {0.48, 0.27, 0.15} or (primary and "raised" or "panel")
    Theme.color("ink", 0.7)
    GFX.rect(b.x + 4, b.y + 5, b.w - 8, b.h)
    woodFrame(b.x, b.y, b.w, b.h, tint, fill)
    local size = b.size or 22
    local bold = primary or focused
    local face = Theme.font(size, bold)
    while size > 16 and face:getWidth(b.label) > b.w - 44 do
        size = size - 1
        face = Theme.font(size, bold)
    end
    local textY = b.y + (b.h - face:getHeight()) / 2
    Theme.text(b.label, b.x + 22, textY + 2, size, "ink", b.w - 44, "center", bold)
    Theme.text(b.label, b.x + 22, textY, size, "ivory", b.w - 44, "center", bold)
end
function Theme.hit(b, x, y)
    return x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h
end

function Theme.trackSelection(state, buttons)
    local mx, my = Viewport.getMousePosition()
    if mx ~= state.mouseX or my ~= state.mouseY then
        for index, b in ipairs(buttons) do
            if Theme.hit(b, mx, my) then state.selected = index end
        end
    end
    state.mouseX, state.mouseY = mx, my
end

function Theme.navigate(state, key, count)
    if key == "down" or key == "s" or key == "tab" then
        state.selected = (state.selected or 1) % count + 1
    elseif key == "up" or key == "w" then
        state.selected = ((state.selected or 1) - 2) % count + 1
    elseif key == "return" or key == "space" then
        return true
    end
    return false
end

function Theme.keycap(label, x, y, width)
    width = width or math.max(32, Theme.font(15):getWidth(label) + 16)
    Theme.color("line")
    GFX.rect(x, y, width, 28)
    Theme.color("ink")
    GFX.rect(x + 2, y + 2, width - 4, 22)
    Theme.text(label, x, y + 4, 15, "ivory", width, "center")
    return width
end

function Theme.image(image, x, y, size)
    local scale = size / math.max(image:getWidth(), image:getHeight())
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, x, y, 0, scale, scale, image:getWidth() / 2, image:getHeight() / 2)
end

function Theme.cursor()
    local x, y = Viewport.getMousePosition()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(GFX.get("cursor"), math.floor(x), math.floor(y), 0, 1, 1, 10, 10)
end

function Theme.dim(alpha)
    Theme.color("ink", alpha or 0.78)
    GFX.rect(0, 0, 1280, 720)
end

function Theme.slider(x, y, w, value, focused)
    Theme.color("line")
    GFX.rect(x, y - 5, w, 10)
    Theme.color("ink")
    GFX.rect(x + 2, y - 3, w - 4, 6)
    Theme.color("accent")
    GFX.rect(x + 2, y - 3, math.floor((w - 4) * value), 6)
    local thumbX = math.floor(x + w * value)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(GFX.get(focused and "slider_focused" or "slider_idle"), thumbX - 9, y - 13)
end

return Theme
