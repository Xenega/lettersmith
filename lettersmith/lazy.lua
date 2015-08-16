local lettersmith = require("lettersmith")
local paths = lettersmith.paths
local pipe = lettersmith.pipe
local query = lettersmith.query

local collection = require("lettersmith.collection")
local map = collection.map
local filter = collection.filter
local reducible = collection.reducible
local transformable = collection.transformable

-- A lazy alternative to reducing over tables. It implements
-- the minimum functions necessary to reduce and transform.
local Lazy = {}
Lazy.__index = Lazy

-- Create a new lazy collection with a function that will produce a value
-- given `step` and `seed`
function Lazy.new(produce)
  return setmetatable({produce = produce}, Lazy)
end

function Lazy.from(t)
  return Lazy.new(function (step, seed)
    return reduce(t, step, seed)
  end)
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

-- Route all docs matching `wildcard_string` through a list of plugins.
-- Returns a lazy sequence of docs.
local function route(wildcard_string, ...)
  return pipe(map(Lazy.from(query(wildcard_string)), load_doc), ...)
end
exports.route = route
