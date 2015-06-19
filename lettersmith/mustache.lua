--[[
Lettersmith Mustache

Template your docs with mustache.

Usage:

    local use_mustache = require("lettersmith.mustache").use_mustache
    local lettersmith = require("lettersmith")
    local pipe = lettersmith.pipe
    local docs = lettersmith.docs

    pipe(
      docs("raw"),
      render_mustache "templates/template.mustache"
    )

Note that after you've templated your docs, the `contents` field will contain
all of the HTML, including the template.
--]]

local exports = {}

local lustache = require("lustache")

local map = require("lettersmith.transducers").map
local transformer = require("lettersmith.reducers").transformer

local merge = require("lettersmith.table_utils").merge

local file_utils = require("lettersmith.file_utils")
local read_entire_file = file_utils.read_entire_file

local path_utils = require("lettersmith.path_utils")

local function load_and_render_template(template_path_string, context)
  local template = read_entire_file(template_path_string)
  return lustache:render(template, context)
end

local function render_mustache(template_path_string)
  return transformer(map(function (doc)
    -- @TODO should also have render function for {{site_url "filename"}}
    -- that will create un-breakable permalink.
    local rendered = load_and_render_template(template_path_string, doc)
    return merge(doc, { contents = rendered })    
  end))
end
exports.render_mustache = render_mustache

-- `choose_mustache` will only template files that have a `template` field in
-- their headmatter. If the file name provided in the `template` field is
-- invalid, an error will be thrown.
local function choose_mustache(template_dir_string)
  return transformer(map(function (doc)
    -- Skip document if it doesn't have a template field.
    if not doc.template then return doc end

    local template_path_string = path_utils.join(template_dir_string, doc.template)
    local rendered = load_and_render_template(template_path_string, doc)
    return merge(doc, { contents = rendered })    
  end))
end
exports.choose_mustache = choose_mustache

return exports
