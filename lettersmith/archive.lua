local Plugin = require("lettermsith.plugin")

local function archive(config)
  return function(docs)
    return docs
  end
end

return archive
