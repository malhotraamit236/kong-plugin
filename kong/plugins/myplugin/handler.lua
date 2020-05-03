-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------



local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1",
}

local function table_length(tab)
  local count = 0
  for _ in pairs(tab) do count = count + 1 end
  return count
end

local function evaluate_and_condition(current_condition, all_headers)
  local result = true
  for k, v in pairs(current_condition) do
    result = result and (all_headers[k] == v)
  end
  return result
end

---[[ handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()

  -- your custom code here
  kong.log.debug("saying hi from the 'init_worker' handler")

end --]]


---[[ runs in the 'access_by_lua_block'
function plugin:access(conf)

  -- your custom code here
  kong.log.inspect(" configuration: ", conf)   -- check the logs for a pretty-printed config!
  
  all_headers = kong.request.get_headers()
  
  local target_upstream = ""
  local max_anded_count = 0
  for _, rule in ipairs(conf.rules) do 
    local current_condition = rule.condition
    local is_condition_satisfied = evaluate_and_condition(current_condition, all_headers)
    if is_condition_satisfied then
      local current_condition_length = table_length(current_condition)
      if current_condition_length > max_anded_count then
        max_anded_count = current_condition_length
        target_upstream = rule.upstream_name
        kong.log.inspect("target_upstream: ", rule.upstream_name)
      end 
    end
  end
  if target_upstream then
    kong.log.inspect("target_upstream: ", target_upstream)
  end
end --]]


---[[ runs in the 'header_filter_by_lua_block'
function plugin:header_filter(plugin_conf)

  -- your custom code here, for example;
  ngx.header[plugin_conf.response_header] = "this is on the response with code change"

end --]]


--[[ runs in the 'body_filter_by_lua_block'
function plugin:body_filter(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'body_filter' handler")

end --]]


--[[ runs in the 'log_by_lua_block'
function plugin:log(plugin_conf)

  -- your custom code here
  kong.log.debug("saying hi from the 'log' handler")

end --]]


-- return our plugin object
return plugin
