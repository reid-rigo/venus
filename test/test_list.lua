local compile = require("test.util").compile

return {
  name = "list",
  tests = {
    {
      name = "empty list",
      input = "let t = []",
      expected = "local t = {  }",
    },
    {
      name = "simple list",
      input = "let t = [1 2 3]",
      expected = "local t = { 1, 2, 3 }",
    },
    {
      name = "list in pipeline",
      input = "[1 2] |> table.concat(3)",
      expected = "table.concat({ 1, 2 }, 3)",
    },
    {
      name = "list as expression",
      input = "[] |> print",
      expected = "print({  })",
    },
    {
      name = "nested list",
      input = "let t = [1 [2 3]]",
      expected = "local t = { 1, { 2, 3 } }",
    },
    {
      name = "list with expressions",
      input = "let t = [1 + 2 3 * 4]",
      expected = "local t = { (1 + 2), (3 * 4) }",
    },
    {
      name = "list with strings",
      input = 'let t = ["a" "b" "c"]',
      expected = 'local t = { "a", "b", "c" }',
    },
    {
      name = "list with comma separators",
      input = "let t = [1, 2, 3]",
      expected = "local t = { 1, 2, 3 }",
    },
    {
      name = "nested list with commas",
      input = "let t = [1, [2, 3]]",
      expected = "local t = { 1, { 2, 3 } }",
    },
  },
}
