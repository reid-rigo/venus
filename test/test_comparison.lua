local compile = require("test.util").compile

return {
  name = "comparison",
  tests = {
    {
      name = "equality",
      input = "1 == 2",
      expected = "(1 == 2)",
    },
    {
      name = "not equal",
      input = "1 != 2",
      expected = "(1 ~= 2)",
    },
    {
      name = "less than",
      input = "1 < 2",
      expected = "(1 < 2)",
    },
    {
      name = "greater than",
      input = "1 > 2",
      expected = "(1 > 2)",
    },
    {
      name = "less or equal",
      input = "1 <= 2",
      expected = "(1 <= 2)",
    },
    {
      name = "greater or equal",
      input = "1 >= 2",
      expected = "(1 >= 2)",
    },
    {
      name = "chained comparisons",
      input = "1 == 2 == 3",
      expected = "((1 == 2) == 3)",
    },
    {
      name = "comparison in let",
      input = "let x = 1 == 2",
      expected = "local x = (1 == 2)",
    },
    {
      name = "comparison with arithmetic",
      input = "1 + 2 == 3",
      expected = "((1 + 2) == 3)",
    },
    {
      name = "arithmetic with comparison",
      input = "1 == 2 + 3",
      expected = "(1 == (2 + 3))",
    },
    {
      name = "logical and",
      input = "1 and 2",
      expected = "(1 and 2)",
    },
    {
      name = "logical or",
      input = "1 or 2",
      expected = "(1 or 2)",
    },
    {
      name = "mixed logical and comparison",
      input = "1 == 2 and 3 < 4",
      expected = "((1 == 2) and (3 < 4))",
    },
    {
      name = "logical chaining",
      input = "1 and 2 or 3",
      expected = "((1 and 2) or 3)",
    },
    {
      name = "comparison in pipeline",
      input = "1 == 2 |> f",
      expected = "f((1 == 2))",
    },
    {
      name = "nil literal",
      input = "nil",
      expected = "nil",
    },
    {
      name = "nil in let",
      input = "let x = nil",
      expected = "local x = nil",
    },
    {
      name = "nil comparison",
      input = "x == nil",
      expected = "(x == nil)",
    },
    {
      name = "true literal",
      input = "true",
      expected = "true",
    },
    {
      name = "false literal",
      input = "false",
      expected = "false",
    },
    {
      name = "false in if condition",
      input = "if false {\n  1\n} else {\n  2\n}",
      expected = table.concat({
        "if false then",
        "  return 1",
        "else",
        "  return 2",
        "end",
      }, "\n"),
    },
    {
      name = "nil in match",
      input = "match x {\n  nil -> \"nothing\"\n  _ -> \"something\"\n}",
      expected = table.concat({
        "(function()",
        "  local _m_1 = x",
        "  if _m_1 == nil then",
        '    return "nothing"',
        "  else",
        '    return "something"',
        "  end",
        "end)()",
      }, "\n"),
    },
  },
}
