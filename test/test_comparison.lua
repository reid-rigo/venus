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
  },
}
