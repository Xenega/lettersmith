--[[
A cursor is a strategy for getting and updating a small piece of a data structure
within a larger data structure.

Inspired by Haskell Lens and Elm Focus libraries.
]]-- 

local function update_next(prev, next)
  return next
end

-- Creates a update cursor function for a lens.
-- A lens is defined as a table with
-- 
-- * A get function which knows how to get the child from the parent.
-- * A set function which knows how to set the child within the parent.
-- * An update function which knows how to advance the state of the child
local function cursor(lens)
  local update = lens.update or update_next
  return function (big, message)
    return lens.set(big, update(lens.get(big), message))
  end
end

return cursor