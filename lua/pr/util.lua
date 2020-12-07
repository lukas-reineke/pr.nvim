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

function M.path_exists(path)
    local ok, err, code = os.rename(path, path)
    if not ok then
        if code == 13 then
            return true
        end
    end
    return ok, err
end

function M.remove_undo()
    local undolevels = vim.o.undolevels
    vim.bo.undolevels = -1
    vim.cmd [[execute "normal a \<BS>\<Esc>"]]
    vim.bo.undolevels = undolevels
end

return M
