--- @enum HttpMethod
local HttpMethod = {
  GET = 'GET',
  POST = 'POST',
}

--- @param method string
--- @return HttpMethod
function HttpMethod.from_string(method)
  return HttpMethod[method:upper()]
end

return HttpMethod
