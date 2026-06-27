local compile = require("test.util").compile

return {
  name = "table",
  tests = {
    {
      name = "empty table",
      input = "let t = {}",
      expected = "local t = {  }",
    },
    {
      name = "list table",
      input = "let t = {1, 2, 3}",
      expected = "local t = { 1, 2, 3 }",
    },
    {
      name = "record table",
      input = "let t = {x = 1, y = 2}",
      expected = "local t = { x = 1, y = 2 }",
    },
    {
      name = "mixed table",
      input = "let t = {1, key = 2}",
      expected = "local t = { 1, key = 2 }",
    },
    {
      name = "table as expression",
      input = "{} |> print",
      expected = "print({  })",
    },
    {
      name = "table in pipeline",
      input = "{1, 2} |> table.concat(3)",
      expected = "table.concat({ 1, 2 }, 3)",
    },
    {
      name = "nested table",
      input = "let t = {1, {2, 3}}",
      expected = "local t = { 1, { 2, 3 } }",
    },
    {
      name = "table with expressions",
      input = "let t = {1 + 2, 3 * 4}",
      expected = "local t = { (1 + 2), (3 * 4) }",
    },
  },
}
