local utils = {}

function utils.fassert(cond, fmt, ...)
    return assert(cond, string.format(fmt, ...))
end

return utils