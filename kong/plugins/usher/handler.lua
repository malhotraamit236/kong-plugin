local access = require "kong.plugins.usher.access"

local UsherPlugin = {
  PRIORITY = 900, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1",
}

function UsherPlugin:access(conf)
  access.execute(conf)
end

return UsherPlugin
