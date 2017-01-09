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

  - Simple
  - Flexible: everything is a plugin.
  - Fast: build thousands of pages in seconds or less.
  - Embeddable: we're going to put this thing in an Mac app so normal people
    can use it.

  It ships with plugins for blogging, Markdown and Mustache, but can be easily
  configured to build any type of static site.
  ]],
  homepage = "https://github.com/gordonbrander/lettersmith",
  license = "MIT/X11"
}
dependencies = {
  "lua >= 5.1",
  "luafilesystem >= 1.6",
  "lustache >= 1.3",
  "lyaml >= 6.1",
  "lua-discount >= 1.2",
  "lualit",
  "lua-cjson-ol"
}
build = {
  type = "builtin",
  modules = {
    ["lettersmith"] = "lettersmith.lua",

    -- Libraries
    ["lettersmith.doc"] = "lettersmith/doc.lua",
    ["lettersmith.headmatter"] = "lettersmith/headmatter.lua",
    ["lettersmith.file"] = "lettersmith/file.lua",
  }
}
