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

local function float(comments)
    local lines = {""}
    local width = 80
    local height = 1
    local time_bias = date():getbias() * -1

    for _, comment in pairs(comments) do
        local created_at = "`" .. date(comment.created_at):addminutes(time_bias):fmt("%Y %b %d %I:%M %p %Z") .. "`"
        local user_name = " @" .. comment.user.login .. " "
        local spacer = ("─"):rep(width - #user_name - #created_at)
        table.insert(lines, user_name .. spacer .. created_at)
        table.insert(lines, "")
        for _, line in pairs(vim.split(comment.body, "\n")) do
            line = "  " .. line:gsub("\r", "")
            table.insert(lines, line)
            height = height + math.ceil(#line / width)
        end
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
            height = height + 2
        end
        height = height + 3
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    local opt = vim.lsp.util.make_floating_popup_options(width, height, {})
    local winnr = vim.api.nvim_open_win(bufnr, false, opt)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    local cwin = vim.api.nvim_get_current_win()

    vim.api.nvim_set_current_win(winnr)
    vim.cmd("ownsyntax markdown")
    vim.cmd("setlocal wrap")
    vim.cmd(string.format("syntax match GitHubUserName /@[^ ]\\+/"))

    vim.api.nvim_set_current_win(cwin)
    return bufnr, winnr
end

M.open = function(g_comments)
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.fn.getcurpos()
    local lnum = cursor[2] - 1
    local comments = {}

    for _, comment in pairs(g_comments) do
        local comment_bufnr = vim.fn.bufnr(comment.path)
        if bufnr ~= comment_bufnr then
            goto continue
        end
        if lnum ~= comment.original_line - 1 then
            goto continue
        end

        table.insert(comments, comment)

        ::continue::
    end

    local _, winnr = float(comments)
    vim.lsp.util.close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, winnr)
end

return M
