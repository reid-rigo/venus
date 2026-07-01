// fizzbuzz with match expressions

fn fizzbuzz(n) {
  match n {
    0 -> "fizzbuzz",
    3 -> "fizz",
    5 -> "buzz",
    6 -> "fizz",
    9 -> "fizz",
    10 -> "buzz",
    12 -> "fizz",
    _ -> n
  }
}

fn run(i, limit) {
  if i < limit {
    print(fizzbuzz(i))
    run(i + 1, limit)
  }
}

fn main() {
  run(0, 15)
}

main()
