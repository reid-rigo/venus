local compile = require("test.util").compile

return {
  name = "if",
  tests = {
    {
      name = "if without else",
      input = "if 1 {\n  42\n}",
      expected = table.concat({
        "if 1 then",
        "  return 42",
        "end",
      }, "\n"),
    },
    {
      name = "if-else",
      input = "if 1 {\n  42\n} else {\n  0\n}",
      expected = table.concat({
        "if 1 then",
        "  return 42",
        "else",
        "  return 0",
        "end",
      }, "\n"),
    },
    {
      name = "if-elseif-else",
      input = "if 1 {\n  \"one\"\n} else if 2 {\n  \"two\"\n} else {\n  \"other\"\n}",
      expected = table.concat({
        "if 1 then",
        '  return "one"',
        "elseif 2 then",
        '  return "two"',
        "else",
        '  return "other"',
        "end",
      }, "\n"),
    },
    {
      name = "if with body statements",
      input = "if 1 {\n  let x = 10\n  x\n} else {\n  let y = 20\n  y\n}",
      expected = table.concat({
        "if 1 then",
        "  local x = 10",
        "  return x",
        "else",
        "  local y = 20",
        "  return y",
        "end",
      }, "\n"),
    },
    {
      name = "nested if",
      input = "if 1 {\n  if 2 {\n    3\n  } else {\n    4\n  }\n} else {\n  5\n}",
      expected = table.concat({
        "if 1 then",
        "  if 2 then",
        "    return 3",
        "  else",
        "    return 4",
        "  end",
        "else",
        "  return 5",
        "end",
      }, "\n"),
    },
    {
      name = "if in fn body",
      input = "fn f(x) {\n  if x {\n    1\n  } else {\n    2\n  }\n}",
      expected = table.concat({
        "local function f(x)",
        "  if x then",
        "    return 1",
        "  else",
        "    return 2",
        "  end",
        "end",
      }, "\n"),
    },
    {
      name = "if with equality comparison",
      input = "if x == 0 {\n  \"zero\"\n}",
      expected = table.concat({
        "if (x == 0) then",
        '  return "zero"',
        "end",
      }, "\n"),
    },
    {
      name = "if with not-equal comparison",
      input = "if x != 0 {\n  \"not zero\"\n}",
      expected = table.concat({
        "if (x ~= 0) then",
        '  return "not zero"',
        "end",
      }, "\n"),
    },
    {
      name = "if with less-than",
      input = "if x < 10 {\n  \"small\"\n}",
      expected = table.concat({
        "if (x < 10) then",
        '  return "small"',
        "end",
      }, "\n"),
    },
    {
      name = "if with and",
      input = "if x > 0 and x < 10 {\n  \"in range\"\n}",
      expected = table.concat({
        "if ((x > 0) and (x < 10)) then",
        '  return "in range"',
        "end",
      }, "\n"),
    },
    {
      name = "if with or",
      input = "if x == 0 or x == 1 {\n  \"small\"\n}",
      expected = table.concat({
        "if ((x == 0) or (x == 1)) then",
        '  return "small"',
        "end",
      }, "\n"),
    },
  },
}
