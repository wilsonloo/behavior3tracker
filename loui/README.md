# loui
base love2d engine scroller(verticilly)

## Usage
```lua
local Scroller = require "loui.scroller"

-- 创建实例
local scroller = Scroller.new(30, 60, 200, 300)

-- 打印文本
scroller:print("world", 100, 50)

-- 划线
scroller:line(x1, y1, x2, y2, ...)

function love.update(dt)
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

```