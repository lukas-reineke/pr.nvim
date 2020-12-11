local util = require "pr/util"

local f = string.format

local M = {}

local reaction_map = {
    ["+1"] = "👍",
    ["-1"] = "👎",
    ["laugh"] = "😄",
    ["hooray"] = "🎉",
    ["confused"] = "😕",
    ["heart"] = "❤️",
    ["rocket"] = "🚀",
    ["eyes"] = "👀"
}

local function insert_body(body, width, lines, format)
    for _, line in pairs(vim.split(vim.trim(body), "\n")) do
        line = line:gsub("\r", "")
        while format and #line > width do
            local trimmed_line = string.sub(line, 1, width)
            local index = trimmed_line:reverse():find(" ")
            if index == nil or index > #trimmed_line / 2 then
                break
            end
            table.insert(lines, string.sub(line, 1, width - index))
            line = string.sub(line, width - index + 2, #line)
        end
        table.insert(lines, line)
    end
end

local function float(github_comments, pending_comments, enter, line1, line2, side, buf_name)
    local lines = {}
    local width = 80
    local commit_id = util.readp("git rev-parse HEAD 2> /dev/null")[1]
    local temp_file_name = ""

    -- TODO make function to parse arguments
    -- support for range would be nice
    local first_comment = {side = side}
    if #github_comments > 0 then
        first_comment = github_comments[1]
        line1 = github_comments[1].start_line
        line2 = github_comments[1].original_line
    elseif #pending_comments > 0 then
        first_comment = pending_comments[1]
        line1 = pending_comments[1].start_line
        line2 = pending_comments[1].original_line
    end

    if line1 == vim.NIL then
        line1 = line2
    end

    -- TODO: move this into a function
    temp_file_name = f("%s++%d++%d++%s++%s", buf_name, line2, line1 or line2, commit_id, side)

    if line1 ~= line2 then
        table.insert(lines, f("Comment on lines +%d to +%d side %s", line1, line2, first_comment.side))
    else
        table.insert(lines, f("Comment on line +%d side %s", line1, first_comment.side))
    end

    table.insert(lines, "")

    for _, comment in pairs(github_comments) do
        local created_at = " " .. util.format_date(comment.created_at)
        local user_name = f("@%s %s ", comment.user.login, comment.author_association)
        local spacer = ("─"):rep(width - #user_name - #created_at)
        table.insert(lines, user_name .. spacer .. created_at)
        table.insert(lines, "")
        insert_body(comment.body, width, lines, true)
        table.insert(lines, "")

        if comment.reactions.total_count > 0 then
            local reactions = ""
            for r, count in pairs(comment.reactions) do
                if r ~= "total_count" and r ~= "url" and count > 0 then
                    local reaction = f(" %s%d", reaction_map[r], count)
                    if #reactions > 0 then
                        reactions = ("%s %s"):format(reactions, reaction)
                    else
                        reactions = reaction
                    end
                end
            end
            table.insert(lines, reactions)
            table.insert(lines, "")
        end
    end

    if #pending_comments == 0 and enter then
        local user_name = "Add a comment below "
        local spacer = ("─"):rep(width - #user_name)
        table.insert(lines, user_name .. spacer)
        table.insert(lines, "")
    end

    for _, comment in pairs(pending_comments) do
        local user_name = "Pending "
        local spacer = ("─"):rep(width - #user_name)
        table.insert(lines, user_name .. spacer)
        table.insert(lines, "")

        insert_body(comment.body, width, lines, not enter)

        if not enter then
            table.insert(lines, "")
        end
    end

    local opt
    local bg_opt
    if enter then
        local height = math.ceil(vim.o.lines * 0.8)
        local row = math.ceil(vim.o.lines * 0.1)
        local col = math.ceil((vim.o.columns / 2) - 40)
        opt = {
            relative = "editor",
            row = row,
            col = col,
            width = width,
            height = height,
            style = "minimal"
        }
        bg_opt = vim.tbl_extend("keep", {col = col - 2, row = row - 1}, opt)
    else
        opt = vim.lsp.util.make_floating_popup_options(width, M.get_preview_height(#lines), {})
        bg_opt = vim.tbl_extend("keep", {}, opt)

        -- adjust for border
        if opt.anchor == "NW" then
            opt.row = opt.row + 1
            opt.col = opt.col + 2
        elseif opt.anchor == "NE" then
            opt.row = opt.row + 1
            opt.col = opt.col - 2
        elseif opt.anchor == "SW" then
            opt.row = opt.row - 1
            opt.col = opt.col + 2
        else
            opt.row = opt.row - 1
            opt.col = opt.col - 2
        end
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    local winnr = vim.api.nvim_open_win(bufnr, false, opt)

    local winhl
    if enter then
        winhl = "Normal:Floating"
    else
        winhl = "Normal:WinNormalNC"
    end

    local bg_winnr, bg_bufnr = M.open_border_win(bg_opt, winhl)

    local cwin = vim.api.nvim_get_current_win()
    local cbufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_set_current_win(winnr)
    vim.cmd("setlocal filetype=prcomment")
    vim.cmd("ownsyntax markdown")
    if enter then
        vim.cmd("setlocal wrap")
    else
        vim.cmd("setlocal nowrap")
    end
    vim.cmd("syntax match GitHubUserName /@[^ ]\\+/")
    vim.cmd(
        "syntax match GitHubAuthorAssociation /\\(COLLABORATOR\\|CONTRIBUTOR\\|FIRST_TIMER\\|FIRST_TIME_CONTRIBUTOR\\|MANNEQUIN\\|MEMBER\\|NONE\\|OWNER\\)/"
    )
    vim.cmd("syntax match GitHubDate /\\d\\d\\d\\d \\w\\w\\w \\d\\d \\d\\d:\\d\\d \\(AM\\|PM\\) \\w\\w\\w/")
    vim.cmd(
        "syntax match GitHubCommentLength /Comment on lines\\? +\\(\\d\\)\\+\\( to +\\(\\d\\)\\+\\)\\?\\( side \\(LEFT\\|RIGHT\\)\\)\\?/"
    )

    -- TODO: clean this up
    vim.b.temp_file_name = temp_file_name
    vim.b.line1 = line1
    vim.b.line2 = line2
    vim.b.bufnr = cbufnr

    vim.wo.winhl = winhl

    if enter then
        vim.cmd [[augroup PRComment]]
        vim.cmd [[autocmd! * <buffer>]]
        vim.cmd(f([[autocmd BufWipeout,BufHidden <buffer> exe 'bw %s']], bg_bufnr))
        vim.cmd [[augroup END]]
        vim.cmd [[command! -buffer -range PRCommentSave lua require("pr").save_comment()]]
        vim.cmd [[command! -buffer -range PRCommentSuggest lua require("pr/comment").suggestion()]]
    else
        vim.api.nvim_set_current_win(cwin)
        vim.lsp.util.close_preview_autocmd(
            {"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave", "WinScrolled"},
            bg_winnr
        )
    end

    return bufnr, winnr
end

M.open = function(comments, enter, line1, line2, args)
    local bufnr = vim.api.nvim_get_current_buf()
    local bufname = vim.fn.bufname(bufnr)
    local cursor = vim.fn.getcurpos()
    local lnum = cursor[2] - 1
    local side = "RIGHT"
    local pick_side = vim.wo.diff
    local fugitive = bufname:match("^fugitive:///")
    local valid_github_comments = {}
    local valid_pending_comments = {}
    if args ~= nil then
        args = vim.split(args, " ")
    else
        args = {}
    end

    if fugitive then
        side = "LEFT"
        bufnr, bufname = util.get_fugitive_buffer(bufnr, bufname, true)
    end

    if #args > 0 and args[1] == "RIGHT" or args[1] == "LEFT" then
        side = args[1]
        pick_side = true
    end

    for _, comment in pairs(comments) do
        local comment_bufnr = vim.fn.bufnr(comment.path)
        if bufnr ~= comment_bufnr then
            goto continue
        end
        if lnum ~= comment.original_line - 1 then
            goto continue
        end

        -- TODO: make this an option?
        if pick_side and comment.side ~= side then
            goto continue
        end

        if comment.pending then
            table.insert(valid_pending_comments, comment)
        else
            table.insert(valid_github_comments, comment)
        end

        ::continue::
    end

    if #valid_pending_comments > 1 then
        for _, comment in pairs(valid_pending_comments) do
            if comment.side == side then
                valid_pending_comments = {comment}
                break
            end
        end
    end

    if (#valid_github_comments > 0 or #valid_pending_comments > 0) or enter then
        local _, winnr =
            float(valid_github_comments, valid_pending_comments, enter, line1, line2, side, bufname:gsub("/", "++"))
        if enter then
            util.remove_undo()
        else
            vim.lsp.util.close_preview_autocmd(
                {"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave", "WinScrolled"},
                winnr
            )
        end
    end
end

M.open_border_win = function(opt, winhl)
    local cwin = vim.api.nvim_get_current_win()
    local bg_bufnr = vim.api.nvim_create_buf(false, true)
    local bg_opt = vim.tbl_extend("keep", {width = opt.width + 4, height = opt.height + 2}, opt)

    local bg_lines = {}
    table.insert(bg_lines, "╭" .. ("─"):rep(opt.width + 2) .. "╮")
    for i = 2, opt.height + 1 do
        bg_lines[i] = "│" .. (" "):rep(opt.width + 2) .. "│"
    end
    table.insert(bg_lines, "╰" .. ("─"):rep(opt.width + 2) .. "╯")
    vim.api.nvim_buf_set_lines(bg_bufnr, 0, -1, false, bg_lines)
    local bg_winnr = vim.api.nvim_open_win(bg_bufnr, true, bg_opt)

    vim.wo.winhl = winhl

    vim.api.nvim_set_current_win(cwin)

    return bg_winnr, bg_bufnr
end

M.get_preview_height = function(height)
    local lines_above = vim.fn.winline() - 1
    local lines_below = vim.fn.winheight(0) - lines_above

    return math.min(height, math.max(lines_above, lines_below) - 2)
end

return M
