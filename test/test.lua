#!/usr/bin/env luajit
package.path = "./?.lua;../?.lua;" .. package.path

local test_files = {
  "test_pipeline",
  "test_let",
  "test_fun",
  "test_table",
  "test_list",
  "test_lambda",
}

local passed = 0
local failed = 0

for _, modname in ipairs(test_files) do
  local ok, suite = pcall(require, "test." .. modname)
  if not ok then
    print(string.format("FAIL: could not load test/%s.lua: %s", modname, suite))
    failed = failed + 1
  else
    print("--- " .. suite.name .. " ---")
    for _, t in ipairs(suite.tests) do
      local ok2, result = pcall(require("test.util").compile, t.input)
      if not ok2 then
        print(string.format("  FAIL: %s\n    error: %s", t.name, result))
        failed = failed + 1
      elseif result == t.expected then
        print(string.format("  PASS: %s", t.name))
        passed = passed + 1
      else
        print(string.format("  FAIL: %s\n    expected: %s\n    got:      %s", t.name, t.expected, result))
        failed = failed + 1
      end
    end
  end
end

print()
print(string.format("%d/%d tests passed", passed, passed + failed))

if failed > 0 then os.exit(1) end
