local http_request = require "http.request"
local cjson = require "cjson"

local M = {}

local request_timeout = 5
local github_accept_header =
    "application/vnd.github.v3+json;application/vnd.github.comfort-fade-preview+json;application/vnd.github.squirrel-girl-preview"

M.load = function(repo, pr)
    local url = string.format("https://api.github.com/repos/%s/pulls/%d/comments", repo, pr)
    local request = http_request.new_from_uri(url)
    request.headers:append("authorization", "token " .. os.getenv("GITHUB_TOKEN"))
    request.headers:append("accept", github_accept_header)
    local headers, stream = assert(request:go(request_timeout))
    local body = assert(stream:get_body_as_string())
    if headers:get ":status" ~= "200" then
        error(body)
    end
    local comments = cjson.decode(body)

    table.sort(
        comments,
        function(a, b)
            return a.created_at < b.created_at
        end
    )

    return comments
end

M.add_comment = function(repo, pr, comment)
    local url = string.format("https://api.github.com/repos/%s/pulls/%d/comments", repo, pr)
    local request = http_request.new_from_uri(url)
    request.headers:upsert(":method", "POST")
    request.headers:append("authorization", "token " .. os.getenv("GITHUB_TOKEN"))
    request.headers:append("accept", github_accept_header)
    request:set_body(
        cjson.encode {
            body = comment.body,
            commit_id = vim.fn.system("git rev-parse HEAD"):gsub("\n", ""),
            path = comment.filename,
            side = "RIGHT",
            start_side = "RIGHT",
            line = comment.lnum
        }
    )
    local headers, stream = assert(request:go(request_timeout))
    local body = assert(stream:get_body_as_string())
    if headers:get ":status" ~= "201" then
        error(body)
    end
    local comments = cjson.decode(body)

    return comments
end

return M
