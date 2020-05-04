local PLUGIN_NAME = "usher"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema)", function()


  it("accepts distinct request_header and response_header", function()
    local ok, err = validate({
        rules = {
          {
            condition = {
              ["X-Location"] = "London"
            },
            upstream_name = "uk_cluster"
          },
          {
            condition = {
              ["X-Location"] = "Toronto"
            },
            upstream_name = "canada_cluster"
          }
        }
      })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)


  it("rejects config with no condition specified in a rule", function()
    local ok, err = validate({
        rules = {
          {
            upstream_name = "uk_cluster"
          },
          {
            condition = {
              ["X-Location"] = "Toronto"
            },
            upstream_name = "canada_cluster"
          }
        }
      })
    assert.is_nil(ok)
    assert.is_truthy(err)
  end)


  it("rejects config with empty condition specified in a rule", function()
    local ok, err = validate({
        rules = {
          {
            condition = {
            },
            upstream_name = "uk_cluster"
          },
          {
            condition = {
              ["X-Location"] = "Toronto"
            },
            upstream_name = "canada_cluster"
          }
        }
      })
    assert.is_nil(ok)
    assert.is_truthy(err)
  end)


end)
