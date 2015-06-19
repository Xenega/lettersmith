local exports = {}

local transducers = require("lettersmith.transducers")
local transduce = transducers.transduce
local map = transducers.map
local collect = transducers.collect

local reducers = require("lettersmith.reducers")
local transform = reducers.transform
local concat = reducers.concat

local path = require("lettersmith.path_utils")

local compare_by_file_path_date = require("lettersmith.docs_utils").compare_by_file_path_date

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
  -- Recursively walk through file paths. Collect result in table.
  local file_paths_table = collect(walk_file_paths(base_path_string))
  -- Sort our new table in-place, comparing by date.
  table.sort(file_paths_table, compare_by_file_path_date)
  file_paths_table.base_path = base_path_string
  return file_paths_table
end
exports.paths = paths

-- Load contents of a file as a document table.
-- Returns a new lua document table on success.
-- Throws exception on failure.
local function load_doc(file_path_string)
  -- @fixme get rid of assert in `read_entire_file`
  -- return early with error instead
  local file_string = read_entire_file(file_path_string)

  -- Get YAML meta table and contents from headmatter parser.
  -- We'll use the meta table as the doc object.
  local doc, contents_string = headmatter.parse(file_string)

  -- Since doc is a new table, go ahead and mutate it, setting contents
  -- as field.
  doc.contents = contents_string

  return doc
end
exports.load_doc = load_doc

-- Docs plugin
-- Given a Lettersmith paths table (generated from `lettersmith.paths()`),
-- returns an iterator of docs read from those paths.
local function docs(base_path_string)
  -- Get sorted paths table. This also acts as a memoization step, so you can
  -- consume the Reducible below multiple times without having to walk the
  -- directory tree multiple times.
  local paths_table = paths(base_path_string)

  -- Walk directory, creating doc objects from files.
  -- Returns a coroutine iterator function good for each doc table.
  local function load_doc_from_path(file_path_string)
    local doc = load_doc(file_path_string)

    -- Remove the base path to get the relative file path.
    local relative_path_string = file_path_string:sub(#base_path_string + 1)
    doc.relative_filepath = relative_path_string

    return doc
  end

  return function (step, seed)
    return transduce(map(load_doc_from_path), step, seed, ipairs(paths_table))
  end
end
exports.docs = docs

-- Given an `out_path_string` and a list of `doc` iterators, write `contents`
-- of each doc to the `relative_filepath` inside the `out_path_string` directory.
-- Returns a tally for number of files written.
local function build(out_path_string, ...)
  local reducer = concat(...)

  -- Remove old build directory recursively.
  if location_exists(out_path_string) then
    assert(remove_recursive(out_path_string))
  end

  local function write_and_tally(number_of_files, doc)
    -- Create new file path from relative path and out path.
    local file_path = path.join(out_path_string, doc.relative_filepath)
    assert(write_entire_file_deep(file_path, doc.contents or ""))
    return number_of_files + 1
  end

  -- Consume Reducibles. Return a tally representing number
  -- of files written.
  return reducer(write_and_tally, 0)
end
exports.build = build

local function call_with(x, f)
  return f(x)
end

-- Pipe a single value through many functions. Pipe will call functions from
-- left-to-right, so the first function in the list gets called first, returning
-- a new value which gets passed to the second function, etc.
local function pipe(x, ...)
  return reduce(call_with, x, ipairs({...}))
end
exports.pipe = pipe

-- Chain many functions together. This is like a classic compose function, but
-- left-to-right, instead of RTL. We think this is easier to read in many cases.
local function chain(...)
  local f = {...}
  return function(x)
    return pipe(x, table.unpack(f))
  end
end
exports.chain = chain

-- Transparently require submodules in the lettersmith namespace.
-- Exports of the module lettersmith still have priority.
-- Convenient for client/build scripts, not intended for modules.
local function autoimport()
  local function get_import(t, k)
    t[k] = require("lettersmith." .. k)
    return m
  end

  return setmetatable(shallow_copy(exports), { __index = get_import })
end
exports.autoimport = autoimport

return exports
