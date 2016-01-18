--[[
A minimal set of helpers for working with dates and times.
See http://www.lua.org/pil/22.1.html.
]]--

local Date = {}

Date.epoch = os.date("%F", 0)

-- Match a `YYYY-MM-DD` date in a string.
-- Returns matched string or `nil`.
function Date.match(yyyy_mm_dd_string)
  return yyyy_mm_dd_string:match("%d%d%d%d%-%d%d%-%d%d")
end

-- Match a `YYYY-MM-DD` date in a string.
-- Returns matched string or Unix Epoch as a `yyyy-mm-dd` string.
function Date.read(s)
  if type(s) == 'string' and Date.match(s) then
    return Date.match(s)
  else
    return Date.epoch
  end
end

-- Parse a yyyy-mm-dd string to a Lua time object.
function Date.to_time(yyyy_mm_dd_string)
  -- Given a `yyyy-mm-dd` date string, return `yyyy`, `mm` and `dd`.
  local yyyy, mm, dd = yyyy_mm_dd_string:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
  return os.time({ year = yyyy, month = mm, day = dd })
end

-- Reformat a a `yyyy-mm-dd` date string. `format` is an `strftime`-style
-- formatting string and supports any format string `os.date` supports.
-- See http://www.lua.org/pil/22.1.html for more.
function Date.format(yyyy_mm_dd_string, format_string)
  return os.date(format_string, Date.to_time(yyyy_mm_dd_string))
end

function Date.compare(a, b)
  return Date.to_time(Date.read(a)) > Date.to_time(Date.read(b))
end

return Date