local Global = require "global"
local Menu = require "menu"

function love.keypressed(key)
    local menu_info = Menu.MenuList[Global.mgr.menu_type]
    if key == "up" then
        menu_info.select_dropdown(1)
    elseif key == "down" then
        menu_info.select_dropdown(-1)
    elseif key == "home" then
        menu_info.select_newest()
    elseif key == "end" then
        menu_info.select_oldest()
    elseif key == "pageup" then
        menu_info.select_page(1)
    elseif key == "pagedown" then
        menu_info.select_page(-1)
    elseif key == "left" then
        Menu.select_menu(-1)
    elseif key == "right" then
        Menu.select_menu(1)
    elseif key == "return" then
        menu_info.confirm_menu()
    end
end