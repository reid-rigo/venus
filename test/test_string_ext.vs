test("reverse", fn() {
  String.reverse("hello") == "olleh"
})

test("reverse single", fn() {
  String.reverse("a") == "a"
})

test("reverse empty", fn() {
  String.reverse("") == ""
})

test("repeat_str", fn() {
  String.repeat_str("ha", 3) == "hahaha"
})

test("repeat_str zero", fn() {
  String.repeat_str("x", 0) == ""
})

test("repeat_str one", fn() {
  String.repeat_str("ab", 1) == "ab"
})

test("pad", fn() {
  String.pad("hi", 5, ".") == "hi..."
})

test("pad already long", fn() {
  String.pad("hello", 3, ".") == "hello"
})

test("pad exact", fn() {
  String.pad("hi", 2, ".") == "hi"
})

test("pad_left", fn() {
  String.pad_left("hi", 5, ".") == "...hi"
})

test("pad_left already long", fn() {
  String.pad_left("hello", 3, ".") == "hello"
})

test("replace", fn() {
  String.replace("hello world", "world", "venus") == "hello venus"
})

test("replace multiple", fn() {
  String.replace("aaa", "a", "b") == "bbb"
})

test("replace not found", fn() {
  String.replace("hello", "xyz", "abc") == "hello"
})

test("chars", fn() {
  let result = String.chars("abc")
  List.len(result) == 3 and List.get(result, 1) == "a" and List.get(result, 2) == "b" and List.get(result, 3) == "c"
})

test("chars empty", fn() {
  List.len(String.chars("")) == 0
})

test("is_empty true", fn() {
  String.is_empty("") == true
})

test("is_empty false", fn() {
  String.is_empty("hello") == false
})
