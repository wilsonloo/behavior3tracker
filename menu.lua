local Global = require "global"
local ColorUtils = require "lib.color_utils"
local Config = require "config"

local mmin = math.min
local mmax = math.max
local mfloor = math.floor

local function _draw_name(x, cur_key, menu_type, menu_title)
    local mgr = Global.mgr
    local cur = mgr[cur_key]
    local old_color = nil
    if mgr.menu_type == menu_type then
        old_color = ColorUtils.set_color_green()
    end

    local menuStr = (menu_title and menu_title .. "\n" or "") .. ((cur and cur.file) or "empty")
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
        if cur and cur.file == list[k].file then
            old_color = ColorUtils.set_color_green()
        end

        local x = Config.MENU_MARGIN_LEFT
        local y = Config.MARGIN_TOP + count * Config.DropdownItemHeigh
        love.graphics.print(list[k].file, x, y)
        count = count + 1

        if old_color then
            ColorUtils.restore_color(old_color)
        end
    end
end

local function _select_dropdown(offset, cur_key, list)
    local mgr = Global.mgr

    if offset == 1 then
        if not mgr[cur_key] then
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
                    mgr:select_menu_item(cur_key, next_elem)
                end
                break
            end
        end       
    end
end

-- 行为树菜单
local MenuB3Tree = {
    menu_type = Config.MenuType.B3Tree,

    draw_name = function(x)
        return _draw_name(x, "b3_tree", Config.MenuType.B3Tree, "Current B3 Tree:")
    end,

    draw_dropdown = function()
        local mgr = Global.mgr
        _draw_dropdown("b3_tree", mgr.b3_tree_list)
    end,

    confirm_menu = function()
        local mgr = Global.mgr
        mgr.menu_type = Config.MenuType.Frame
        mgr:on_b3tree_menu_item_selected()
        mgr.need_reload_runtime_data = true
    end,

    select_menu = function()
        Global.mgr:on_b3tree_menu_item_selected()
    end,

    select_dropdown = function(offset)
        local mgr = Global.mgr
        _select_dropdown(offset, "b3_tree", mgr.b3_tree_list)
        mgr:filter_log_list()
    end,
}

-- 数据文件菜单
local MenuB3Log = {
    menu_type = Config.MenuType.B3Log,

    draw_name = function(x)
        return _draw_name(x, "b3_log", Config.MenuType.B3Log, "Current Runtime Log:")
    end,

    draw_dropdown = function()
        _draw_dropdown("b3_log", Global.mgr.b3_log_list_filtered)
    end,

    confirm_menu = function()
        local mgr = Global.mgr
        mgr.menu_type = Config.MenuType.Frame
        mgr.need_reload_runtime_data = true
    end,

    select_menu = function()

    end,
    
    select_dropdown = function(offset)
        local mgr = Global.mgr
        _select_dropdown(offset, "b3_log", mgr.b3_log_list_filtered)
    end,
}

-- 数据文件各帧信息
local MenuFrames = {
    menu_type = Config.MenuType.Frame,
    
    draw_dropdown = function()
        local mgr = Global.mgr
        local cur_frame, frame_slot = mgr:get_cur_frame()
        local x = Config.MENU_MARGIN_LEFT
        local y = Config.MARGIN_TOP
        local viewport_len = Config.WindowSize.h - Config.MARGIN_TOP
        local viewport_count = mfloor(viewport_len/Config.DropdownItemHeigh)
        local mark = 0
        local total_frames = #mgr.frames
        if total_frames == 0 then
            love.graphics.print("No Frames", x, y)
            return
        end

        if total_frames == viewport_count + 1 then
            mark = 1
        elseif total_frames > viewport_count + 1 then
            mark = 2
        end

        local top = (frame_slot or 0) + viewport_count - mark
        top = mmin(top, total_frames)
        local count = 0
        local frame_tag_len = 0
        for k = top, 1, -1 do
            local old_color
            if cur_frame and cur_frame.frame_id == mgr.frames[k].frame_id then
                old_color = ColorUtils.set_color_green()
            end

            local frame_tag = "frame:" .. mgr.frames[k].frame_id
            local len = love.graphics.getFont():getWidth(frame_tag)
            frame_tag_len = mmax(frame_tag_len, len)
            love.graphics.print(frame_tag, x, y + count * Config.DropdownItemHeigh)
            ColorUtils.restore_color(old_color)
            count = count + 1
        end
        y = y + count * Config.DropdownItemHeigh

        mgr.frame_tag_len = frame_tag_len
    end,

    confirm_menu = function()
        Global.mgr.menu_type = Config.MenuType.Frame
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

    select_newest = function()
        local mgr = Global.mgr
        mgr.frame_slot = #mgr.frames
    end,

    select_oldest = function()
        local mgr = Global.mgr
        if #mgr.frames > 0 then
            mgr.frame_slot = 1
        else
            mgr.frame_slot = 0
        end
    end,

    select_page = function(offset)
        local mgr = Global.mgr
        local viewport_len = Config.WindowSize.h - Config.MARGIN_TOP
        local viewport_count = mfloor(viewport_len/Config.DropdownItemHeigh) - 2
        if viewport_count > 0 then
            viewport_count = viewport_count * offset
        end

        local frame_slot = mgr.frame_slot + viewport_count 
        mgr.frame_slot = mmax(mmin(frame_slot, #mgr.frames), 1)
        if #mgr.frames == 0 then
            mgr.frame_slot = 0
        end
        print(33333, offset, viewport_count, frame_slot, #mgr.frames, mgr.frame_slot)
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

function M.get_menu_info(menu_type)
    if menu_type then
        return MenuList[menu_type]
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
    local menu_type = mgr.menu_type
    if menu_type == Config.MenuType.Frame then
        first = true
        if offset == 1 then
            mgr.menu_type = Config.MenuType.B3Tree
        elseif offset == -1 then
            mgr.menu_type = Config.MenuType.B3Log
        else
            assert(false, "invalid select menu offset:"..tostring(offset))
        end
    else
        mgr.menu_type = MenuList[mmin(mmax(menu_type+offset, 1), #MenuList)].menu_type
    end
    
    local list, cur_key
    if mgr.menu_type == Config.MenuType.B3Tree then
        list = mgr.b3_tree_list
        cur_key = "b3_tree"

    elseif mgr.menu_type == Config.MenuType.B3Log then
        list = mgr.b3_log_list_filtered
        cur_key = "b3_log"
    else
        assert(false)
    end 
    
    local recent = mgr.menu_recent_items[cur_key]
    if recent then
        -- 检测recent有效性
        if not mgr:check_rectent(recent, list) then
            recent = nil
            mgr.menu_recent_items[cur_key] = nil
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

    local menu_info = M.MenuList[mgr.menu_type]
    menu_info.select_menu()
end

return M