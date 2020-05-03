local utils = {}

function utils.table_length(tab)
  local count = 0
  for _ in pairs(tab) do count = count + 1 end
  return count
end

function utils.get_case_insensitive_set(tab)
  local keyset = {}
  for k,v in pairs(tab) do
    keyset[lower(k)]=v
  end
  return keyset
end

return utils