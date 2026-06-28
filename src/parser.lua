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

-- statement := fun_decl | let_decl | if_expr | expression
function Parser:parse_statement()
  if self:peek().type == "FN" and self:peek(1).type == "IDENT" then
    return self:parse_fun_decl()
  elseif self:peek().type == "LET" then
    return self:parse_let_decl()
  elseif self:peek().type == "IF" then
    return self:parse_if_expr()
  end
  return self:parse_expression()
end

-- fun_decl := "fn" IDENT "(" fn_param ("," fn_param)* ")" "{" body "}"
-- fn_param := IDENT | NUMBER | STRING
function Parser:parse_fun_decl()
  self:expect("FN")
  local name = self:expect("IDENT").value
  self:expect("LPAREN")
  local params = {}
  if self:peek().type ~= "RPAREN" then
    table.insert(params, self:parse_fn_param())
    while self:peek().type == "COMMA" do
      self:advance()
      table.insert(params, self:parse_fn_param())
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
  return { type = "fn", name = name, params = params, body = body }
end

-- lambda := "fn" "(" params? ")" "{" body "}"
function Parser:parse_lambda()
  self:expect("FN")
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
  return { type = "lambda", params = params, body = body }
end

function Parser:parse_block()
  self:expect("LBRACE")
  self:skip_newlines()
  local body = {}
  while self:peek().type ~= "RBRACE" and self:peek().type ~= "EOF" do
    local stmt = self:parse_statement()
    table.insert(body, stmt)
    self:skip_newlines()
  end
  self:expect("RBRACE")
  return body
end

-- if_expr := "if" expression block ("else" "if" expression block)* ("else" block)?
function Parser:parse_if_expr()
  self:expect("IF")
  local condition = self:parse_expression()
  self:skip_newlines()
  local body = self:parse_block()

  local elifs = {}
  while self:peek().type == "ELSE" and self:peek(1).type == "IF" do
    self:advance()
    self:advance()
    local elif_condition = self:parse_expression()
    self:skip_newlines()
    table.insert(elifs, { condition = elif_condition, body = self:parse_block() })
  end

  local else_body = nil
  if self:peek().type == "ELSE" then
    self:advance()
    self:skip_newlines()
    else_body = self:parse_block()
  end

  return { type = "if", condition = condition, body = body, elifs = elifs, else_body = else_body }
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
    self:advance()
    local right = self:parse_call()

    if right.type == "call" then
      local has_placeholder = false
      for _, arg in ipairs(right.args) do
        if arg.type == "placeholder" then
          has_placeholder = true
          break
        end
      end
      if has_placeholder then
        for i, arg in ipairs(right.args) do
          if arg.type == "placeholder" then
            right.args[i] = left
          end
        end
      else
        table.insert(right.args, 1, left)
      end
      left = right
    elseif right.type == "ident" then
      left = { type = "call", callee = right.name, args = { left } }
    elseif right.type == "lambda" then
      left = { type = "call", callee = right, args = { left } }
    else
      error("Pipeline right-hand side must be a function call")
    end
  end

  return left
end

-- logical := comparison (("and" | "or") comparison)*
function Parser:parse_logical()
  local left = self:parse_comparison()

  while self:peek().type == "AND" or self:peek().type == "OR" do
    local tok = self:advance()
    local right = self:parse_comparison()
    left = { type = "binary", op = tok.value, left = left, right = right }
  end

  return left
end

-- comparison := addition (("==" | "!=" | "<" | ">" | "<=" | ">=") addition)*
function Parser:parse_comparison()
  local left = self:parse_addition()

  while self:peek().type == "EQEQ" or self:peek().type == "BANGEQ"
    or self:peek().type == "LT" or self:peek().type == "GT"
    or self:peek().type == "LE" or self:peek().type == "GE" do
    local tok = self:advance()
    local right = self:parse_addition()
    left = { type = "binary", op = tok.value, left = left, right = right }
  end

  return left
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

