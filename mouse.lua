local listeners = {}

function love.mousepressed(x, y, button, istouch)
    local list = listeners["mousepressed"]
    if list then
        for _, cb in ipairs(list) do
            cb(x, y, button, istouch)
        end
    end
end

function love.mousereleased(x, y, button)
    local list = listeners["mousereleased"]
    if list then
        for _, cb in ipairs(list) do
            cb(x, y, button)
        end
    end
end

local M = {
    register = function (event_type, cb)
        local list = listeners[event_type]
        if not(list) then
            list = {}
            listeners[event_type] = list
        end
        list[#list + 1] = cb
    end,
}
return M