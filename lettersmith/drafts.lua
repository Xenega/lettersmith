--[[
Lettersmith Drafts

Remove drafts from rendered docs. A draft is any file who's name starts with
an underscore.
--]]
local Doc = require('lettersmith.doc')
local filtering = require("lettersmith.plugin_utils").filtering
local path_utils = require("lettersmith.path_utils")

local function isnt_prefixed_with_underscore(doc)
  -- Treat any document path that starts with an underscore as a draft.
  return path_utils.basename(Doc.path(doc)):find("^_") == nil
end

-- Remove all docs who's path is prefixed with an underscore.
local function remove_drafts()
  return filtering(isnt_prefixed_with_underscore)
end

return remove_drafts
