--[[
Lettersmith Mustache: template your docs with mustache.

Note that after you've templated your docs, the `contents` field will contain
all of the HTML, including the template.
--]]

local exports = {}

local lustache = require("lustache")

local merge = require("lettersmith.table_utils").merge

local file_utils = require("lettersmith.file_utils")
local read_entire_file = file_utils.read_entire_file

local path_utils = require("lettersmith.path_utils")

local function load_and_render_template(template_path_string, meta)
  local template = read_entire_file(template_path_string)
  return lustache:render(template, meta)
end

-- `choose_mustache` will only template files that have a `template` field in
-- their headmatter. If the file name provided in the `template` field is
-- invalid, an error will be thrown.
local function choose(template_dir_string)
  return function (contents, meta)
    -- Skip document if it doesn't have a template field.
    if not meta.template then return contents end
    local template_path = path_utils.join(template_dir_string, meta.template)
    return load_and_render_template(
      template_path,
      merge(meta, {contents = contents})
    )
  end
end
exports.choose = choose

local function render(template_path)
  return function (contents, meta)
    return load_and_render_template(
      template_path,
      merge(meta, {contents = contents})
    )
  end
end
exports.render = render

-- Render mustache tokens within the contents field.
local function render_contents(contents, meta)
    return lustache:render(contents, meta)
end
exports.render_contents = render_contents

return exports