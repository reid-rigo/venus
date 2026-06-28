test("empty list len", fn() {
  let expected = 0
  List.len([]) == expected
})

test("single element", fn() {
  let expected = 1
  List.len([1]) == expected
})

test("three elements", fn() {
  let expected = 3
  List.len([1, 2, 3]) == expected
})

test("get first", fn() {
  let expected = 10
  List.get([10, 20, 30], 1) == expected
})

test("get last", fn() {
  let expected = 30
  List.get([10, 20, 30], 3) == expected
})

test("map", fn() {
  let doubled = List.map([1, 2, 3], fn(x) { x * 2 })
  let expected_first = 2
  let expected_last = 6
  List.get(doubled, 1) == expected_first and List.get(doubled, 3) == expected_last
})

test("nested list", fn() {
  let expected = 2
  List.len([1, [2, 3]]) == expected
})
