fn describe(x) {
  if x == 0 { "zero" } else if x == 1 { "one" } else { "other" }
}

test("if without else", fn() {
  fn f() { if 1 { 42 } }
  let expected = 42
  f() == expected
})

test("if else false", fn() {
  fn f(x) { if x { 1 } else { 2 } }
  let expected = 2
  f(nil) == expected
})

test("if else true", fn() {
  fn f(x) { if x { 1 } else { 2 } }
  let expected = 1
  f(1) == expected
})

test("if else truthy string", fn() {
  fn f(x) { if x { 1 } else { 2 } }
  let expected = 1
  f("hi") == expected
})

test("else if zero", fn() {
  let expected = "zero"
  describe(0) == expected
})

test("else if one", fn() {
  let expected = "one"
  describe(1) == expected
})

test("else if other", fn() {
  let expected = "other"
  describe(2) == expected
})

fn f4(x) {
  if x > 0 and x < 10 { "small" } else if x == 42 { "answer" } else { "other" }
}

test("if with and", fn() {
  let expected = "small"
  f4(5) == expected
})

test("if with and eq", fn() {
  let expected = "answer"
  f4(42) == expected
})

test("if else", fn() {
  let expected = "other"
  f4(100) == expected
})
