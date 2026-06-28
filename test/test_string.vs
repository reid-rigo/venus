test("interpolation with ident", fn() {
  let name = "world"
  "hello #{name}" == "hello world"
})

test("interpolation with expression", fn() {
  "10 - 7 = #{10 - 7}" == "10 - 7 = 3"
})

test("interpolation with multiple exprs", fn() {
  let a = 10
  let b = 4
  "#{a} - #{b} = #{a - b}" == "10 - 4 = 6"
})

test("interpolation with function call", fn() {
  "hello #{string.upper("world")}" == "hello WORLD"
})

test("multiline string interpolation", fn() {
  let x = "world"
  let s = """hello
#{x}"""
  s == "hello\nworld"
})

test("multiline string length", fn() {
  let s = """a
b"""
  let expected = 3
  string.len(s) == expected
})
