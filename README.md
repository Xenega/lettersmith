Lettersmith
===========

Lettersmith is a simple, flexible, fast  _static site generator_. It's written in [Lua](http://lua.org).

Lettersmith's goals are:

- Simple
- Flexible: everything is a plugin, and plugins are just functions.
- Fast: build thousands of pages in seconds or less.

Lettersmith is open-source and a work-in-progress. [You can help](https://github.com/gordonbrander/lettersmith/issues).


What does it do?
----------------

Lettersmith is based on a simple idea: load files as Lua tables. Let's say we have a markdown file called `2015-03-01-example.md`:

```markdown
---
title: Trying out Lettersmith
---
Let's add some content to this file.
```

Lettersmith turns it into this:

```lua
{
  path = "2015-03-01-example.md",
  title = "Trying out Lettersmith",
  contents = "Let's add some content to this file.",
  date = "2015-03-01"
}
```

- The file contents will end up in the `contents` field.
- You can add an optional [YAML](yaml.org) headmatter block to files. Any YAML properties you put in the block will show up on the table.
- Date will be inferred from file name, but you can provide your own by adding a `date` field to the headmatter.

The function `lettersmith.docs(directory)` returns a list of of document tables:

```lua
{
  {
    path = "2015-03-01-example.md",
    title = "Trying out Lettersmith",
    contents = "Let's add some content to this file.",
    date = "2015-03-01"
  }
  ...
}
```

Creating a site
---------------

Creating a site is simple. Just create a new lua file. Call it anything you like.

Transformation of docs is done with plugins. Plugins are just functions that transform the list of document tables.

```lua
-- Import lettersmith and a Markdown plugin
local lettersmith = require("lettersmith")
local markdown = require("lettersmith.markdown")

-- Render markdown
local docs = lettersmith.docs(paths)
docs = markdown(docs)

-- Build files, writing them to "www" folder
lettersmith.build("www", docs)
```

That's it! No fancy classes or complex conventions. Just a convenient library for transforming files with functions.

What if you want to combine a series of plugins? Lettersmith has a function
called `route` that can be used to grab a collection of files and transform it
through a pipeline of plugin functions:

```lua
-- ...
local posts = lettersmith.route(
  'posts/*.md',
  markdown,
  mustache "templates/post.html"
)

local pages = lettersmith.route(
  'pages/*.md',
  markdown,
  mustache "templates/page.html"
)

lettersmith.build('www', posts, pages)
```


Plugins
-------

In Lettersmith, everything is a plugin. This makes Lettersmith small, simple and easy to extend.

Lettersmith comes with a few useful plugins out of the box:

* Write [Markdown](http://daringfireball.net/projects/markdown/) with [lettersmith.markdown](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_markdown.lua)
* Use Mustache templates with [lettersmith.mustache](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_mustache.lua)
* Generate pretty permalinks with [lettersmith.permalinks](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_permalinks.lua)
* Add site metadata with [lettersmith.meta](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_meta.lua)
* Hide drafts with [lettersmith.drafts](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_drafts.lua)
* Generate automatic RSS feeds with [lettersmith.rss](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_rss.lua)

<!--
Pressed for time? The [lettersmith.blogging](https://github.com/gordonbrander/lettersmith/blob/master/lettersmith_blogging.lua) plugin bundles together Markdown, pretty permalinks, RSS feeds and more, so you can blog right out of the box.

Here's a simple blogging setup, using [Mustache](https://mustache.github.io/) templates:

```lua
local lettersmith = require("lettersmith")
local use_blogging = require("lettersmith.blogging")
local use_mustache = require("lettersmith.mustache")

local docs = lettersmith.docs("raw")

docs = use_blogging(docs)
docs = use_mustache(docs, "templates")

lettersmith.build(docs, "out")
```
-->

Of course, this is just a start. "Plugins" are really just functions that modify the list of tables. This makes Lettersmith simple. It also means it is extremely flexible. Lettersmith can be anything you want: a website builder, a blog, a documentation generation script... If you need to transform text files, Lettersmith is an easy way to do it.


Creating new plugins
--------------------

Don't see the feature you want? No problem. Creating a plugin is easy! "Plugins" are really just functions that return reducer function.

For example, here's a simple plugin to remove drafts:

```lua
function remove_drafts(docs)
  local out = {}
  for i, doc in ipairs(docs) do
    if not doc.draft then
      table.insert(out, doc)
    end
  end
  return out
end
```

This can be simplified, though. Lettersmith comes with handy tools for creating plugins. Here's the same plugin, using Lettersmith's `filtering` decorator:

```lua
local filtering = require('plugin_utils').filtering

remove_drafts = filtering(function (doc)
  return not doc.draft
end)
```

That's much cleaner.


What's so great about static sites?
-----------------------------------

Why use Lettersmith?

- The most important reason: it's simple.
- Blazing-fast sites on cheap hosting. Run-of-the-mill servers like Apache and nginx can serve thousands of static files per second.
- You can't hack what doesn't exist. Static sites aren't prone to being hacked, because they're entirely static... there is no program to hack.
- Your data is in plain text. No databases to worry about, no export necessary. Want to take your data elsewhere? It's all there in text files.


Contributing
------------

Lettersmith is open source, and you can help shape it. Check out the [contributing page on the wiki](https://github.com/gordonbrander/lettersmith/wiki/Contributing) to learn more.


License
-------

The MIT License (MIT)

Copyright &copy; 2014, Gordon Brander

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
- Neither the name "Lettersmith" nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
