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

test("Table.each iterates values", fn() {
  let seen = []
  Table.each({ a -> 1, b -> 2 }, fn(v, k) { List.add(seen, v) })
  let expected = 2
  List.len(seen) == expected
})

test("Table.each returns nothing", fn() {
  Table.each({ a -> 1 }, fn(v, k) {}) == nil
})

test("Table.map transforms values", fn() {
  let doubled = Table.map({ x -> 5, y -> 10 }, fn(v) { v * 2 })
  let has_10 = List.filter(doubled, fn(x) { x == 10 })
  let has_20 = List.filter(doubled, fn(x) { x == 20 })
  List.len(doubled) == 2 and List.len(has_10) == 1 and List.len(has_20) == 1
})

test("Table.map empty", fn() {
  List.len(Table.map({}, fn(v) { v })) == 0
})

test("Table.map returns list", fn() {
  let r = Table.map({ a -> 1 }, fn(v) { v })
  List.len(r) == 1 and List.get(r, 1) == 1
})
