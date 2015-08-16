--[[
Lettersmith Drafts

Remove drafts from rendered docs. A draft is any file who's name starts with
an underscore.
--]]
local expanding = require("lettersmith.plugin_utils").filtering
local path_utils = require("lettersmith.path_utils")

local function is_doc_path_prefixed_with_underscore(doc)
  -- Treat any document path that starts with an underscore as a draft.
  return path_utils.basename(doc.relative_filepath):find("^_")
end

-- Remove all docs who's path is prefixed with an underscore.
local remove_drafts = filtering(function (doc)
  if is_doc_path_prefixed_with_underscore(doc) then
    return false
  else
    return true
  end
end)

return remove_drafts
