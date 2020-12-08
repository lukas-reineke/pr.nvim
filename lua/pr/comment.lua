local util = require "pr/util"
local M = {}

local get_path = function()
    local git_base = util.readp("basename $(git rev-parse --show-toplevel 2> /dev/null) 2> /dev/null")[1]
    local git_branch = util.readp("git rev-parse --abbrev-ref HEAD 2> /dev/null")[1]:gsub("/", "-")
    local path = string.format("%s%s%s/%s", os.getenv("HOME"), "/.cache/nvim/pr.nvim/", git_base, git_branch)

    return path
end

M.save_comment = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local width = 80
    local comment_header = "Add a comment below "
    local spacer_comment = ("─"):rep(width - #comment_header)
    local foo = comment_header .. spacer_comment
    local pending_header = "Pending "
    local spacer_pending = ("─"):rep(width - #pending_header)
    local bar = pending_header .. spacer_pending
    local path = get_path()

    local comment_lines = ""

    local read = false
    for i = 1, #lines do
        if read then
            comment_lines = comment_lines .. "\n" .. lines[i]
        end
        if lines[i] == foo or lines[i] == bar then
            read = true
        end
    end

    os.execute(string.format("mkdir -p %s", path))
    local file = io.open(path .. "/" .. vim.b.temp_file_name, "w+")
    io.output(file)
    io.write(vim.trim(comment_lines))
    io.close(file)
end

M.find = function()
    local comments = {}
    local temp_path = get_path()

    if not util.path_exists(temp_path) then
        return {}
    end

    local filenames = util.readp(string.format("find %s/* -maxdepth 1 2> /dev/null", temp_path))
    for i, filename in pairs(filenames) do
        local file = io.open(filename, "rb")
        if not file then
            goto continue
        end
        local body = file:read "*a"
        file:close()

        local parts = vim.split(filename, "++")
        local side = parts[#parts]
        parts[#parts] = nil
        local commit_id = parts[#parts]
        parts[#parts] = nil
        local start_line = tonumber(parts[#parts])
        parts[#parts] = nil
        local original_line = tonumber(parts[#parts])
        parts[#parts] = nil
        local path = ""
        for _, part in pairs(parts) do
            path = string.format("%s/%s", path, part)
        end

        comments[i] = {
            path = path:sub(#temp_path + 3),
            original_line = original_line,
            start_line = start_line,
            commit_id = commit_id,
            body = body,
            side = side,
            pending = true
        }
        ::continue::
    end

    return comments
end

M.delete_all_comments = function()
    local path = get_path()

    if not util.path_exists(path) then
        return
    end
    os.execute("rm --recursive " .. path)
end

M.delete_comment = function(_, line2)
    local path = get_path()
    local buf_name = vim.fn.expand("%"):gsub("/", "++")
    local file = string.format("%s++%d++%s", buf_name, line2, "*")

    if not util.path_exists(path) then
        return {}
    end

    local filenames = util.readp(string.format("find %s/%s -maxdepth 1 2> /dev/null", path, file))
    for _, filename in pairs(filenames) do
        os.remove(filename)
    end
end

M.suggestion = function()
    local lines = vim.api.nvim_buf_get_lines(vim.b.bufnr, vim.b.line1 - 1, vim.b.line2, false)
    local cursor = vim.fn.getcurpos()
    table.insert(lines, 1, "```suggestion")
    table.insert(lines, "```")
    vim.api.nvim_buf_set_lines(cursor[1], cursor[2], cursor[2], false, lines)
end

return M
