test("empty table", fn() {
  let expected = 0
  Table.len({}) == expected
})

test("field access", fn() {
  let t = { x -> 10 }
  let expected = 10
  t.x == expected
})

test("has key", fn() {
  let t = { x -> 10 }
  Table.has(t, "x")
})

test("not has key", fn() {
  let t = { x -> 10 }
  let expected = false
  Table.has(t, "y") == expected
})

test("chained field", fn() {
  let t2 = { x -> { y -> 20 } }
  let expected = 20
  t2.x.y == expected
})

test("string keys", fn() {
  let t3 = { "a" -> 1, "b" -> 2 }
  t3.a == 1 and t3.b == 2
})

test("safe nav existing", fn() {
  let t4 = { x -> 10 }
  let expected = 10
  t4?.x == expected
})

test("safe nav missing", fn() {
  let t4 = { x -> 10 }
  let expected = nil
  t4?.z == expected
})

test("safe nav nil object", fn() {
  let t5 = nil
  let expected = nil
  t5?.x == expected
})
