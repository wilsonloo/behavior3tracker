local Scroller = require "loui.scroller"
local ColorUtils = require "lib.color_utils"
local Global = require "global"
local Mgr = require "mgr"
local Menu = require "menu"
local LeftDropdown = require "left_dropdown"
local Config = require "config"

local mgr = Mgr.new(Config.WindowSize)
Global.mgr = mgr

require "keyboard"
require "mouse"

local function get_first_war(mgr)
    local war_id = next(mgr.treeview_map)
    if war_id then
        return mgr:get_war(war_id)
    end
end

function love.draw()
    --love.graphics.print("Hello World!", 400, 300)
    Menu.draw()

    local menu_info = Menu.get_menu_info(mgr.menu_type)
    LeftDropdown.draw(menu_info)

    if mgr.menu_type == Config.MenuType.Frame then
        mgr:draw()
    end
end

function love.update(dt)
    if mgr.need_reload_runtime_data then
        mgr.need_reload_runtime_data = false
        mgr:reload_b3_runtime_data()
    end

    mgr:update(dt)
end

---@param args[1] mode <file> or <runtime>
function love.load(args)
    love.window.setTitle("B3 Tracker")
    love.window.setMode(Config.WindowSize.w, Config.WindowSize.h)
    local function error_usage()
        error("usage: love ..\\. <file/runtime> [--console]")
    end

    local mode = args[1]
    if not mode then
        error_usage()
        return
    end
    
    mgr:start(mode)
end