local signs = require "pr/signs"
local floating_win = require "pr/floating_win"
local api = require "pr/api"
local quickfix = require "pr/quickfix"

local M = {}

M.comments = {}

M.setup = function()
    signs.setup()
    vim.cmd [[augroup PR]]
    vim.cmd [[autocmd!]]
    vim.cmd [[autocmd BufReadPost lua require("pr").place_signs()]]
    vim.cmd [[augroup END]]
end

M.load = function(repo, pr)
    M.comments = api.load(repo, pr)

    signs.place(M.comments)
end

M.place_signs = function()
    return signs.place(M.comments)
end

M.open_floating_win = function()
    return floating_win.open(M.comments)
end

M.set_quickfix = function()
    return quickfix.set(M.comments)
end

return M
