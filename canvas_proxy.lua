local proxy = function()
    local temp = {}

    function temp:print(text, x, y)
        love.graphics.print(text, x, y)
    end

    function temp:line(x1, y1, x2, y2, ...)
        love.graphics.line( x1, y1, x2, y2, ... )
    end

    function temp:get_pos()
        return 0, 0
    end

    return temp
end

return {
    new = function()
        return proxy()
    end,
}