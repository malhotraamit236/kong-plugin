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


  it("accepts a valid config", function()
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


  it("rejects config with no rule specified", function()
    local ok, err = validate({
        rules = {}
      })
    assert.is_nil(ok)
    assert.is_truthy(err)
  end)

  it("rejects config if rules array is not passed", function()
    local ok, err = validate({})
    assert.is_nil(ok)
    assert.is_truthy(err)
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
            condition = {},
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


  it("rejects config with absurd condition specified in a rule", function()
    local ok, err = validate({
        rules = {
          {
            condition = {
              ["X-Location"] = "Toronto",
              [""] = ""
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


  it("rejects config with header key missing in a condition of a rule", function()
    local ok, err = validate({
        rules = {
          {
            condition = {
              ["X-Location"] = "Toronto",
              [""] = "xyz"
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


  it("rejects config with empty header value in a condition of a rule", function()
    local ok, err = validate({
        rules = {
          {
            condition = {
              ["X-Location"] = "",
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


  it("rejects config with nil header value in a condition of a rule", function()
    local ok, err = validate({
        rules = {
          {
            condition = {
              ["X-Location"] = nil,
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


  it("rejects config with a duplicate by case set of headers in a rule", function()
    local ok, err = validate({
        rules = {
          {
            condition = {
              ["X-Location"] = "London",
              ["x-LocaTion"] = "Toronto",
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


  it("accepts config with duplicate headers if case matches exactly in a rule", function()
    local ok, err = validate({
        rules = {
          {
            condition = {
              ["X-Location"] = "London",
              ["X-Location"] = "Toronto",
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
    assert.are.equal(ok.config.rules[1].condition["X-Location"], "Toronto")
  end)


  it("rejects config with no upstream specified in a rule", function()
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
            }
          }
        }
      })
    assert.is_nil(ok)
    assert.is_truthy(err)
  end)



  it("rejects config if upstream is absent in a rule", function()
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
            }
          }
        }
      })
    assert.is_nil(ok)
    assert.is_truthy(err)
  end)


  it("rejects config with nil upstream value in a rule", function()
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
            upstream_name = nil
          }
        }
      })
    assert.is_nil(ok)
    assert.is_truthy(err)
  end)


  it("rejects config with absurd upstream value in a rule", function()
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
            upstream_name = "  "
          }
        }
      })
    assert.is_nil(ok)
    assert.is_truthy(err)
  end)


end)
