local compile = require("test.util").compile

return {
  name = "lambda",
  tests = {
    {
      name = "lambda with empty body",
      input = "let f = fn() {}",
      expected = "local f = function()\nend",
    },
    {
      name = "lambda with expression body",
      input = "let f = fn(x) { x }",
      expected = "local f = function(x)\n  return x\nend",
    },
    {
      name = "lambda with arithmetic",
      input = "let f = fn(x) { x + 1 }",
      expected = "local f = function(x)\n  return (x + 1)\nend",
    },
    {
      name = "lambda as call arg",
      input = "map([1 2], fn(x) { x * 2 })",
      expected = "map({ 1, 2 }, function(x)\n  return (x * 2)\nend)",
    },
    {
      name = "lambda with let in body",
      input = "let f = fn(x) {\n  let y = x + 1\n  y\n}",
      expected = "local f = function(x)\n  local y = (x + 1)\n  return y\nend",
    },
    {
      name = "lambda in pipeline",
      input = "5 |> fn(x) { x * 2 }",
      expected = "function(x)\n  return (x * 2)\nend(5)",
    },
  },
}
