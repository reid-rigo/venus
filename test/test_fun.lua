local compile = require("test.util").compile

return {
  name = "fn",
  tests = {
    {
      name = "empty function",
      input = "fn f() {\n}",
      expected = "local function f()\nend",
    },
    {
      name = "function with expression body",
      input = "fn f() {\n  42\n}",
      expected = "local function f()\n  return 42\nend",
    },
    {
      name = "function with params",
      input = "fn add(a, b) {\n  a + b\n}",
      expected = "local function add(a, b)\n  return (a + b)\nend",
    },
    {
      name = "function with let then return",
      input = "fn f() {\n  let x = 42\n  x\n}",
      expected = "local function f()\n  local x = 42\n  return x\nend",
    },
    {
      name = "function with pipeline",
      input = "fn double(x) {\n  x |> add(1) |> add(1)\n}",
      expected = "local function double(x)\n  return add(add(x, 1), 1)\nend",
    },
    {
      name = "function with string literal",
      input = "fn hey() {\n  \"hey\"\n}",
      expected = 'local function hey()\n  return "hey"\nend',
    },
    {
      name = "multiple functions in program",
      input = "fn a() {\n  1\n}\nfn b() {\n  2\n}",
      expected = "local function a()\n  return 1\nend\nlocal function b()\n  return 2\nend",
    },
    {
      name = "single overloaded fn with literal",
      input = "fn f(0) {\n  \"zero\"\n}",
      expected = table.concat({
        "local function f(...)",
        "  local _args = {...}",
        "  if _args[1] == 0 then",
        '    return "zero"',
        "  end",
        "end",
      }, "\n"),
    },
    {
      name = "overloaded fn dispatches by value",
      input = "fn fib(0) { 0 }\nfn fib(1) { 1 }\nfn fib(n) { n }",
      expected = table.concat({
        "local function fib(...)",
        "  local _args = {...}",
        "  if _args[1] == 0 then",
        "    return 0",
        "  elseif _args[1] == 1 then",
        "    return 1",
        "  else",
        "    local n = _args[1]",
        "    return n",
        "  end",
        "end",
      }, "\n"),
    },
    {
      name = "overloaded fn with body statements",
      input = "fn f(0) {\n  let x = 10\n  x\n}\nfn f(n) {\n  n\n}",
      expected = table.concat({
        "local function f(...)",
        "  local _args = {...}",
        "  if _args[1] == 0 then",
        "    local x = 10",
        "    return x",
        "  else",
        "    local n = _args[1]",
        "    return n",
        "  end",
        "end",
      }, "\n"),
    },
    {
      name = "overloaded fn preserves interleaving",
      input = "fn f(0) { 0 }\nlet x = 1\nfn f(1) { 1 }",
      expected = table.concat({
        "local function f(...)",
        "  local _args = {...}",
        "  if _args[1] == 0 then",
        "    return 0",
        "  elseif _args[1] == 1 then",
        "    return 1",
        "  end",
        "end",
        "local x = 1",
      }, "\n"),
    },
  },
}
