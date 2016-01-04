--[[
Lettersmith Markdown
Renders markdown in contents field.
--]]
local markdown = require("discount")
local rendering = require("lettersmith.plugin_utils").rendering

local function render_markdown()
  return rendering(markdown)
end

return render_markdown