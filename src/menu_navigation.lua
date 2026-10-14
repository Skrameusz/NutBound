local Theme = require("src.theme")

local MenuNavigation = {}

function MenuNavigation.update(state)
    Theme.trackSelection(state, state:buttons())
end

function MenuNavigation.drawButtons(state)
    for index, button in ipairs(state:buttons()) do
        Theme.button(button, state.selected == index, index == 1)
    end
end

function MenuNavigation.mousepressed(state, x, y, button)
    if button ~= 1 then return end

    for index, item in ipairs(state:buttons()) do
        if Theme.hit(item, x, y) then
            state.selected = index
            state:activate(item.id)
            return
        end
    end
end

function MenuNavigation.keypressed(state, key)
    local buttons = state:buttons()
    if Theme.navigate(state, key, #buttons) then
        state:activate(buttons[state.selected].id)
    end
end

return MenuNavigation
