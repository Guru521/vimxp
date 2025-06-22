--- @class View
--- @field uri string
--- @field is_regex_uri boolean
--- @field on_requested table<HttpMethod, fun(request: Request, sock: uv.uv_stream_t): Response>
--- @field auto_handles_sock table<HttpMethod, boolean>
local View = {}
View.__index = View

local Response = require('libs.http.response')
local Method = require('libs.http.method')
local Page = require('libs.http.page')
local UriUtil = require('libs.http.utils.uri')

local function method_not_allowed()
  return Response.new('Method Not Allowed', 405)
end

--- @param uri string
--- @return View
function View.new(uri)
  local self = setmetatable({}, View)
  self.uri = uri
  self.on_requested = {}
  self.auto_handles_sock = {}
  return self
end

--- @param uri string
--- @param file_path string
--- @return View
function View.static_file(uri, file_path)
  return View.new(uri):with_get(function(_)
    return Page.from_file(file_path)
  end)
end

--- @param uri string
--- @param dir_path string
--- @return View[]
function View.static_directory(uri, dir_path)
  dir_path = UriUtil.with_slash(dir_path)

  local views = {}
  for _, inner in ipairs(vim.fn.readdir(dir_path)) do
    if vim.fn.isdirectory(dir_path .. inner) == 1 then
      for _, inner_view in ipairs(View.static_directory(UriUtil.with_slash(uri) .. inner .. '/', dir_path .. inner .. '/')) do
        table.insert(views, inner_view)
      end

      goto continue
    end

    table.insert(views, View.static_file(UriUtil.with_slash(uri) .. inner, dir_path .. inner))
    ::continue::
  end

  return views
end

--- @return View
function View:as_regex_uri()
  self.is_regex_uri = true
  return self
end

--- @param on_get fun(request: Request, sock: uv.uv_stream_t): Response
--- @return View
function View:with_get(on_get)
  self.on_requested[Method.GET] = on_get
  self.auto_handles_sock[Method.GET] = true
  return self
end

--- @param on_post fun(request: Request, sock: uv.uv_stream_t): Response
--- @return View
function View:with_post(on_post)
  self.on_requested[Method.POST] = on_post
  self.auto_handles_sock[Method.POST] = true
  return self
end

--- @param handles boolean
--- @return View
function View:with_get_handles_sock(handles)
  self.auto_handles_sock[Method.GET] = handles
  return self
end

--- @param handles boolean
--- @return View
function View:with_post_handles_sock(handles)
  self.auto_handles_sock[Method.POST] = handles
  return self
end

--- @param uri string
--- @return boolean
function View:uri_matches(uri)
  return uri == UriUtil.with_slash(self.uri) or self.is_regex_uri and vim.regex(self.uri):match_str(uri) ~= nil
end

--- @param request Request
--- @param sock uv.uv_stream_t
--- @return Response
function View:get_response(request, sock)
  if not self:uri_matches(request.uri) then
    error('URI does not match.')
  end

  if self.on_requested[request.method] then
    return self.on_requested[request.method](request, sock)
  end

  return method_not_allowed()
end

--- @param request Request
--- @return boolean
function View:get_auto_handles_sock(request)
  if not self:uri_matches(request.uri) then
    error('URI does not match.')
  end

  if self.auto_handles_sock[request.method] ~= nil then
    return self.auto_handles_sock[request.method]
  end

  return true
end

return View