-- list_constructor := "[" expression* "]"
function Parser:parse_list_constructor()
  self:expect("LBRACKET")
  local values = {}
  self:skip_newlines()
  while self:peek().type ~= "RBRACKET" and self:peek().type ~= "EOF" do
    table.insert(values, self:parse_expression())
    self:skip_newlines()
  end
  self:expect("RBRACKET")
  return { type = "list", values = values }
end

-- map_constructor := "{" (STRING | IDENT expression)* "}"
function Parser:parse_map_constructor()
  self:expect("LBRACE")
  local fields = {}
  self:skip_newlines()
  while self:peek().type ~= "RBRACE" and self:peek().type ~= "EOF" do
    local tok = self:peek()
    if tok.type == "STRING" then
      local raw = self:advance().value
      local key = raw:sub(2, -2)
      self:skip_newlines()
      local value = self:parse_expression()
      table.insert(fields, { type = "field", key = key, value = value })
    elseif tok.type == "IDENT" then
      local key = self:advance().value
      self:skip_newlines()
      local value = self:parse_expression()
      table.insert(fields, { type = "field", key = key, value = value })
    else
      error("Expected string key in map literal but got " .. tok.type)
    end
    self:skip_newlines()
  end
  self:expect("RBRACE")
  return { type = "table", fields = fields }
end

-- match_expr := "match" expression "{" (pattern "->" expression)* "}"
function Parser:parse_match_expression()
  self:expect("MATCH")
  local value = self:parse_expression()
  self:skip_newlines()
  self:expect("LBRACE")
  self:skip_newlines()
  local arms = {}
  while self:peek().type ~= "RBRACE" and self:peek().type ~= "EOF" do
    local pattern = self:parse_pattern()
    self:skip_newlines()
    self:expect("ARROW")
    self:skip_newlines()
    local body = self:parse_expression()
    table.insert(arms, { pattern = pattern, body = body })
    self:skip_newlines()
    if self:peek().type == "COMMA" then
      self:advance()
      self:skip_newlines()
    end
  end
  self:expect("RBRACE")
  return { type = "match", value = value, arms = arms }
end

function Parser:parse_fn_param()
  local tok = self:peek()
  if tok.type == "IDENT" then
    self:advance()
    return { type = "param", name = tok.value }
  elseif tok.type == "NUMBER" then
    self:advance()
    return { type = "param", value = tok.value, is_literal = true }
  elseif tok.type == "STRING" then
    self:advance()
    return { type = "param", value = tok.value, is_literal = true }
  else
    error("Expected parameter name or literal but got " .. tok.type)
  end
end

-- pattern := "_" | NUMBER | STRING | IDENT
function Parser:parse_pattern()
  local tok = self:peek()
  if tok.type == "UNDERSCORE" then
    self:advance()
    return { type = "wildcard" }
  elseif tok.type == "NUMBER" then
    self:advance()
    return { type = "number", value = tok.value }
  elseif tok.type == "STRING" then
    self:advance()
    return { type = "string", value = tok.value }
  elseif tok.type == "IDENT" then
    self:advance()
    return { type = "ident", name = tok.value }
  else
    error("Unexpected token in pattern: " .. tok.type)
  end
end

-- primary := NUMBER | STRING | IDENT | "(" expression ")" | list_constructor | map_constructor | match_expr
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
  elseif tok.type == "FN" then
    return self:parse_lambda()
  elseif tok.type == "LBRACKET" then
    return self:parse_list_constructor()
  elseif tok.type == "LBRACE" then
    return self:parse_map_constructor()
  elseif tok.type == "MATCH" then
    return self:parse_match_expression()
  elseif tok.type == "UNDERSCORE" then
    self:advance()
    return { type = "placeholder" }
  else
    error("Unexpected token: " .. tok.type .. " (" .. tostring(tok.value) .. ")")
  end
end

return Parser
