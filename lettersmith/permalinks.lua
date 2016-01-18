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
--]]

local Plugin = require("lettersmith.plugin")
local Path = require("lettersmith.path")
local Tokens = require("lettersmith.tokens")
local Doc = require("lettersmith.doc")

local function permalinks(config)
  return mapping(function(doc)
    local path = Path.view(config.template, Doc.read_tokens(doc))
    local url = Path.to_url(path, config.site_url)
    doc = Doc.update_out(doc, path)
    doc = Doc.update_meta(doc, {
      url = url,
      site_url = site_url
    })
    return doc
  end)
end

return permalinks