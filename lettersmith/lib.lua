local exports = {}

local iter = require("iter")
local reduce = iter.reduce
local map = iter.map
local filter = iter.filter
local values = iter.values
local collect = iter.collect

local path = require("lettersmith.path_utils")
local wildcards = require("lettersmith.wildcards")

local Doc = require("lettersmith.doc")

local file_utils = require("lettersmith.file_utils")
local location_exists = file_utils.location_exists
local write_entire_file_deep = file_utils.write_entire_file_deep
local read_entire_file = file_utils.read_entire_file
local remove_recursive = file_utils.remove_recursive
local walk_file_paths = file_utils.walk_file_paths

local shallow_copy = require("lettersmith.table_utils").shallow_copy

local headmatter = require("lettersmith.headmatter")

-- Get a sorted list of all file paths under a given `path_string`.
-- `compare` is a comparison function for `table.sort`.
-- By default, will sort file paths using `compare_by_file_path_date`.
-- Returns a Lua list table of file paths.
local function paths(base_path_string)
  -- Recursively walk through file paths.
  local file_paths_table = walk_file_paths(base_path_string)
  -- Sort our new table in-place, comparing by date.
  table.sort(file_paths_table, Doc.compare_by_file_path_date)
  return file_paths_table
end
exports.paths = paths

-- Query a directory for filepaths matching a wildcard string
local function query(wildcard_string)
  -- Get head of wildcard string
  local base_path_string = path.shift(wildcard_string)
  -- Walk files paths, then filter out all paths that don't match wildcard
  -- pattern.
  return filter(function(path)
    return wildcards.is_match(path, wildcard_string)
  end, values(paths(base_path_string)))
end

-- Load contents of a file as a document table.
-- Returns a new lua document table on success.
-- Throws exception on failure.
local function load_doc(path)
  -- @fixme get rid of assert in `read_entire_file`
  -- return early with error instead
  local file_string = read_entire_file(path)

  -- Get YAML meta table and contents from headmatter parser.
  -- We'll use the meta table as the doc object.
  local doc, contents = headmatter.parse(file_string)

  -- Since doc is a new table, go ahead and mutate it, setting contents
  -- as field.
  doc.contents = contents
  doc.path = path

  return doc
end
exports.load_doc = load_doc

-- Create an iterator of docs matching `wildcard_string`.
local function match(wildcard_string)
  return map(load_doc, query(wildcard_string))
end

local function call_with(x, f)
  return f(x)
end

-- Chain many functions together. This is like a classic compose function, but
-- composes a table of functions left-to-right, instead of RTL.
local function chain(functions)
  return function(x)
    return reduce(call_with, x, ipairs(functions))
  end
end
exports.chain = chain

-- Given a base path, returns a table of documents under that path.
local function docs(base_path_string)
  return map(load_doc, values(paths(base_path_string)))
end
exports.docs = docs

-- Write out the contents of a single doc object to a file.
local function write_doc(out_path_string, doc)
  -- Create new file path from relative path and out path.
  local file_path = path.join(out_path_string, Doc.path(doc))
  assert(write_entire_file_deep(file_path, doc.contents or ""))
end
exports.write_doc = write_doc

-- Given an `out_path_string` and a bunch of stateful iterators, write `contents`
-- of each doc to its path inside the `out_path_string` directory.
local function write(out_path_string, iters)
  -- Remove old build directory recursively.
  if location_exists(out_path_string) then
    assert(remove_recursive(out_path_string))
  end

  -- @TODO might be nice to have a `concat` function for iter
  for iter in values(iters) do
    for doc in iter do
      write_doc(out_path_string, doc)
    end
  end
end
exports.write = write

-- Load and instantiate plugin from config object.
local function load_plugin(plugin_table)
  local plugin = require(plugin_table[1])
  return plugin(plugin_table[2])
end

local function load_plugins(plugins_table)
  return chain(collect(map(load_plugin, values(plugins_table))))
end

local function load_route(route_table)
  local docs = match(route_table.match)
  local plugins_table = route_table.plugins
  if plugins_table and #plugins_table > 0 then
    local plugin = load_plugins(plugins_table)
    return plugin(docs)
  else
    return docs
  end
end

-- Build files from a config object
local function build(config)
  local out = config.out or 'out'
  local iters = collect(map(load_route, values(config.routes)))
  return write(out, iters)
end
exports.build = build

-- Load a config file and build from it
local function load_config(lua_file)
  return build_config(require(lua_file))
end
exports.load_config = load_config

return exports
