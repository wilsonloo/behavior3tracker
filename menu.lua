local Global = require "global"
local ColorUtils = require "lib.color_utils"
local Config = require "config"

local mmin = math.min
local mmax = math.max

local function _draw_name(x, cur_key, menu_type)
    local mgr = Global.mgr
    local cur = mgr[cur_key]
    local old_color = nil
    if mgr.menu == menu_type then
        old_color = ColorUtils.set_color_green()
    end

    local menuStr = (cur and cur.file) or "empty"
    local len = love.graphics.getFont():getWidth(menuStr)
    love.graphics.print(menuStr, x, 0)
    x = x + len

    if old_color then
        ColorUtils.restore_color(old_color)
    end

    return x
end

local function _draw_dropdown(cur_key, list)
    local mgr = Global.mgr
    local cur = mgr[cur_key]
    
    local count = 0
    for k = 1, #list do
        local old_color
        local PrintR = require "lib.print_r"
        PrintR.print_r("_draw_dropdown:", cur, list[k])
        if cur and cur.file == list[k].file then
            old_color = ColorUtils.set_color_green()
        end

        love.graphics.print(list[k].file, 0, Config.MARGIN_TOP + count * 20)
        count = count + 1

        if old_color then
            ColorUtils.restore_color(old_color)
        end
    end
end

local function _select_dropdown(offset, cur_key, list)
    local mgr = Global.mgr

    print("_select_drowdown:>>>>>>", offset)
    if offset == 1 then
        print("_select_drowdown:", 2)
        if not mgr[cur_key] then
            print("_select_drowdown:", 3)
            mgr:select_menu_item(cur_key, list[#list])
            return
        end

        for k = #list, 1, -1 do
            local v = list[k]
            if v.file == mgr[cur_key].file then
                local prev_elem = list[k-1]
                if prev_elem then
                    mgr:select_menu_item(cur_key, prev_elem)
                end
                break
            end
        end
    elseif offset == -1 then
        if not mgr[cur_key] then
            mgr:select_menu_item(cur_key, list[1])
            return
        end

        for k, v in ipairs(list) do
            if v.file == mgr[cur_key].file then
                local next_elem = list[k+1]
                if next_elem then
                    local PrintR = require "lib.print_r"
                    PrintR.print_r("_select_drowdown:", 4, cur_key, next_elem)
                    mgr:select_menu_item(cur_key, next_elem)
                end
                break
            end
        end       
    end
end

-- 行为树菜单
local MenuB3Tree = {
    draw_name = function(x)
        return _draw_name(x, "b3_tree", Config.MenuType.B3Tree)
    end,

    draw_dropdown = function()
        local mgr = Global.mgr
        _draw_dropdown("b3_tree", mgr.b3_tree_list)
    end,

    confirm_menu = function()
        Global.mgr.menu = 0
    end,

    select_dropdown = function(offset)
        local mgr = Global.mgr
        _select_dropdown(offset, "b3_tree", mgr.b3_tree_list)
    end,
}

-- 数据文件菜单
local MenuB3Log = {
    draw_name = function(x)
        return _draw_name(x, "b3_log", Config.MenuType.B3Log)
    end,

    draw_dropdown = function()
        _draw_dropdown("b3_log", Global.mgr.b3_log_list)
    end,

    confirm_menu = function()
        Global.mgr.menu = 0
    end,
    
    select_dropdown = function(offset)
        local mgr = Global.mgr
        _select_dropdown(offset, "b3_log", mgr.b3_log_list)
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

    select_dropdown = function(offset)
        local mgr = Global.mgr
        if #mgr.frames <= 0 then
            print("frame is empty")
            mgr.frame_slot = nil
            return
        end
    
        if not mgr.frame_slot then
            if offset == 1 then
                mgr.frame_slot = #mgr.frames
            else
                mgr.frame_slot = 1
            end
            return
        end
    
        mgr.frame_slot = mgr.frame_slot + offset
        mgr.frame_slot = mmin(mmax(mgr.frame_slot, 1), #mgr.frames)
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
    local mgr = Global.mgr
    local first = false
    local menu = mgr.menu
    if menu == 0 then
        first = true
        if offset == 1 then
            mgr.menu = 1
        elseif offset == -1 then
            mgr.menu = #MenuList
        else
            assert(false, "invalid select menu offset:"..tostring(offset))
        end
    end

    if not first then
        mgr.menu = mmin(mmax(menu+offset, 1), #MenuList)
    end
    
    local list, cur_key
    if mgr.menu == Config.MenuType.B3Tree then
        list = mgr.b3_tree_list
        cur_key = "b3_tree"

    elseif mgr.menu == Config.MenuType.B3Log then
        list = mgr.b3_log_list
        cur_key = "b3_log"
    else
        assert(false)
    end 
    
    local recent = mgr.menu_recent_items[cur_key]
    if recent then
        -- 检测recent有效性
        if list then
            local ok = false
            for _, v in ipairs(list) do
                if v.file == recent.file then
                    ok = true
                    break
                end
            end
            if not ok then
                recent = nil
            end
        else
            recent = nil
        end
    end

    if recent then
        mgr:select_menu_item(cur_key, recent)
    else
        if #list > 0 then
            mgr:select_menu_item(cur_key, list[(offset == 1) and 1 or #list])
        else
            mgr:select_menu_item(cur_key, nil)
        end
    end
end

return M