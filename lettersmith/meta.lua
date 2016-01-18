--[[
Lettersmith Meta

Add metadata to every doc object. This is useful for things like site meta.
--]]
local Docs = require("lettersmith.docs")
local Doc = require("lettersmith.doc")

local mix_meta = Docs.mapping(Doc.update_meta)

return mix_meta