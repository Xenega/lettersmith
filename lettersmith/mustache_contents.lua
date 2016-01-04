--[[
Lettersmith Mustache Content: render mustache tags in the contents field.
It's a good idea to use this before the `markdown` plugin.
--]]

local lustache = require("lustache")
local Doc = require("lettersmith.doc")
local mapping = require("lettersmith.plugin_utils").mapping

local merge = require("lettersmith.table_utils").merge

-- Render mustache tokens within the contents field.
local function render_contents()
  return mapping(function (doc)
    local rendered = lustache:render(Doc.contents(doc), doc)
    return merge(doc, { contents = rendered })
  end)
end

return render_contents
