--- @class Response
--- @field response string
--- @field status number
--- @field headers table<string, string>
--- @field content_type string
local Response = {}
Response.__index = Response

--- @param response string | table
--- @param status number?
--- @param options ({ headers?: table<string, string>, content_type?: string })?
--- @return Response
function Response.new(response, status, options)
  local self = setmetatable({}, Response)

  local headers = options and options.headers
  local content_type = options and options.content_type

  if type(response) == 'table' then
    content_type = 'application/json'
    response = vim.json.encode(response)
  end

  local part = response:sub(1, 3):lower()
  if part == '<!d' or part == '<ht' then
    content_type = 'text/html'
  end

  self.response = response
  self.status = status or 200
  self.headers = headers or {}
  self.content_type = content_type or 'text/plain'
  return self
end

--- @return string
function Response:__tostring()
  local header = ''
  for k, v in pairs(self.headers) do
    header = header .. string.format('%s: %s\r\n', k, v)
  end

  return string.format('HTTP/1.1 %d\r\nContent-Type: %s\r\nContent-Length: %d\r\n%s\r\n%s', self.status,
    self.content_type,
    string.len(self.response), header, self.response)
end

return Response
