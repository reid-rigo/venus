local List = {}

function List.add(t, v)
  t[#t + 1] = v
  return t
end

function List.remove(t, i)
  table.remove(t, i)
  return t
end

function List.get(t, i)
  return t[i]
end

function List.len(t)
  return #t
end

function List.map(t, f)
  local out = {}
  for i, v in ipairs(t) do
    out[i] = f(v)
  end
  return out
end

function List.filter(t, f)
  local out = {}
  for _, v in ipairs(t) do
    if f(v) then out[#out + 1] = v end
  end
  return out
end

function List.reduce(t, f, init)
  local acc = init
  for _, v in ipairs(t) do
    acc = f(acc, v)
  end
  return acc
end

function List.each(t, f)
  for i, v in ipairs(t) do
    f(v, i)
  end
end

function List.join(t, sep)
  return table.concat(t, sep or "")
end

return List
