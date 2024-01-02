local Global = require "global"

function love.keypressed(key)
    if key == "pageup" then
        Global.mgr:select_next_war()
    elseif key == "pagedown" then
        Global.mgr:select_prev_war()
    end
end