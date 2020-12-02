local M = {}

local github_sign_namespace = "github_sign_namespace"

M.setup = function()
    vim.fn.sign_define("GitHubComment", {text = "C"})
end

M.place = function(comments)
    for _, comment in pairs(comments) do
        local bufnr = vim.fn.bufnr(comment.path)
        if comment.in_reply_to_id ~= nil then
            goto continue
        end
        if bufnr > -1 then
            vim.fn.sign_place(0, github_sign_namespace, "GitHubComment", bufnr, {lnum = comment.original_line})
        end
        ::continue::
    end
end

return M
