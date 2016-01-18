--[[
Blog plugins that provide Markdown posts and pages rendered with Mustache.
]]--

local Blog = {}

local comp = require("lettersmith.prelude").comp
local RSS = require("lettersmith.rss")
local Archive = require("lettersmith.archive")
local Permalinks = require("lettersmith.permalinks")
local Mustache = require("lettersmith.mustache")
local Markdown = require("lettersmith.markdown")

function Blog.posts(config)
  return comp(
    Mustache(config.layouts, config.includes),
    RSS(),
    Markdown(config.markdown),
    Archive {
      per_page = config.per_page,
      page_path = config.page_path
    },
    Permalinks {
      site_url = config.site_url,
      template = config.permalinks
    },
    Meta(config.defaults)
  )
end

function Blog.pages(config)
  return comp(
    Mustache(config.layouts, config.includes),
    Markdown(config.markdown),
    Permalinks {
      site_url = config.site_url,
      template = config.permalinks
    },
    Meta(config.defaults)
  )
end

return Blog