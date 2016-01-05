local merge = require('lettersmith.table_utils').merge

local iter = require("iter")
local take = iter.take
local map = iter.map
local collect = iter.collect
local values = iter.values

local Doc = require("lettersmith.doc")

local function generate_archive(config)
  return function(next)
    local items = collect(take(config.limit or 20, map(Doc.to_teaser, next)))

    local contents = {
      items = items
    }

    return values({merge(config, {items = items})})
  end
end

return generate_archive
