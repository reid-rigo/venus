// hello world with various Venus features

fn greet(name) {
  "hello #{name}"
}

fn main() {
  let message = greet("world")
  print(message)

  // multiline string
  let multi = """line one
line two"""
  print(multi)

  // table
  let t = { name -> "venus", version -> 1 }
  print(t.name)

  // list
  let items = [1, 2, 3]
  print(Table.len(items))

  // safe nav
  let t2 = nil
  print(t2?.x)
}

main()
