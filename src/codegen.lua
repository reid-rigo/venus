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
  elseif node.type == "lambda" then
    local saved_output = self.output
    self.output = {}
    local saved_indent = self.indent

    self:emit("function(" .. table.concat(node.params, ", ") .. ")")
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

    local result = table.concat(self.output, "\n")
    self.output = saved_output
    self.indent = saved_indent
    return result
  elseif node.type == "fn" then
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
  elseif node.type == "list" then
    local parts = {}
    for _, val in ipairs(node.values) do
      table.insert(parts, self:emit_expr(val))
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
  elseif node.type == "table" then
    local parts = {}
    for _, field in ipairs(node.fields) do
      table.insert(parts, "[\"" .. field.key .. "\"] = " .. self:emit_expr(field.value))
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
  elseif node.type == "match" then
    self.match_counter = (self.match_counter or 0) + 1
    local tmp = "_m_" .. self.match_counter
    local value_code = self:emit_expr(node.value)

    local parts = {}
    table.insert(parts, "(function()")
    table.insert(parts, "  local " .. tmp .. " = " .. value_code)

    local has_if = false

    for _, arm in ipairs(node.arms) do
      local pat = arm.pattern
      local body_code = self:emit_expr(arm.body)

      if pat.type == "wildcard" then
        local indent = has_if and "    " or "  "
        if has_if then
          table.insert(parts, "  else")
        end
        table.insert(parts, indent .. "return " .. body_code)
        break
      elseif pat.type == "ident" then
        local indent = has_if and "    " or "  "
        if has_if then
          table.insert(parts, "  else")
        end
        table.insert(parts, indent .. "local " .. pat.name .. " = " .. tmp)
        table.insert(parts, indent .. "return " .. body_code)
        break
      else
        local pat_code = self:emit_expr(pat)
        if not has_if then
          table.insert(parts, "  if " .. tmp .. " == " .. pat_code .. " then")
          has_if = true
        else
          table.insert(parts, "  elseif " .. tmp .. " == " .. pat_code .. " then")
        end
        table.insert(parts, "    return " .. body_code)
      end
    end

    if has_if then
      table.insert(parts, "  end")
    end
    table.insert(parts, "end)()")

    return table.concat(parts, "\n")
  elseif node.type == "placeholder" then
    error("placeholder outside pipeline context")
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
