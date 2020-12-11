local gh = require "octo.gh"

local f = string.format
local json = {
    parse = vim.fn.json_decode,
    stringify = vim.fn.json_encode
}

local M = {}

local github_accept_header =
    "accept:application/vnd.github.v3+json;application/vnd.github.comfort-fade-preview+json;application/vnd.github.squirrel-girl-preview"

M.load_gh = function(repo, pr, cb)
    gh.run {
        args = {"api", f("repos/%s/pulls/%d/comments", repo, pr), "-H", github_accept_header, "--paginate"},
        cb = function(response)
            local resp = json.parse(response)
            cb(resp)
        end
    }
end

M.add_comment = function(repo, pr, comment)
    local args = {
        "api",
        f("repos/%s/pulls/%d/comments", repo, pr),
        "-H",
        github_accept_header,
        "--method",
        "POST",
        "--field",
        "body=" .. comment.body,
        "--field",
        "commit_id=" .. comment.commit_id,
        "--field",
        "path=" .. comment.path,
        "--field",
        "side=" .. comment.side,
        "--field",
        "start_side=" .. comment.side,
        "--field",
        "line=" .. comment.original_line
    }
    if comment.start_line ~= comment.original_line then
        table.insert(args, "--field start_line=" .. comment.start_line)
    end

    gh.run {
        args = args,
        mode = "sync"
    }
end

return M
