local helpers = require "spec.helpers"


local PLUGIN_NAME = "usher"


for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()
      
      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      local upstream1 = bp.upstreams:insert({
        name = "europe_cluster",
        service = service1
      })
      local target1 = bp.targets:insert({
        target = helpers.mock_upstream_host..":"..helpers.mock_upstream_port,
        upstream = upstream1
      })
      local service1 = bp.services:insert({
        name = "example_service",
        host = upstream1.name
      })
      
      local upstream2 = bp.upstreams:insert({
        name = "italy_cluster"
      })
      local target2 = bp.targets:insert({
        target = helpers.mock_upstream_host..":"..helpers.mock_upstream_port,
        upstream = upstream2
      })
      

      local route1 = bp.routes:insert({
        name = "localroute",
        paths = {"/local"},
        service = service1
      })

      
      bp.plugins:insert {
        name = PLUGIN_NAME,
        service = { id = service1.id },
        config = { rules = {{ condition = {["X-Region"] = "Italy"}, upstream_name = "italy_cluster" }} },
      }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)



    describe("request", function()
      it("first test", function()
        local r = client:get("/local", {
          headers = {
            ["X-Region"] = "Italy"
          }
        })
        assert.response(r).has.status(200)
      end)

      it("first test", function()
        local r = client:get("/local", {})
        assert.response(r).has.status(200)
      end)
    end)

  end)
end
