local ColorUtils = require "lib.color_utils"
local PrintR = require "lib.print_r"
local Scroller = require "loui.scroller"

local tinsert = table.insert

local ValueMetaInterface = {
    color = {r=1, g=1, b=1, a=1},
}

-- implement ValueMetaInterface
local DefaultValueMeta = {
    color = {r=1, g=1, b=1, a=1},
}

local function get_value_meta(self, value)
    local meta = self.ctx.value_metas and self.ctx.value_metas[value]
    return meta or DefaultValueMeta
end

local function set_color(color)
    return ColorUtils.set_color(color.r, color.g, color.b, color.a)
end

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
    },
}

local function get_node_msg(self, tree_node, data)
    local msg = ""
    if tree_node.node_id > 0 then
        msg = msg..tree_node.node_id..":"
    end

    if tree_node.tag then
        msg = msg..tostring(tree_node.tag)
    end
    -- if tree_node.tag_msg then
    --     msg = msg..tostring(tree_node.tag_msg)
    -- end

    if data then
        local run_tips = data[2]
        if run_tips then
            msg = msg.."("..run_tips..")"
        end
    end

    return msg
end

local function calc_to_root_len(self, node)
    local function loop(n)
        if not (n) or not (n.parent) then
            return 0
        end
        local len = 0
        local pmsg = get_node_msg(self, n.parent)
        if pmsg then
            len = len + love.graphics.getFont():getWidth(pmsg) + node.ctx.ITEM_INTERVAL
        end
        len = len + loop(n.parent)
        return len
    end
    return loop(node)
end

local function render(self)
    local ctx = self.ctx
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
    local function do_render(treeview_node)
        treeview_node.render_pos = {
            x = ctx.cursor.x,
            y = ctx.cursor.y,
        }

        local old_color = nil
        local frame = self.ctx.frame
        local node_data = frame and frame.node_value_map[treeview_node.node_id]

        if node_data then
            local node_value = node_data[1]
            local node_msg = node_data[2]
            local meta = get_value_meta(self, node_value)
            old_color = set_color(meta.color)
        end

        local node_msg = get_node_msg(self, treeview_node, node_data)
        if node_msg then
            render_item(ctx, node_msg, ctx.cursor.x, ctx.cursor.y)
        end
        
        render_connect(treeview_node)
        if old_color then
            ColorUtils.restore_color(old_color)
        end

        if treeview_node.children then
            for k, v in ipairs(treeview_node.children) do
                do_render(v)
            end
        end

        -- new line
        ctx.cursor.x = calc_to_root_len(self, treeview_node)
        ctx.cursor.y = ctx.cursor.y + ctx.LINE_HIGHT
    end
    do_render(self)
end

function M.draw(self, frame, re_render)
    self.ctx.frame = frame
    if not (self.ctx.rendered) or re_render then
        self.ctx.cursor.x = 0
        self.ctx.cursor.y = 0
        self.ctx.scroller:clear()
        render(self)
        self.ctx.rendered = true
    end
    self.ctx.scroller:draw()
end

function M.update(self, dt)
    self.ctx.scroller:update(dt)
end

function M.new_treeview(x, y, w, h)
    x = x or 0
    y = y or 0
    w = w or 800
    h = h or 600

    local node = new_node(nil, M.TAG_TYPE.ROOT, "root")
    node.ctx = {
        rendered = false,
        cursor = {
            x = 0,
            y = 0,
        },
        LINE_HIGHT = 15,
        ITEM_INTERVAL = 10,
        scroller = Scroller.new(x+100, y, w, h),
        value_metas = nil,
    }
    node.node_id = -1
    return node
end

function M.add_child(node, child_id, value, tag, tag_msg)
    if not (node.children) then
        node.children = {}
    end
    local child = new_node(value, tag, tag_msg)
    child.node_id = child_id
    local mt = getmetatable(node)
    if mt then
        setmetatable(child, mt)
    end
    child.parent = node
    child.ctx = node.ctx
    tinsert(node.children, child)
    return child
end

---@param metas: ValueMetaInterface[]
function M.set_value_metas(self, metas)
    self.ctx.value_metas = metas
end

function M.set_matrix(self, set)
    if set.x then
        self.ctx.scroller.base_x = set.x
    end

    if set.y then
        self.ctx.scroller.base_y = set.y
    end

    if set.w then
        self.ctx.scroller.base_w = set.w
    end

    if set.h then
        self.ctx.scroller.base_h = set.h
    end
end

return M
