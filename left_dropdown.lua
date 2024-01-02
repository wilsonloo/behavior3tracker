local Global = require "global"

local M = {}

function M.draw(menu_info)
    if menu_info then
        menu_info.draw_dropdown()
    end
end

return M