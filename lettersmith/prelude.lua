--[[
A collection of commonly useful functions.
]]--

local exports = {}

local reduce = require('iter').reduce

local function id(thing)
  return thing
end
exports.id = id

-- Compose 2 functions.
local function comp2(z, y)
  return function(x) return z(y(x)) end
end

-- Compose multiple functions of one argument into a single function of one
-- argument that will transform argument through each function, starting with
-- the last in the list.
--
-- `compose(z, y)` can be read as "z after y". Or to put it another way,
-- `z(y(x))` is equivalent to `compose(z, y)(x)`.
-- https://en.wikipedia.org/wiki/Function_composition_%28computer_science%29
-- Returns the composed function.
local function comp(z, y, ...)
  return reduce(comp2, z, ipairs{y, ...})
end
exports.comp = comp

return exports