--[[
Lettersmith Drafts

Remove drafts from rendered docs. A draft is any file who's name starts with
an underscore.
--]]
local Doc = require('lettersmith.doc')
local Plugin = require("lettersmith.plugin")
local Path = require("lettersmith.path")

local function isnt_draft(doc)
  -- Treat any document path that starts with an underscore as a draft.
  return Path.basename(Doc.read_out(doc)):find("^_") == nil
end

-- Remove all docs who's path is prefixed with an underscore.
local remove_drafts = Plugin.filtering(isnt_draft)

return remove_drafts