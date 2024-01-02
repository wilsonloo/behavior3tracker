local unpack = unpack or table.unpack

local M = {}
function M.select(n, ...)
    if n == "#" then
        local list = { ... }
        return #list
    end
    assert(type(n) == "number")
    assert(n > 0)
    local list = { ... }
    local ret = {}
    for k = n, #list do
        ret[#ret + 1] = list[k]
    end
    return unpack(ret)
end

return {
    unpack = unpack,
    select = select or M.select,
}