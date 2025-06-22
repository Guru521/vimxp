local Wait = {}

--- @param time number
--- @param condition fun(): boolean
--- @param callback fun(boolean)
--- @param interval number?
function Wait.until_non_blocking(time, condition, callback, interval)
  condition = condition or function() return false end
  interval = interval or 200

  local elapsed = 0
  local function wait()
    if condition() then
      callback(true)
      return
    end

    if elapsed < time then
      elapsed = elapsed + interval
      vim.defer_fn(wait, interval)
    else
      callback(false)
    end
  end
  wait()
end

--- @param time number
--- @param callback fun(boolean)
--- @param interval number?
function Wait.non_blocking(time, callback, interval)
  Wait.until_non_blocking(time, function() return false end, callback, interval)
end

return Wait
