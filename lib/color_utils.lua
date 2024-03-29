local tunpack = table.unpack or unpack

local M = {}

function M.set_color_red()
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(255, 0, 0, a)
    return {r, g, b, a}
end

function M.set_color_green()
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(0, 255, 0, a)
    return {r, g, b, a}
end

function M.set_color(r, g, b, a)
    local _r, _g, _b, _a = love.graphics.getColor()
    love.graphics.setColor(r, g, b, a or _a)
    return {_r, _g, _b, _a}
end

function M.restore_color(old)
    if old then
        love.graphics.setColor(tunpack(old))
    end
end

return M