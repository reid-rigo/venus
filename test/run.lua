#!/usr/bin/env luajit
package.path = "./?.lua;../?.lua;" .. package.path

local runner = require("test.runner")

local suites = {
  { name = "arithmetic",   file = "test/test_arithmetic.vs" },
  { name = "let",          file = "test/test_let.vs" },
  { name = "function",     file = "test/test_fun.vs" },
  { name = "if",           file = "test/test_if.vs" },
  { name = "match",        file = "test/test_match.vs" },
  { name = "list",         file = "test/test_list.vs" },
  { name = "table",        file = "test/test_table.vs" },
  { name = "logical",      file = "test/test_logical.vs" },
  { name = "string",       file = "test/test_string.vs" },
  { name = "module",       file = "test/test_module.vs" },
}

local total_passed = 0
local total_failed = 0

for _, suite in ipairs(suites) do
  print("--- " .. suite.name .. " ---")
  local passed, failed = runner.run_file(suite.file)
  total_passed = total_passed + passed
  total_failed = total_failed + failed
  print()
end

print(total_passed .. "/" .. (total_passed + total_failed) .. " tests passed")

if total_failed > 0 then os.exit(1) end
