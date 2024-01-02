local Compat = require "loui.compat"
local tunpack = Compat.unpack
local select = Compat.select

-- ===========================================================
local scrollbar = function(x, y, w, h, canvas)
    local obj = {
        x = x,
        y = y,

        w = w or 20,
        h = h or 200,
        minW = 20,
        minH = 20,

        rect = {},

        padding = 2,
        visible = true,
        contentHeight = 0,

        scrollY = 0,
    }

    local mouseDown = false;

    function obj:updateContentHeight(h)
        obj.contentHeight = h
    end

    ---@return [0, 1]
    function obj:getScrollRatio()
        return obj.scrollY / obj.h
    end

    function obj:loadScroll()
        obj.rect.x = obj.x;
        obj.rect.y = obj.y;
        obj.rect.w = obj.w;
        obj.rect.h = obj.minH;
    end

    function obj:updateScroll(mx, my)
        if obj.contentHeight < obj.h then
            obj.visible = false;
            return false
        else
            obj.visible = true;
        end

        obj.rect.h = obj.h / obj.contentHeight;
        obj.rect.h = math.max(obj.rect.h, obj.minH);

        if mouseDown == true then
            obj.rect.y = math.max(obj.y, math.min(math.floor(my), (obj.h - obj.y)));
            obj.scrollY = obj.rect.y - obj.y;
            return true
        end
    end

    function obj:mousepressedScroll(x, y, button)
        if button == 1 then
            if x >= obj.rect.x and x <= (obj.rect.x + obj.rect.w) and
                    y >= obj.rect.y and y <= (obj.rect.y + obj.rect.h) then
                mouseDown = true;
            end
        end
    end

    function obj:mousereleasedScroll(x, y, button)
        mouseDown = false;
    end

    function obj:drawScroll()
        if obj.visible == true then
            love.graphics.setCanvas(canvas)
            love.graphics.rectangle("fill", obj.x, obj.y, obj.w, obj.h);
            love.graphics.setColor(255, 0, 0, 200);
            love.graphics.rectangle("fill", obj.rect.x, obj.rect.y, obj.rect.w, obj.rect.h);
            love.graphics.setColor(255, 255, 255, 255);
            love.graphics.setCanvas()
        end
    end

    return obj;
end

-- ===========================================================
local new_scroller = function(x, y, w, h)
    local canvas = love.graphics.newCanvas(w, h)

    local bar_weight = 20
    local bar_height = h
    local bar = scrollbar(w - bar_weight, 0, bar_weight, bar_height, canvas)
    bar:loadScroll()

    local obj = {
        base_x = x,
        base_y = y,
        base_w = w,
        base_h = h,
    }

    local contentMax = {
        x = w,
        y = h,
    }

    local viewport = {
        x = 0,
        y = 0,
        w = w,
        h = h,
    }

    local elements = {}

    local function calc_view_pos(x, y)
        return x - viewport.x, y - viewport.y
    end

    local function print_elem(elem)
        local _, text, x, y = tunpack(elem)
        x, y = calc_view_pos(x, y)

        love.graphics.setCanvas(canvas)
        love.graphics.print(text, x, y)
        love.graphics.setCanvas()
    end

    local function line_elem(elem)
        local _, pos_list = tunpack(elem)
        local fix_pos_list = {}
        for k = 1, #pos_list, 2 do
            fix_pos_list[k], fix_pos_list[k + 1] = calc_view_pos(pos_list[k], pos_list[k + 1])
        end

        love.graphics.setCanvas(canvas)
        love.graphics.line(tunpack(fix_pos_list))
        love.graphics.setCanvas()
    end

    local function draw_element(elem)
        local etype = elem[1]
        if etype == "print" then
            print_elem(elem)
        elseif etype == "line" then
            line_elem(elem)
        end
    end

    local function draw_elements()
        for _, elem in ipairs(elements) do
            draw_element(elem)
        end
    end

    local function updateViewport()
        local ratio = bar:getScrollRatio()
        viewport.y = contentMax.y * ratio

        --print("viewport:", viewport.x, viewport.y, ratio)
        love.graphics.setCanvas(canvas)
        love.graphics.clear()
        love.graphics.setCanvas()
    end

    local function update_cord_max(list)
        for k = 1, #list, 2 do
            if list[k] > contentMax.x then
                contentMax.x = list[k]
            end
            if list[k + 1] > contentMax.y then
                contentMax.y = list[k + 1]
                bar:updateContentHeight(contentMax.y)
            end
        end
    end

    function obj:get_pos()
        return self.base_x, self.base_y
    end

    -- implement for canvas-proxy
    function obj:print(text, x, y)
        local elem = { "print", text, x, y}
        elements[#elements + 1] = elem

        update_cord_max({x, y})
        print_elem(elem)
    end

    function obj:line(x1, y1, x2, y2, ...)
        local pos_list = {x1, y1, x2, y2, ...}
        local elem = {"line", pos_list}
        elements[#elements + 1] = elem

        update_cord_max(pos_list)
        line_elem(elem)
    end

    -- event listener
    function obj:mousepressed(x, y, button, istouch)
        bar:mousepressedScroll(x - self.base_x, y - self.base_y, button)
    end
    function obj:mousereleased(x, y, button)
        bar:mousereleasedScroll(x - self.base_x, y - self.base_y, button)
    end

    -- scroller 所属函数
    function obj:draw()
        love.graphics.rectangle("line", obj.base_x, obj.base_y, obj.base_w, obj.base_h)
        love.graphics.draw(canvas, obj.base_x, obj.base_y)
        bar:drawScroll()
    end

    function obj:update(dt)
        local mx = love.mouse.getX() - self.base_x
        local my = love.mouse.getY() - self.base_y
        if bar:updateScroll(mx, my) then
            updateViewport()
            draw_elements()
        end
    end

    function obj:clear()
        elements = {}
        contentMax.x = obj.base_w
        contentMax.y = obj.base_h
        bar:updateContentHeight(0)
        updateViewport()
    end

    return obj
end

return {
    new = new_scroller,
}
