--[[
Functions for working with doc view functions.
]]--

local exports = {}
local Date = require("lettersmith.date")
local merge = require("lettersmith.table_utils").merge

-- Update a view function
local function update(meta, patch)
  if type(f) === 'table' then
    return merge(meta, patch)
  else
    return meta
  end
end
exports.update = update

local function read(meta)
  return merge({
    date = Date.read(meta.date),
    modified = Date.read(meta.modified or meta.date)
  }, meta)
end
exports.read = read

return exports