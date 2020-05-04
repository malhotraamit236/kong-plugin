local utils = {}
local lower = string.lower

function utils.get_case_insensitive_set(tab)
  local keyset = {}
  for k,v in pairs(tab) do
    keyset[lower(k)]=v
  end
  return keyset
end

return utils