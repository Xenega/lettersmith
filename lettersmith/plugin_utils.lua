local exports = {}

local transducers = require("lettersmith.transducers")
local iter = transducers.iter
local into = transducers.into
local map = transducers.map
local mapcat = transducers.mapcat

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge

-- Lift a transducer into Transducer that maps each element of a 2d list using a mapping function.
-- Returns a new 2d list of mapped elements.
local function twodee(xform)
  return map(function (inner_list_table)
    return into(xform, ipairs(inner_list_table))
  end)
end

--[[
local foo = paging(function(page)
  local out = {}
  for i, doc in ipairs(page) do
    ...
  end
  return out
end)
]]--
local function paging(f)
  return function(pages_iter)
    return iter(map(f), pages_iter)
  end
end
exports.paging = paging

-- Lift a function into a function that maps over a list table.
local function mapping(f)
  return function(pages_iter)
    return iter(twodee(map(f)), pages_iter)
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
  return function(pages_iter)
    return into(twodee(filter(f)), pages_iter)
  end
end
exports.filtering = filtering

-- Lifts a function of 0 or more return values into a function that returns
-- a list table of values.
local function listing(f)
  return function (v)
    -- Pack all return values into a list table.
    return table.pack(f(v))
  end
end

-- Lift a function `x -> y` into a function that takes a list and expands it
-- using multiple return values. Returning no values is equivalent to filtering
-- that item from the list.
local function expanding(f)
  return function(pages_iter)
    return iter(twodee(mapcat(listing(f))), pages_iter)
  end
end
exports.expanding = expanding

return exports