local print_r = require "lib.print_r"
local Json = require "lib.json"
local Mouse = require "mouse"
local Treeview = require "views.treeview"

local tunpack = unpack or table.unpack
local tinsert = table.insert
local tsort = table.sort
local string_gsub = string.gsub
local string_format = string.format

local function get_war_info(self, war_id)
    local war = self.treeview_map[war_id]
    if not war then
        --print("implement war info, prepare-turn ignored, war_id:", war_id)
        return
    end
    return war
end

local function get_turn(self, war_id, turn)
    local war = get_war_info(self, war_id)
    if war then
        local turn_info = Treeview.get_child_by_value(war, turn)
        return turn_info, war
    end
end

local function get_last_checking_trigger(self, war_id, turn)
    local turn_info = get_turn(self, war_id, turn)
    if not (turn_info) then
        return
    end

    return turn_info.last_checking_trigger, turn_info
end

local function get_fighter(self, war_id, turn, pos)
    local turn_info, war = get_turn(self, war_id, turn)
    if not (turn_info) then
        return
    end

    if not (turn_info.fighter_map) then
        print_r.print_r(turn_info)
        assert(false, turn)
    end
    local fighter_info = turn_info.fighter_map[pos]
    return fighter_info, turn_info, war
end

local function get_cur_skill(self, war_id, turn, pos)
    local fighter_info, turn_info, war = get_fighter(self, war_id, turn, pos)
    if not (fighter_info) then
        return
    end

    local cur_skill
    local skills = Treeview.get_child(fighter_info, "skills")
    if skills then
        cur_skill = Treeview.get_latest_child(skills)
    end
    return cur_skill, fighter_info, turn_info, war
end

local function get_cur_buff(self, war_id, turn, pos)
    local cur_skill, fighter_info, turn_info, war = get_cur_skill(self, war_id, turn, pos)
    if not (cur_skill) then
        return
    end

    local cur_buff
    local buffs = Treeview.get_child(cur_skill, "buffs")
    if buffs then
        cur_buff = Treeview.get_latest_child(buffs)
    end
    return cur_buff, cur_skill, fighter_info, turn_info, war
end

local function get_cur_fighter(self, war_id)
    local war = self:get_war(war_id)
    if war then
        return war.cur_fighter
    end
end

local function get_cur_buff_exec(self, war_id)
    local war = self:get_war(war_id)
    if war then
        return war.cur_buff_exec
    end
end

local function cap_matched(line, pattern, no_unpack)
    local ret
    string_gsub(line, pattern, function(...)
        ret = { ... }
    end)
    if ret then
        if no_unpack then
            return ret
        else
            return tunpack(ret)
        end
    end
end

local function cap_with_war_tag(line, pattern)
    pattern = pattern or ""
    local ret = cap_matched(line, "%[war:(%d+):([%d-]+):(%d+)/(%d+)%]%s*" .. pattern, true)
    if ret then
        local list = {}
        for k, v in ipairs(ret) do
            list[k] = tonumber(v) or v
        end
        return tunpack(list)
    end
end

local function is_first_war(self, war_id)
    local k = next(self.treeview_map)
    if not (k) or k == war_id then
        return true
    end
end

local function build_tree(self, treeview, b3node)
    -- add_child(node, child_id, value, tag, tag_msg)
    local child = Treeview.add_child(treeview, node.id, "value", "tag", "tag_msg")
    for _, n in ipairs(b3node.children) do
        build_tree(self, child, n)
    end
end

local mt = {}
mt.__index = mt

function mt:load_b3_tree(b3_file)
    assert(self.b3_file, "missing b3_tree")

    local f = io.open(self.b3_file, "r")
    assert(f, self.b3_file)
    local text = f:read("a")
    f:close()

    local data = Json.decode(text)
    self.treeview = Treeview.new_treeview(self.ScrollerMatrix.x, 
        self.ScrollerMatrix.y,
        self.ScrollerMatrix.w, 
        self.ScrollerMatrix.h)
    
    build_tree(self, self.treeview, data.root)
    Treeview.draw(self.treeview, true)
end

function mt:load_from_logfile()
    assert(self.b3_log, "missing b3_log")
    
    local f = io.open(self.b3_log, "r")
    assert(f, self.b3_log)
    local text = f:read("a")
    f:close()

    self.data = Json.decode(text)
    self:dump()

    -- for _, frame in ipairs(self.data) do
    --     local treeview = Treeview.new_treeview(self.ScrollerMatrix.x, 
    --         self.ScrollerMatrix.y,
    --         self.ScrollerMatrix.w, 
    --         self.ScrollerMatrix.h)

    --     for _, 

    --     self.frame_map_treeview[frame.frame_id] = treeview
    -- end
