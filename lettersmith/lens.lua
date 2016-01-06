--[[
A lens is a strategy for getting and updating a small piece of a data structure
within a larger data structure.

Inspired by Haskell Lens and Elm Focus libraries.
]]-- 

local exports = {}

local function step_next(prev, next)
  return next
end

-- A convenience function for creating a new lens table.
-- A lens is defined via
-- 
-- * A get function which knows how to get the child from the parent.
-- * A set function which knows how to set the child within the parent.
-- * An update function which knows how to advance the state of the child
local function create(config)
  return {
    get = config.get,
    set = config.set,
    -- Default to advancing the state directly
    update = config.update or step_next
  }
end
exports.create = create

-- Creates a update cursor function for a lens.
local function cursor(lens)
  return function (big, message)
    return lens.set(big, lens.update(lens.get(big), message))
  end
end
exports.cursor = cursor

return exports