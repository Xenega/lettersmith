local exports = {}

-- Simple type-based dispatch on first argument.
-- `default` provides a default implementation for plain tables.
local function poly(default)
  local function method(self, ...)
    -- If the `method` function is used as a key on the table to store a
    -- function, then we consider that to be a specialized method.
    if type(self[method]) == "function" then
      return self[method](self, ...)
    else
      return default(self, ...)
    end
  end
  return method
end
exports.poly = poly

-- Create a setter functions that will set `v` on table `t` at key `k`.
-- Useful for creating convenient decorator functions for poly functions.
local function setter(k)
  return function(t, v)
    t[k] = v
    return t
  end
end
exports.setter = setter

return exports