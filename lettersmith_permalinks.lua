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

    local use_permalinks = require('lettersmith.permalinks').use
    local lettersmith = require('lettersmith')

    local docs = lettersmith.docs("raw")
    docs = use_permalinks(docs, "*.html", ":yyyy/:mm/:dd/:slug")
    build(docs, "out")
--]]
local lettersmith = require("lettersmith")
local route = lettersmith.route

local table_utils = require("table_utils")
local merge = table_utils.merge
local extend = table_utils.extend

local path = require("path")

local date = require("date")

local exports = {}

local function trim_string(str)
  return str:gsub("^%s+", ""):gsub("%s+$", "")
end

local function to_slug(str)
  -- Trim string, remove characters that are not numbers, letters or _ and -.
  -- Replace spaces with dashes.
  -- For example, `to_slug("   hEY. there! ")` returns `hey-there`.
  return trim_string(str):gsub("[^%w%s-_]", ""):gsub("%s", "-"):lower()
end
exports.to_slug = to_slug

local function filter_map_table_values(t, predicate, transform)
  -- Filter and map values in t, retaining fields that return a value.
  -- Returns new table with values mapped via function `transform`.
  local out = {}
  for k, v in pairs(t) do
    if predicate(v) then out[k] = transform(v) end
  end
  return out
end

local function is_string(thing)
  return type(thing) == "string"
end

local function render_doc_permalink_from_template(doc, url_template)
  local basename, dir_path = path.basename(doc.relative_filepath)
  local extension = path.extension(basename)
  local filename = path.replace_extension(basename, "")

  -- Uses title as slug, but falls back to the filename.
  -- @TODO it would probably be better to slugify all the string meta
  -- rather than treating title as a "magic" field. However, this might not
  -- be worth the complication, since this does exactly what you want 80% of
  -- the time.
  local slug = to_slug(doc.title or filename)

  -- This gives you a way to favor filename.
  local file_slug = to_slug(filename)

  -- Parse date and capture granular year, month and day values.
  local doc_date = date(doc.date)
  local yyyy, yy, mm, dd = doc_date
    :fmt("%Y %y %m %d"):match("(%d%d%d%d) (%d%d) (%d%d) (%d%d)")

  -- Generate context object that contains only strings in doc, mapped to slugs
  local doc_context = filter_map_table_values(doc, is_string, to_slug)

  -- Merge doc context and extra template vars, favoring template vars.
  local context = extend({
    file_slug = file_slug,
    slug = slug,
    dir_path = dir_path,
    yyyy = yyyy,
    yy = yy,
    mm = mm,
    dd = dd
  }, doc_context)

  local path_string = url_template:gsub(":([%w_]+)", context)

  -- Add index file to end of path and return.
  return path_string:gsub("/$", "/index" .. extension)
end

local function use(doc_stream, path_query_string, relative_path_template)
  -- Write pretty permalinks for 
  return route(doc_stream, path_query_string, function (doc)
    local permalink = render_doc_permalink_from_template(
      doc, relative_path_template)

    return merge(doc, {
      relative_filepath = permalink
    })
  end)
end
exports.use = use

return exports