local M = {}

local get_path = function()
    local git_base = vim.fn.system("basename $(git rev-parse --show-toplevel)"):gsub("\n", "")
    local git_branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")
    local path = string.format("%s%s%s/%s", os.getenv("HOME"), "/.cache/nvim/pr.nvim/", git_base, git_branch)

    return path
end

-- TODO: support not only floating win
M.new = function(line1, line2)
    local buf_name = vim.fn.expand("%"):gsub("/", "++")
    local width = 80
    local win_height = vim.o.lines
    local height = math.ceil(win_height * 0.8)
    local row = math.ceil(win_height * 0.1)
    local col = math.ceil((vim.o.columns / 2) - 40)
    local commit_id = vim.fn.system("git rev-parse HEAD"):gsub("\n", "")

    local bufnr = vim.api.nvim_create_buf(false, false)
    local opt = {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal"
    }
    local winnr = vim.api.nvim_open_win(bufnr, true, opt)
    vim.wo.winhl = "Normal:Floating"
    vim.cmd [[setlocal wrap]]

    local file = string.format("%s++%d++%d++%s", buf_name, line1, line2, commit_id)
    local path = get_path()
    vim.fn.mkdir(path, "p")
    vim.cmd(string.format("edit %s/%s", path, file))

    vim.cmd [[set filetype=markdown]]

    vim.cmd [[augroup PRSaveComment]]
    vim.cmd [[autocmd! * <buffer>]]
    vim.cmd [[autocmd BufWritePost <buffer> lua require("pr").find_new_comments()]]
    vim.cmd [[augroup END]]
end

local function dir_exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
        if code == 13 then
            return true
        end
    end
    return ok, err
end

M.find = function()
    local files = {}
    local path = get_path()

    if not dir_exists(path) then
        return {}
    end

    local pfile = assert(io.popen("find " .. get_path() .. "/* -maxdepth 1 2> /dev/null"))
    for filename in pfile:lines() do
        table.insert(files, filename)
    end
    pfile:close()

    local comments = {}
    for i, file in pairs(files) do
        local f = io.open(file, "rb")
        if not f then
            goto continue
        end
        local body = f:read "*a"
        f:close()

        local parts = vim.split(file, "++")
        local commit_id = parts[#parts]
        parts[#parts] = nil
        parts[#parts] = nil
        local lnum = tonumber(parts[#parts])
        parts[#parts] = nil
        local filename = ""
        for _, part in pairs(parts) do
            filename = string.format("%s/%s", filename, part)
        end

        comments[i] = {
            filename = filename:sub(#path + 3),
            lnum = lnum,
            commit_id = commit_id,
            body = body
        }
        ::continue::
    end

    return comments
end

M.delete_all_comments = function()
    local path = get_path()

    if not dir_exists(path) then
        return
    end
    os.execute("rm --recursive " .. path)
end

M.delete_comment = function(line1, line2)
    local path = get_path()
    local buf_name = vim.fn.expand("%"):gsub("/", "++")
    local file = string.format("%s++%d++%d++%s", buf_name, line1, line2, "*")

    if not dir_exists(path) then
        return {}
    end

    local pfile = assert(io.popen(string.format("find %s/%s -maxdepth 1 2> /dev/null", path, file)))
    for filename in pfile:lines() do
        os.remove(filename)
    end
    pfile:close()
end

return M
