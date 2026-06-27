local Map = {}

function Map.get(m, k)
  return m[k]
end

function Map.set(m, k, v)
  m[k] = v
  return m
end

function Map.keys(m)
  local ks = {}
  for k in pairs(m) do
    ks[#ks + 1] = k
  end
  return ks
end

function Map.values(m)
  local vs = {}
  for _, v in pairs(m) do
    vs[#vs + 1] = v
  end
  return vs
end

function Map.len(m)
  local n = 0
  for _ in pairs(m) do n = n + 1 end
  return n
end

function Map.has(m, k)
  return m[k] ~= nil
end

function Map.remove(m, k)
  m[k] = nil
  return m
end

return Map
