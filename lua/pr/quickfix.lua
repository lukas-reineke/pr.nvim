local M = {}

M.set = function(comments, opts)
    opts = opts or {}
    local open_qflist = vim.F.if_nil(opts.open_qflist, true)
    local items = {}

    for _, comment in pairs(comments) do
        table.insert(
            items,
            {
                filename = comment.path,
                lnum = comment.original_line,
                text = "@" .. comment.user.login .. ": " .. comment.body:gsub("\r", ""):gsub("\n", " ")
            }
        )
    end

    vim.fn.setqflist(items)

    if open_qflist then
        vim.cmd [[copen]]
    end
end

return M
