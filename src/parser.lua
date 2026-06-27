local Parser = {}
Parser.__index = Parser

function Parser.new(tokens)
  local self = setmetatable({}, Parser)
  self.tokens = tokens
  self.pos = 1
  return self
end

function Parser:peek(offset)
  offset = offset or 0
  local idx = self.pos + offset
  local tok = self.tokens[idx]
  if not tok then
    return { type = "EOF", value = nil }
  end
  return tok
end

function Parser:advance()
  local tok = self.tokens[self.pos]
  if tok then self.pos = self.pos + 1 end
  return tok
end

function Parser:expect(typ)
  local tok = self:advance()
  if tok.type ~= typ then
    error("Expected " .. typ .. " but got " .. tok.type .. " (" .. tostring(tok.value) .. ")")
  end
  return tok
end

function Parser:skip_newlines()
  while self:peek().type == "NEWLINE" do
    self:advance()
  end
end

-- program := statement*
function Parser:parse_program()
  local stmts = {}
  self:skip_newlines()
  while self:peek().type ~= "EOF" do
    local stmt = self:parse_statement()
    table.insert(stmts, stmt)
    self:skip_newlines()
  end
  return { type = "program", body = stmts }
end

-- statement := fun_decl | let_decl | expression
function Parser:parse_statement()
  if self:peek().type == "FUN" then
    return self:parse_fun_decl()
  elseif self:peek().type == "LET" then
    return self:parse_let_decl()
  end
  return self:parse_expression()
end

-- fun_decl := "fun" IDENT "(" params? ")" "{" body "}"
function Parser:parse_fun_decl()
  self:expect("FUN")
  local name = self:expect("IDENT").value
  self:expect("LPAREN")
  local params = {}
  if self:peek().type ~= "RPAREN" then
    table.insert(params, self:expect("IDENT").value)
    while self:peek().type == "COMMA" do
      self:advance()
      table.insert(params, self:expect("IDENT").value)
    end
  end
  self:expect("RPAREN")
  self:skip_newlines()
  self:expect("LBRACE")
  self:skip_newlines()
  local body = {}
  while self:peek().type ~= "RBRACE" and self:peek().type ~= "EOF" do
    local stmt = self:parse_statement()
    table.insert(body, stmt)
    self:skip_newlines()
  end
  self:expect("RBRACE")
  return { type = "fun", name = name, params = params, body = body }
end

-- let_decl := "let" IDENT ("=" expression)?
function Parser:parse_let_decl()
  self:expect("LET")
  local names = {}

  local name_tok = self:expect("IDENT")
  table.insert(names, name_tok.value)

  while self:peek().type == "COMMA" do
    self:advance()
    name_tok = self:expect("IDENT")
    table.insert(names, name_tok.value)
  end

  local values = {}
  if self:peek().type == "EQ" then
    self:advance()
    table.insert(values, self:parse_expression())
    while self:peek().type == "COMMA" do
      self:advance()
      table.insert(values, self:parse_expression())
    end
  end

  return { type = "let", names = names, values = values }
end

-- expression := pipeline
function Parser:parse_expression()
  return self:parse_pipeline()
end

-- pipeline := logical ("|>" call)*
function Parser:parse_pipeline()
  local left = self:parse_logical()

  while self:peek().type == "PIPE" do
    self:advance() -- consume |>
    local right = self:parse_call()

    if right.type == "call" then
      table.insert(right.args, 1, left)
      left = right
    elseif right.type == "ident" then
      left = { type = "call", callee = right.name, args = { left } }
    else
      error("Pipeline right-hand side must be a function call")
    end
  end

  return left
end

-- logical := comparison (("and" | "or") comparison)*
-- For now, we skip logicals and go straight to comparison

-- logical := comparison
function Parser:parse_logical()
  return self:parse_comparison()
end

-- comparison := addition (("==" | "~=" | "<" | ">" | "<=" | ">=") addition)*
-- For now, skip comparisons

