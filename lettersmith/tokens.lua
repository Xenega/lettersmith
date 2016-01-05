--[[
Simple :token template rendering.
]]--

local exports = {}

local function render(template, context)
  return template:gsub(":([%w_]+)", context)
end
exports.render = render
