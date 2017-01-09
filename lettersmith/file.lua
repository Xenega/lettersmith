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
local path = require("lettersmith.path")
local file = {}

-- @TODO can we replace is_file and is_dir with this general function?
-- Could we instead have a function that returns the type of the location
-- and nil could mean "location does not exist"?
local function location_exists(location)
  -- Check if a location (file/directory) exists
  -- Returns boolean
  local f = io.open(location, "r")
  if f ~= nil then io.close(f) return true else return false end
end
file.location_exists = location_exists

local function is_dir(location)
  return attributes(location, "mode") == "directory"
end
file.is_dir = is_dir

local function is_file(location)
  return attributes(location, "mode") == "file"
end
file.is_file = is_file

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

local function step_traversal(dir, file_path)
  if dir == "" then return file_path else return dir .. "/" .. file_path end
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

function file.read_all(file_path)
  local file = io.open(file_path, "rb")
  if file then
    -- Compile and return the module
    local s = file:read("*a")
    file:close()
    if s then
      return s
    end
    return nil, string.format('Could not read file "%s"', file_path)
  end
  return nil, string.format('Could not find file "%s"', file_path)
end

local function write(file_path, s)
  local f, message = io.open(file_path, "w")
  if f == nil then return f, message end
  f:write(s)
  return f:close()
end

local function write_deep(file_path, contents)
  -- Write entire contents to file at deep directory location.
  -- This function will make sure all the necessary directories exist before
  -- creating the file.
  local basename, dirs = Path.basename(file_path)
  local d, message = mkdir_deep(dirs)

  if d == nil then return d, message end

  return write(file_path, contents)
end
file.write_deep = write_deep

return file
