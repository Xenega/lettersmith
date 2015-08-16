--[[
Lettersmith Markdown
Renders markdown in contents field.
--]]
local markdown = require("discount")
local rendering = require("lettersmith.plugin_utils").rendering

local render_markdown = rendering(markdown)

return render_markdown