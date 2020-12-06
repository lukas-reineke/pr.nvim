local floating_win = require "pr/floating_win"
local util = require "pr/util"
local M = {}

local get_path = function()
    local git_base = util.readp("basename $(git rev-parse --show-toplevel 2> /dev/null) 2> /dev/null")[1]
    local git_branch = util.readp("git rev-parse --abbrev-ref HEAD 2> /dev/null")[1]:gsub("/", "-")
    local path = string.format("%s%s%s/%s", os.getenv("HOME"), "/.cache/nvim/pr.nvim/", git_base, git_branch)

    return path
end

-- TODO: support not only floating win
M.new = function(line1, line2)
    local buf_name = vim.fn.expand("%"):gsub("/", "++")
    local commit_id = util.readp("git rev-parse HEAD 2> /dev/null")[1]

    local width = 80
    local height = math.ceil(vim.o.lines * 0.8)
    local row = math.ceil(vim.o.lines * 0.1)
    local col = math.ceil((vim.o.columns / 2) - 40)

    local bufnr = vim.api.nvim_create_buf(false, true)
    local opt = {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal"
    }
    local bg_opt = vim.tbl_extend("keep", {col = col - 1, row = row - 1}, opt)
    local _, bg_bufnr = floating_win.open_border_win(bg_opt, "Normal:Floating")
    local winnr = vim.api.nvim_open_win(bufnr, true, opt)
    vim.wo.winhl = "Normal:Floating"
    vim.cmd [[setlocal wrap]]

    local file = string.format("%s++%d++%d++%s", buf_name, line1, line2, commit_id)
    local path = get_path()
    os.execute(string.format("mkdir -p %s", path))
    vim.cmd(string.format("edit %s/%s", path, file))

    vim.cmd [[set filetype=markdown]]

    vim.cmd [[augroup PRComment]]
    vim.cmd [[autocmd! * <buffer>]]
    vim.cmd [[autocmd BufWritePost <buffer> lua require("pr").find_pending_comments()]]
    vim.cmd(string.format([[autocmd BufWipeout,BufHidden <buffer> exe 'bw %s']], bg_bufnr))
    vim.cmd [[augroup END]]
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

    local filenames = util.readp(string.format("find %s/* -maxdepth 1 2> /dev/null", path))
    for _, filename in pairs(filenames) do
        table.insert(files, filename)
    end

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

    local filenames = util.readp(string.format("find %s/%s -maxdepth 1 2> /dev/null", path, file))
    for _, filename in pairs(filenames) do
        os.remove(filename)
    end
end

return M
