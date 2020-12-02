local M = {}

M.set = function(comments)
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
end

return M
