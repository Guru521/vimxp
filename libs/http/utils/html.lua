local HtmlUtil = {}

--- @param value string
--- @return string
function HtmlUtil.escape(value)
  return select(1, value:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'):gsub("'", '&#39;'))
end

return HtmlUtil
