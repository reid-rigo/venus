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
  List.len(doubled) == 3 and List.get(doubled, 1) == 2 and List.get(doubled, 2) == 4 and List.get(doubled, 3) == 6
})

test("map empty", fn() {
  List.len(List.map([], fn(x) { x })) == 0
})

test("map single", fn() {
  List.get(List.map([7], fn(x) { x * 10 }), 1) == 70
})

test("nested list", fn() {
  let expected = 2
  List.len([1, [2, 3]]) == expected
})

test("List.each iterates values", fn() {
  let result = List.reduce([10, 20, 30], fn(acc, v) { List.add(acc, v) }, [])
  List.len(result) == 3 and List.get(result, 1) == 10 and List.get(result, 2) == 20 and List.get(result, 3) == 30
})

test("List.each returns nothing", fn() {
  List.each([1], fn(v) {}) == nil
})

test("List.join", fn() {
  List.join(["a", "b", "c"], ", ") == "a, b, c"
})

test("List.join single", fn() {
  List.join(["x"], ",") == "x"
})

test("List.join empty", fn() {
  List.join([], ",") == ""
})

test("List.join default sep", fn() {
  List.join(["a", "b", "c"]) == "abc"
})
