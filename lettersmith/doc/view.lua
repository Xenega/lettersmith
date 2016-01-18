--[[
Functions for working with doc view functions.

A view is any function of shape:

  context -> string
]]--

local exports = {}

local merge = require("lettersmith.table_utils").merge

-- Compose 2 view functions together so that `view_first` is run first
-- and `view_second` is run second.
-- Returns a new view function.
local function pipe(view_first, view_second)
  return function(context)
    -- Thread contents through views
    return view_second(merge(context, {contents = view_first(context)}))
  end
end
exports.pipe = pipe

-- Update a view function
local function update(prev_f, next_f)
  if type(prev_f) === 'function' and type(next_f) === 'function' then
    return pipe(prev_f, next_f)
  else if type(next_f) === 'function' then
    return next_f
  else
    return prev_f
  end
end
exports.update = update

return exports