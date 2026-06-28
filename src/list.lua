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

function List.range(start, stop)
  local out = {}
  for i = start, stop do
    out[#out + 1] = i
  end
  return out
end

function List.reverse(t)
  local out = {}
  for i = #t, 1, -1 do
    out[#out + 1] = t[i]
  end
  return out
end

function List.flatten(t)
  local out = {}
  for _, v in ipairs(t) do
    if type(v) == "table" and #v > 0 then
      local flat = List.flatten(v)
      for _, fv in ipairs(flat) do
        out[#out + 1] = fv
      end
    else
      out[#out + 1] = v
    end
  end
  return out
end

return List
