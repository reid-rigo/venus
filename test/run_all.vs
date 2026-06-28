let runner = import "src.runner"

List.each([
  ["arithmetic", "test/test_arithmetic.vs"],
  ["let", "test/test_let.vs"],
  ["function", "test/test_fun.vs"],
  ["if", "test/test_if.vs"],
  ["match", "test/test_match.vs"],
  ["list", "test/test_list.vs"],
  ["math", "test/test_math.vs"],
  ["table", "test/test_table.vs"],
  ["logical", "test/test_logical.vs"],
  ["string", "test/test_string.vs"],
  ["string module", "test/test_string_module.vs"],
  ["module", "test/test_module.vs"],
], fn(s) {
  print("--- #{List.get(s, 1)} ---")
  runner.run_file(List.get(s, 2))
  print("")
})
