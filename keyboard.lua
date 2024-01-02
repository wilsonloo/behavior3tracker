local Global = require "global"

function love.keypressed(key)
    if key == "up" then
        Global.mgr:select_next_frame()
    elseif key == "down" then
        Global.mgr:select_prev_frame()
    end
end