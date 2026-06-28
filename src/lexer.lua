local Lexer = {}
Lexer.__index = Lexer

local Token = {
  NUMBER = "NUMBER",
  STRING = "STRING",
  IDENT  = "IDENT",
  PIPE   = "PIPE",
  LPAREN = "LPAREN",
  RPAREN = "RPAREN",
  PLUS   = "PLUS",
  MINUS  = "MINUS",
  STAR   = "STAR",
  SLASH  = "SLASH",
  EQ     = "EQ",
  EQEQ   = "EQEQ",
  BANGEQ = "BANGEQ",
  BANG    = "BANG",
  LT     = "LT",
  GT     = "GT",
  LE     = "LE",
  GE     = "GE",
  COMMA  = "COMMA",
  DOT    = "DOT",
  QDOT   = "QDOT",
  NEWLINE = "NEWLINE",
  LET    = "LET",
  FN     = "FN",
  MATCH  = "MATCH",
  ARROW  = "ARROW",
  LBRACE = "LBRACE",
  RBRACE = "RBRACE",
  LBRACKET = "LBRACKET",
  RBRACKET = "RBRACKET",
  UNDERSCORE = "UNDERSCORE",
  IF     = "IF",
  ELSE   = "ELSE",
  AND    = "AND",
  OR     = "OR",
  NIL    = "NIL",
  TRUE   = "TRUE",
  FALSE  = "FALSE",
  IMPORT = "IMPORT",
  EXPORT = "EXPORT",
  EOF    = "EOF",
}
Lexer.Token = Token

local function is_alpha(c)
  return c and c:match("^[%a_]$") ~= nil
end

local function is_alnum(c)
  return c and c:match("^[%w_]$") ~= nil
end

local function is_digit(c)
  return c and c:match("^%d$") ~= nil
end

local keywords = {
  ["let"] = "LET",
  ["fn"] = "FN",
  ["match"] = "MATCH",
  ["if"] = "IF",
  ["else"] = "ELSE",
  ["and"] = "AND",
  ["or"] = "OR",
  ["nil"] = "NIL",
  ["true"] = "TRUE",
  ["false"] = "FALSE",
  ["import"] = "IMPORT",
  ["export"] = "EXPORT",
}

function Lexer.new(source)
  local self = setmetatable({}, Lexer)
  self.source = source
  self.pos = 1
  self.len = #source
  self.tokens = {}
  return self
end

function Lexer:peek(offset)
  offset = offset or 0
  local idx = self.pos + offset
  if idx > self.len then return nil end
  return self.source:sub(idx, idx)
end

function Lexer:advance()
  local c = self.source:sub(self.pos, self.pos)
  self.pos = self.pos + 1
  return c
end

function Lexer:skip_whitespace()
  while self.pos <= self.len do
    local c = self:peek()
    if c == " " or c == "\t" or c == "\r" then
      self:advance()
    elseif c == "/" and self:peek(1) == "/" then
      while self.pos <= self.len do
        if self:advance() == "\n" then break end
      end
    else
      break
    end
  end
end

function Lexer:read_number()
  local start = self.pos
  while is_digit(self:peek()) do self:advance() end
  if self:peek() == "." and is_digit(self:peek(1)) then
    self:advance()
    while is_digit(self:peek()) do self:advance() end
  end
  return self.source:sub(start, self.pos - 1)
end

function Lexer:read_interp_expr()
  local buf = {}
  local depth = 1
  while self.pos <= self.len do
    local c = self:advance()
    if c == "{" then
      depth = depth + 1
      table.insert(buf, c)
    elseif c == "}" then
      depth = depth - 1
      if depth == 0 then break end
      table.insert(buf, c)
    elseif c == '"' or c == "'" then
      table.insert(buf, c)
      local str_end = c
      while self.pos <= self.len do
        local sc = self:advance()
        table.insert(buf, sc)
        if sc == "\\" then
          local esc = self:advance()
          table.insert(buf, esc or "")
        elseif sc == str_end then
          break
        end
      end
    else
      table.insert(buf, c)
    end
  end
  return table.concat(buf)
end

function Lexer:read_string()
  local start = self.pos
  local quote = self:advance()
  if quote == "'" then
    while self.pos <= self.len do
      local c = self:advance()
      if c == "\\" then
        self:advance()
      elseif c == quote then
        break
      end
    end
    return self.source:sub(start, self.pos - 1)
  end

  local parts = {}
  local buf = {}

  local function flush()
    if #buf > 0 then
      table.insert(parts, { type = "text", value = table.concat(buf) })
      buf = {}
    end
  end

  while self.pos <= self.len do
    local c = self:advance()
    if c == "\\" then
      table.insert(buf, c)
      local next = self:advance()
      table.insert(buf, next or "")
    elseif c == "#" and self:peek() == "{" then
      flush()
      self:advance()
      table.insert(parts, { type = "expr", source = self:read_interp_expr() })
    elseif c == quote then
      flush()
      local has_expr = false
      for _, part in ipairs(parts) do
        if part.type == "expr" then
          has_expr = true
          break
        end
      end
      if has_expr then
        return { parts = parts }
      end
      return self.source:sub(start, self.pos - 1)
    else
      table.insert(buf, c)
    end
  end

  return self.source:sub(start, self.pos - 1)
end

