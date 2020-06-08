local utils = {}

function utils.fassert(cond, fmt, ...)
    return assert(cond, string.format(fmt, ...))
end

function utils.ferror(fmt, ...)
    return error(string.format(fmt, ...))
end

function utils.readfile(filename)
    local f, err, code = io.open(filename)
    if not f then return nil, err, code end
    local contents = f:read('*a')
    f:close()
    return contents
end

return utils