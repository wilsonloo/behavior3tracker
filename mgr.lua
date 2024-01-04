local PrintR = require "lib.print_r"
local Json = require "lib.json"
local Mouse = require "mouse"
local Treeview = require "views.treeview"
local Config = require "config"

local tunpack = unpack or table.unpack
local tinsert = table.insert
local tsort = table.sort
local string_gsub = string.gsub
local string_match = string.match
local string_format = string.format

local ValueType = {
    FAIL = 1,
    SUCCESS = 2,
    RUNNING = 3,
}
local ValueMetas = {
    -- implement ValueMetaInterface
    [ValueType.FAIL] = {
        color = {r=255, g=0, b=0},
    },
    [ValueType.SUCCESS] = {
        color = {r=0, g=255, b=0},
    },
    [ValueType.RUNNING] = {
        color = {r=255, g=255, b=0},
    },
}

local function build_tree(self, treeview, b3node)
    -- add_child(node, child_id, value, tag, tag_msg)
    local child = Treeview.add_child(treeview, b3node.id, "value", b3node.name)
    if b3node.children then
        for _, n in ipairs(b3node.children) do
            build_tree(self, child, n)
        end
    end
end

local function get_last_frame(self)
    local slot = #self.frames
    if slot > 0 then
        return self.frames[slot], slot
    end
end

local mt = {}
mt.__index = mt

function mt:load_b3_tree()
    assert(self.b3_tree, "missing b3_tree")

    local f = io.open(self.b3_tree.fullpath, "r")
    assert(f, self.b3_tree.fullpath)
    local text = f:read("a")
    f:close()

    local data = Json.decode(text)
    self.treeview = Treeview.new_treeview(self.ScrollerMatrix.x, 
        self.ScrollerMatrix.y,
        self.ScrollerMatrix.w, 
        self.ScrollerMatrix.h)

    Treeview.set_value_metas(self.treeview, ValueMetas)
    
    build_tree(self, self.treeview, data.root)
end

function mt:load_from_logfile()
    assert(self.b3_log, "missing b3_log")
    
    local f = io.open(self.b3_log.fullpath, "r")
    assert(f, self.b3_log.fullpath)
    local text = f:read("a")
    f:close()

    local data = Json.decode(text)
    for _, frame in ipairs(data.frames) do
        local new_frame = {
            frame_id = frame.frame_id,
            node_value_map={},
        }

        tinsert(self.frames, new_frame)
        for _, v in ipairs(frame.list) do
            local id, stat = v[1], v[2]
            new_frame.node_value_map[id] = {stat}
        end
    end

    local _, frame_slot = get_last_frame(self)
    self.frame_slot = frame_slot
end

function mt:dump()
    PrintR.print_r("== dump =============", self.data)
end

function mt:get_cur_frame()
    if self.frame_slot then
        return self.frames[self.frame_slot], self.frame_slot
    end
end

function mt:get_war(war_id)
    return self.treeview_map[war_id]
end

local function get_json_filenames(path)
    local list = {}
    local baseDir = love.filesystem.getSourceBaseDirectory()
    local files = love.filesystem.getDirectoryItems(path)
    for _, file in ipairs(files) do
        local filePath = path .. "/" .. file
        local attr = love.filesystem.getInfo(filePath)
        if attr.type == "file" then
            if string_match(file, ".*%.json$") then
                tinsert(list, {
                    file = file,
                    fullpath = baseDir.."/../"..filePath,
                })
            end
        end
    end
    return list
end

function mt:select_menu_item(menu_key, item)
    self[menu_key] = item
    self.menu_recent_items[menu_key] = item
end

function mt:setup(mode, b3_tree_dir, b3_log_dir)
    self.mode = mode

    self.b3_tree_list = get_json_filenames(Config.B3TreeDir)
    self:select_menu_item("b3_tree", self.b3_tree_list[1])
    local PrintR = require "lib.print_r"
    PrintR.print_r("33333", self.b3_tree_list)

    self.b3_log_list = get_json_filenames(Config.B3LogDir)
    self:select_menu_item("b3_log", self.b3_log_list[1])
end

function mt:update(dt)
    if self.mode == "runtime" then
        -- todo
    end

    local cur_frame = self:get_cur_frame()
    if cur_frame then
        Treeview.update(self.treeview, dt)
    end
end

function mt:draw()
    local frame = self:get_cur_frame()
    -- local PrintR = require "lib.print_r"
    -- PrintR.print_r("frame data:", frame)
    Treeview.draw(self.treeview, frame, true)
end

function mt:mousepressed(x, y, button, istouch)
    if self.frame_slot then
        self.treeview.ctx.scroller:mousepressed(x, y, button, istouch)
    end
end

function mt:mousereleased(x, y, button)
    if self.frame_slot then
        self.treeview.ctx.scroller:mousereleased(x, y, button)
    end
end

local M = {}
function M.new(WindowSize)
    local mgr = setmetatable({
        WindowSize = WindowSize,
        ScrollerMatrix = {
            x = 80,
            y = Config.MARGIN_TOP,
            w = WindowSize.w - 60,
            h = WindowSize.h,
        },
        war_ids_set = {},
        war_ids = {},

        treeview = nil,
        frames = {},
        frame_slot = nil,

        mode = nil,

        b3_tree_list = {},
        b3_tree = nil,

        b3_log_list = {},
        b3_log = nil,

        menu_recent_items = {},

        menu = 0,
    }, mt)

    Mouse.register("mousepressed", function(x, y, button, istouch)
        mgr:mousepressed(x, y, button, istouch)
    end)

    Mouse.register("mousereleased", function(x, y, button, istouch)
        mgr:mousereleased(x, y, button)
    end)

    return mgr
end
return M