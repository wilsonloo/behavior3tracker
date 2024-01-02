local Scroller = require "loui.scroller"
local ColorUtils = require "lib.color_utils"
local Global = require "global"
local Mgr = require "mgr"

local WindowSize = {
    w = 1280,
    h = 600,
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

local function draw_frame_ids()
    local cur_frame = mgr:get_cur_frame()
    local count = 0
    for k = #mgr.frames, 1, -1 do
        local old_color
        if cur_frame and cur_frame.frame_id == mgr.frames[k].frame_id then
            old_color = ColorUtils.set_color_green()
        end
        love.graphics.print("frame:" .. mgr.frames[k].frame_id, 0, count * 20)
        ColorUtils.restore_color(old_color)
        count = count + 1
    end
end

function love.draw()
    --love.graphics.print("Hello World!", 400, 300)
    draw_frame_ids()
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
    mgr:load_b3_tree()

    if mode == "file" then
        mgr:set_b3log(b3_log)
        mgr:load_from_logfile()

    elseif mode == "runtime" then
        -- TODO
    end
end