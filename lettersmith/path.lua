--[[
A tiny library for working with paths. Tiny, because it is simple.

Only Unix-style paths are supported. Windows-style `\` are currently not handled.
]]--

local Path = {}

local Tokens = require("lettersmith.tokens")

-- Update a view function
function Path.update(prev_path, next_path)
  if type(next_path) === 'string' then
    return next_path
  else
    return prev_path
  end
end

function Path.remove_trailing_slash(s)
  -- Remove trailing slash from string. Will not remove slash if it is the
  -- only character in the string.
  return s:gsub('(.)%/$', '%1')
end

local function resolve_double_slashes(s)
  -- Resolution is a simple case of replacing double slashes with single.
  return s:gsub('%/%/', '/')
end

local function make_same_dir_explicit(s)
  if s == "" then return "." else return s end
end

local function resolve_dir_traversals(s)
  -- Resolves ../ and ./ directory traversals.
  -- Takes a path as string and returns resolved path string.

  -- First, resolve `../`. It needs to be handled first because `./` also
  -- matches `../`

  -- Watch for illegal traversals above root.
  -- For these cases, simply return root.
  -- /../ -> /
  if (s:find("^%/%.%.") ~= nil) then return "/" end

  -- Leading double dots should not be messed with.
  -- Replace leading dots with token so we don't accidentally replace it.
  s = s:gsub('^%.%.', "<LEADING_DOUBLE_DOT>")

  -- Elsewhere, remove double dots as well as directory above.
  s = s:gsub('[^/]+%/%.%.%/?', '')

  -- Next, resolve `./`.

  -- Remove single ./ from beginning of string
  s = s:gsub("^%.%/", "")

  -- Remove single ./ elsewhere in string
  -- Note: if we didn't do ../ subsitution earlier, this naive pattern would
  -- cause problems. Future me: don't introduce a bug by running this before
  -- ../ subsitution.
  s = s:gsub("%.%/", "")

  -- Remove single /. at end of string
  s = s:gsub("%/%.$", "")

  -- Bring back any leading double dots.
  s = s:gsub('<LEADING_DOUBLE_DOT>', "..")

  -- The patterns above can leave behind trailing slashes. Trim them.
  s = Path.remove_trailing_slash(s)

  -- If string ended up empty, return "."
  s = make_same_dir_explicit(s)

  return s
end

function Path.normalize(s)
  --[[
  /foo/bar          -> /foo/bar
  /foo/bar/         -> /foo/bar
  /foo/../          -> /
  /foo/bar/baz/./   -> /foo/bar/baz
  /foo/bar/baz/../  -> /foo/bar
  ..                -> ..
  /..               -> /
  /../../           -> /
  ]]--
  s = resolve_double_slashes(s)
  s = resolve_dir_traversals(s)
  return s
end

function Path.join(a, b)
  return Path.normalize(Path.normalize(a) .. '/' .. Path.normalize(b))
end

function Path.shift(s)
  -- Return the highest-level portion of a path (it's a split on `/`), along
  -- with the rest of the path string.
  -- If your path contains traversals, you probably want to use `Path.normalize`
  -- before passing to shift, since traversals will be considered parts of the
  -- path as well.

  -- Special case: if path starts with slash, it is a root path and slash has
  -- value. Return slash, along with rest of string.
  if s:find("^/") then return "/", s:sub(2) end

  local i, j = s:find('/')

  if i == nil then return s
  else return s:sub(1, i - 1), s:sub(j + 1) end
end

function Path.parts(s)
  -- Get all parts of path as list table.
  local head, rest = "", s
  local t = {}

  repeat
    head, rest = Path.shift(rest)
    table.insert(t, head)
  until rest == nil

  return t
end

-- Return the portion at the end of a path.
function Path.basename(path)
  -- Get all parts of path as list table.
  local head, rest = "", path

  repeat
    head, rest = Path.shift(rest)
  until rest == nil

  -- @fixme I think the way I calculate the rest of the path may be too naive.
  -- Update: it is. It doesn't take into account cases where you don't have a
  -- basename.
  return head, path:sub(0, #path - #head - 1)
end

function Path.extension(path)
  local dot_i = path:find("%.%w+$")
  if not dot_i then return "" end
  return path:sub(dot_i)
end

function Path.replace_extension(path, extension)
  return path:gsub("(%.%w+)$", extension)
end

function Path.has_any_extension(path, extensions)
  for _, extension in ipairs(extensions) do
    if Path.extension(path) == extension then return true end
  end
  return false
end

-- Remove the explicit index at the end of a url.
-- Returns URL with any index removed.
function Path.drop_explicit_index(path)
  return path:gsub("/index%.[^.]+$", "/")
end

-- Given a path and a base URL, will return a pretty URL.
-- `base_url_string` can be absolute or relative.
function Path.to_url(path, base_url)
  local normalized_path = Path.normalize(path)
  local pretty_path = Path.drop_explicit_index(normalized_path)
  -- Rebase path and return.
  return ((base_url or "") .. "/" .. pretty_path)
end

function Path.view(path_template, context)
  local path = Tokens.render(path_template, context)
  -- Add index file to end of path and return.
  return path:gsub("/$", "/index" .. context.ext)
end

return Path