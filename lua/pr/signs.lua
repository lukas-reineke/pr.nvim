local M = {}

local github_sign_namespace = "github_sign_namespace"

M.setup = function()
    vim.fn.sign_define("PRGitHubComment", {text = "C", texthl = "GitGutterChange"})
    -- vim.fn.sign_define("PRGitHubComment", {text = "", texthl = "GitGutterChange"})
    vim.fn.sign_define("PRNewComment", {text = "C", texthl = "GitGutterAdd"})
end

M.place_github = function(comments)
    for _, comment in pairs(comments) do
        local bufnr = vim.fn.bufnr(comment.path)
        if comment.in_reply_to_id ~= nil then
            goto continue
        end
        if bufnr > -1 then
            vim.fn.sign_place(0, github_sign_namespace, "PRGitHubComment", bufnr, {lnum = comment.original_line})
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
