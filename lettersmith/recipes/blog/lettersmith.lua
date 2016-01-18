local lettersmith = require("lettersmith")
local comp = require("lettersmith.prelude").comp
local File = require("lettersmith.file_utils")
local Blog = require("lettersmith.blog")
local Meta = require("lettersmith.meta")

-- Load config from YAML file
local config = File.read_yaml('_config.yml')

-- Load docs
local posts = lettersmith.load('_posts')
local pages = lettersmith.load('_pages')

-- Create plugins by composing smaller plugins
local Posts = Blog.posts {
  layouts = config.layouts,
  includes = config.includes,
  permalinks = (config.permalinks or ':yyyy/:mm/:dd/:slug/'),
  per_page = config.per_page,
  -- Using Jekyll's "paginate_path" keyname
  page_path = config.paginate_path,
  defaults = config.defaults
}

local Pages = Blog.pages {
  layouts = config.layouts,
  includes = config.includes,
  permalinks = (config.permalinks or ':slug/'),
  defaults = config.defaults
}

-- Process docs with plugins and combine them into one table
local all = table.concat(
  Posts(posts),
  Pages(pages)
)

-- lettersmith.compile {
--   ['_posts/*.md'] = Posts,
--   ['_pages/*.md'] = Pages
-- }

-- Build the website
lettersmith.build(all)