-- comparison := addition
function Parser:parse_comparison()
  return self:parse_addition()
end

-- addition := multiplication (("+" | "-") multiplication)*
function Parser:parse_addition()
  local left = self:parse_multiplication()

  while self:peek().type == "PLUS" or self:peek().type == "MINUS" do
    local op = self:advance()
    local right = self:parse_multiplication()
    left = { type = "binary", op = op.value, left = left, right = right }
  end

  return left
end

-- multiplication := unary (("*" | "/") unary)*
function Parser:parse_multiplication()
  local left = self:parse_unary()

  while self:peek().type == "STAR" or self:peek().type == "SLASH" do
    local op = self:advance()
    local right = self:parse_unary()
    left = { type = "binary", op = op.value, left = left, right = right }
  end

  return left
end

-- unary := ("+" | "-" | "not") unary | call
function Parser:parse_unary()
  local tok = self:peek()
  if tok.type == "MINUS" or tok.type == "PLUS" then
    self:advance()
    local operand = self:parse_unary()
    if tok.type == "MINUS" then
      return { type = "unary", op = "-", operand = operand }
    end
    return operand
  end
  return self:parse_call()
end

-- call := primary postfix*
-- postfix := "(" args? ")" | "." IDENT
function Parser:parse_call()
  local expr = self:parse_primary()

  while true do
    if self:peek().type == "LPAREN" then
      self:advance()
      local args = {}
      if self:peek().type ~= "RPAREN" then
        table.insert(args, self:parse_expression())
        while self:peek().type == "COMMA" do
          self:advance()
          table.insert(args, self:parse_expression())
        end
      end
      self:expect("RPAREN")
      if expr.type == "ident" then
        expr = { type = "call", callee = expr.name, args = args }
      else
        expr = { type = "call", callee = expr, args = args }
      end
    elseif self:peek().type == "DOT" then
      self:advance()
      local field = self:expect("IDENT")
      if expr.type == "ident" then
        expr = { type = "ident", name = expr.name .. "." .. field.value }
      else
        expr = { type = "member", object = expr, field = field.value }
      end
    else
      break
    end
  end

  return expr
end

-- table_field := IDENT "=" expression | expression
function Parser:parse_table_field()
  self:skip_newlines()
  if self:peek().type == "IDENT" and self:peek(1).type == "EQ" then
    local key = self:advance().value
    self:advance()
    local value = self:parse_expression()
    return { type = "field", key = key, value = value }
  else
    local value = self:parse_expression()
    return { type = "field", key = nil, value = value }
  end
end

-- table_constructor := "{" table_field? ("," table_field)* "}"
function Parser:parse_table_constructor()
  self:expect("LBRACE")
  local fields = {}
  self:skip_newlines()
  if self:peek().type ~= "RBRACE" then
    table.insert(fields, self:parse_table_field())
    while self:peek().type == "COMMA" do
      self:advance()
      self:skip_newlines()
      if self:peek().type == "RBRACE" then break end
      table.insert(fields, self:parse_table_field())
    end
  end
  self:expect("RBRACE")
  return { type = "table", fields = fields }
end

-- primary := NUMBER | STRING | IDENT | "(" expression ")" | table_constructor
function Parser:parse_primary()
  local tok = self:peek()

  if tok.type == "NUMBER" then
    self:advance()
    return { type = "number", value = tok.value }
  elseif tok.type == "STRING" then
    self:advance()
    return { type = "string", value = tok.value }
  elseif tok.type == "IDENT" then
    self:advance()
    return { type = "ident", name = tok.value }
  elseif tok.type == "LPAREN" then
    self:advance()
    local expr = self:parse_expression()
    self:expect("RPAREN")
    return expr
  elseif tok.type == "LBRACE" then
    return self:parse_table_constructor()
  else
    error("Unexpected token: " .. tok.type .. " (" .. tostring(tok.value) .. ")")
  end
end

return Parser
