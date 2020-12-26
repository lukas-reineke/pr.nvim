local util = require "pr/util"
local M = {}

local github_sign_namespace = "github_sign_namespace"

M.setup = function()
    vim.fn.sign_define("PRGitHubComment", {text = "C", texthl = "GitGutterChange"})
    -- vim.fn.sign_define("PRGitHubComment", {text = "", texthl = "GitGutterChange"})
    vim.fn.sign_define("PRNewComment", {text = "C", texthl = "GitGutterAdd"})

    -- vim.g.pr_namespace = vim.api.nvim_create_namespace("pr_namespace")
end

M.place = function(comment_lists)
    M.clear()

    for _, comment_list in pairs(comment_lists) do
        local comment = comment_list[1]
        local bufnr = vim.fn.bufnr(comment.path)

        if comment.side == "LEFT" then
            -- try to find the matching fugitive buffer to place the sign in instead
            for _, cwinid in pairs(util.buf_get_wins(bufnr)) do
                if vim.api.nvim_win_get_option(cwinid, "diff") then
                    bufnr, _ = util.get_fugitive_buffer(bufnr, vim.fn.bufname(bufnr))
                    break
                end
            end
        end

        local highlight_group = "PRGitHubComment"
        if comment.pending then
            highlight_group = "PRNewComment"
        end

        if bufnr > -1 then
            vim.fn.sign_place(
                0,
                github_sign_namespace,
                highlight_group,
                bufnr,
                {lnum = comment.original_line, priority = 1000}
            )
        end
    end
end

M.clear = function()
    vim.fn.sign_unplace(github_sign_namespace)
end

return M
