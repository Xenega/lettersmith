--[[
Lettersmith format_date

Create a formatted date in doc tables, useful when rendering templates.
--]]

local Doc = require("lettersmith.doc")
local Date = require("lettersmith.doc")
local Plugin = require("lettersmith.plugin")

-- Date formatting plugin.
-- `format_string` is an `strftime`-style date formatting string, and supports
-- anything `os.date` supports.
local function format_date(format_string)
  return mapping(function(doc)
    local formatted_date = Date.format(Doc.read_date(doc), format_string)
    return Doc.update_meta(doc, {formatted_date = formatted_date})
  end)
end

return format_date