function Lexer:read_multiline_string()
  local start = self.pos
  self:advance(); self:advance(); self:advance()
  local parts = {}
  local buf = {}

  local function flush()
    if #buf > 0 then
      table.insert(parts, { type = "text", value = table.concat(buf) })
      buf = {}
    end
  end

  while self.pos <= self.len do
    local c = self:advance()
    if c == "#" and self:peek() == "{" then
      flush()
      self:advance()
      table.insert(parts, { type = "expr", source = self:read_interp_expr() })
    elseif c == '"' and self:peek() == '"' and self:peek(1) == '"' then
      flush()
      self:advance(); self:advance()
      local has_expr = false
      for _, part in ipairs(parts) do
        if part.type == "expr" then
          has_expr = true
          break
        end
      end
      if has_expr then
        return { parts = parts }
      end
      return self.source:sub(start, self.pos - 1)
    else
      table.insert(buf, c)
    end
  end

  return self.source:sub(start, self.pos - 1)
end

function Lexer:read_ident()
  local start = self.pos
  while is_alnum(self:peek()) do self:advance() end
  return self.source:sub(start, self.pos - 1)
end

function Lexer:tokenize()
  while self.pos <= self.len do
    self:skip_whitespace()
    if self.pos > self.len then break end

    local c = self:peek()
    local c2 = self:peek(1)

    if c == "\n" then
      self:advance()
      table.insert(self.tokens, { type = Token.NEWLINE, value = "\\n" })
    elseif c == "|" and c2 == ">" then
      self:advance(); self:advance()
      table.insert(self.tokens, { type = Token.PIPE, value = "|>" })
    elseif c == "(" then
      self:advance()
      table.insert(self.tokens, { type = Token.LPAREN, value = "(" })
    elseif c == ")" then
      self:advance()
      table.insert(self.tokens, { type = Token.RPAREN, value = ")" })
    elseif c == "+" then
      self:advance()
      table.insert(self.tokens, { type = Token.PLUS, value = "+" })
    elseif c == "-" and c2 == ">" then
      self:advance(); self:advance()
      table.insert(self.tokens, { type = Token.ARROW, value = "->" })
    elseif c == "-" then
      self:advance()
      table.insert(self.tokens, { type = Token.MINUS, value = "-" })
    elseif c == "*" then
      self:advance()
      table.insert(self.tokens, { type = Token.STAR, value = "*" })
    elseif c == "/" then
      self:advance()
      table.insert(self.tokens, { type = Token.SLASH, value = "/" })
    elseif c == "=" and c2 == "=" then
      self:advance(); self:advance()
      table.insert(self.tokens, { type = Token.EQEQ, value = "==" })
    elseif c == "=" then
      self:advance()
      table.insert(self.tokens, { type = Token.EQ, value = "=" })
    elseif c == "!" and c2 == "=" then
      self:advance(); self:advance()
      table.insert(self.tokens, { type = Token.BANGEQ, value = "!=" })
    elseif c == "!" then
      self:advance()
      table.insert(self.tokens, { type = Token.BANG, value = "!" })
    elseif c == "<" and c2 == "=" then
      self:advance(); self:advance()
      table.insert(self.tokens, { type = Token.LE, value = "<=" })
    elseif c == "<" then
      self:advance()
      table.insert(self.tokens, { type = Token.LT, value = "<" })
    elseif c == ">" and c2 == "=" then
      self:advance(); self:advance()
      table.insert(self.tokens, { type = Token.GE, value = ">=" })
    elseif c == ">" then
      self:advance()
      table.insert(self.tokens, { type = Token.GT, value = ">" })
    elseif c == "," then
      self:advance()
      table.insert(self.tokens, { type = Token.COMMA, value = "," })
    elseif c == "{" then
      self:advance()
      table.insert(self.tokens, { type = Token.LBRACE, value = "{" })
    elseif c == "}" then
      self:advance()
      table.insert(self.tokens, { type = Token.RBRACE, value = "}" })
    elseif c == "[" then
      self:advance()
      table.insert(self.tokens, { type = Token.LBRACKET, value = "[" })
    elseif c == "]" then
      self:advance()
      table.insert(self.tokens, { type = Token.RBRACKET, value = "]" })
    elseif c == "?" and c2 == "." then
      self:advance(); self:advance()
      table.insert(self.tokens, { type = Token.QDOT, value = "?." })
    elseif c == "." then
      if c2 and is_digit(c2) then
        local num = self:read_number()
        table.insert(self.tokens, { type = Token.NUMBER, value = num })
      else
        self:advance()
        table.insert(self.tokens, { type = Token.DOT, value = "." })
      end
    elseif c == '"' and c2 == '"' and self:peek(2) == '"' then
      local str = self:read_multiline_string()
      table.insert(self.tokens, { type = Token.STRING, value = str })
    elseif c == '"' or c == "'" then
      local str = self:read_string()
      table.insert(self.tokens, { type = Token.STRING, value = str })
    elseif is_digit(c) then
      local num = self:read_number()
      table.insert(self.tokens, { type = Token.NUMBER, value = num })
    elseif c == "_" then
      self:advance()
      table.insert(self.tokens, { type = Token.UNDERSCORE, value = "_" })
    elseif is_alpha(c) then
      local ident = self:read_ident()
      local kw_type = keywords[ident]
      if kw_type then
        table.insert(self.tokens, { type = Token[kw_type], value = ident })
      else
        table.insert(self.tokens, { type = Token.IDENT, value = ident })
      end
    else
      error("Unexpected character: " .. c)
    end
  end

  table.insert(self.tokens, { type = Token.EOF, value = nil })
  return self.tokens
end

return Lexer
