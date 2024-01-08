local PrintR = require "lib.print_r"
local Json = require "lib.json"
local Mouse = require "mouse"
local Treeview = require "views.treeview"
local Config = require "config"
local RuntimeServer = require "runtime_server"

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

function mt:reload_b3_runtime_data()
    self.frames = {}
    self.frame_slot = nil
    self:load_b3_runtime_data()
end

function mt:load_b3_runtime_data()
    if not self.b3_log then
        print("missing b3_log")
        return
    end
    
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
            local id, stat, msg = v[1], v[2], v[3]
            new_frame.node_value_map[id] = {stat, msg}
        end
    end

    local _, frame_slot = get_last_frame(self)
    self.frame_slot = frame_slot
end

local function parse_treename(log_fullpath)
    assert(log_fullpath, "empty log_fullpath")
    
    local f = io.open(log_fullpath, "r")
    assert(f, log_fullpath)
    local text = f:read("a")
    f:close()

    local data = Json.decode(text)
    return data.tree_name
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

local function load_b3tree_filenames(self)
    self.b3_tree_list = get_json_filenames(Config.B3TreeDir)
end

local function load_runtime_filenames(self)
    self.b3_log_list = get_json_filenames(Config.B3LogDir)

    -- 填充tree_name
    for _, v in ipairs(self.b3_log_list) do
        v.tree_name = parse_treename(v.fullpath)
    end
end

function mt:on_b3tree_menu_item_selected()
    print("select b3_tree:", self.b3_tree and self.b3_tree.file or "none")
    self:filter_log_list()

    local recent = self.menu_recent_items["b3_log"]
    if recent then
        if self:check_rectent(recent, self.b3_log_list_filtered) then
            self:select_menu_item("b3_log", recent)
        else
            recent = nil
        end
    end
    
    if not recent then
        self:select_menu_item("b3_log", self.b3_log_list_filtered[1])
    end
end

function mt:select_menu_item(menu_key, item)
    self[menu_key] = item
    self.menu_recent_items[menu_key] = item
end

function mt:filter_log_list()
    self.b3_log_list_filtered = {}
    if self.b3_tree then
        if self.b3_log_list then
            for _, v in ipairs(self.b3_log_list) do
                if v.tree_name == self.b3_tree.file then
                    tinsert(self.b3_log_list_filtered, v)
                    print("  filter log:", v.file)
                end
            end
        end
    end
    
    local recent = self.menu_recent_items["b3_log"]
    if recent then
        -- todo check
        self:select_menu_item("b3_log", recent)
    else
        self:select_menu_item("b3_log", self.b3_log_list_filtered[1])
    end
end

-- 检测recent有效性
function mt:check_rectent(recent, list)
    assert(recent, "recent nil")

    if not list then
        return false
    end

    local ok = false
    for _, v in ipairs(list) do
        if v.file == recent.file then
            return true
        end
    end
    return false
end

function mt:start(mode)
    self.mode = mode

    if mode == "file" then
        load_b3tree_filenames(self)
        load_runtime_filenames(self)
    
        self:select_menu_item("b3_tree", self.b3_tree_list[1])
        self:on_b3tree_menu_item_selected()
        self:load_b3_tree()
        self:load_b3_runtime_data()

    elseif mode == "runtime" then
        load_b3tree_filenames(self)
        self:select_menu_item("b3_tree", self.b3_tree_list[1])
        self:on_b3tree_menu_item_selected()
        self:load_b3_tree()

        self.server = RuntimeServer.new(Config.RuntimeServerIp, Config.RuntimeServerPort)
        self.server:start()
    end
end

function mt:update(dt)
    if self.mode == "runtime" then
        self.server:update(dt)
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
        b3_log_list_filtered = {},
        b3_log = nil,
        need_reload_runtime_data = false,

        server = nil,

        menu_recent_items = {},

        menu_type = Config.MenuType.Frame,
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