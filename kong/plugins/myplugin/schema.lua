local typedefs = require "kong.db.schema.typedefs"
local utils = require "kong.plugins.myplugin.utils"
local lower = string.lower

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local function validate_rules(r)
  
  local original_keys_length = utils.table_length(r.condition)
  local case_insensitive_keys_set = utils.get_case_insensitive_set(r.condition)
  local case_insensitive_keys_length = utils.table_length(case_insensitive_keys_set)
  if original_keys_length ~= case_insensitive_keys_length then
    return nil, "duplicate headers detected in one of the conditions"
  end

  return true
end

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
    },
    custom_validator = validate_rules
  }
}

local schema = {
  name = plugin_name,
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { rules = rules_array }
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
