local compile = require("test.util").compile

return {
  name = "fun",
  tests = {
    {
      name = "empty function",
      input = "fun f() {\n}",
      expected = "local function f()\nend",
    },
    {
      name = "function with expression body",
      input = "fun f() {\n  42\n}",
      expected = "local function f()\n  return 42\nend",
    },
    {
      name = "function with params",
      input = "fun add(a, b) {\n  a + b\n}",
      expected = "local function add(a, b)\n  return (a + b)\nend",
    },
    {
      name = "function with let then return",
      input = "fun f() {\n  let x = 42\n  x\n}",
      expected = "local function f()\n  local x = 42\n  return x\nend",
    },
    {
      name = "function with pipeline",
      input = "fun double(x) {\n  x |> add(1) |> add(1)\n}",
      expected = "local function double(x)\n  return add(add(x, 1), 1)\nend",
    },
    {
      name = "function with string literal",
      input = "fun hey() {\n  \"hey\"\n}",
      expected = 'local function hey()\n  return "hey"\nend',
    },
    {
      name = "multiple functions in program",
      input = "fun a() {\n  1\n}\nfun b() {\n  2\n}",
      expected = "local function a()\n  return 1\nend\nlocal function b()\n  return 2\nend",
    },
  },
}
