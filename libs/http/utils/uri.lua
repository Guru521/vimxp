local UriUtil = {}

--- @param uri string
--- @return string
function UriUtil.encode(uri)
  return select(1, uri:gsub('([^A-Za-z0-9])', function(c)
    return string.format('%%%02X', string.byte(c))
  end))
end

--- @param uri string
--- @return string
function UriUtil.decode(uri)
  return select(1, uri:gsub('%%(%x%x)', function(hex)
    return string.char(tonumber(hex, 16))
  end))
end

--- @param uri string
--- @return string
function UriUtil.with_slash(uri)
  return uri:sub(-1) == '/' and uri or uri .. '/'
end

return UriUtil
