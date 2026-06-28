test("import math pi", fn() {
  let m = import "math"
  m.pi > 3 and m.pi < 4
})

test("import math call", fn() {
  let m = import "math"
  let expected = 5
  m.abs(-5) == expected
})
