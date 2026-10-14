local config = require("src.config")
local GFX = require("src.graphics")
local Audio = require("src.audio")
local StateManager = require("src.state_manager")

local Viewport = require("src.viewport")

local stateManager

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.mouse.setVisible(false)

    Viewport.init()

    GFX.init()
    Audio.init()

    stateManager = StateManager.new()
    for _, name in ipairs({"menu", "play", "pause", "options", "gameover", "victory"}) do
        local state = require("src.states." .. name .. "_state")
        stateManager:register(name, state.new(stateManager))
    end

    stateManager:switch("menu")

    love.resize(love.graphics.getDimensions())
end

function love.resize(w, h)
    Viewport.resize(w, h)
    config.fullscreen = love.window.getFullscreen()
end

function love.update(dt)
    dt = math.min(dt, 0.05)

    Viewport.resize(love.graphics.getDimensions())

    if stateManager then
        stateManager:update(dt)
    end
end

function love.draw()
    Viewport.beginDraw()
    if stateManager then
        stateManager:draw()
    end

    Viewport.present()
end

function love.keypressed(key)
    if key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
        love.resize(love.graphics.getDimensions())
        return
    end
    if stateManager then
        stateManager:keypressed(key)
    end
end

function love.focus(focused)
    if not focused and stateManager and stateManager:current() == stateManager.states.play then
        stateManager:push("pause", { playState = stateManager.states.play })
    end
end

for _, event in ipairs({"mousepressed", "mousereleased"}) do
    love[event] = function(x, y, button)
        local vx, vy = Viewport.windowToVirtual(x, y)
        if stateManager then
            stateManager[event](stateManager, vx, vy, button)
        end
    end
end
