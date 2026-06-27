local compile = require("test.util").compile

return {
  name = "let",
  tests = {
    {
      name = "let with init",
      input = "let x = 42",
      expected = "local x = 42",
    },
    {
      name = "let with pipeline",
      input = "let y = 2 |> math.pow(3)",
      expected = "local y = math.pow(2, 3)",
    },
    {
      name = "let multiple vars",
      input = "let a, b = 1, 2",
      expected = "local a, b = 1, 2",
    },
    {
      name = "let no init",
      input = "let x",
      expected = "local x",
    },
    {
      name = "let then use in pipeline",
      input = "let x = 42\nx |> print",
      expected = "local x = 42\nprint(x)",
    },
    {
      name = "let with arithmetic",
      input = "let x = 1 + 2",
      expected = "local x = (1 + 2)",
    },
    {
      name = "let with chained pipeline",
      input = "let x = 2 |> math.pow(3) |> math.sqrt",
      expected = "local x = math.sqrt(math.pow(2, 3))",
    },
  },
}
