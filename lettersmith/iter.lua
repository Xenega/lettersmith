--[[
Transform iterator functions using familiar `map`, `filter`, `reduce`, etc.

Can transform any stateful iterator function.
]]--

local exports = {}

-- Iterate over the values of a table.
-- Returns a stateful iterator function.
local function values(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end
exports.values = values

local function stateful(next, state, at)
  local v
  return function()
    at, v = next(state, at)
    return v
  end
end

-- Filter a stateful `next` iterator function, returning a new `next` function
-- for the items that pass `predicate` function.
local function filter(predicate, next)
  return function()
    for v in next do
      if predicate(v) then return v end
    end
  end
end
exports.filter = filter

local function remove(predicate, next)
  return function()
    for v in next do
      if not predicate(v) then return v end
    end
  end
end
exports.remove = remove

-- Map a non-nil value through function `a2b`.
-- Returns value or nil.
local function map_value(a2b, v)
  if v then return a2b(v) end
end
exports.map_value = map_value

local function map(a2b, next)
  return function()
    return map_value(a2b, next())
  end
end
exports.map = map

local function reductions(step, result, next)
  return function()
    for v in next do
      result = step(result, v)
      return result
    end
  end
end
exports.reductions = reductions

local function take(n, next)
  return function()
    n = n - 1
    if n > 0 then return next() end
  end
end
exports.take = take

local function skip(n, next)
  return function()
    for v in next do
      n = n - 1
      if n < 1 then return v end
    end
  end
end
exports.skip = skip

local function value(x, y)
  if x and y then return y else return x end
end

local function reduce(step, result, next, ...)
  for i, v in next, ... do
    result = step(result, value(i, v))
  end
  return result
end
exports.reduce = reduce

local function append(t, v)
  table.insert(t, v)
  return t
end

local function collect(next, ...)
  return reduce(append, {}, next, ...)
end
exports.collect = collect

return exports