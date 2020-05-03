local typedefs = require "kong.db.schema.typedefs"

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local condition_record = {
  type = "map",
  required = true,
  keys = typedefs.header_name ,
  values = {
    type = "string"
  }
}

local rules_array = {
  type = "array",
  default = {},
  elements = {
    type = "record",
    fields = {
      { condition = condition_record },
      { upstream_name = typedefs.name }
    }
  }
}

local schema = {
  name = plugin_name,
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { rules = rules_array}
        }
      },
    },
  },
}

-- run_on_first typedef/field was removed in Kong 2.x
-- try to insert it, but simply ignore if it fails
pcall(function()
        table.insert(schema.fields, { run_on = typedefs.run_on_first })
      end)

return schema
