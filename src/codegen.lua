local Codegen = {}
Codegen.__index = Codegen

function Codegen.new()
  local self = setmetatable({}, Codegen)
  self.output = {}
  self.indent = 0
  return self
end

function Codegen:emit(line)
  if line ~= "" then
    local indent = string.rep("  ", self.indent)
    table.insert(self.output, indent .. line)
  else
    table.insert(self.output, "")
  end
end

function Codegen:emit_expr(node)
  if node.type == "number" then
    return node.value
  elseif node.type == "string" then
    return node.value
  elseif node.type == "ident" then
    return node.name
  elseif node.type == "member" then
    return self:emit_expr(node.object) .. "." .. node.field
  elseif node.type == "binary" then
    local left = self:emit_expr(node.left)
    local right = self:emit_expr(node.right)
    return "(" .. left .. " " .. node.op .. " " .. right .. ")"
  elseif node.type == "unary" then
    local operand = self:emit_expr(node.operand)
    return "(-" .. operand .. ")"
  elseif node.type == "call" then
    local callee
    if type(node.callee) == "string" then
      callee = node.callee
    else
      callee = self:emit_expr(node.callee)
    end
    local args = {}
    for _, arg in ipairs(node.args) do
      table.insert(args, self:emit_expr(arg))
    end
    return callee .. "(" .. table.concat(args, ", ") .. ")"
  elseif node.type == "let" then
    local parts = {}
    for _, name in ipairs(node.names) do
      table.insert(parts, name)
    end
    local lhs = table.concat(parts, ", ")
    if #node.values > 0 then
      local rhs_parts = {}
      for _, val in ipairs(node.values) do
        table.insert(rhs_parts, self:emit_expr(val))
      end
      return "local " .. lhs .. " = " .. table.concat(rhs_parts, ", ")
    else
      return "local " .. lhs
    end
  elseif node.type == "fun" then
    self:emit("local function " .. node.name .. "(" .. table.concat(node.params, ", ") .. ")")
    self.indent = self.indent + 1
    for i, stmt in ipairs(node.body) do
      local line = self:emit_expr(stmt)
      if line ~= "" then
        if i == #node.body and stmt.type ~= "let" then
          line = "return " .. line
        end
        self:emit(line)
      end
    end
    self.indent = self.indent - 1
    self:emit("end")
    return ""
  elseif node.type == "table" then
    local parts = {}
    for _, field in ipairs(node.fields) do
      if field.key then
        table.insert(parts, field.key .. " = " .. self:emit_expr(field.value))
      else
        table.insert(parts, self:emit_expr(field.value))
      end
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
  elseif node.type == "program" then
    for _, stmt in ipairs(node.body) do
      local line = self:emit_expr(stmt)
      if line ~= "" then
        self:emit(line)
      end
    end
    return ""
  else
    error("Unknown node type: " .. node.type)
  end
end

function Codegen:generate(ast)
  self:emit_expr(ast)
  return table.concat(self.output, "\n")
end

return Codegen
