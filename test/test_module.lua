local compile = require("test.util").compile

return {
  name = "modules",
  tests = {
    {
      name = "import standalone",
      input = 'import "math"',
      expected = 'require("math")',
    },
    {
      name = "import assign",
      input = 'let m = import "math"',
      expected = 'local m = require("math")',
    },
    {
      name = "import in expression",
      input = 'print(import "math".pi)',
      expected = 'print(require("math").pi)',
    },
    {
      name = "export value",
      input = "export 42",
      expected = "return 42",
    },
    {
      name = "export table",
      input = 'export { add -> fn(a, b) { a + b } }',
      expected = 'return { ["add"] = function(a, b)\n  return (a + b)\nend }',
    },
    {
      name = "module with fn and export",
      input = 'fn add(a, b) { a + b }\nexport { add -> add }',
      expected = 'local function add(a, b)\n  return (a + b)\nend\nreturn { ["add"] = add }',
    },
    {
      name = "module with import and export",
      input = 'let m = import "math"\nexport { pi -> m.pi }',
      expected = 'local m = require("math")\nreturn { ["pi"] = m.pi }',
    },
  },
}
