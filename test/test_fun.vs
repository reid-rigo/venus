fn add(a, b) { a + b }

test("fn expression body", fn() {
  let expected = 5
  add(2, 3) == expected
})

test("fn string literal", fn() {
  fn greet() { "hello" }
  let expected = "hello"
  greet() == expected
})

test("fn params", fn() {
  fn f(x, y) { x }
  let expected = 42
  f(42, 99) == expected
})

test("fn with let", fn() {
  fn f2() {
    let x = 42
    x
  }
  let expected = 42
  f2() == expected
})

test("fn with pipeline", fn() {
  fn f3(x) { x |> math.sqrt |> math.floor }
  let expected = 4
  f3(17) == expected
})

test("lambda", fn() {
  let expected = 10
  fn(x) { x * 2 }(5) == expected
})

test("lambda with let", fn() {
  let expected = 6
  fn(x) {
    let y = x + 1
    y
  }(5) == expected
})

fn fib(0) { 0 }
fn fib(1) { 1 }
fn fib(n) { fib(n - 1) + fib(n - 2) }

test("fib(0) = 0", fn() { fib(0) == 0 })
test("fib(1) = 1", fn() { fib(1) == 1 })
test("fib(10) = 55", fn() { fib(10) == 55 })
