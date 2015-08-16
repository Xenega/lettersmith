local exports = {}

local transducers = require("lettersmith.transducers")
local reduce_iter = transducers.reduce
local into = transducers.into

local Poly = require("lettersmith.poly")
local poly = Poly.poly
local setter = Poly.setter

-- Define a generic reduce that knows how to reduce over plain tables.
local reduce = poly(function (self, step, seed)
  return reduce_iter(step, seed, ipairs(self))
end)
exports.reduce = reduce
exports.reducible = setter(reduce)

-- Define a generic transduce in terms of generic reduce
local function transduce(xform, x, step, seed)
  return reduce(x, xform(step), seed)
end
exports.transduce = transduce

-- Define a generic `into` function that knows how to take a table and transform
-- it using transducers, returning a new table.
local transform = poly(function(self, xform)
  return into(xform, ipairs(self))
end)
exports.transform = transform
exports.transformable = setter(transform)

local function transformer(xform_factory)
  return function (x, ...)
    return transform(x, xform_factory(...))
  end
end
exports.transformer = transformer

--[[
Create polymorphous collection transformation functions. Example use:

    t1 = {1, 2, 3}
    t2 = map(t1, square)
]]--
exports.map = transformer(transducers.map)
exports.filter = transformer(transducers.filter)
exports.reject = transformer(transducers.reject)
exports.take = transformer(transducers.take)

-- A lazy alternative to reducing over tables. It implements
-- the minimum functions necessary to reduce and transform.
local Lazy = {}
Lazy.__index = Lazy

-- Create a new lazy collection with a function that will produce a value
-- given `step` and `seed`
function Lazy.new(produce)
  return setmetatable({produce = produce}, Lazy)
end

reducible(Lazy, function (self, step, seed)
  -- Produce values
  return self.produce(step, seed)
end)

transformable(Lazy, function (self, xform)
  return Lazy.new(function (step, seed)
    return transduce(xform, self, step, seed)
  end)
end)

exports.Lazy = Lazy

return exports