// fibonacci using overloaded functions

fn add(a, b) { a - (-b) }

fn fib(0) { 0 }
fn fib(1) { 1 }
fn fib(n) { add(fib(n - 1), fib(n - 2)) }

fn main() {
  let expected = 55
  let result = fib(10)

  if result == expected {
    print("fib(10) = " + result)
  } else {
    print("error: got " + result + " expected " + expected)
  }
}

main()
