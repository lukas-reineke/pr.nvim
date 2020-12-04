local M = {}

function M.readp(cmd)
    local result = {}
    local pfile = assert(io.popen(cmd))
    for lines in pfile:lines() do
        table.insert(result, lines)
    end
    pfile:close()

    return result
end

return M
