local Socket = require "socket"

local sformat = string.format

local FramePattern = "^(%^%^%^)([^%$]*)(%$%$%$)"

local function on_new_frame(frame_msg)
    print("   frame data:", frame_msg)
end

local function try_parse_message(data)
    --这里的match是string.match,它使用参数中的模式来匹配
    -- local test_str = "aebd^^^sef898$$$$se"
    local start_flag, frame_msg, end_flag = data:match(FramePattern)
    if start_flag then
        data = data:sub(#start_flag + #frame_msg + #end_flag + 1)
    end
    return frame_msg, data
end

local mt = {}
mt.__index = mt

function mt:start()
    self.sock = Socket.bind(self.ip, self.port)
    if not self.sock then
        print(sformat("socket server start at: %s:%d failed", self.ip, self.port))
        assert(false)
        return
    end    
    self.sock:settimeout(0)
    
    print(sformat("socket server started at: %s:%d", self.ip, self.port))
    print("server: waiting for client to connect...")
end

function mt:update(dt)
    if not self.client then
        
        self.client, errmsg = self.sock:accept()
        if not self.client then
            if errmsg ~= "timeout" then
                error("accept client failed:"..errmsg)
            end
            return
        else
            print("client connected")    
        end
    end

    --很可能有许多消息，因此循环来等待消息
    local data, errmsg
    local frame_msg
    repeat
        --[[这里期望另一端的 tcp:send!
            tcp:receive将返回等待数据包 （或为nil，或错误消息）。
            数据是一个字符串，承载远端tcp:send的内容。我们可以使用lua的string库处理
        ]]
        data, errmsg = self.client:receive()
        if errmsg == "closed" then
            error("client is closed")
            return;
        end
        
        repeat 
            if data then
                print("current data:", data, "len:", #data)
                frame_msg, data = try_parse_message(data)
                if frame_msg then
                    on_new_frame(frame_msg)
                end

            elseif errmsg ~= 'timeout' then
                -- 打印错误，一般情况下错误是timeout，由于我们把timeout设为0了，
                error("Network error: "..tostring(errmsg))
            end
        until not frame_msg
    until not data
end

local M = {}

function M.new(ip, port)
    local server = {
        ip = ip, 
        port = port,
        sock = nil,
        time_elapsed = 0,
        client = nil,
    }
    setmetatable(server, mt)
    return server
end

return M