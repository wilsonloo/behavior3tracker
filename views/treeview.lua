local ColorUtils = require "lib.color_utils"
local Scroller = require "loui.scroller"

local tinsert = table.insert

local function new_node(value, tag, tag_msg)
    local obj = {
        value = value,
        tag = tag,
        tag_msg = tag_msg,
        children = nil,
    }
    return obj
end

local M = {
    TAG_TYPE = {
        ROOT = 1,
        FAILED = 2,
    },
}

local function get_node_msg(node)
    local function append(msg, what)
        if msg then
            return msg .. "_" .. tostring(what)
        else
            return tostring(what)
        end
    end
    local msg
    if node.tag then
        msg = append(msg, node.tag)
    end
    if node.tag_msg then
        msg = append(msg, node.tag_msg)
    end
    if node.value then
        msg = append(msg, node.value)
    end
    return msg
end

local function calc_to_root_len(node)
    local function loop(n)
        if not (n) or not (n.parent) then
            return 0
        end
        local len = 0
        local pmsg = get_node_msg(n.parent)
        if pmsg then
            len = len + love.graphics.getFont():getWidth(pmsg) + node.ctx.ITEM_INTERVAL
        end
        len = len + loop(n.parent)
        return len
    end
    return loop(node)
end

local function render(root)
    local ctx = root.ctx
    local function render_connect(node)
        if node.parent then
            ctx.scroller:line(node.render_pos.x, node.render_pos.y + ctx.LINE_HIGHT,
                    node.parent.render_pos.x, node.parent.render_pos.y + ctx.LINE_HIGHT)
        end
    end
    local function render_item(ctx, text, x, y)
        text = tostring(text)
        ctx.scroller:print(text, x, y)
        ctx.cursor.x = ctx.cursor.x + love.graphics.getFont():getWidth(text) + ctx.ITEM_INTERVAL
    end
    local function do_render(node)
        node.render_pos = {
            x = ctx.cursor.x,
            y = ctx.cursor.y,
        }

        local old_color
        if node.tag == M.TAG_TYPE.FAILED then
            old_color = ColorUtils.set_color_red()
        end
        local node_msg = get_node_msg(node)
        if node_msg then
            render_item(ctx, node_msg, ctx.cursor.x, ctx.cursor.y)
        end
        render_connect(node)
        ColorUtils.restore_color(old_color)

        if node.children then
            local array_id_set = {}
            for k, v in ipairs(node.children) do
                do_render(v)
                array_id_set[k] = true
            end
            for k, v in pairs(node.children) do
                if not (array_id_set[k]) then
                    render_item(ctx, k, ctx.cursor.x, ctx.cursor.y)
                    do_render(v)
                end
            end
        end

        -- new line
        ctx.cursor.x = calc_to_root_len(node)
        ctx.cursor.y = ctx.cursor.y + ctx.LINE_HIGHT
    end
    do_render(root)
end

function M.draw(node, rerender)
    if not (node.ctx.rendered) or rerender then
        node.ctx.scroller:clear()
        render(node)
        node.ctx.rendered = true
    end
    node.ctx.scroller:draw()
end

function M.update(node, dt)
    node.ctx.scroller:update(dt)
end

function M.new_node_id(ctx)
    ctx._node_id = ctx._node_id + 1
    return ctx._node_id
end
function M.new_treeview(x, y, w, h)
    x = x or 0
    y = y or 0
    w = w or 800
    h = h or 600

    local node = new_node(nil, M.TAG_TYPE.ROOT, "root")
    node.ctx = {
        _node_id = 0,
        rendered = false,
        anchor = {
            x = x,
            y = y,
        },
        cursor = {
            x = 0,
            y = 0,
        },
        LINE_HIGHT = 15,
        ITEM_INTERVAL = 10,
        scroller = Scroller.new(x, y, w, h),
    }
    node.node_id = M.new_node_id(node.ctx)
    return node
end

function M.set_tostring(node, func)
    local mt = getmetatable(node)
    if not (mt) then
        mt = {}
        setmetatable(node, mt)
    end
    mt.__tostring = function()
        func(node)
    end
end

function M.add_child(node, child_id, value, tag, tag_msg)
    if not (node.children) then
        node.children = {}
    end
    local child = new_node(value, tag, tag_msg)
    child.node_id = M.new_node_id(node.ctx)
    local mt = getmetatable(node)
    if mt then
        setmetatable(child, mt)
    end
    child.parent = node
    child.ctx = node.ctx
    if child_id then
        node.children[child_id] = child
    else
        tinsert(node.children, child)
    end
    return child
end

function M.get_child(node, child_id)
    if node.children then
        return node.children[child_id]
    end
end

function M.get_child_by_value(node, child_value)
    if node.children then
        for _, v in pairs(node.children) do
            if v.value == child_value then
                return v
            end
        end
    end
end

function M.get_latest_child(node)
    if node.children then
        return node.children[#node.children]
    end
end

function M.set_failed_tag(node, tag_msg)
    node.tag = M.TAG_TYPE.FAILED
    node.tag_msg = tag_msg
end

function M.add_failed_tag(node, tag_msg)
    M.add_child(node, nil, nil, M.TAG_TYPE.FAILED, tag_msg)
end

return M
