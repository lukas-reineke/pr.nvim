local util = require "pr/util"
local M = {}

local github_sign_namespace = "github_sign_namespace"

M.setup = function()
    vim.fn.sign_define("PRGitHubComment", {text = "C", texthl = "GitGutterChange"})
    -- vim.fn.sign_define("PRGitHubComment", {text = "", texthl = "GitGutterChange"})
    vim.fn.sign_define("PRNewComment", {text = "C", texthl = "GitGutterAdd"})

    -- vim.g.pr_namespace = vim.api.nvim_create_namespace("pr_namespace")
end

M.place_github = function(comments)
    for _, comment in pairs(comments) do
        local bufnr = vim.fn.bufnr(comment.path)
        local bufname = vim.fn.bufname(bufnr)

        local diff = false
        local winid
        for _, cwinid in pairs(util.buf_get_wins(bufnr)) do
            if vim.api.nvim_win_get_option(cwinid, "diff") then
                winid = cwinid
                diff = true
                break
            end
        end

        -- TODO: make this a util function
        if comment.side == "LEFT" and diff then
            for _, cwinid in pairs(vim.api.nvim_list_wins()) do
                if cwinid ~= winid and vim.api.nvim_win_get_option(cwinid, "diff") then
                    local cbufnr = vim.api.nvim_win_get_buf(cwinid)
                    local cbufname = vim.fn.bufname(cbufnr)
                    if cbufname:find(bufname, 1, true) then
                        bufnr = cbufnr
                        break
                    end
                end
            end
        end

        if comment.in_reply_to_id ~= nil then
            goto continue
        end
        if bufnr > -1 then
            vim.fn.sign_place(
                0,
                github_sign_namespace,
                "PRGitHubComment",
                bufnr,
                {lnum = comment.original_line, priority = 1000}
            )

        -- -- TODO: make this smarter
        -- vim.api.nvim_buf_set_virtual_text(
        --     bufnr,
        --     vim.g.pr_namespace,
        --     comment.original_line - 1,
        --     {{"     " .. comment.body:sub(1, 40) .. "...", "Comment"}},
        --     vim.empty_dict()
        -- )
        end
        ::continue::
    end
end

M.place_new = function(comments)
    for _, comment in pairs(comments) do
        local bufnr = vim.fn.bufnr(comment.filename)
        if bufnr > -1 then
            vim.fn.sign_place(0, github_sign_namespace, "PRNewComment", bufnr, {lnum = comment.lnum})
        end
    end
end

M.place = function(github_comments, pending_comments, opts)
    opts = opts or {}
    local place_github_comments = vim.F.if_nil(opts.place_github_comments, true)
    local place_pending_comments = vim.F.if_nil(opts.place_pending_comments, true)

    if place_github_comments then
        M.place_github(github_comments)
    end

    if place_pending_comments then
        M.place_new(pending_comments)
    end
end

M.clear = function()
    vim.fn.sign_unplace(github_sign_namespace)
end

return M
