local signs = require "pr/signs"
local floating_win = require "pr/floating_win"
local api = require "pr/api"
local quickfix = require "pr/quickfix"
local comment = require "pr/comment"

local M = {}

M.github_comments = {}
M.new_comments = {}

M.setup = function()
    signs.setup()
    vim.cmd [[augroup PR]]
    vim.cmd [[autocmd!]]
    vim.cmd [[autocmd BufReadPost lua require("pr").place_signs()]]
    vim.cmd [[augroup END]]

    vim.cmd [[command! -range PRComment lua require("pr/comment").new(<line1>, <line2>)]]
    vim.cmd [[command! -range PRDelteComment lua require("pr").delete_comment(<line1>, <line2>)]]
end

M.load = function(repo, pr)
    M.github_comments = api.load(repo, pr)

    M.find_new_comments()
end

M.place_signs = function(opts)
    return signs.place(M.github_comments, M.new_comments, opts)
end

M.open_floating_win = function()
    return floating_win.open(M.github_comments, M.new_comments)
end

M.set_quickfix = function(opts)
    return quickfix.set(M.github_comments, opts)
end

M.find_new_comments = function()
    signs.clear()
    M.new_comments = comment.find()
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
    M.find_new_comments()
end

return M
