-- Unix-style wildcard path queries:
--
-- `hello/*.md` matches `hello/x.md` but not `hello/y/x.md`.
-- `hello/**.md` matches `hello/x.md` and `hello/y/x.md`.
-- `hello/???.md` matches `hello/you.md`

local exports = {}

local function escape_pattern(pattern_string)
  -- Auto-escape all magic characters in a string.
  return pattern_string:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
end
exports.escape_pattern = escape_pattern

local function parse(wildcard_string)
  -- Parses a path query string into a proper Lua pattern string that can be
  -- used with find and gsub.

  -- Replace double-asterisk and single-asterisk query symbols with
  -- temporary tokens.
  local tokenized = wildcard_string
    :gsub("%*%*", "__DOUBLE_WILDCARD__")
    :gsub("%*", "__WILDCARD__")
    :gsub("%?", "__ANY_CHAR__")
  -- Then escape any magic characters.
  local escaped = escape_pattern(tokenized)
  -- Finally, replace tokens with true magic-character patterns.
  -- Double-asterisk will traverse any number of characters to make a match.
  -- single-asterisk will only traverse non-slash characters (i.e. in same dir).
  -- the ? will match any single character.
  local pattern = escaped
    :gsub("__DOUBLE_WILDCARD__", ".+")
    :gsub("__WILDCARD__", "[^/]+")
    :gsub("__ANY_CHAR__", ".")

  -- Make sure pattern matches from beginning of string.
  local bounded = "^" .. pattern

  return bounded
end
exports.parse = parse

local function is_match(s, wildcard_string)
  return s:find(wildcard_string) == 1
end
exports.is_match = is_match

return exports