local String = {}

function String.split(s, sep)
  local out = {}
  if sep == "" then
    for i = 1, #s do
      out[#out + 1] = s:sub(i, i)
    end
    return out
  end
  local escaped = sep:gsub("([^%w])", "%%%1")
  local start = 1
  while true do
    local pos, endpos = s:find(escaped, start)
    if not pos then
      out[#out + 1] = s:sub(start)
      break
    end
    out[#out + 1] = s:sub(start, pos - 1)
    start = endpos + 1
  end
  return out
end

function String.trim(s)
  return s:match("^%s*(.-)%s*$") or ""
end

function String.starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

function String.ends_with(s, suffix)
  return #s >= #suffix and s:sub(-#suffix) == suffix
end

function String.contains(s, sub)
  return s:find(sub, 1, true) ~= nil
end

function String.concat(...)
  return table.concat({ ... })
end

function String.len(s)
  return #s
end

return String
