test("subtraction", fn() {
  10 - 3 == 7
})

test("multiplication", fn() {
  3 * 4 == 12
})

test("division", fn() {
  20 / 5 == 4
})

test("unary negation", fn() {
  -5 == -5
})

test("pipeline pipes value as first arg", fn() {
  2 |> math.pow(3) == 8
})

test("pipeline placeholder fills last position", fn() {
  2 |> math.pow(3, _) == 9
})

test("pipeline placeholder fills first position", fn() {
  2 |> math.pow(_, 3) == 8
})

test("pipeline chains multiple operations", fn() {
  16 |> math.sqrt |> math.floor == 4
})

test("pipeline pipes into lambda", fn() {
  5 |> fn(x) { x * 2 } == 10
})
