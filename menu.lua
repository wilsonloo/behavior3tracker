local Global = require "global"
local ColorUtils = require "lib.color_utils"
local Config = require "config"

local mmin = math.min
local mmax = math.max

-- 行为树菜单
local MenuB3Tree = {
    draw_name = function(x)
        local b3_tree = Global.mgr.b3_tree
        local old_color = nil
        if Global.mgr.menu == Config.MenuType.B3Tree then
            old_color = ColorUtils.set_color_green()
        end

        local menuStr = (b3_tree and b3_tree.file) or "no b3 file"
        local len = love.graphics.getFont():getWidth(menuStr)
        love.graphics.print(menuStr, x, 0)
        x = x + len

        if old_color then
            ColorUtils.restore_color(old_color)
        end

        return x
    end,

    draw_dropdown = function()
        local mgr = Global.mgr
        local cur_tree = mgr.b3_tree
        local count = 0
        for k = #mgr.b3_tree_list, 1, -1 do
            local old_color
            if cur_tree and cur_tree.file == mgr.b3_tree_list[k].file then
                old_color = ColorUtils.set_color_green()
            end

            love.graphics.print(mgr.b3_tree_list[k].file, 0, Config.MARGIN_TOP + count * 20)
            count = count + 1

            if old_color then
                ColorUtils.restore_color(old_color)
            end
        end
    end,

    confirm_menu = function()
        Global.mgr.menu = 0
    end,

    select_dropdown = function(offset)
        local mgr = Global.mgr

        if offset == 1 then
            if not mgr.b3_tree then
                mgr.b3_tree = mgr.b3_tree_list[1]
                return
            end

            for k, v in ipairs(mgr.b3_tree_list) do
                if v.file == mgr.b3_tree.file then
                    local next_tree = mgr.b3_tree_list[k+1]
                    if next_tree then
                        mgr.b3_tree = next_tree
                    end
                    break
                end
            end
        elseif offset == -1 then
            if not mgr.b3_tree then
                mgr.b3_tree = mgr.b3_tree_list[#mgr.b3_tree_list]
                return
            end

            for k = #mgr.b3_tree_list, 1, -1 do
                local v = mgr.b3_tree_list[k]
                if v.file == mgr.b3_tree.file then
                    local prev_tree = mgr.b3_tree_list[k-1]
                    if prev_tree then
                        mgr.b3_tree = prev_tree
                    end
                    break
                end
            end
        end
    end,
}

-- 数据文件菜单
local MenuB3Log = {
    draw_name = function(x)
        local b3_log = Global.mgr.b3_log
        local old_color = nil
        if Global.mgr.menu == Config.MenuType.B3Log then
            old_color = ColorUtils.set_color_green()
        end

        local menuStr = (b3_log and b3_log.file) or "no b3 file"
        local len = love.graphics.getFont():getWidth(menuStr)
        love.graphics.print(menuStr, x, 0)
        x = x + len

        if old_color then
            ColorUtils.restore_color(old_color)
        end

        return x
    end,

    draw_dropdown = function()
        local mgr = Global.mgr
        local b3_log = mgr.b3_log
        local count = 0
        for k = #mgr.b3_log_list, 1, -1 do
            local old_color
            if b3_log and b3_log.file == mgr.b3_log_list[k].file then
                old_color = ColorUtils.set_color_green()
            end

            love.graphics.print(mgr.b3_log_list[k].file, 0, Config.MARGIN_TOP + count * 20)
            count = count + 1

            if old_color then
                ColorUtils.restore_color(old_color)
            end
        end
    end,

    confirm_menu = function()
        Global.mgr.menu = 0
    end,
    
    select_dropdown = function(offset)
        local mgr = Global.mgr

        if offset == 1 then
            if not mgr.b3_log then
                mgr.b3_log = mgr.b3_log_list[1]
                return
            end

            for k, v in ipairs(mgr.b3_log_list) do
                if v.file == mgr.b3_log.file then
                    local next_log = mgr.b3_log_list[k+1]
                    if next_log then
                        mgr.b3_log = next_log
                    end
                    break
                end
            end
        elseif offset == -1 then
            if not mgr.b3_log then
                mgr.b3_log = mgr.b3_log_list[#mgr.b3_log_list]
                return
            end

            for k = #mgr.b3_log_list, 1, -1 do
                local v = mgr.b3_log_list[k]
                if v.file == mgr.b3_log.file then
                    local prev_log = mgr.b3_log_list[k-1]
                    if prev_log then
                        mgr.b3_log = prev_log
                    end
                    break
                end
            end
        end
    end,
}

-- 数据文件各帧信息
local MenuFrames = {
    type = Config.MenuType.Frame,
    
    draw_dropdown = function()
        local mgr = Global.mgr
        local cur_frame = mgr:get_cur_frame()
        local count = 0
        for k = #mgr.frames, 1, -1 do
            local old_color
            if cur_frame and cur_frame.frame_id == mgr.frames[k].frame_id then
                old_color = ColorUtils.set_color_green()
            end
            love.graphics.print("frame:" .. mgr.frames[k].frame_id, 0, Config.MARGIN_TOP + count * 20)
            ColorUtils.restore_color(old_color)
            count = count + 1
        end
    end,

    confirm_menu = function()
        Global.mgr.menu = 0
    end,
}

local function draw_verticle_sepreator(x)
    x = x + Config.VERTICLE_SEPREATOR_WIDTH
    love.graphics.line(x, 0, x, Config.MARGIN_TOP)
    x = x + Config.VERTICLE_SEPREATOR_WIDTH
    return x
end

local MenuList = {
    [Config.MenuType.Frame] = MenuFrames,
    [Config.MenuType.B3Tree] = MenuB3Tree,
    [Config.MenuType.B3Log] = MenuB3Log,
}

local M = {}
M.MenuList = MenuList

function M.get_menu_info(menu)
    if menu then
        return MenuList[menu]
    end
end

function M.draw()
    love.graphics.line(0, Config.MARGIN_TOP, Config.WindowSize.w, Config.MARGIN_TOP)

    local x = Config.MENU_MARGIN_LEFT

    -- 行为树菜单
    x = MenuList[1].draw_name(x)
    x = draw_verticle_sepreator(x)

    -- 数据文件菜单
    x = MenuList[2].draw_name(x)
    x = draw_verticle_sepreator(x)
end

function M.select_menu(offset)
    local menu = Global.mgr.menu
    if menu == 0 then
        if offset == 1 then
            Global.mgr.menu = 1
            return
        elseif offset == -1 then
            Global.mgr.menu = #MenuList
            return
        else
            assert(false, "invalid select menu offset:"..tostring(offset))
        end
    end

    Global.mgr.menu = mmin(mmax(menu+offset, 1), #MenuList)
end

return M