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

    local menu_info = Menu.get_menu_info(mgr.menu)
    LeftDropdown.draw(menu_info)

    if mgr.menu == 0 then
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
    love.window.setMode(Config.WindowSize.w, Config.WindowSize.h)
    local function error_usage()
        error("usage: \nlove ..\\. <file/runtime> <b3_file> <b3_log> [--console]\n")
    end

    if not (args) or #args < 3 then
        error_usage()
        return
    end

    local mode = args[1]
    local b3_tree_dir = args[2]
    local b3_log_dir = args[3]

    mgr:setup(mode, b3_tree_dir, b3_log_dir)
    mgr:load_b3_tree()

    if mode == "file" then
        mgr:load_b3_runtime_data()

    elseif mode == "runtime" then
        -- TODO
    end
end