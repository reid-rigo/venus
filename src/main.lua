local Lexer = require("src.lexer")
local Parser = require("src.parser")
local Codegen = require("src.codegen")
local module_loader = require("src.module_loader")
List = require("src.list")
Table = require("src.table")
String = require("src.string")
Math = require("src.math")

_G.vs_require = module_loader.vs_require

local function merge_ext(base, ext)
  for k, v in pairs(ext) do
    base[k] = v
  end
end

local ok_list, list_ext = pcall(vs_require, "src/list.vs")
if ok_list then merge_ext(List, list_ext) end

local ok_table, table_ext = pcall(vs_require, "src/table.vs")
if ok_table then merge_ext(Table, table_ext) end

local ok_string, string_ext = pcall(vs_require, "src/string.vs")
if ok_string then merge_ext(String, string_ext) end

local orig_tostring = tostring
_G.tostring = function(v)
  if type(v) == "table" then
    local n = #v
    if n > 0 then
      local parts = {}
      for i = 1, n do
        parts[i] = tostring(v[i])
      end
      return "[" .. table.concat(parts, " ") .. "]"
    end
    local has_keys = false
    for _ in pairs(v) do
      has_keys = true
      break
    end
    if not has_keys then
      return "[]"
    end
    local parts = {}
    for k in pairs(v) do
      if type(k) == "string" then
        table.insert(parts, k .. ": " .. tostring(v[k]))
      else
        table.insert(parts, tostring(k) .. ": " .. tostring(v[k]))
      end
    end
    return "{" .. table.concat(parts, " ") .. "}"
  end
  return orig_tostring(v)
end

local function compile(source)
  local lexer = Lexer.new(source)
  local tokens = lexer:tokenize()
  local parser = Parser.new(tokens)
  local ast = parser:parse_program()
  local codegen = Codegen.new()
  return codegen:generate(ast)
end

local function load_stmt(lua_code, chunkname)
  return load(lua_code, chunkname or "(venus)", "t")
end

local function load_expr(lua_code, chunkname)
  local fn, err = load("return " .. lua_code, chunkname or "(venus)", "t")
  if fn then return fn end
  -- fallback: try as statement
  return load(lua_code, chunkname or "(venus)", "t")
end

local function run_lua(loader, lua_code, chunkname, show_result)
  local fn, err = loader(lua_code, chunkname)
  if not fn then
    io.stderr:write("Lua error: " .. err .. "\n")
    os.exit(1)
  end
  local ok, ret = pcall(fn)
  if not ok then
    io.stderr:write("Runtime error: " .. tostring(ret) .. "\n")
    os.exit(1)
  end
  if show_result and ret ~= nil then
    print(ret)
  end
end

local function compile_and_run(source, filename)
  local ok, result = pcall(compile, source)
  if not ok then
    io.stderr:write("Compile error: " .. result .. "\n")
    os.exit(1)
  end
  io.write(result)
  if #result > 0 and result:sub(-1) ~= "\n" then
    io.write("\n")
  end
  return result
end

local function usage()
  io.stderr:write("Usage: vs [options] <file.vs>\n")
  io.stderr:write("Options:\n")
  io.stderr:write("  -c           Print compiled Lua only (do not run)\n")
  io.stderr:write("  -e <code>    Execute Venus code from string\n")
  io.stderr:write("  --help       Show this help\n")
  os.exit(1)
end

local args = arg or {}
local filename
local compile_only = false
local inline_code = false

local i = 1
while i <= #args do
  local a = args[i]
  if a == "-c" then
    compile_only = true
  elseif a == "-e" then
    i = i + 1
    inline_code = args[i]
    if not inline_code then usage() end
  elseif a == "--help" then
    usage()
  elseif a:sub(1, 1) == "-" then
    io.stderr:write("Unknown option: " .. a .. "\n")
    usage()
  else
    filename = a
  end
  i = i + 1
end

if inline_code then
  local ok, lua_code = pcall(compile, inline_code)
  if not ok then
    io.stderr:write("Compile error: " .. lua_code .. "\n")
    os.exit(1)
  end
  if compile_only then
    io.write(lua_code)
    if lua_code:sub(-1) ~= "\n" then io.write("\n") end
  else
    run_lua(load_expr, lua_code, "(venus)", true)
  end
elseif filename then
  local f = io.open(filename, "r")
  if not f then
    io.stderr:write("Error: could not open file " .. filename .. "\n")
    os.exit(1)
  end
  local source = f:read("*a")
  f:close()
  local lua_code = compile_and_run(source, filename)
  if not compile_only then
    io.write("\n")
    run_lua(load_stmt, lua_code, "=" .. filename, false)
  end
else
  io.write("Venus REPL (type 'exit' to quit)\n")
  while true do
    io.write("> ")
    io.flush()
    local line = io.read()
    if not line or line == "exit" then break end
    local ok, result = pcall(compile, line)
    if ok then
      local fn, err = load_expr(result, "(venus)")
      if fn then
        local ok2, ret = pcall(fn)
        if ok2 then
          if ret ~= nil then
            print(ret)
          end
        else
          print("Runtime error: " .. tostring(ret))
        end
      else
        print("Lua error: " .. tostring(err))
      end
    else
      print("Error: " .. tostring(result))
    end
  end
end
