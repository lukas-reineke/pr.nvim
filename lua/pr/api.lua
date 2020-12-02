local http_request = require "http.request"
local cjson = require "cjson"

local M = {}

M.load = function(repo, pr)
    local url = string.format("https://api.github.com/repos/%s/pulls/%d/comments", repo, pr)
    local request = http_request.new_from_uri(url)
    request.headers:append("authorization", "token " .. os.getenv("GITHUB_TOKEN"))
    local headers, stream = assert(request:go())
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

return M
