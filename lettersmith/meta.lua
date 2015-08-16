--[[
Lettersmith Meta

Add metadata to every doc object. This is useful for things like site meta.
--]]
local merge = require("lettersmith.table_utils").merge
local mapping = require("lettersmith.plugin_utils").mapping

local function use_meta(meta)
  return mapping(function (doc)
    return merge(meta, doc)
  end)
end

return use_meta