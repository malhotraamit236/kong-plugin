local utils = require "kong.plugins.myplugin.utils"
local _M = {}

local function evaluate_and_condition(current_condition, all_headers)
  local result = true
  for k, v in pairs(current_condition) do
    result = result and (all_headers[k] == v)
  end
  return result
end


function _M.execute(conf)
  all_headers = kong.request.get_headers()
  
  local target_upstream = ""
  local max_anded_count = 0
  for _, rule in ipairs(conf.rules) do 
    local current_condition = rule.condition
    local is_condition_satisfied = evaluate_and_condition(current_condition, all_headers)
    if is_condition_satisfied then
      local current_condition_length = utils.table_length(current_condition)
      if current_condition_length > max_anded_count then
        max_anded_count = current_condition_length
        target_upstream = rule.upstream_name
        kong.log.inspect("max_anded_upstream: ", rule.upstream_name)
      end 
    end
  end
  if target_upstream then
    kong.log.inspect("target_upstream: ", target_upstream)
    kong.service.set_upstream(target_upstream)
  end
end

return _M