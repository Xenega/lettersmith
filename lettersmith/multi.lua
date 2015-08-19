-- Multiple dispatch at runtime. Inspired by http://clojure.org/multimethods.

local exports = {}

local function dispatch(self, ...)
  -- Generate a key using `gen_key` function we've stored at `dispatch`.
  local key = self[dispatch](...)
  -- If we have a function at key, call it.
  if self[key] then
    return self[key](...)
  else
    error("No multimethod implementation for key: " .. key)
  end
end

-- Create a new multimethod. A multimethod is a callable object.
-- Gen key is passed the calling arguments and produces a key. That key is then
-- used to pick a method. See `dispatch` for implementation.
-- Returns a callable object.
local function multi(gen_key)
  local multi = {[dispatch] = gen_key}
  return setmetatable(multi, {__call = dispatch})
end
exports.multi = multi

-- Implement a multimethod for a given key
local function impl(mf, key, f)
  mf[key] = f
  return mf
end
exports.impl = impl

return exports