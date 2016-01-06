local exports = {}

local iter = require("iter")
local reduce = iter.reduce
local map = iter.map
local filter = iter.filter
local values = iter.values
local collect = iter.collect

local path = require("lettersmith.path_utils")
local Wildcard = require("lettersmith.wildcards")

local Doc = require("lettersmith.doc")

local file_utils = require("lettersmith.file_utils")
local location_exists = file_utils.location_exists
local write_entire_file_deep = file_utils.write_entire_file_deep
local read_entire_file = file_utils.read_entire_file
local remove_recursive = file_utils.remove_recursive
local walk_file_paths = file_utils.walk_file_paths

local headmatter = require("lettersmith.headmatter")

local function load_file(path)
  -- @fixme get rid of assert in `read_entire_file`
  -- return early with error instead
  local file_string = read_entire_file(path)

  -- Get YAML meta table and contents from headmatter parser.
  local meta, contents = headmatter.parse(file_string)
  return meta, contents
end

-- Load contents of a file as a document table.
-- Returns a new lua document table on success.
-- Throws exception on failure.
local function load_doc(path)
  -- Get YAML meta table and contents from headmatter parser. Throw out contents.
  local meta, contents = load_file(path)

  -- Since doc is a new table, go ahead and mutate it, setting contents
  -- as field.
  return {
    meta = meta,
    in_path = path,
    out_path = path
  }
end
exports.load_doc = load_doc

-- Query a directory for filepaths matching a wildcard string
local function query(wildcard_string)
  -- Get head of wildcard string
  local base_path_string = path.shift(wildcard_string)
  -- Walk files paths, returning a list table.
  local paths = walk_file_paths(base_path_string)
  -- Filter out paths that don't match.
  local matching = filter(Wildcard.matching(wildcard_string), values(paths))
  -- Map paths to docs
  local docs = map(load_doc, matching)
  return collect(docs)
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

-- Define error message strings
local error_out_path = [[
Out path must be different from in path.
You should set the out path with a plugin.
In: %s
Out: %s
]]

local error_write_file = [[
File "%s" failed to write
]]

-- Write out the contents of a single doc object to a file.
local function write_through(compile, doc)
  -- Create new file path from relative path and out path.
  assert(
    Doc.get_out(doc) ~= Doc.get_in(doc),
    string.format(error_out_path, Doc.get_out(doc), Doc.get_in(doc))
  )

  -- Load and compile contents
  local meta, contents = load_file(Doc.get_in(doc))
  local compiled = compile(contents, Doc.get_meta(doc))

  assert(
    write_entire_file_deep(Doc.get_out(doc), compiled),
    string.format(error_write_file, Doc.get_out(doc))
  )
end

-- Build files from a config object
local function build(config)
  for wildcard, rule in pairs(config) do
    local docs = rule.collate(query(wildcard))
    for i, doc in ipairs(docs) do
      write_through(rule.compile, doc)
    end
  end
end
exports.build = build

return exports
