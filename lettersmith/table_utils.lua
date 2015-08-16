--[[
Table utilities: the goodies you might wish were part of the standard
table library.
]]--

local exports = {}

local function extend(a, b)
  -- Set values of b on a, mutating a
  -- Returns a
  for k, v in pairs(b) do a[k] = v end
  return a
end
exports.extend = extend

local function merge(a, b)
  -- Combine keys and values of a and b in new table.
  -- b's keys will overwrite a's keys when a conflict arises.
  -- Returns new table.
  return extend(extend({}, a), b)
end
exports.merge = merge

local function shallow_copy(t)
  return extend({}, t)
end
exports.shallow_copy = shallow_copy

local function slice_table(t, from, to)
  to = to or math.huge
  from = from or 1

  local at = math.min(from - 1, 0)
  local iter = ipairs(t)
  local sliced_t = {}

  for i, v in iter, t, at do
    if i > to then return sliced_t end
    table.insert(sliced_t, v)
  end

  return sliced_t
end
exports.slice_table = slice_table

-- Partition an iterator into "chunks", returning an iterator of tables
-- containing `n` items each.
-- Returns a `Reducible` table.
local function partition(n, list_table)
  local function step_chunk(chunk, input)
    if #chunk < n then
      return append(chunk, input)
    else
      -- If chunk is full, step value
      value = step(chunk, value)
      return {input}
    end
  end
  -- Capture the last chunk, and reduce it with `step`.
  local last_chunk = reduce(step_chunk, value, ipairs(list_table))
  return step(last_chunk, value)
end
exports.partition = partition

return exports