test("empty vector len", fn() {
  let expected = 0
  Vector.len(Vector.make()) == expected
})

test("vector with initial size", fn() {
  let v = Vector.make(3)
  Vector.len(v) == 3
})

test("vector with initial value", fn() {
  let v = Vector.make(3, 42)
  Vector.len(v) == 3 and Vector.get(v, 1) == 42 and Vector.get(v, 2) == 42 and Vector.get(v, 3) == 42
})

test("set and get", fn() {
  let v = Vector.make(3)
  Vector.set(v, 2, 99)
  Vector.get(v, 2) == 99 and Vector.get(v, 1) == nil and Vector.get(v, 3) == nil
})

test("push grows vector", fn() {
  let v = Vector.make()
  Vector.push(v, 10)
  Vector.push(v, 20)
  Vector.push(v, 30)
  Vector.len(v) == 3 and Vector.get(v, 1) == 10 and Vector.get(v, 2) == 20 and Vector.get(v, 3) == 30
})

test("push after initial size", fn() {
  let v = Vector.make(2, 7)
  Vector.push(v, 8)
  Vector.len(v) == 3 and Vector.get(v, 3) == 8
})

test("pop returns last element", fn() {
  let v = Vector.make()
  Vector.push(v, 1)
  Vector.push(v, 2)
  Vector.pop(v) == 2 and Vector.len(v) == 1
})

test("pop shrinks len", fn() {
  let v = Vector.make(3, "x")
  Vector.pop(v) == "x" and Vector.len(v) == 2
  Vector.pop(v) == "x" and Vector.len(v) == 1
  Vector.pop(v) == "x" and Vector.len(v) == 0
})

test("each iterates values", fn() {
  let v = Vector.make()
  Vector.push(v, 10)
  Vector.push(v, 20)
  Vector.push(v, 30)
  let acc = Vector.make()
  Vector.each(v, fn(x) { Vector.push(acc, x) })
  Vector.to_list(acc) == [10, 20, 30]
})

test("each returns nil", fn() {
  let v = Vector.make()
  Vector.push(v, 42)
  Vector.each(v, fn(x) { nil }) == nil
})

test("map transforms", fn() {
  let v = Vector.make()
  Vector.push(v, 1)
  Vector.push(v, 2)
  Vector.push(v, 3)
  let doubled = Vector.map(v, fn(x) { x * 2 })
  List.len(doubled) == 3 and List.get(doubled, 1) == 2 and List.get(doubled, 2) == 4 and List.get(doubled, 3) == 6
})

test("map empty", fn() {
  Vector.map(Vector.make(), fn(x) { x }) == []
})

test("filter", fn() {
  let v = Vector.make()
  Vector.push(v, 10)
  Vector.push(v, 20)
  Vector.push(v, 30)
  let big = Vector.filter(v, fn(x) { x > 15 })
  List.len(big) == 2 and List.get(big, 1) == 20 and List.get(big, 2) == 30
})

test("filter empty", fn() {
  Vector.filter(Vector.make(), fn(x) { true }) == []
})

test("to_list", fn() {
  let v = Vector.make()
  Vector.push(v, 10)
  Vector.push(v, 20)
  Vector.to_list(v) == [10, 20]
})

test("to_list empty", fn() {
  Vector.to_list(Vector.make()) == []
})

test("copy is independent", fn() {
  let v = Vector.make()
  Vector.push(v, 1)
  Vector.push(v, 2)
  let c = Vector.copy(v)
  Vector.set(c, 1, 99)
  Vector.get(v, 1) == 1 and Vector.get(c, 1) == 99
})
