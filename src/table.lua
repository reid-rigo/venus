local Table = {}

function Table.get(m, k)
  return m[k]
end

function Table.set(m, k, v)
  m[k] = v
  return m
end

function Table.keys(m)
  local ks = {}
  for k in pairs(m) do
    ks[#ks + 1] = k
  end
  return ks
end

function Table.values(m)
  local vs = {}
  for _, v in pairs(m) do
    vs[#vs + 1] = v
  end
  return vs
end

function Table.len(m)
  local n = 0
  for _ in pairs(m) do n = n + 1 end
  return n
end

function Table.has(m, k)
  return m[k] ~= nil
end

function Table.remove(m, k)
  m[k] = nil
  return m
end

return Table
