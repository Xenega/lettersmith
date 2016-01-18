--[[
Handy functions for working with `doc` tables.
]]--

local exports = {}

local Date = require("lettersmith.path_utils")
local Path = require("lettersmith.path_utils")
local Meta = require("lettersmith.doc.meta")
local View = require("lettersmith.doc.view")
local cursor = require("lettersmith.cursor")
local merge = require("lettersmith.table_utils").merge
local File = require("lettersmith.file_utils")

local function get_meta(doc)
  return doc.meta
end

local function set_meta(doc, meta)
  return merge(doc, {meta = meta})
end

-- @TODO add a proper compose function
local function read_meta(doc)
  return Meta.read(get_meta(doc))
end
exports.read_meta = read_meta

local update_meta = cursor({
  get = get_meta,
  set = set_meta,
  update = Meta.update
})
exports.update_meta = update_meta

local function read_out(doc)
  return doc.out_path
end
exports.read_out = read_out

local function set_out(doc, out_path)
  return merge(doc, {out_path = out_path})
end

local update_out = cursor({
  get = read_out,
  set = set_out,
  update = Path.update
})
exports.update_out = update_out

local function read_in(doc)
  return doc.in_path
end
exports.read_in = read_in

local function read_view(doc)
  return doc.view
end

local function set_view(doc, view)
  return merge(doc, {view = view})
end

local update_view = cursor({
  get = read_view,
  set = set_view,
  update = View.update
})
exports.update_view = update_view

-- Load the contents of the doc file, if the doc has an in_path.
local function read_contents(doc)
    -- Load and compile contents
  local in_path = read_in(doc)
  if in_path then
    return File.load_contents(in_path)
  else
    return ""
  end
end

-- Read full template context for rendering
local function read_context(doc)
  return merge(read_meta(doc), {
    contents = read_contents(doc)
  })
end

local function init(in_path, out_path, meta, view)
  return {
    in_path = Path.update(nil, in_path),
    out_path = Path.update(nil, out_path),
    meta = Meta.update({}, meta),
    view = View.update(nil, view)
  }
end
exports.init = init

-- Load contents of a file as a document table.
-- Returns a new lua document table on success.
-- Throws exception on failure.
local function load(path)
  return Doc.init(path, path, File.read_headmatter(path))
end
exports.load = load

-- Define error message strings
local error_same_out = [[
Out path must be different from in path.
You should set the out path with a plugin.
In: %s
Out: %s
]]

local error_out_missing = [[
Doc must have out_path to write.
]]

local error_write_failed = [[
File "%s" failed to write
]]

-- Write out the contents of a single doc object to a file.
local function write(doc)
  local out_path = read_out(doc)
  local in_path = read_in(doc)

  assert(out_path, error_out_missing)

  -- Create new file path from relative path and out path.
  assert(
    out_path ~= in_path,
    string.format(error_same_out, out_path, in_path)
  )

  local view = read_view(doc)

  assert(
    File.write_deep(out_path, view(read_context(doc)),
    string.format(error_write_failed, out_path)
  )
end
exports.write = write

local function trim_string(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

-- Trim string, remove characters that are not numbers, letters or _ and -.
-- Replace spaces with dashes.
-- For example, `to_slug("   hEY. there! ")` returns `hey-there`.
local function to_slug(s)
  return trim_string(s):gsub("[^%w%s-_]", ""):gsub("%s", "-"):lower()
end
exports.to_slug = to_slug

local function find_slug_in_file_path(file_path_string)
  local file_name = Path.replace_extension(Path.basename(file_path_string), "")
  -- Remove date if present
  return file_name:gsub("^%d%d%d%d%-%d%d%-%d%d%-?", "", 1)
end

-- Derive a pretty permalink slug from a `doc` table.
-- `derive_slug` will do its best to create something nice.
-- Returns a slug made from title, filename or contents.
local function derive_slug(doc)
  local file_name_slug = find_slug_in_file_path(read_out(doc))

  -- Prefer title if present.
  if doc.title then
    return to_slug(doc.title)
  -- Fall back to slug derived from file name.
  elseif #file_name_slug > 0 then
    -- Make really sure it is slug-friendly.
    return to_slug(file_name_slug)
  else
    -- Otherwise, derive title and slugify it.
    -- @TODO decide if we should limit this.
    return to_slug(derive_title(doc))
  end
end
exports.derive_slug = derive_slug

-- Matches a date from file names that have the format:
--
--     YEAR-MONTH-DAY-whatever
--
-- Where YEAR is a four-digit number, MONTH and DAY are both two-digit numbers.
--
-- Returns the matched date string, or `nil`.
local function match_yyyy_mm_dd_in_file_name(path)
  return Date.match_yyyy_mm_dd(Path.basename(path))
end

-- Derive a `yyyy-mm-dd` date string from a `doc` table. Will look at valid date
-- fields in headmatter, file path or fall back to Unix epoch if nothing else.
-- Returns a `YYYY-MM-DD` date string.
local function read_date(doc)
  local meta = get_meta(doc)
  local path_date = match_yyyy_mm_dd_in_file_name(read_out(doc))

  if type(meta.modified) == 'string' then
    return Date.read(meta.modified)
  elseif type(meta.date) == 'string' then
    return Date.read(meta.date)
  elseif path_date then
    return Date.read(path_date)
  else
    return Date.epoch
  end
end
exports.read_date = read_date

-- Compare 2 file name strings by parsing out a date from the beginning of
-- the file name.
local function compare_by_date(doc_a, doc_b)
  return Date.compare(read_date(doc_a), read_date(doc_b))
end
exports.compare_by_date = compare_by_date

-- Read a table of url tokens from a doc table.
-- The resulting table contains useful path tokens like year, extension, etc.
local function read_tokens(doc)
  local file_path = read_out(doc)
  local basename, dir = Path.basename(file_path)
  local ext = Path.extension(basename)
  local file_title = Path.replace_extension(basename, "")

  -- Uses title as slug, but falls back to the file name, sans extension.
  local slug = derive_slug(doc)

  -- This gives you a way to favor file_name.
  local file_slug = to_slug(file_title)

  local yyyy, yy, mm, dd = reformat_yyyy_mm_dd(derive_date(doc), "%Y %y %m %d")
    :match("(%d%d%d%d) (%d%d) (%d%d) (%d%d)")

  return {
    basename = basename,
    dir = dir,
    path = file_path,
    file_slug = file_slug,
    slug = slug,
    ext = ext,
    yyyy = yyyy,
    yy = yy,
    mm = mm,
    dd = dd
  }
end
exports.read_tokens = read_tokens

return exports
