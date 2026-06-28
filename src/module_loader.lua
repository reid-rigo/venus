local Lexer = require("src.lexer")
local Parser = require("src.parser")
local Codegen = require("src.codegen")

local M = {}
local cache = {}

local function compile(source, chunkname)
  local lexer = Lexer.new(source)
  local tokens = lexer:tokenize()
  local parser = Parser.new(tokens)
  local ast = parser:parse_program()
  local codegen = Codegen.new()
  return codegen:generate(ast)
end

local function resolve_path(path)
  local try = {
    path,
    "lib/" .. path,
    "src/" .. path,
  }
  for _, p in ipairs(try) do
    local f = io.open(p, "r")
    if f then
      local content = f:read("*a")
      f:close()
      return content, p
    end
  end
  return nil, nil
end

function M.vs_require(path)
  if cache[path] then
    return cache[path]
  end

  local source, resolved = resolve_path(path)
  if not source then
    error("Cannot find module: " .. path)
  end

  local ok, lua_code = pcall(compile, source, "=" .. resolved)
  if not ok then
    error("Compile error in " .. path .. ": " .. tostring(lua_code))
  end

  local fn, err = load(lua_code, "=" .. resolved, "t")
  if not fn then
    error("Lua error in " .. path .. ": " .. err)
  end

  local ok2, result = pcall(fn)
  if not ok2 then
    error("Runtime error in " .. path .. ": " .. tostring(result))
  end

  cache[path] = result
  return result
end

function M.cache_get(path)
  return cache[path]
end

function M.cache_set(path, value)
  cache[path] = value
end

return M
