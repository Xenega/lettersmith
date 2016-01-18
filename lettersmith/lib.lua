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

local walk_file_paths = require("lettersmith.file_utils").walk_file_paths

-- Query a directory for filepaths matching a wildcard string
local function query(wildcard_string)
  -- Get head of wildcard string
  local base_path_string = path.shift(wildcard_string)
  -- Walk files paths, returning a list table.
  local paths = walk_file_paths(base_path_string)
  -- Filter out paths that don't match.
  local matching = filter(Wildcard.matching(wildcard_string), values(paths))
  -- Map paths to docs
  local docs = map(Doc.load, matching)
  return collect(docs)
end

-- Build files from a config object
local function build(config)
  for wildcard, plugin in pairs(config) do
    local docs = plugin(query(wildcard))
    for i, doc in ipairs(docs) do
      Doc.write(doc)
    end
  end
end
exports.build = build

return exports
