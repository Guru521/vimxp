local Page = {}
Page.__index = Page

local Response = require('libs.http.response')
local HttpUtil = require('libs.http.utils.html')

--- @param path string
--- @param context table<string, any>?
--- @param status number?
--- @return Response
function Page.from_file(path, context, status)
  context = context or {}
  status = status or 200

  local file = io.open(path, 'r')
  if not file then
    vim.defer_fn(function()
      error('File not found: ' .. path)
    end, 0)
    return Response.new('Internal Server Error', 500)
  end

  local mes = file:read('*a')
  for key, value in pairs(context) do
    local escaped = HttpUtil.escape(tostring(value))
    mes = mes:gsub(string.format('{{%s}}', key), escaped)
  end

  return Response.new(mes, status)
end

return Page
