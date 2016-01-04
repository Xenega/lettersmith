--[[
Lettersmith format_date

Create a formatted date in doc tables, useful when rendering templates.

Usage:

    local format_date = require("lettersmith.format_date")
    ...
    local date_plugin = format_date "%F"
    date_plugin(docs)

--]]

local docs = require("lettersmith.doc")
local derive_date = docs.derive_date
local reformat_yyyy_mm_dd = docs.reformat_yyyy_mm_dd
local mapping = require("lettersmith.plugin_utils")
local merge = require("lettersmith.table_utils").merge

-- Date formatting plugin.
-- `format_string` is an `strftime`-style date formatting string, and supports
-- anything `os.date` supports.
local function format_date(format_string)
  return mapping(function(doc)
    -- Derive date from doc headmatter or file name, then format it.
    local formatted_date = reformat_yyyy_mm_dd(derive_date(doc), format_string)
    -- Merge into doc, returning new table.
    return merge(doc, { formatted_date = formatted_date })
  end)
end

return format_date
