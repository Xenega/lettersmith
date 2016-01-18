--[[
File system utilities.

A thin wrapper around `lua-file-system` and `io`, tailored to Lettersmith's
particular needs.

@TODO this should be merged with Path.
]]--

local lfs = require("lfs")
local attributes = lfs.attributes
local mkdir = lfs.mkdir
local rmdir = lfs.rmdir

local iter = require("iter")
local reductions = iter.reductions
local values = iter.values

local comp = require("lettersmith.prelude").comp

local Path = require("lettersmith.path")

local Yaml = require('yaml')
local Headmatter = require('headmatter')

local exports = {}

-- @TODO can we replace is_file and is_dir with this general function?
-- Could we instead have a function that returns the type of the location
-- and nil could mean "location does not exist"?
local function location_exists(location)
  -- Check if a location (file/directory) exists
  -- Returns boolean
  local f = io.open(location, "r")
  if f ~= nil then io.close(f) return true else return false end
end
exports.location_exists = location_exists

local function is_dir(location)
  return attributes(location, "mode") == "directory"
end
exports.is_dir = is_dir

local function is_file(location)
  return attributes(location, "mode") == "file"
end
exports.is_file = is_file

local function mkdir_if_missing(location)
  if location_exists(location) then
    return true
  else
    return mkdir(location)
  end
end

local function is_plain_location(location_chunk)
  -- Returns true if file or directory is not a traversal (.. or .), not hidden
  -- (.something)
  return location_chunk:find("^%.") == nil
end

local function children(location)
  return coroutine.wrap(function ()
    -- We use a for-loop instead of reject because lfs.dir requires the
    -- context of a userdata table it returns as a second argument.
    for sub_location in lfs.dir(location) do
      if is_plain_location(sub_location) then coroutine.yield(sub_location) end
    end
  end)
end
exports.children = children

local function step_traversal(dir, path)
  if dir == "" then return path else return dir .. "/" .. path end
end

-- Returns every iteration of a path traversal, as an iterator.
local function traversals(path_string)
  return reductions(step_traversal, "", values(Path.parts(path_string)))
end

local function mkdir_deep(path_string)
  -- Create deeply nested directory at `location`.
  -- Returns `true` on success, or `nil, message` on failure.

  for path_substring in traversals(path_string) do
    local is_success, message = mkdir_if_missing(path_substring)
    if not is_success then return is_success, message end
  end

  return true
end

local function remove_recursive(location)
  if is_dir(location) then
    for sub_location in children(location) do
      local sub_path = Path.join(location, sub_location)
      local is_success, message = remove_recursive(sub_path)
      if not is_success then return is_success, message end
    end
  end
  return os.remove(location)
end
exports.remove_recursive = remove_recursive

local function read_entire_file(path)
  -- Read entire contents of file and return as string.
  -- Will return string, or throw error if file can not be read.
  local f = assert(io.open(path, "r"))
  local contents = f:read("*all")
  f:close()
  return contents
end
exports.read_entire_file = read_entire_file

-- Read a file's contents as YAML data
local read_yaml = comp(Yaml.load, read_entire_file)
exports.read_yaml = read_yaml

local read_contents = comp(Headmatter.parse_contents, read_entire_file)
exports.read_contents = read_contents

local read_headmatter = comp(Headmatter.parse_headmatter, read_entire_file)
exports.read_headmatter = read_headmatter

local function write(path, s)
  local f, message = io.open(path, "w")

  if f == nil then return f, message end

  f:write(s)

  return f:close()
end

local function write_deep(path, contents)
  -- Write entire contents to file at deep directory location.
  -- This function will make sure all the necessary directories exist before
  -- creating the file.
  local basename, dirs = Path.basename(path)
  local d, message = mkdir_deep(dirs)

  if d == nil then return d, message end

  return write(path, contents)
end
exports.write_deep = write_deep

-- Recursively walk through directory at `path_string`, appending
-- items found to table `t`.
local function walk_file_paths_into(t, path_string)
  for f in children(path_string) do
    local filepath = Path.join(path_string, f)

    if is_file(filepath) then
      table.insert(t, filepath)
    elseif is_dir(filepath) then
      walk_file_paths_into(t, filepath)
    end
  end
  return t
end

-- Given `path_string` -- a path to a directory -- recursively walks through
-- directory for all file paths.
-- Returns a list table of paths.
local function walk_file_paths(path_string)
  return walk_file_paths_into({}, path_string)
end
exports.walk_file_paths = walk_file_paths

return exports
