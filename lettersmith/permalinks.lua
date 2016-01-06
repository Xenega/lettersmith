--[[
Lettersmith permalinks

Pretty URLs for your generated files. URL templates are written as strings
with special tokens:

- `:yyyy` the 4-digit year (e.g. 2014)
- `:yy` 2-digit year
- `:mm` 2-digit month
- `:dd` 2-digit day
- `:slug` a pretty version of the `title` field (if present) or the file name.
- `:file_slug` a pretty version of the file name
- `:path` the directory path of the file
- In addition, you may use any string field in the YAML meta by referencing
  it's key name preceded by `:`. So, if you wanted to use the `category` field
  you could write `:category`.

For example, this template:

    :yyyy/:mm/:dd/:slug/

...would result in a permalink like this:

    2014/10/19/example/

Usage:

    local use_permalinks = require('lettersmith.permalinks').use_permalinks
    local lettersmith = require('lettersmith')

    lettersmith.generate("raw", "out", use_permalinks {
      query = "*.html",
      template = ":yyyy/:mm/:slug"
    })
--]]
local exports = {}

local mapping = require("lettersmith.plugin_utils").mapping

local table_utils = require("lettersmith.table_utils")
local merge = table_utils.merge
local extend = table_utils.extend

local path_utils = require("lettersmith.path_utils")
local tokens = require("lettersmith.tokens")

local Doc = require("lettersmith.doc")

local function render_doc_path_from_template(doc, url_template)
  local doc_tokens = Doc.read_tokens(doc)
  local path_string = tokens.render(url_template, doc_tokens)
  -- Add index file to end of path and return.
  return path_string:gsub("/$", "/index" .. doc_tokens.ext)
end

-- Remove "index" from end of URL.
local function make_pretty_url(root_url_string, relative_path_string)
  local path_string = path_utils.join(root_url_string, relative_path_string)
  return path_string:gsub("/index%.[^.]*$", "/")
end

local function render(template_string, root_url_string)
  return mapping(function(doc)
    local path = render_doc_path_from_template(doc, template_string)
    local url = make_pretty_url(root_url_string or "/", path)
    return Doc.update_out(doc, path)
  end)
end
exports.render = render

return exports