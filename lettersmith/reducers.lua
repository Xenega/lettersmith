-- Ordinary reduce is a function of shape:
--
--    (step, seed, table) -> value
--
-- A reducer is similar... it is a function of shape:
--
--    (step, seed) -> value
--
-- Similar to reduce, it produces a value from a stepping function and a seed.
-- Unlike reduce, it does not take a collection: it contains its own state and
-- knows how to produce values by itself. This means it is free to generate
-- values in any way it likes.
--
-- You can use this library with `transducers` to transform reduction.
-- These functions transform lazily, so no intermediate collections are created
-- for transformations. This is can be crazy fast for large collections.
--
-- No actual work is done until you call the reducible function:
--
--     result = reducible(step, seed)
local exports = {}

local transducers = require("lettersmith.transducers")
local reduce = transducers.reduce
local map = transducers.map
local filter = transducers.filter
local append = transducers.append

-- Create a reducible function from an iterator.
local function from_iter(iter, state, at)
  return function(step, seed)
    return reduce(step, seed, iter, state, at)
  end
end
exports.from_iter = from_iter

-- Create a reducible function from a table.
local function from_table(t)
  return from_iter(ipairs(t))
end
exports.from_table = from_table

-- Collect a reducer function's values into a table.
-- Note that reducer functions can yield an infinite series of values,
-- so be smart!
-- Returns a table.
local function collect(reducer)
  return reducer(append, {})
end
exports.collect = collect

local function step_and_yield(_, v)
  coroutine.yield(v)
end

-- Create a coroutine iterator from a reducible function.
local function to_iter(reducible)
  return coroutine.wrap(function () reduce(step_and_yield, reducible) end)
end
exports.to_iter = to_iter

-- Wrap single value in a reducer function.
local function wrap(x)
  return function(step, seed)
    return step(x, seed)
  end
end
exports.wrap = wrap

-- Transform a reducible function using a transducer `xform` function.
-- Returns transformed reducible function.
local function transform(xform, reducible)
  return function(step, seed)
    return reducible(xform(step), seed)
  end
end
exports.transform = transform

-- Given a transducers `xform` function, will create a function that takes a
-- reducible and returns a transformed reducible.
local function transformer(xform)
  return function(reducible)
    return transform(xform, reducible)
  end
end
exports.transformer = transformer

local function transforming(xform_factory)
  return function(...)
    return transformer(xform_factory(...))
  end
end

-- Define special case transformers for typical things like mapping each value.

-- `mapping(a2b)` will return a plugin function that will map each item in the
-- list using `a2b`.
local mapping = transforming(map)
exports.mapping = mapping

-- `filtering(predicate)` will return a plugin function that will filter values
-- in the reducible that don't pass `predicate`.
local filtering = transforming(filter)
exports.filtering = filtering

-- Concatenate many reducibles together.
-- Returns new Reducible.
local function concat(...)
  local reducibles = {...}
  -- Wrap result in a new Reducible.
  return function (step, seed)
    -- Reduce the list of `Reducibles`.
    return reduce(function (seed, reducible)
      -- Reduce the `Reducible` to it's value using `step`.
      -- Return that value to be accumulated with next `Reducible`.
      return reducible(step, seed)
    end, seed, ipairs(reducibles))
  end
end
exports.concat = concat

-- Partition an iterator into "chunks", returning an iterator of tables
-- containing `n` items each.
-- Returns a `Reducible` table.
local function partition(reducible, n)
  return function(step, seed)
    local function step_chunk(chunk, input)
      if #chunk < n then
        return append(chunk, input)
      else
        -- If chunk is full, step seed
        seed = step(chunk, seed)
        return {input}
      end
    end
    -- Capture the last chunk, and reduce it with `step`.
    local last_chunk = reducible(step_chunk, seed)
    return step(last_chunk, seed)
  end
end
exports.partition = partition

-- Delay all items in an iterable by one step.
--
-- This is useful if you need to mutate left and right items in an iterator
-- with reduce. By using `delay` you can make sure no one sees the mutation
-- happen.
local function delay(reducible)
  return function (step, seed)
    local function step_delay(prev, curr)
      -- Skip step if the previous value is nil.
      if prev then
        seed = step(prev, seed)
      end
      return curr
    end
    local last = reducible(step_delay, delay)
    return step(last, seed)
  end
end
exports.delay = delay

return exports