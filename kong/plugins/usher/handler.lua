local access = require "kong.plugins.usher.access"
local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1",
}
---[[ runs in the 'access_by_lua_block'
function plugin:access(conf)

  -- your custom code here
  kong.log.inspect(" configuration: ", conf)   -- check the logs for a pretty-printed config!
  access.execute(conf)
end --]]

return plugin
