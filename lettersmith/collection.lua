local exports = {}

local multimethod = require('lettersmith.multi')
local multi = multimethod.multi
local impl = multimethod.impl

local transducers = require("lettersmith.transducers")
local reduce_iter = transducers.reduce
local into = transducers.into

-- Define a generic reduce over any type
local reduce = multi(function (step, seed, x)
  if x == nil then
    return 'empty'
  else
    return type(x)
  end
end)
exports.reduce = reduce

-- Implement reduce for nil values
impl(reduce, 'empty', function (step, seed)
  return seed
end)

-- Implement reduce for single values
function reduce_value(step, seed, value)
  return step(seed, value)
end

impl(reduce, 'string', reduce_value)
impl(reduce, 'number', reduce_value)

-- Implement reduce for bare tables.
impl(reduce, 'table', function (step, seed, table)
  return reduce_iter(step, seed, ipairs(table))
end)

-- Implement reduce for functions (iterators)
impl(reduce, 'function', reduce_iter)

-- Define a polymorphic `transform` function that knows how to take a
-- transducers `xform` function and transform itself.
local transform = multi(function (xform, x)
  return type(x)
end)
exports.transform = transform

-- Implement transform for tables. Returns a transformed table.
impl(transform, 'table', function (xform, table)
  return into(xform, ipairs(table))
end)

local function step_yield_ipairs(i, v)
  coroutine.yield(i, v)
  return i + 1
end

-- Implement transform for iterators. Returns a coroutine iterator of
-- transformed values.
impl(transform, 'function', function (xform, iter, ...)
  return coroutine.wrap(function ()
    return reduce_iter(xform(step_yield_ipairs), 1, iter, ...)
  end)
end)

-- Create a coroutine iterator from a table
local function table_to_co(t)
  return coroutine.wrap(function ()
    return reduce_iter(step_yield_ipairs, 1, ipairs(t))
  end)
end
exports.table_to_co = table_to_co

local function transformer(xform_factory)
  return function (x, ...)
    return transform(xform_factory(x), ...)
  end
end
exports.transformer = transformer

--[[
Create generic collection transformation functions based on our `transform`
multimethod. Example use:

    t1 = {1, 2, 3}
    t2 = map(square, t1)
]]--
exports.map = transformer(transducers.map)
exports.filter = transformer(transducers.filter)
exports.reject = transformer(transducers.reject)
exports.take = transformer(transducers.take)
exports.take_while = transformer(transducers.take_while)

return exports