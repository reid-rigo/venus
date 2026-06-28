test("flat_map", fn() {
  let result = List.flat_map([1, 2, 3], fn(x) { [x, x * 2] })
  List.len(result) == 6 and List.get(result, 1) == 1 and List.get(result, 2) == 2 and List.get(result, 3) == 2 and List.get(result, 4) == 4 and List.get(result, 5) == 3 and List.get(result, 6) == 6
})

test("flat_map empty", fn() {
  List.len(List.flat_map([], fn(x) { [x] })) == 0
})

test("flat_map single", fn() {
  let result = List.flat_map([5], fn(x) { [x, x] })
  List.len(result) == 2 and List.get(result, 1) == 5 and List.get(result, 2) == 5
})

test("zip", fn() {
  let result = List.zip([1, 2, 3], ["a", "b", "c"])
  List.len(result) == 3 and List.get(List.get(result, 1), 1) == 1 and List.get(List.get(result, 1), 2) == "a" and List.get(List.get(result, 3), 1) == 3 and List.get(List.get(result, 3), 2) == "c"
})

test("zip unequal lengths", fn() {
  let result = List.zip([1, 2], ["a", "b", "c"])
  List.len(result) == 2
})

test("zip empty", fn() {
  List.len(List.zip([], [])) == 0
})

test("take_while", fn() {
  let result = List.take_while([1, 2, 3, 4, 5], fn(x) { x < 4 })
  List.len(result) == 3 and List.get(result, 1) == 1 and List.get(result, 2) == 2 and List.get(result, 3) == 3
})

test("take_while none", fn() {
  let result = List.take_while([1, 2, 3], fn(x) { x > 10 })
  List.len(result) == 0
})

test("take_while all", fn() {
  let result = List.take_while([1, 2, 3], fn(x) { x < 10 })
  List.len(result) == 3
})

test("drop_while", fn() {
  let result = List.drop_while([1, 2, 3, 4, 5], fn(x) { x < 4 })
  List.len(result) == 2 and List.get(result, 1) == 4 and List.get(result, 2) == 5
})

test("drop_while none", fn() {
  let result = List.drop_while([1, 2, 3], fn(x) { x > 10 })
  List.len(result) == 3
})

test("drop_while all", fn() {
  let result = List.drop_while([1, 2, 3], fn(x) { x < 10 })
  List.len(result) == 0
})

test("flatten", fn() {
  let result = List.flatten([[1, 2], [3, 4]])
  List.len(result) == 4 and List.get(result, 1) == 1 and List.get(result, 4) == 4
})

test("flatten nested", fn() {
  let result = List.flatten([1, [2, [3, 4]], 5])
  List.len(result) == 5 and List.get(result, 3) == 3 and List.get(result, 4) == 4
})

test("flatten empty", fn() {
  List.len(List.flatten([])) == 0
})

test("reverse", fn() {
  let result = List.reverse([1, 2, 3])
  List.len(result) == 3 and List.get(result, 1) == 3 and List.get(result, 2) == 2 and List.get(result, 3) == 1
})

test("reverse single", fn() {
  let result = List.reverse([42])
  List.len(result) == 1 and List.get(result, 1) == 42
})

test("reverse empty", fn() {
  List.len(List.reverse([])) == 0
})

test("find", fn() {
  let result = List.find([1, 2, 3, 4], fn(x) { x > 2 })
  result == 3
})

test("find not found", fn() {
  let result = List.find([1, 2, 3], fn(x) { x > 10 })
  result == nil
})

test("any true", fn() {
  List.any([1, 2, 3], fn(x) { x == 2 }) == true
})

test("any false", fn() {
  List.any([1, 2, 3], fn(x) { x == 5 }) == false
})

test("any empty", fn() {
  List.any([], fn(x) { true }) == false
})

test("all true", fn() {
  List.all([1, 2, 3], fn(x) { x > 0 }) == true
})

test("all false", fn() {
  List.all([1, 2, 3], fn(x) { x > 2 }) == false
})

test("all empty", fn() {
  List.all([], fn(x) { false }) == true
})
