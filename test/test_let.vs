test("let with init", fn() {
  let x = 42
  let expected = 42
  x == expected
})

test("let with pipeline", fn() {
  let y = 2 |> math.pow(3)
  let expected = 8
  y == expected
})

test("let multiple vars", fn() {
  let a, b = 1, 2
  a == 1 and b == 2
})

test("let no init", fn() {
  let z
  let expected = nil
  z == expected
})

test("let used in expr", fn() {
  let x = 42
  let y = 8
  let expected = 50
  x + y == expected
})
