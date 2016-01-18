local Yaml = require('yaml')

local Headmatter = {}

local function split(s)
  -- Split headmatter from "the rest of the content" in a string.
  -- Files may contain headmatter, but may also choose to omit it.
  -- Returns two strings, a headmatter string (which may or may not
  -- be empty) and the rest of the content string.

  local delimiter = "%-%-%-*"

  -- Look for headmatter start tag.
  local headmatter_open_start, headmatter_open_end = s:find(delimiter)

  -- If no headmatter is present, return an empty table and string
  if headmatter_open_start == nil or headmatter_open_start > 1 then
    return "", s
  end

  local headmatter_close_start, headmatter_close_end =
    s:find(delimiter, headmatter_open_end + 1)

  local headmatter =
    s:sub(headmatter_open_end + 1, headmatter_close_start - 1)

  local rest = s:sub(headmatter_close_end + 1)

  return headmatter, rest
end

function Headmatter.parse_headmatter(s)
  local headmatter, contents = split(s)
  return Yaml.load(headmatter) or {}
end

function Headmatter.parse_contents(s)
  local headmatter, contents = split(s)
  return contents
end

return Headmatter