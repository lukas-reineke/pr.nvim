local signs = require "pr/signs"
local floating_win = require "pr/floating_win"
local api = require "pr/api"
local quickfix = require "pr/quickfix"
local comment = require "pr/comment"
local util = require "pr/util"

local M = {}

-- M.github_comments = {}
-- M.pending_comments = {}

M.comments = {}
M.base = {}

M.setup = function()
    signs.setup()
    vim.cmd [[augroup PR]]
    vim.cmd [[autocmd!]]
    vim.cmd [[autocmd BufReadPost,BufDelete * lua require("pr").place_signs()]]
    vim.cmd [[augroup END]]

    vim.cmd [[command! -range PRCommentDelete lua require("pr").delete_comment(<line1>, <line2>)]]
    -- vim.cmd [[command! -range -nargs=* PRComment lua require("pr").open_floating_win(true, <line1>, <line2>, "<args>")]]
    vim.cmd [[command! -range -nargs=* PRCommentPreview lua require("pr").open_comment(<line1>, <line2>, "<args>", true)]]

    vim.cmd [[command! -range -nargs=? PRComment lua require("pr").open_comment(<line1>, <line2>, "<args>", false)]]
end

M.load = function(repo, pr)
    api.load_gh(
        repo,
        pr,
        function(resp)
            M.comments, M.base = util.build_comments(resp, {}, {})
            M.comments, M.base = util.build_comments(comment.find(), M.comments, M.base)
            -- M.github_comments = comments
            -- M.find_pending_comments()
            M.place_signs()
        end
    )
end

function M.open_comment(line1, line2, side, preview)
    comment.open_comment(
        M.comments,
        {
            line1 = line1,
            line2 = line2,
            side = side,
            preview = preview
        }
    )
end

M.place_signs = function()
    return signs.place(M.comments)
end

M.open_floating_win = function(enter, line1, line2, args)
    -- return floating_win.open(util.concat(M.github_comments, M.pending_comments), enter, line1, line2, args)
end

M.save_comment = function()
    comment.save_comment()
    M.find_pending_comments()
end

M.set_quickfix = function(opts)
    -- return quickfix.set(util.concat(M.github_comments, M.pending_comments), opts)
end

M.find_pending_comments = function()
    M.pending_comments = comment.find()
    M.place_signs()
end

M.add_comments = function(repo, pr)
    for _, c in pairs(comment.find()) do
        api.add_comment(repo, pr, c)
    end
    comment.delete_all_comments()
    signs.clear()
    M.load(repo, pr)
end

M.delete_comment = function(line1, line2)
    comment.delete_comment(line1, line2)
    M.find_pending_comments()
end

return M
