test("merge", fn() {
  let a = { "x" -> 1, "y" -> 2 }
  let b = { "y" -> 3, "z" -> 4 }
  let result = Table.merge(a, b)
  Table.get(result, "x") == 1 and Table.get(result, "y") == 3 and Table.get(result, "z") == 4
})

test("merge empty", fn() {
  let result = Table.merge({}, {})
  Table.len(result) == 0
})

test("merge left wins on conflict", fn() {
  let a = { "x" -> 1 }
  let b = { "x" -> 2 }
  let result = Table.merge(a, b)
  Table.get(result, "x") == 2
})

test("invert", fn() {
  let result = Table.invert({ "a" -> 1, "b" -> 2 })
  Table.get(result, 1) == "a" and Table.get(result, 2) == "b"
})

test("invert empty", fn() {
  let result = Table.invert({})
  Table.len(result) == 0
})

test("pick", fn() {
  let m = { "a" -> 1, "b" -> 2, "c" -> 3 }
  let result = Table.pick(m, ["a", "c"])
  Table.get(result, "a") == 1 and Table.get(result, "c") == 3 and Table.has(result, "b") == false
})

test("pick missing key", fn() {
  let m = { "a" -> 1 }
  let result = Table.pick(m, ["a", "z"])
  Table.get(result, "a") == 1 and Table.len(result) == 1
})

test("omit", fn() {
  let m = { "a" -> 1, "b" -> 2, "c" -> 3 }
  let result = Table.omit(m, ["b"])
  Table.get(result, "a") == 1 and Table.get(result, "c") == 3 and Table.has(result, "b") == false
})

test("omit non-existent key", fn() {
  let m = { "a" -> 1, "b" -> 2 }
  let result = Table.omit(m, ["z"])
  Table.len(result) == 2
})

test("map_keys", fn() {
  let m = { "a" -> 1, "b" -> 2 }
  let result = Table.map_keys(m, fn(k) { "#{k}!" })
  Table.get(result, "a!") == 1 and Table.get(result, "b!") == 2
})

test("filter", fn() {
  let m = { "a" -> 1, "b" -> 2, "c" -> 3 }
  let result = Table.filter(m, fn(v) { v > 1 })
  Table.get(result, "b") == 2 and Table.get(result, "c") == 3 and Table.has(result, "a") == false
})

test("filter empty", fn() {
  let result = Table.filter({}, fn(v) { true })
  Table.len(result) == 0
})

test("to_list", fn() {
  let m = { "a" -> 1, "b" -> 2 }
  let result = Table.to_list(m)
  List.len(result) == 2
})
