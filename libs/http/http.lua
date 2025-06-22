--- @class Http
--- @field server Tcp
--- @field views View[]
local Http = {}
Http.__index = Http

local Tcp = require('libs.tcp')
local Request = require('libs.http.request')
local Response = require('libs.http.response')

--- @param sock uv.uv_stream_t
--- @param response Response
function Http.handle_response(response, sock)
  sock:write(tostring(response), function(err)
    assert(not err, err)
  end)

  sock:close()
end

--- @param host string
--- @param port number?
--- @return Http?
function Http.new(host, port)
  local self = setmetatable({}, Http)
  port = port or 0

  local server = Tcp.new(host, port, function(sock)
    sock:read_start(function(error, chunk)
      assert(not error, error)

      local request = Request:from_http_response(chunk)
      if request.uri:sub(-1) ~= '/' then
        sock:write(
          tostring(Response.new('', 301, { headers = { Location = request.uri .. '/' } })), function(err)
            assert(not err, err)
          end)
        sock:close()
        return
      end

      for _, view in ipairs(self.views) do
        if view:uri_matches(request.uri) then
          vim.defer_fn(function()
            local response = view:get_response(request, sock)
            if view:get_auto_handles_sock(request) then
              self.handle_response(response, sock)
            end
          end, 0)
          return
        end
      end

      sock:write(
        tostring(Response.new('Page Not Found', 404)), function(err)
          assert(not err, err)
        end)
      sock:close()
    end)
  end)
  if not server then
    return nil
  end

  self.server = server
  self.views = {}
  return self
end

--- @param view View
--- @return Http
function Http:with_view(view)
  table.insert(self.views, view)
  return self
end

--- @param views View[]
--- @return Http
function Http:with_views(views)
  for _, view in ipairs(views) do
    table.insert(self.views, view)
  end

  return self
end

--- @return string
function Http:get_ip()
  return self.server:get_ip()
end

--- @return number
function Http:get_port()
  return self.server:get_port()
end

function Http:close()
  self.server:close()
end

return Http
