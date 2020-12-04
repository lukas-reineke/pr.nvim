local date = require "date"

local M = {}

local reaction_map = {
    ["+1"] = "👍",
    ["-1"] = "👎",
    ["laugh"] = "😀",
    ["hooray"] = "🎉",
    ["confused"] = "☹️",
    ["heart"] = "❤️",
    ["rocket"] = "🚀",
    ["eyes"] = "👀"
}

local function insert_body(body, width, lines)
    local padding = "  "
    for _, line in pairs(vim.split(body, "\n")) do
        line = padding .. line:gsub("\r", "")
        if #line > width then
            while #line > width do
                local trimmed_line = string.sub(line, 1, width)
                local index = trimmed_line:reverse():find(" ")
                if index == nil or index > #trimmed_line / 2 then
                    break
                else
                    table.insert(lines, string.sub(line, 1, width - index))
                    line = padding .. string.sub(line, width - index + 2, #line)
                end
            end
        end
        table.insert(lines, line)
    end
end

local function float(github_comments, new_comments)
    local lines = {""}
    local width = 80
    local time_bias = date():getbias() * -1

    for _, comment in pairs(github_comments) do
        local created_at = "`" .. date(comment.created_at):addminutes(time_bias):fmt("%Y %b %d %I:%M %p %Z") .. "`"
        local user_name = " @" .. comment.user.login .. " "
        local spacer = ("─"):rep(width - #user_name - #created_at)
        table.insert(lines, user_name .. spacer .. created_at)
        table.insert(lines, "")

        insert_body(comment.body, width, lines)
        table.insert(lines, "")

        if comment.reactions.total_count > 0 then
            local reactions = ""
            for r, count in pairs(comment.reactions) do
                if r ~= "total_count" and r ~= "url" and count > 0 then
                    reactions = string.format("%s  %s%d", reactions, reaction_map[r], count)
                end
            end
            table.insert(lines, reactions)
            table.insert(lines, "")
        end
    end

    for _, comment in pairs(new_comments) do
        local user_name = " Pending "
        local spacer = ("─"):rep(width - #user_name - 1)
        table.insert(lines, user_name .. spacer)
        table.insert(lines, "")

        insert_body(comment.body, width, lines)
        table.insert(lines, "")
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    local opt = vim.lsp.util.make_floating_popup_options(width, #lines, {})
    local winnr = vim.api.nvim_open_win(bufnr, false, opt)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    local cwin = vim.api.nvim_get_current_win()

    vim.api.nvim_set_current_win(winnr)
    vim.cmd("setlocal filetype=prcomment")
    vim.cmd("ownsyntax markdown")
    vim.cmd("setlocal nowrap")
    vim.cmd(string.format("syntax match GitHubUserName /@[^ ]\\+/"))

    vim.api.nvim_set_current_win(cwin)
    return bufnr, winnr
end

M.open = function(github_comments, new_comments)
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.fn.getcurpos()
    local lnum = cursor[2] - 1
    local valid_github_comments = {}
    local valid_new_comments = {}

    for _, comment in pairs(github_comments) do
        local comment_bufnr = vim.fn.bufnr(comment.path)
        if bufnr ~= comment_bufnr then
            goto continue
        end
        if lnum ~= comment.original_line - 1 then
            goto continue
        end

        table.insert(valid_github_comments, comment)

        ::continue::
    end

    for _, comment in pairs(new_comments) do
        local comment_bufnr = vim.fn.bufnr(comment.filename)
        if bufnr ~= comment_bufnr then
            goto continue
        end
        if lnum ~= comment.lnum - 1 then
            goto continue
        end

        table.insert(valid_new_comments, comment)

        ::continue::
    end

    local _, winnr = float(valid_github_comments, valid_new_comments)
    vim.lsp.util.close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave", "WinScrolled"}, winnr)
end

return M
