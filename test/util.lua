local Lexer = require("src.lexer")
local Parser = require("src.parser")
local Codegen = require("src.codegen")

local M = {}

function M.compile(source)
  local lexer = Lexer.new(source)
  local tokens = lexer:tokenize()
  local parser = Parser.new(tokens)
  local ast = parser:parse_program()
  local codegen = Codegen.new()
  return codegen:generate(ast)
end

return M
