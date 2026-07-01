test("match literal", fn() {
  match 1 { 1 -> true, _ -> false }
})

test("match wildcard", fn() {
  match 42 { 1 -> false, _ -> true }
})

test("match binding", fn() {
  let expected = 42
  match 42 { x -> x } == expected
})

test("match binding after if", fn() {
  match 42 { 1 -> false, x -> x == 42 }
})

test("match multiple literals", fn() {
  let expected = "other"
  match 3 { 1 -> "one", 2 -> "two", _ -> "other" } == expected
})

fn classify(x) { match x { 1 -> "one", _ -> "other" } }

test("match in fn body one", fn() {
  let expected = "one"
  classify(1) == expected
})

test("match in fn body wildcard", fn() {
  let expected = "other"
  classify(99) == expected
})

test("match string pattern", fn() {
  match "hi" { "hi" -> true, _ -> false }
})

test("match nil", fn() {
  match nil { nil -> true, _ -> false }
})

test("match not nil", fn() {
  match 42 { nil -> false, _ -> true }
})

test("match true", fn() {
  match true { true -> true, false -> false }
})

test("match false", fn() {
  let expected = "yes"
  match false { true -> "no", false -> "yes" } == expected
})
