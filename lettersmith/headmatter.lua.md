# headmatter

Tools for parsing headmatter.

    local yaml = require('lyaml')
    local headmatter = {}

Split headmatter from "the rest of the content" in a string.
Files may contain headmatter, but may also choose to omit it.
Returns two strings, a headmatter string (which may or may not
be empty) and the rest of the content string.

    function headmatter.split(str)
      local delimiter = "%-+\n"
      -- Look for headmatter start tag.
      local headmatter_open_start, headmatter_open_end = str:find(delimiter)

      -- If no headmatter is present, return an empty table and string
      if headmatter_open_start == nil or headmatter_open_start > 1 then
        return "", str
      end

      local headmatter_close_start, headmatter_close_end =
        str:find(delimiter, headmatter_open_end + 1)

      local headmatter_chunk =
        str:sub(headmatter_open_end + 1, headmatter_close_start - 1)

      local rest = str:sub(headmatter_close_end + 1)
      return headmatter_chunk, rest
    end

Split out headmatter from "the rest of the content" and parse into
Lua table using YAML.
If headmatter is not legit YAML, an error will be thrown.
Returns table, string (parsed head matter, content)

    function headmatter.parse(s)
      local headmatter_chunk, rest = headmatter.split(s)
      local head = yaml.load(headmatter_chunk) or {}
      return head, rest
    end

    return headmatter
