local Lexer = require("src.lexer")
local Parser = require("src.parser")
local Codegen = require("src.codegen")

local Bundler = {}

local function compile(source, chunkname)
  local lexer = Lexer.new(source)
  local tokens = lexer:tokenize()
  local parser = Parser.new(tokens)
  local ast = parser:parse_program()
  local codegen = Codegen.new()
  return codegen:generate(ast)
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local function resolve_path(path)
  local try = {
    path,
    "lib/" .. path,
    "src/" .. path,
    "test/" .. path,
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

function Bundler.find_luajit()
  local handle = io.popen("which luajit 2>/dev/null")
  if handle then
    local path = handle:read("*l")
    handle:close()
    if path and path ~= "" then
      return path
    end
  end

  local try = {
    "/usr/bin/luajit",
    "/usr/local/bin/luajit",
    "/opt/homebrew/bin/luajit",
  }
  for _, p in ipairs(try) do
    local f = io.open(p, "r")
    if f then
      f:close()
      return p
    end
  end

  return nil
end

function Bundler.find_luajit_headers()
  local try = {
    "/usr/include/luajit-2.1",
    "/usr/include/luajit-2.0",
    "/usr/local/include/luajit-2.1",
    "/usr/local/include/luajit-2.0",
    "/opt/homebrew/include/luajit-2.1",
    "/opt/homebrew/include/luajit-2.0",
  }

  local handle = io.popen("luajit -e 'print(jit.version_num)' 2>/dev/null")
  if handle then
    local version = handle:read("*l")
    handle:close()
    if version then
      local major = math.floor(version / 10000)
      local minor = math.floor((version % 10000) / 100)
      table.insert(try, 1, "/usr/include/luajit-" .. major .. "." .. minor)
      table.insert(try, 1, "/usr/local/include/luajit-" .. major .. "." .. minor)
    end
  end

  local handle = io.popen("luajit -e 'print(jit.os)' 2>/dev/null")
  local os_name = "unknown"
  if handle then
    os_name = handle:read("*l") or "unknown"
    handle:close()
  end

  local home = os.getenv("HOME") or ""
  if home ~= "" then
    local mise_include = home .. "/.local/share/mise/installs/luajit/latest/include"
    table.insert(try, 1, mise_include .. "/luajit-2.1")
    table.insert(try, 1, mise_include .. "/luajit-2.0")
  end

  for _, p in ipairs(try) do
    local f = io.open(p .. "/lua.h", "r")
    if f then
      f:close()
      return p
    end
  end
  return nil
end

function Bundler.find_luajit_lib()
  local try = {
    "/usr/lib",
    "/usr/local/lib",
    "/opt/homebrew/lib",
  }

  local home = os.getenv("HOME") or ""
  if home ~= "" then
    local mise_lib = home .. "/.local/share/mise/installs/luajit/latest/lib"
    table.insert(try, 1, mise_lib)
  end

  for _, p in ipairs(try) do
    local f = io.open(p .. "/libluajit-5.1.dylib", "r")
    if f then
      f:close()
      return p, "luajit-5.1"
    end
    f = io.open(p .. "/libluajit-5.1.so", "r")
    if f then
      f:close()
      return p, "luajit-5.1"
    end
    f = io.open(p .. "/libluajit.a", "r")
    if f then
      f:close()
      return p, "luajit"
    end
  end
  return nil, nil
end

function Bundler.collect_modules(entry_file)
  local visited = {}
  local modules = {}
  local lua_modules = {}

  local function add_lua_module(name, source)
    if lua_modules[name] then return end
    lua_modules[name] = source
  end

  local function process_vs_file(path)
    if visited[path] then return end
    visited[path] = true

    local source = read_file(path)
    if not source then
      error("Cannot read file: " .. path)
    end

    local lua_code = compile(source, "=" .. path)
    modules[path] = lua_code

    local lexer = Lexer.new(source)
    local tokens = lexer:tokenize()
    local parser = Parser.new(tokens)
    local ast = parser:parse_program()

    local function walk_ast(node)
      if not node or type(node) ~= "table" then return end

      if node.type == "import" then
        local import_path = node.path
        if import_path:match("%.vs$") then
          local content, resolved = resolve_path(import_path)
          if resolved then
            process_vs_file(resolved)
          end
        else
          local lua_source = read_file("src/" .. import_path .. ".lua")
          if lua_source then
            add_lua_module(import_path, lua_source)
          end
        end
      end

      for _, child in ipairs(node) do
        if type(child) == "table" then
          walk_ast(child)
        end
      end

      if node.body then
        for _, child in ipairs(node.body) do
          walk_ast(child)
        end
      end

      if node.values then
        for _, child in ipairs(node.values) do
          walk_ast(child)
        end
      end

      if node.arms then
        for _, arm in ipairs(node.arms) do
          walk_ast(arm.pattern)
          walk_ast(arm.body)
        end
      end

      if node.condition then walk_ast(node.condition) end
      if node.else_body then
        for _, child in ipairs(node.else_body) do
          walk_ast(child)
        end
      end
      if node.else_ifs then
        for _, ei in ipairs(node.else_ifs) do
          walk_ast(ei.condition)
          for _, child in ipairs(ei.body) do
            walk_ast(child)
          end
        end
      end
      if node.left then walk_ast(node.left) end
      if node.right then walk_ast(node.right) end
      if node.operand then walk_ast(node.operand) end
      if node.callee then walk_ast(node.callee) end
      if node.args then
        for _, child in ipairs(node.args) do
          walk_ast(child)
        end
      end
      if node.value then walk_ast(node.value) end
      if node.object then walk_ast(node.object) end
      if node.overloads then
        for _, overload in ipairs(node.overloads) do
          walk_ast(overload)
        end
      end
      if node.parts then
        for _, child in ipairs(node.parts) do
          walk_ast(child)
        end
      end
    end

    for _, stmt in ipairs(ast.body) do
      walk_ast(stmt)
    end
  end

  add_lua_module("module_loader", read_file("src/module_loader.lua"))
  add_lua_module("list", read_file("src/list.lua"))
  add_lua_module("table", read_file("src/table.lua"))
  add_lua_module("string", read_file("src/string.lua"))
  add_lua_module("math", read_file("src/math.lua"))

  local vs_files = { "src/list.vs", "src/table.vs", "src/string.vs" }
  for _, vs_path in ipairs(vs_files) do
    local source = read_file(vs_path)
    if source then
      local lua_code = compile(source, "=" .. vs_path)
      add_lua_module("vs:" .. vs_path, lua_code)
    end
  end

  process_vs_file(entry_file)

  return modules, lua_modules
end

local function escape_c_string(s)
  s = s:gsub("\\", "\\\\")
  s = s:gsub('"', '\\"')
  s = s:gsub("\n", "\\n")
  s = s:gsub("\r", "\\r")
  s = s:gsub("\t", "\\t")
  return s
end

function Bundler.generate_bundle_c(modules, lua_modules, user_code)
  local c = {}

  c[#c + 1] = '#include <stdio.h>'
  c[#c + 1] = '#include <stdlib.h>'
  c[#c + 1] = '#include <string.h>'
  c[#c + 1] = '#include "lua.h"'
  c[#c + 1] = '#include "luajit.h"'
  c[#c + 1] = '#include "lauxlib.h"'
  c[#c + 1] = '#include "lualib.h"'
  c[#c + 1] = ''
  c[#c + 1] = 'static const char *embedded_modules[] = {'

  local idx = 0
  for name, source in pairs(lua_modules) do
    if source then
      c[#c + 1] = '  "' .. escape_c_string(name) .. '",'
      c[#c + 1] = '  "' .. escape_c_string(source) .. '",'
      idx = idx + 1
    end
  end

  for path, source in pairs(modules) do
    c[#c + 1] = '  "' .. escape_c_string("vs:" .. path) .. '",'
    c[#c + 1] = '  "' .. escape_c_string(source) .. '",'
    idx = idx + 1
  end

  c[#c + 1] = '  NULL'
  c[#c + 1] = '};'
  c[#c + 1] = ''
  c[#c + 1] = 'static const char *main_code ='
  c[#c + 1] = '  "' .. escape_c_string(user_code) .. '";'
  c[#c + 1] = ''
  c[#c + 1] = 'static int embedded_require(lua_State *L) {'
  c[#c + 1] = '  const char *name = luaL_checkstring(L, 1);'
  c[#c + 1] = '  for (int i = 0; embedded_modules[i] != NULL; i += 2) {'
  c[#c + 1] = '    if (strcmp(embedded_modules[i], name) == 0) {'
  c[#c + 1] = '      if (luaL_loadstring(L, embedded_modules[i + 1]) != 0) {'
  c[#c + 1] = '        return lua_error(L);'
  c[#c + 1] = '      }'
  c[#c + 1] = '      if (lua_pcall(L, 0, 1, 0) != 0) {'
  c[#c + 1] = '        return lua_error(L);'
  c[#c + 1] = '      }'
  c[#c + 1] = '      return 1;'
  c[#c + 1] = '    }'
  c[#c + 1] = '  }'
  c[#c + 1] = '  luaL_error(L, "module not found: %s", name);'
  c[#c + 1] = '  return 0;'
  c[#c + 1] = '}'
  c[#c + 1] = ''
  c[#c + 1] = 'int main(int argc, char *argv[]) {'
  c[#c + 1] = '  lua_State *L = luaL_newstate();'
  c[#c + 1] = '  luaL_openlibs(L);'
  c[#c + 1] = ''
  c[#c + 1] = '  lua_pushcfunction(L, embedded_require);'
  c[#c + 1] = '  lua_setglobal(L, "embedded_require");'
  c[#c + 1] = ''
  c[#c + 1] = '  const char *init_lua ='
  c[#c + 1] = '    "List = embedded_require(\'list\')\\n"'
  c[#c + 1] = '    "Table = embedded_require(\'table\')\\n"'
  c[#c + 1] = '    "String = embedded_require(\'string\')\\n"'
  c[#c + 1] = '    "Math = embedded_require(\'math\')\\n"'
  c[#c + 1] = '    "local _orig_vs_require = embedded_require\\n"'
  c[#c + 1] = '    "_G.vs_require = function(path)\\n"'
  c[#c + 1] = '    "  if path:match(\'%.vs$\') then\\n"'
  c[#c + 1] = '    "    return _orig_vs_require(\'vs:\' .. path)\\n"'
  c[#c + 1] = '    "  end\\n"'
  c[#c + 1] = '    "  return _orig_vs_require(path)\\n"'
  c[#c + 1] = '    "end\\n"'
  c[#c + 1] = '    "local _le = embedded_require(\'vs:src/list.vs\')\\n"'
  c[#c + 1] = '    "for k, v in pairs(_le) do List[k] = v end\\n"'
  c[#c + 1] = '    "local _te = embedded_require(\'vs:src/table.vs\')\\n"'
  c[#c + 1] = '    "for k, v in pairs(_te) do Table[k] = v end\\n"'
  c[#c + 1] = '    "local _se = embedded_require(\'vs:src/string.vs\')\\n"'
  c[#c + 1] = '    "for k, v in pairs(_se) do String[k] = v end\\n";'
  c[#c + 1] = ''
  c[#c + 1] = '  if (luaL_dostring(L, init_lua) != 0) {'
  c[#c + 1] = '    fprintf(stderr, "Init error: %s\\n", lua_tostring(L, -1));'
  c[#c + 1] = '    lua_close(L);'
  c[#c + 1] = '    return 1;'
  c[#c + 1] = '  }'
  c[#c + 1] = ''
  c[#c + 1] = '  if (luaL_dostring(L, main_code) != 0) {'
  c[#c + 1] = '    fprintf(stderr, "Runtime error: %s\\n", lua_tostring(L, -1));'
  c[#c + 1] = '    lua_close(L);'
  c[#c + 1] = '    return 1;'
  c[#c + 1] = '  }'
  c[#c + 1] = ''
  c[#c + 1] = '  lua_close(L);'
  c[#c + 1] = '  return 0;'
  c[#c + 1] = '}'

  return table.concat(c, "\n")
end

function Bundler.compile_c_to_binary(c_path, output_path)
  local luajit_lib_path, luajit_lib_name = Bundler.find_luajit_lib()
  local luajit_include = Bundler.find_luajit_headers()

  local include_flags = ""
  if luajit_include then
    include_flags = "-I" .. luajit_include
  end

  local link_flags = ""
  if luajit_lib_path and luajit_lib_name then
    link_flags = "-L" .. luajit_lib_path .. " -l" .. luajit_lib_name
    link_flags = link_flags .. " -Wl,-rpath," .. luajit_lib_path
  else
    link_flags = "-lluajit-5.1"
  end

  local cmd = string.format("cc %s -o %s %s %s",
    include_flags, output_path, c_path, link_flags)

  io.stderr:write("Compiling: " .. cmd .. "\n")
  local ok = os.execute(cmd)
  if not ok then
    error("Failed to compile C code")
  end
end

function Bundler.bundle(entry_file, output_path)
  io.stderr:write("Bundling: " .. entry_file .. "\n")

  local luajit = Bundler.find_luajit()
  if not luajit then
    error("LuaJIT not found on system")
  end
  io.stderr:write("Found LuaJIT: " .. luajit .. "\n")

  local entry_source = read_file(entry_file)
  if not entry_source then
    error("Cannot read entry file: " .. entry_file)
  end

  local user_code = compile(entry_source, "=" .. entry_file)

  local modules, lua_modules = Bundler.collect_modules(entry_file)

  local c_code = Bundler.generate_bundle_c(modules, lua_modules, user_code)

  local tmp_c = os.tmpname() .. ".c"
  local f = io.open(tmp_c, "w")
  f:write(c_code)
  f:close()

  Bundler.compile_c_to_binary(tmp_c, output_path)

  os.remove(tmp_c)

  io.stderr:write("Bundle created: " .. output_path .. "\n")
end

return Bundler
