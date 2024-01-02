local Scroller = require "loui.scroller"

local scroller = Scroller.new(30, 60, 200, 300)

local data_loaded = false
local function load_datas()
    if not (data_loaded) then
        scroller:print("hello", 0, 0)
        scroller:print("world", 100, 50)
        for k = 1, 20 do
            scroller:print("new line", 0, 100 + k * 50)
        end
        data_loaded = true
    end
end

function love.update(dt)
    load_datas()
    scroller:update(dt)
end

function love.draw()
    scroller:draw()
end

function love.mousepressed(x, y, button, istouch)
    scroller:mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button)
    scroller:mousereleased(x, y, button)
end