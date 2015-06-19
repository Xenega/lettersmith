--[[
Lettersmith Markdown
Renders markdown in contents field.
--]]
local markdown = require("discount")
local mapping = require("lettersmith.reducers").mapping
local renderer = require("lettersmith.plugin_utils").renderer

local render_markdown = mapping(renderer(markdown))

return render_markdown