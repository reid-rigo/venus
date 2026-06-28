local compile = require("test.util").compile

return {
  name = "match",
  tests = {
    {
      name = "match literal",
      input = "match 1 { 1 -> 42 }",
      expected = [[(function()
  local _m_1 = 1
  if _m_1 == 1 then
    return 42
  end
end)()]],
    },
    {
      name = "match with wildcard",
      input = "match 1 { 2 -> 0, _ -> 42 }",
      expected = [[(function()
  local _m_1 = 1
  if _m_1 == 2 then
    return 0
  else
    return 42
  end
end)()]],
    },
    {
      name = "match with binding",
      input = "match 1 { x -> x }",
      expected = [[(function()
  local _m_1 = 1
  local x = _m_1
  return x
end)()]],
    },
    {
      name = "match with binding after if",
      input = "match 1 { 2 -> 0, x -> x }",
      expected = [[(function()
  local _m_1 = 1
  if _m_1 == 2 then
    return 0
  else
    local x = _m_1
    return x
  end
end)()]],
    },
    {
      name = "match multiple literals",
      input = "match 1 { 1 -> \"one\", 2 -> \"two\", 3 -> \"three\" }",
      expected = [[(function()
  local _m_1 = 1
  if _m_1 == 1 then
    return "one"
  elseif _m_1 == 2 then
    return "two"
  elseif _m_1 == 3 then
    return "three"
  end
end)()]],
    },
    {
      name = "match in fn body",
      input = "fn classify(x) {\n  match x { 1 -> \"one\", _ -> \"other\" }\n}",
      expected = [[local function classify(x)
  return (function()
  local _m_1 = x
  if _m_1 == 1 then
    return "one"
  else
    return "other"
  end
end)()
end]],
    },
    {
      name = "match with string patterns",
      input = [[match "hi" { "hi" -> 1, _ -> 0 }]],
      expected = [[(function()
  local _m_1 = "hi"
  if _m_1 == "hi" then
    return 1
  else
    return 0
  end
end)()]],
    },
  },
}
