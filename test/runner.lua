local util = require("test.util")

local M = {}

function M.run_file(path)
  local f = io.open(path, "r")
  if not f then return nil, "could not open " .. path end
  local source = f:read("*a")
  f:close()

  local ok, lua = pcall(util.compile, source)
  if not ok then return nil, "compile: " .. lua end

  local fn, err = load(lua, "@" .. path, "t")
  if not fn then return nil, "load: " .. err end

  List = require("src.list")
  Table = require("src.table")
  local Math = math

  local tests = {}
  _G.test = function(name, test_fn)
    tests[#tests + 1] = { name = name, fn = test_fn }
  end

  local ok2, err2 = pcall(fn)
  _G.test = nil

  if not ok2 then
    print("  ERROR: " .. tostring(err2))
    return 0, 1
  end

  local passed = 0
  local failed = 0

  for _, t in ipairs(tests) do
    local ok3, result = pcall(t.fn)
    if ok3 and result then
      print("  PASS: " .. t.name)
      passed = passed + 1
    elseif ok3 then
      print("  FAIL: " .. t.name)
      print("    returned " .. tostring(result))
      failed = failed + 1
    else
      print("  FAIL: " .. t.name)
      print("    " .. tostring(result))
      failed = failed + 1
    end
  end

  return passed, failed
end

return M
