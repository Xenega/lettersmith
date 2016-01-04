-- Given a doc list, will generate an RSS feed file.
-- Can be used as a plugin, or as a helper for a theme plugin.

local iter = require("iter")
local take = iter.take
local map = iter.map
local collect = iter.collect
local values = iter.values

local lustache = require("lustache")

local path_utils = require("lettersmith.path_utils")

local docs = require("lettersmith.doc")
local derive_date = docs.derive_date
local reformat_yyyy_mm_dd = docs.reformat_yyyy_mm_dd

-- Note that escaping the description is uneccesary because Mustache escapes
-- by default!
local rss_template_string = [[
<rss version="2.0">
<channel>
  <title>{{site_title}}</title>
  <link>{{{site_url}}}</link>
  <description>{{site_description}}</description>
  <generator>Lettersmith</generator>
  {{#items}}
  <item>
    {{#title}}
    <title>{{title}}</title>
    {{/title}}
    <link>{{{url}}}</link>
    <description>{{contents}}></description>
    <pubDate>{{pubdate}}</pubDate>
    {{#author}}
    <author>{{author}}</author>
    {{/author}}
  </item>
  {{/items}}
</channel>
</rss>
]]

local function render_feed(context_table)
  -- Given table with feed data, render feed string.
  -- Returns rendered string.
  return lustache:render(rss_template_string, context_table)
end

local function to_rss_item_from_doc(doc, root_url_string)
  local title = doc.title
  local contents = doc.contents
  local author = doc.author

  -- Reformat doc date as RFC 1123, per RSS spec
  -- http://tools.ietf.org/html/rfc1123.html
  local pubdate =
    reformat_yyyy_mm_dd(derive_date(doc), "!%a, %d %b %Y %H:%M:%S GMT")

  -- Create absolute url from root URL and relative path.
  local url = path_utils.join(root_url_string, doc.relative_filepath)
  local pretty_url = url:gsub("/index%.html$", "/")

  -- The RSS template doesn't really change, so no need to get fancy.
  -- Return just the properties we need for the RSS template.
  return {
    title = title,
    url = pretty_url,
    contents = contents,
    pubdate = pubdate,
    author = author
  }
end

local function generate_rss(config)
  local function to_rss_item(doc)
    return to_rss_item_from_doc(doc, config.site_url)
  end

  return function(next)
    local items = collect(take(20, map(to_rss_item, next)))

    local contents = render_feed({
      site_url = config.site_url,
      site_title = config.site_title,
      site_description = config.site_description,
      items = items
    })

    local feed_date
    if #items > 0 then
      feed_date = items[1].date
    else
      feed_date = os.date("!%a, %d %b %Y %H:%M:%S GMT", os.time())
    end

    local rss_doc = {
      -- Set date of feed to most recent document date.
      date = feed_date,
      contents = contents,
      relative_filepath = config.path
    }

    return values({rss_doc})
  end
end

return generate_rss
