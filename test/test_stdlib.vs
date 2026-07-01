test("List.remove", fn() {
  let result = List.remove([1, 2, 3], 2)
  List.len(result) == 2 and List.get(result, 1) == 1 and List.get(result, 2) == 3
})

test("List.filter", fn() {
  let result = List.filter([1, 2, 3, 4, 5], fn(x) { x > 2 })
  List.len(result) == 3 and List.get(result, 1) == 3
})

test("List.filter none", fn() {
  List.len(List.filter([1, 2, 3], fn(x) { x > 10 })) == 0
})

test("List.reduce sum", fn() {
  List.reduce([1, 2, 3, 4], fn(acc, x) { acc + x }, 0) == 10
})

test("List.reduce strings", fn() {
  List.reduce(["a", "b", "c"], fn(acc, x) { "${acc}${x}" }, "") == "abc"
})

test("List.reduce single", fn() {
  List.reduce([42], fn(acc, x) { acc + x }, 0) == 42
})

test("List.reduce empty", fn() {
  List.reduce([], fn(acc, x) { acc + x }, 100) == 100
})

test("List.range", fn() {
  let result = List.range(1, 5)
  List.len(result) == 5 and List.get(result, 1) == 1 and List.get(result, 5) == 5
})

test("List.range single", fn() {
  let result = List.range(3, 3)
  List.len(result) == 1 and List.get(result, 1) == 3
})

test("List.range empty", fn() {
  List.len(List.range(5, 1)) == 0
})

test("Table.set", fn() {
  let m = #{}
  Table.set(m, "x", 10)
  Table.get(m, "x") == 10
})

test("Table.set overwrite", fn() {
  let m = #{ "x" -> 5 }
  Table.set(m, "x", 10)
  Table.get(m, "x") == 10
})

test("Table.keys", fn() {
  let m = #{ "a" -> 1, "b" -> 2 }
  List.len(Table.keys(m)) == 2
})

test("Table.values", fn() {
  let m = #{ "a" -> 1, "b" -> 2 }
  List.len(Table.values(m)) == 2
})

test("Table.remove", fn() {
  let m = #{ "a" -> 1, "b" -> 2 }
  Table.remove(m, "a")
  Table.has(m, "a") == false and Table.has(m, "b") == true
})

test("String.len", fn() {
  String.len("hello") == 5
})

test("String.len empty", fn() {
  String.len("") == 0
})
