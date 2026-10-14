local StateManager = {}
StateManager.__index = StateManager

local function getState(self, name)
    local state = self.states[name]
    if not state then
        error("State not found: " .. tostring(name))
    end
    return state
end

function StateManager.new()
    return setmetatable({states = {}, stack = {}}, StateManager)
end

function StateManager:register(name, state)
    self.states[name] = state
end

function StateManager:switch(name, params)
    local state = getState(self, name)

    self.stack = { state }
    if state.enter then state:enter(params) end
end

function StateManager:push(name, params)
    local state = getState(self, name)

    table.insert(self.stack, state)
    if state.enter then state:enter(params) end
end

function StateManager:pop()
    if #self.stack > 1 then
        table.remove(self.stack)
    end
end

function StateManager:current()
    return self.stack[#self.stack]
end

for _, event in ipairs({"update", "draw", "keypressed", "mousepressed", "mousereleased"}) do
    StateManager[event] = function(self, ...)
        local state = self:current()
        if state and state[event] then
            state[event](state, ...)
        end
    end
end

return StateManager
