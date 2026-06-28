test("split", fn() {
  let parts = String.split("a,b,c", ",")
  List.len(parts) == 3 and List.get(parts, 1) == "a" and List.get(parts, 2) == "b" and List.get(parts, 3) == "c"
})

test("split empty fields", fn() {
  let parts = String.split("a,,c", ",")
  List.len(parts) == 3 and List.get(parts, 1) == "a" and List.get(parts, 2) == "" and List.get(parts, 3) == "c"
})

test("split empty string", fn() {
  List.len(String.split("", ",")) == 1 and List.get(String.split("", ","), 1) == ""
})

test("split by empty sep", fn() {
  let parts = String.split("ab", "")
  List.len(parts) == 2 and List.get(parts, 1) == "a" and List.get(parts, 2) == "b"
})

test("trim", fn() {
  String.trim("  hello  ") == "hello"
})

test("trim empty", fn() {
  String.trim("") == ""
})

test("starts_with", fn() {
  String.starts_with("hello", "hel")
})

test("starts_with false", fn() {
  let expected = false
  String.starts_with("hello", "x") == expected
})

test("ends_with", fn() {
  String.ends_with("hello", "lo")
})

test("ends_with false", fn() {
  let expected = false
  String.ends_with("hello", "x") == expected
})

test("contains", fn() {
  String.contains("hello world", "lo wo")
})

test("contains false", fn() {
  let expected = false
  String.contains("hello", "xyz") == expected
})

test("concat", fn() {
  String.concat("a", "b", "c") == "abc"
})

test("concat single", fn() {
  String.concat("hello") == "hello"
})

test("concat empty", fn() {
  String.concat() == ""
})
