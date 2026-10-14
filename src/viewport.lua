local config = require("src.config")

local Viewport = {}
local canvas, smoothShader
local scale, offsetX, offsetY = 1, 0, 0
local windowWidth, windowHeight

local smoothShaderCode = [[
    extern vec2 textureSize;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
        vec2 texel = tc * textureSize;
        vec2 p = texel - 0.5;
        vec2 p_floor = floor(p);
        vec2 frac = p - p_floor;
        vec2 f = clamp((frac - 0.5) / fwidth(texel) + 0.5, 0.0, 1.0);
        vec2 sharp_tc = (p_floor + f + 0.5) / textureSize;
        return Texel(tex, sharp_tc) * color;
    }
]]

function Viewport.updateSurfaceFilter()
    if canvas then
        local filter = config.surfaceSmoothing and "linear" or "nearest"
        canvas:setFilter(filter, filter)
    end
end

function Viewport.resize(width, height)
    if width <= 0 or height <= 0 then return end
    if width == windowWidth and height == windowHeight then return end
    windowWidth, windowHeight = width, height
    scale = math.min(width / config.VIRTUAL_WIDTH, height / config.VIRTUAL_HEIGHT)
    offsetX = math.floor((width - config.VIRTUAL_WIDTH * scale) * 0.5)
    offsetY = math.floor((height - config.VIRTUAL_HEIGHT * scale) * 0.5)
end

function Viewport.init()
    canvas = love.graphics.newCanvas(config.VIRTUAL_WIDTH, config.VIRTUAL_HEIGHT)
    Viewport.updateSurfaceFilter()

    local ok, result = pcall(love.graphics.newShader, smoothShaderCode)
    if ok then
        smoothShader = result
        smoothShader:send("textureSize", {config.VIRTUAL_WIDTH, config.VIRTUAL_HEIGHT})
    else
        smoothShader = nil
        print("[NutBound] Smooth scaling shader unavailable: " .. tostring(result))
    end
    Viewport.resize(love.graphics.getDimensions())
end

function Viewport.windowToVirtual(x, y)
    return (x - offsetX) / scale, (y - offsetY) / scale
end

function Viewport.getMousePosition()
    return Viewport.windowToVirtual(love.mouse.getPosition())
end

function Viewport.beginDraw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.08, 0.06, 0.10, 1)
end

function Viewport.present()
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    if config.surfaceSmoothing and smoothShader and scale ~= 1 then
        love.graphics.setShader(smoothShader)
    end
    love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)
    love.graphics.setShader()
end

return Viewport
