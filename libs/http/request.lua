--- @class Request
--- @field method HttpMethod
--- @field uri string
--- @field query_params table<string, any>
--- @field headers table<string, string>
--- @field body string
local Request = {}
Request.__index = Request

local UriUtil = require('libs.http.utils.uri')
local HttpMethod = require('libs.http.method')

--- @param method HttpMethod
--- @param uri string
--- @param query_params table<string, any>
--- @param headers table<string, string>
--- @param body string
--- @return Request
function Request.new(method, uri, query_params, headers, body)
  local self = setmetatable({}, Request)
  self.method = method
  self.uri = uri
  self.query_params = query_params
  self.headers = headers
  self.body = body
  return self
end

--- @param http_response string
--- @return Request
function Request:from_http_response(http_response)
  local raw_method, uri = http_response:match('^(%w+) ([^ ]+) HTTP/1.%d')
  local method = HttpMethod.from_string(raw_method)
  local query_param_start = uri:find('?')
  local query_params = {}
  if query_param_start then
    for k, v in string.gmatch(uri:sub(query_param_start + 1), '([^&=]+)=([^&=]+)') do
      local lower_value = v:lower()
      if lower_value == 'true' then
        v = true
      elseif lower_value == 'false' then
        v = false
      end

      if lower_value == 'nil' or lower_value == 'null' then
        v = nil
      end

      local number = tonumber(v)
      if number then
        v = number
      end

      if type(v) == 'string' then
        v = UriUtil.decode(v)

        if v:match('^{') or v:match('^%[') then
          v = vim.json.decode(v)
        end
      end

      if query_params[k] then
        if type(query_params[k]) == 'table' then
          query_params[k] = vim.list_extend(query_params[k], { v })
        else
          query_params[k] = { query_params[k], v }
        end
      else
        query_params[k] = v
      end
    end

    uri = uri:sub(1, query_param_start - 1)
  end

  local split = vim.split(http_response, '\r\n\r\n')
  local header_lines = vim.split(split[1], '\r\n')
  local body = split[2]

  local headers = {}
  for _, line in ipairs(header_lines) do
    local key, value = line:match('([^:]+): (.+)')
    if key then
      headers[key] = value
    end
  end

  return Request.new(method, uri, query_params, headers, body)
end

--- @param error_is_empty boolean?
--- @return table
function Request:json(error_is_empty)
  if error_is_empty then
    local ok, result = pcall(vim.json.decode, self.body)
    if ok then
      return result
    end

    return {}
  end

  return vim.json.decode(self.body)
end

return Request
