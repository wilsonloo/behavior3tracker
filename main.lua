local Scroller = require "loui.scroller"
local ColorUtils = require "lib.color_utils"
local Global = require "global"
local Mgr = require "mgr"

local WindowSize = {
    w = 1280,
    h = 1024,
}

local mgr = Mgr.new(WindowSize)
Global.mgr = mgr

require "keyboard"
require "mouse"

local function get_first_war(mgr)
    local war_id = next(mgr.treeview_map)
    if war_id then
        return mgr:get_war(war_id)
    end
end

local function draw_war_ids()
    local cur_war = mgr:get_cur_war()
    local count = 0
    for k = #mgr.war_ids, 1, -1 do
        local old_color
        if cur_war and cur_war.war_id == mgr.war_ids[k] then
            old_color = ColorUtils.set_color_green()
        end
        love.graphics.print("war:" .. mgr.war_ids[k], 0, count * 20)
        ColorUtils.restore_color(old_color)
        count = count + 1
    end
end
function love.draw()
    --love.graphics.print("Hello World!", 400, 300)
    draw_war_ids()
    mgr:draw()
end

function love.update(dt)
    mgr:update(dt)
end

---@param args[1] mode <file> or <runtime>
function love.load(args)
    love.window.setMode(WindowSize.w, WindowSize.h)
    local function error_usage()
        error("usage: \nlove ..\\. <file/runtime> <b3_file> <b3_log> [--console]\n")
    end

    if not (args) or #args < 3 then
        error_usage()
        return
    end

    local mode = args[1]
    local b3_file = args[2]
    local b3_log = args[3]

    mgr:setup(mode, b3_file)
    if mode == "file" then
        mgr:set_b3log(b3_log)

        mgr:load_from_logfile()
        mgr:show_current()

    elseif mode == "runtime" then
        mgr:start_watch_file()
    end
end