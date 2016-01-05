--[[
Handy functions for working with `doc` tables.
]]--

local exports = {}

local path_utils = require("lettersmith.path_utils")

-- Read path from doc table
local function path(doc)
  return doc.path
end
exports.path = path

-- Read contents from doc table
local function contents(doc)
  return doc.contents
end
exports.contents = contents

-- Returns the title of the doc from headmatter, or the first sentence of
-- the contents.
local function derive_title(doc)
  if doc.title then
    return doc.title
  else
    -- @FIXME this is naive and is not localized.
    -- In future, would be better to be able to generate titles from
    -- contents field. But before we do that, we'll need a clever way to strip
    -- special characters like HTML and markdown. Maybe impossible?
    return "Untitled"
  end
end
exports.derive_title = derive_title

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
  local file_name = path_utils.replace_extension(path_utils.basename(file_path_string), "")
  -- Remove date if present
  return file_name:gsub("^%d%d%d%d%-%d%d%-%d%d%-?", "", 1)
end

-- Derive a pretty permalink slug from a `doc` table.
-- `derive_slug` will do its best to create something nice.
-- Returns a slug made from title, filename or contents.
local function derive_slug(doc)
  local file_name_slug = find_slug_in_file_path(path(doc))

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

-- Date helpers. See http://www.lua.org/pil/22.1.html.

-- Given a `yyyy-mm-dd` date string, return `yyyy`, `mm` and `dd` as separate
-- return values. Returns values or nil if there is no match.
local function destructure_yyyy_mm_dd(date_string)
  return date_string:match("(%d%d%d%d)%-(%d%d)%-(%d%d)")
end

local function yyyy_mm_dd_to_time(date_string)
  local yyyy, mm, dd = destructure_yyyy_mm_dd(date_string)
  return os.time({ year = yyyy, month = mm, day = dd })
end
exports.yyyy_mm_dd_to_time = yyyy_mm_dd_to_time

-- Reformat a a `yyyy-mm-dd` date string. `format` is an `strftime`-style
-- formatting string and supports any format string `os.date` supports.
-- See http://www.lua.org/pil/22.1.html for more.
local function reformat_yyyy_mm_dd(date_string, format)
  return os.date(format, yyyy_mm_dd_to_time(date_string))
end
exports.reformat_yyyy_mm_dd = reformat_yyyy_mm_dd

-- Match a `YYYY-MM-DD` date at the beginning of a string.
-- Returns matched string or `nil`.
local function match_yyyy_mm_dd(s)
  return s:match("%d%d%d%d%-%d%d%-%d%d")
end
exports.match_yyyy_mm_dd = match_yyyy_mm_dd

-- Matches a date from filenames that have the format:
--
--     YEAR-MONTH-DAY-whatever
--
-- Where YEAR is a four-digit number, MONTH and DAY are both two-digit numbers.
--
-- Returns the matched date string, or `nil`.
local function match_yyyy_mm_dd_in_file_path(file_path_string)
  return match_yyyy_mm_dd(path_utils.basename(file_path_string))
end
exports.match_yyyy_mm_dd_in_file_path = match_yyyy_mm_dd_in_file_path

local epoch_yyyy_mm_dd = os.date("%F", 0)

-- Derive a `yyyy-mm-dd` date string from a `doc` table. Will look at valid date
-- fields in headmatter, file path or fall back to Unix epoch if nothing else.
-- Returns a `YYYY-MM-DD` date string.
local function derive_date(doc)
  local headmatter_date_string = doc.date and match_yyyy_mm_dd(doc.date)
  local file_path_date_string = match_yyyy_mm_dd_in_file_path(path(doc))

  if headmatter_date_string then
    return headmatter_date_string
  elseif file_path_date_string then
    return file_path_date_string
  else
    return epoch_yyyy_mm_dd
  end
end
exports.derive_date = derive_date

-- Derive a Unix epoch-based number representing time from file path.
-- Returns unix-epoch based number representing time.
local function derive_time_from_file_path(file_path_string)
  local extracted_date = match_yyyy_mm_dd_in_file_path(file_path_string)
  if extracted_date then
    return yyyy_mm_dd_to_time(extracted_date)
  else
    -- Return epoch time as fallback.
    return 0
  end
end

-- Compare 2 file name strings by parsing out a date from the beginning of
-- the file name.
local function compare_by_file_path_date(a, b)
  return derive_time_from_file_path(a) > derive_time_from_file_path(b)
end
exports.compare_by_file_path_date = compare_by_file_path_date

-- Derive a teaser object from a doc object
local function to_teaser(doc)
  return {
    title = derive_title(doc),
    date = derive_date(doc),
    path = path(doc)
  }
end
exports.to_teaser = to_teaser

-- Read a table of url tokens from a doc table.
-- The resulting table contains useful path tokens like year, extension, etc.
local function read_tokens(doc)
  local file_path = path(doc)
  local basename, dir = path_utils.basename(file_path)
  local ext = path_utils.extension(basename)
  local file_title = path_utils.replace_extension(basename, "")

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
