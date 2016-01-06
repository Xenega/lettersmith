local exports = {}

local iter = require("iter")
local map = iter.map
local filter = iter.filter
local collect = iter.collect
local values = iter.values

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

-- Lift a function into a function that maps over a list table.
local function mapping(a2b)
  return function(docs)
    return collect(map(a2b, values(docs)))
  end
end
exports.mapping = mapping

local function filtering(predicate)
  return function(docs)
    return collect(filter(predicate, values(docs)))
  end
end
exports.filtering = filtering

return exports