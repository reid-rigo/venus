local compile = require("test.util").compile

return {
  name = "table",
  tests = {
    {
      name = "empty table",
      input = "let m = {}",
      expected = "local m = {  }",
    },
    {
      name = "table with string keys",
      input = 'let m = { "x" 1 "y" 2 }',
      expected = 'local m = { ["x"] = 1, ["y"] = 2 }',
    },
    {
      name = "table as expression",
      input = "{} |> print",
      expected = "print({  })",
    },
    {
      name = "table with expressions",
      input = 'let m = { "a" 1 + 2 }',
      expected = 'local m = { ["a"] = (1 + 2) }',
    },
    {
      name = "table in pipeline",
      input = '{ "key" 42 } |> print',
      expected = 'print({ ["key"] = 42 })',
    },
    {
      name = "table with identifier key",
      input = "let m = { a 1 }",
      expected = 'local m = { ["a"] = 1 }',
    },
    {
      name = "table with multiple keys",
      input = 'let m = { "a" 1 "b" 2 "c" 3 }',
      expected = 'local m = { ["a"] = 1, ["b"] = 2, ["c"] = 3 }',
    },
    {
      name = "field access via dot",
      input = "let t = { x 10 }\nt.x",
      expected = 'local t = { ["x"] = 10 }\nt.x',
    },
    {
      name = "chained field access",
      input = "t.a.b",
      expected = "t.a.b",
    },
    {
      name = "field in arithmetic",
      input = "t.x + t.y",
      expected = "(t.x + t.y)",
    },
    {
      name = "field as function call",
      input = "t.greet(42)",
      expected = "t.greet(42)",
    },
    {
      name = "field in pipeline",
      input = "t.x |> print",
      expected = "print(t.x)",
    },
    {
      name = "field access on literal table",
      input = '{ "a" 1 }.a',
      expected = '{ ["a"] = 1 }.a',
    },
  },
}
