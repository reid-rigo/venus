// string concatenation uses +
test("concatenation", fn() {
  "hello " + "world" == "hello world"
})

test("multiline string length", fn() {
  let s = """a
b"""
  let expected = 3
  string.len(s) == expected
})
