--[[
Lettersmith Mustache: template your docs with mustache.

Note that after you've templated your docs, the `contents` field will contain
all of the HTML, including the template.
--]]

local exports = {}

local lustache = require("lustache")

local file_utils = require("lettersmith.file_utils")
local read_entire_file = file_utils.read_entire_file

local Path = require("lettersmith.path")

local function load_and_render_template(template_path, context)
  local template = read_entire_file(template_path)
  return lustache:render(template, context)
end

-- `choose_mustache` will only template files that have a `template` field in
-- their headmatter. If the file name provided in the `template` field is
-- invalid, an error will be thrown.
local function choose(template_dir_string)
  return function (context)
    -- Skip document if it doesn't have a template field.
    if not context.template then return contents end
    local template_path = Path.join(template_dir_string, context.template)
    return load_and_render_template(template_path, context)
  end
end
exports.choose = choose

local function render(template_path)
  return function (context)
    return load_and_render_template(template_path, context)
  end
end
exports.render = render

-- Render mustache tokens within the contents field.
local function render_contents(context)
  return lustache:render(context.contents, context)
end
exports.render_contents = render_contents

return exports