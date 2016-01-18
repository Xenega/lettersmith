-- http://www.luarocks.org/en/Creating_a_rock
package = "Lettersmith"
version = "scm-1"
source = {
  url = "git://github.com/gordonbrander/lettersmith"
}
description = {
  summary = "A simple, flexible static site generator based on plugins",
  detailed = [[
  Lettersmith is a static site generator. It's goals are:

  - Simple: just a small library for transforming files with functions.
  - Flexible: everything is a plugin.
  - Fast: build thousands of pages in seconds or less.

  It ships with plugins for blogging, Markdown and Mustache, but can be easily
  configured to build any type of static site.
  ]],
  homepage = "https://github.com/gordonbrander/lettersmith",
  license = "MIT/X11"
}
dependencies = {
  "lua >= 5.1",
  "iter >= 0.0",
  "luafilesystem >= 1.6",
  "lustache >= 1.3",
  "yaml >= 1.1",
  "lua-discount >= 1.2"
}
build = {
  type = "builtin",
  modules = {
    ["lettersmith"] = "lettersmith.lua",

    -- Plugins
    ["lettersmith.mustache"] = "lettersmith/mustache.lua",
    ["lettersmith.permalinks"] = "lettersmith/permalinks.lua",
    ["lettersmith.drafts"] = "lettersmith/drafts.lua",
    ["lettersmith.markdown"] = "lettersmith/markdown.lua",
    ["lettersmith.meta"] = "lettersmith/meta.lua",
    ["lettersmith.rss"] = "lettersmith/rss.lua",
    ["lettersmith.archive"] = "lettersmith/archive.lua",
    ["lettersmith.format_date"] = "lettersmith/format_date.lua",

    -- Libraries
    ["lettersmith.lib"] = "lettersmith/lib.lua",
    ["lettersmith.prelude"] = "lettersmith/prelude.lua",
    ["lettersmith.cursor"] = "lettersmith/cursor.lua",
    ["lettersmith.docs"] = "lettersmith/docs.lua",
    ["lettersmith.doc"] = "lettersmith/doc.lua",
    ["lettersmith.doc.meta"] = "lettersmith/doc/meta.lua",
    ["lettersmith.doc.view"] = "lettersmith/doc/view.lua",
    ["lettersmith.headmatter"] = "lettersmith/headmatter.lua",
    ["lettersmith.path"] = "lettersmith/path.lua",
    ["lettersmith.wildcards"] = "lettersmith/wildcards.lua",
    ["lettersmith.tokens"] = "lettersmith/tokens.lua",
    ["lettersmith.file_utils"] = "lettersmith/file_utils.lua",
    ["lettersmith.table_utils"] = "lettersmith/table_utils.lua"
  }
}
