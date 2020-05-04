local typedefs = require "kong.db.schema.typedefs"
local utils = require "kong.plugins.usher.utils"
local pl_pretty_write = require("pl.pretty").write
local pl_tablex_size = require("pl.tablex").size

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local function validate_condition(condition)
  local num_of_given_header_keys = pl_tablex_size(condition)

  local case_insensitive_hearder_keys_set = utils.get_case_insensitive_set(condition)
  local num_of_case_insensitive_header_keys = pl_tablex_size(case_insensitive_hearder_keys_set)

  if num_of_given_header_keys ~= num_of_case_insensitive_header_keys then
    return nil, "Duplicate headers with different case found in condition: " ..  pl_pretty_write(condition)
  elseif num_of_given_header_keys < 1 then
    return nil, "Empty condition" ..  pl_pretty_write(condition)
  end
  return true
end

local condition_record = {
  type = "map",
  required = true,
  keys = typedefs.header_name { required = true },
  values = {
    type = "string",
    required = true
  },
  custom_validator = validate_condition
}

local rules_array = {
  type = "array",
  required = true,
  len_min = 1,
  elements = {
    type = "record",
    fields = {
      { condition = condition_record },
      { upstream_name = typedefs.name { required = true } }
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
