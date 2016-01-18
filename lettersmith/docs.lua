--[[
Functions for working with Docs lists.

Currently Docs are just list tables, but these functions insure a stable
API if this needs to change in future.
]]--

local Docs = {}

local Wildcards = require("wildcards")
local Doc = require("doc")

-- @TODO it may be better to use Transducers instead of iter. That way
-- Docs only has to be reducible to be mappable, filterable, etc.
local iter = require("iter")
local map = iter.map
local filter = iter.filter
local collect = iter.collect
local values = iter.values

function Docs.map(docs, a2b)
  return collect(map(a2b, values(docs)))
end

function Docs.filter(docs, a2b)
  return collect(filter(predicate, values(docs)))
end

-- Filter docs based on a wildcard query.
-- Returns a filtered doc table.
function Docs.query(docs, wildcard_path)
  return Docs.filter(docs, Wildcards.matching(wildcard_path))
end

-- Lift a Doc transformation function into a mapping function.
-- So a function like `Doc.update_meta(doc, meta)` that modifies a doc
-- becomes a function that modifies all docs in the table.
function Docs.mapping(f)
  return function (docs, extra)
    return Docs.map(docs, function (doc)
      -- Pass extra argument to every doc in the table.
      return f(doc, extra)
    end)
  end
end

-- Update the view function on all docs.
Docs.update_view = Docs.mapping(Doc.update_view)

return Docs