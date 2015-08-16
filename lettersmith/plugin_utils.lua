local exports = {}

local collection = require("lettersmith.collection")
local map = collection.map
local filter = collection.filter

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

-- Lift a function into a function that maps over a list table.
local function mapping(a2b)
  return function(docs)
    return map(docs, a2b)
  end
end
exports.mapping = mapping

-- A specialized type of mapping function that runs the `doc.contents` field
-- through a function, returning a new doc object.
local function rendering(f)
  return mapping(function (doc)
    return merge(doc, {contents = f(doc.contents)})
  end)
end
exports.rendering = rendering

local function filtering(f)
  return function(docs)
    return filter(docs, f)
  end
end
exports.filtering = filtering

return exports