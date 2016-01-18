--[[
Lettersmith Markdown
Renders markdown in contents field.
--]]
local markdown = require("discount")
local Docs = require("lettersmith.docs")

local function render_markdown(docs, config)
  return Docs.update_view(docs, function (doc)
    return markdown(context.contents, config)
  end)
end

return render_markdown