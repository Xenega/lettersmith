# jsontools

    local Json = require("cjson")
    local jsontools = {}

Map from JSON string to JSON string through a function.

    local function map(f, v)
      return Json.encode(f(Json.decode(v)))
    end

Re-export encode and decode. This lets us swap out json libs if necessary.

    jsontools.encode = Json.encode
    jsontools.decode = Json.decode

    return jsontools
