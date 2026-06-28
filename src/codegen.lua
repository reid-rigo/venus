local Codegen = {}
Codegen.__index = Codegen

function Codegen.new()
  local self = setmetatable({}, Codegen)
  self.output = {}
  self.indent = 0
  return self
end

function Codegen:has_literal_params(fn_node)
  for _, p in ipairs(fn_node.params) do
    if p.is_literal then return true end
  end
  return false
end

function Codegen:preprocess(ast)
  if ast.type ~= "program" then return ast end

  local groups = {}

  for _, stmt in ipairs(ast.body) do
    if stmt.type == "fn" then
      local name = stmt.name
      if not groups[name] then
        groups[name] = {}
      end
      groups[name][#groups[name] + 1] = stmt
    end
  end

  local new_body = {}
  local emitted = {}

  for _, stmt in ipairs(ast.body) do
    if stmt.type == "fn" then
      local name = stmt.name
      if not emitted[name] then
        emitted[name] = true
        new_body[#new_body + 1] = { type = "overloaded_fn", name = name, overloads = groups[name] }
      end
    else
      new_body[#new_body + 1] = stmt
    end
  end

  ast.body = new_body
  return ast
end

function Codegen:emit_fn_body(body, return_last)
  for i, stmt in ipairs(body) do
    local line = self:emit_expr(stmt)
    if line ~= "" then
      if return_last and i == #body and stmt.type ~= "let" then
        line = "return " .. line
      end
      self:emit(line)
    end
  end
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
    local param_names = {}
    for _, p in ipairs(node.params) do
      param_names[#param_names + 1] = p.name
    end
    self:emit("local function " .. node.name .. "(" .. table.concat(param_names, ", ") .. ")")
    self.indent = self.indent + 1
    self:emit_fn_body(node.body, true)
    self.indent = self.indent - 1
    self:emit("end")
    return ""
  elseif node.type == "overloaded_fn" then
    return self:emit_overloaded_fn(node)
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

function Codegen:emit_overloaded_fn(node)
  local name = node.name
  local overloads = node.overloads

  if #overloads == 1 and not self:has_literal_params(overloads[1]) then
    local param_names = {}
    for _, p in ipairs(overloads[1].params) do
      param_names[#param_names + 1] = p.name
    end
    local sig = table.concat(param_names, ", ")
    self:emit("local function " .. name .. "(" .. sig .. ")")
    self.indent = self.indent + 1
    self:emit_fn_body(overloads[1].body, true)
    self.indent = self.indent - 1
    self:emit("end")
    return ""
  end

  local catch_all
  for _, overload in ipairs(overloads) do
    if not self:has_literal_params(overload) then
      catch_all = overload
      break
    end
  end

  local use_named = catch_all and (function()
    for _, overload in ipairs(overloads) do
      if #overload.params ~= #catch_all.params then
        return false
      end
    end
    return true
  end)()

  if use_named then
    local param_names = {}
    for _, p in ipairs(catch_all.params) do
      param_names[#param_names + 1] = p.name
    end
    local sig = table.concat(param_names, ", ")
    self:emit("local function " .. name .. "(" .. sig .. ")")
    self.indent = self.indent + 1

    local has_chain = false
    for idx, overload in ipairs(overloads) do
      if self:has_literal_params(overload) then
        local conditions = {}
        for j, p in ipairs(overload.params) do
          if p.is_literal then
            conditions[#conditions + 1] = param_names[j] .. " == " .. p.value
          end
        end
        local cond = table.concat(conditions, " and ")
        if not has_chain then
          self:emit("if " .. cond .. " then")
          has_chain = true
        else
          self:emit("elseif " .. cond .. " then")
        end

        self.indent = self.indent + 1
        for j, p in ipairs(overload.params) do
          if not p.is_literal then
            self:emit("local " .. p.name .. " = " .. param_names[j])
          end
        end
        self:emit_fn_body(overload.body, true)
        self.indent = self.indent - 1
      end
    end

    if has_chain then
      self:emit("else")
      self.indent = self.indent + 1
      self:emit_fn_body(catch_all.body, true)
      self.indent = self.indent - 1
      self:emit("end")
    end

    self.indent = self.indent - 1
    self:emit("end")
    return ""
  end

  self:emit("local function " .. name .. "(...)")
  self.indent = self.indent + 1

  local has_chain = false
  for idx, overload in ipairs(overloads) do
    local has_literal = self:has_literal_params(overload)

    if has_literal then
      local conditions = {}
      for j, p in ipairs(overload.params) do
        if p.is_literal then
          conditions[#conditions + 1] = "select(" .. j .. ", ...) == " .. p.value
        end
      end
      local cond = table.concat(conditions, " and ")
      if not has_chain then
        self:emit("if " .. cond .. " then")
        has_chain = true
      else
        self:emit("elseif " .. cond .. " then")
      end
    else
      if has_chain then
        self:emit("else")
      end
    end

    self.indent = self.indent + 1
    for j, p in ipairs(overload.params) do
      if not p.is_literal then
        self:emit("local " .. p.name .. " = select(" .. j .. ", ...)")
      end
    end
    self:emit_fn_body(overload.body, true)
    self.indent = self.indent - 1
  end

  if has_chain then
    self:emit("end")
  end
  self.indent = self.indent - 1
  self:emit("end")
  return ""
end

function Codegen:generate(ast)
  self:preprocess(ast)
  self:emit_expr(ast)
  return table.concat(self.output, "\n")
end

return Codegen
