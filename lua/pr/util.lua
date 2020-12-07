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

function M.buf_get_wins(bufnr)
    local wins = {}

    for _, winid in pairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(winid) == bufnr then
            table.insert(wins, winid)
        end
    end

    return wins
end

return M
