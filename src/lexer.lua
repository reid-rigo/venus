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
  COMMA  = "COMMA",
  DOT    = "DOT",
  NEWLINE = "NEWLINE",
  LET    = "LET",
  FUN    = "FUN",
  LBRACE = "LBRACE",
  RBRACE = "RBRACE",
  LBRACKET = "LBRACKET",
  RBRACKET = "RBRACKET",
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
  ["fun"] = "FUN",
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
    elseif c == "-" and self:peek(1) == "-" then
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

function Lexer:read_string()
  local start = self.pos
  local quote = self:advance()
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
    elseif c == "-" then
      self:advance()
      table.insert(self.tokens, { type = Token.MINUS, value = "-" })
    elseif c == "*" then
      self:advance()
      table.insert(self.tokens, { type = Token.STAR, value = "*" })
    elseif c == "/" then
      self:advance()
      table.insert(self.tokens, { type = Token.SLASH, value = "/" })
    elseif c == "=" then
      self:advance()
      table.insert(self.tokens, { type = Token.EQ, value = "=" })
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
    elseif c == "." then
      if c2 and is_digit(c2) then
        local num = self:read_number()
        table.insert(self.tokens, { type = Token.NUMBER, value = num })
      else
        self:advance()
        table.insert(self.tokens, { type = Token.DOT, value = "." })
      end
    elseif c == '"' or c == "'" then
      local str = self:read_string()
      table.insert(self.tokens, { type = Token.STRING, value = str })
    elseif is_digit(c) then
      local num = self:read_number()
      table.insert(self.tokens, { type = Token.NUMBER, value = num })
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
