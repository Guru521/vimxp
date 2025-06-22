--- @class Tcp
--- @field server uv.uv_tcp_t
local Tcp = {}
Tcp.__index = Tcp

local uv = vim.uv

--- @param host string
--- @param port number
--- @param on_connect fun(sock: uv.uv_stream_t)
--- @return Tcp?
function Tcp.new(host, port, on_connect)
  local self = setmetatable({}, Tcp)

  local server = uv.new_tcp()
  if not server then
    return nil
  end

  server:bind(host, port)
  server:listen(128, function(err)
    assert(not err, err)

    local sock = uv.new_tcp()
    assert(sock, 'Failed to create socket.')

    server:accept(sock)
    on_connect(sock)
  end)

  self.server = server
  return self
end

--- @return string
function Tcp:get_ip()
  return self.server:getsockname().ip
end

--- @return number
function Tcp:get_port()
  return self.server:getsockname().port
end

function Tcp:close()
  if self.server and not self.server:is_closing() then
    self.server:close()
  end
end

return Tcp
