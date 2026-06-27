local compile = require("test.util").compile

return {
  name = "pipeline",
  tests = {
    {
      name = "basic pipeline",
      input = "42 |> print",
      expected = "print(42)",
    },
    {
      name = "pipeline with args",
      input = "2 |> math.pow(3) |> print",
      expected = "print(math.pow(2, 3))",
    },
    {
      name = "chained pipelines",
      input = "10 |> math.pow(2) |> math.sqrt |> print",
      expected = "print(math.sqrt(math.pow(10, 2)))",
    },
    {
      name = "pipeline with parens",
      input = "(3 + 4) |> print",
      expected = "print((3 + 4))",
    },
    {
      name = "pipeline in arg",
      input = "print(2 |> math.pow(3))",
      expected = "print(math.pow(2, 3))",
    },
    {
      name = "pipeline member access",
      input = [["hello" |> string.upper |> print]],
      expected = 'print(string.upper("hello"))',
    },
    {
      name = "pipeline then call",
      input = "2 |> add(1) |> double",
      expected = "double(add(2, 1))",
    },
    {
      name = "pipeline with arithmetic left",
      input = "(1 + 2) |> print",
      expected = "print((1 + 2))",
    },
    {
      name = "pipeline with negation",
      input = "-5 |> math.abs |> print",
      expected = "print(math.abs((-5)))",
    },
  },
}
