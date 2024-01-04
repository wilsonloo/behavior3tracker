local Global = require "global"
local Menu = require "menu"

function love.keypressed(key)
    local menu_info = Menu.MenuList[Global.mgr.menu_type]
    if key == "up" then
        menu_info.select_dropdown(1)
    elseif key == "down" then
        menu_info.select_dropdown(-1)
    elseif key == "left" then
        Menu.select_menu(-1)
    elseif key == "right" then
        Menu.select_menu(1)
    elseif key == "return" then
        menu_info.confirm_menu()
    end
end