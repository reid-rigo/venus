local compile = require("test.util").compile

return {
  name = "map",
  tests = {
    {
      name = "empty map",
      input = "let m = {}",
      expected = "local m = {  }",
    },
    {
      name = "map with string keys",
      input = 'let m = { "x" 1 "y" 2 }',
      expected = 'local m = { ["x"] = 1, ["y"] = 2 }',
    },
    {
      name = "map as expression",
      input = "{} |> print",
      expected = "print({  })",
    },
    {
      name = "map with expressions",
      input = 'let m = { "a" 1 + 2 }',
      expected = 'local m = { ["a"] = (1 + 2) }',
    },
    {
      name = "map in pipeline",
      input = '{ "key" 42 } |> print',
      expected = 'print({ ["key"] = 42 })',
    },
    {
      name = "map with identifier key",
      input = "let m = { a 1 }",
      expected = 'local m = { ["a"] = 1 }',
    },
    {
      name = "map with multiple keys",
      input = 'let m = { "a" 1 "b" 2 "c" 3 }',
      expected = 'local m = { ["a"] = 1, ["b"] = 2, ["c"] = 3 }',
    },
  },
}