end

function mt:load_war_from_file(expecting_war_id)
    local filename = self.mode_param
    assert(filename)
    local f = io.open(filename, "r")
    for line in f:lines("L") do
        local war_id = cap_with_war_tag(line)
        if war_id and war_id == expecting_war_id then
            handle_line(self, line)
        end
    end
    io.close(f)
    dump(self)
end

function mt:dump()
    PrintR.print_r("== dump =============", self.data)
end

function mt:start_watch_file()
    local filename = self.mode_param
    local f = io.open(filename, "r")
    self.last_size = f:seek("end")
    io.close(f)
end

function mt:get_war(war_id)
    return self.treeview_map[war_id]
end

function mt:show_current()
    if not self.data then
        print("no data to show")
        return
    end

    Treeview.draw(self.treeview, true)
end

function mt:get_cur_war()
    if self.cur_war_id then
        local war = self.treeview_map[self.cur_war_id]
        return war
    end
end

function mt:select_next_war()
    if not (self.cur_war_id) then
        self.cur_war_id = self.war_ids[#self.war_ids]
    end
    if not (self.cur_war_id) then
        print("cur_war_id nil")
        return
    end
    local latest = self.war_ids[#self.war_ids]
    if not (latest) then
        print("already the latest")
        return
    end
    if self.cur_war_id == latest then
        print("already the latest")
        return
    end

    for k = self.cur_war_id + 1, latest do
        if self.war_ids_set[k] then
            self:select_war(k)
            break
        end
    end
end

function mt:select_prev_war()
    if not (self.cur_war_id) then
        self.cur_war_id = self.war_ids[#self.war_ids]
    end
    if not (self.cur_war_id) then
        print("cur_war_id nil")
        return
    end
    local oldest = self.war_ids[1]
    if not (oldest) then
        print("already the oldest")
        return
    end
    if self.cur_war_id == oldest then
        print("already the oldest")
        return
    end

    for k = self.cur_war_id - 1, oldest, -1 do
        if self.war_ids_set[k] then
            self:select_war(k)
            break
        end
    end
end

function mt:setup(mode, b3_file)
    self.mode = mode
    self.b3_file = b3_file
    -- self.mode_param = mode_param
end

function mt:set_b3log(b3_log)
    self.b3_log = b3_log
end

local function batch_read_newlines(self)
    local filename = self.mode_param
    local f = io.open(filename, "r")
    assert(f, filename)
    local new_size = f:seek("end")
    if new_size == self.last_size then
        io.close(f)
        return
    end

    print(string_format("new data:%d, last:%d new_size:%d", new_size - self.last_size, self.last_size, new_size))
    if new_size < self.last_size then
        self.last_size = 0
    end

    f:seek("set", self.last_size)
    local line, war_id
    while true do
        line = f:read("L")
        if not (line) then
            break
        end
        self.last_size = self.last_size + #line
        war_id = cap_with_war_tag(line)
        if war_id then
            handle_line(self, line)
        end
    end
    io.close(f)
    dump(self)

    local war = self:get_cur_war()
    if war then
        Treeview.draw(war, true)
    end
end
function mt:update(dt)
    if self.mode == "runtime" then
        if not (self.next_watch_time) or os.time() >= self.next_watch_time then
            self.next_watch_time = os.time() + 5
            batch_read_newlines(self)
        end
    end
    local war = self:get_cur_war()
    if war then
        Treeview.update(war, dt)
    end
end

function mt:draw()
    local war = self:get_cur_war()
    if war then
        Treeview.draw(war)
    end
end

function mt:mousepressed(x, y, button, istouch)
    local war = self:get_cur_war()
    if war then
        war.mgr.scroller:mousepressed(x, y, button, istouch)
    end
end

function mt:mousereleased(x, y, button)
    local war = self:get_cur_war()
    if war then
        war.mgr.scroller:mousereleased(x, y, button)
    end
end

local M = {}
function M.new(WindowSize)
    local mgr = setmetatable({
        WindowSize = WindowSize,
        ScrollerMatrix = {
            x = 60,
            y = 0,
            w = WindowSize.w - 60,
            h = WindowSize.h,
        },
        war_ids_set = {},
        war_ids = {},
        cur_war_id = nil,

        treeview = nil,

        mode = nil,
        b3_file = nil,
        b3_log = nil,

        last_size = nil,
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