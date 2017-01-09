# doc

Tools for working with doc tables.

    local doc = {}
    local headmatter = require("lettersmith.headmatter")

Load contents of a file as a document table. Returns a new lua document table
on success. Throws exception on failure.

    function doc.parse(s)
      -- Get YAML meta table and contents from headmatter parser.
      -- We'll use the meta table as the doc object.
      local meta, contents = headmatter.parse(s)
      return {meta=meta, contents=contents}
    end

    return doc
