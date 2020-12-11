local date_ok, date = pcall(require, "date")

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
    local ok, _, code = os.rename(path, path)
    if not ok then
        if code == 13 then
            return true
        end
    end
    return ok
end

function M.concat(tablea, tableb)
    local result = {}

    for _, v in pairs(tablea) do
        table.insert(result, v)
    end
    for _, v in pairs(tableb) do
        table.insert(result, v)
    end

    return result
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

function M.get_fugitive_buffer(bufnr, bufname, reverse)
    local check
    if reverse then
        check = function(name, cname)
            return name:find(cname, 1, true)
        end
    else
        check = function(name, cname)
            return cname:find(name, 1, true)
        end
    end

    for _, cwinid in pairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_option(cwinid, "diff") then
            local cbufnr = vim.api.nvim_win_get_buf(cwinid)
            local cbufname = vim.fn.bufname(cbufnr)
            if cbufname ~= bufname and check(bufname, cbufname) then
                return cbufnr, cbufname
            end
        end
    end

    return bufnr, bufname
end

function M.format_date(to_format)
    if not date_ok then
        return to_format
    end

    local time_bias = date():getbias() * -1
    return date(to_format):addminutes(time_bias):fmt("%Y %b %d %I:%M %p %Z")
end

return M
