# Venus

A small compiled language built on LuaJIT.

## Build & Run

```sh
mise build           # compile src/main.c -> bin/vs
./bin/vs file.vs     # compile and run
./bin/vs -c file.vs  # compile only (show Lua output)
./bin/vs -e 'code'   # run inline Venus code
./bin/vs --help      # flags
luajit src/main.lua  # dev equivalent (no build needed)
```

## Language

### Pipeline operator (`|>`)

```venus
2 |> math.pow(3) |> print           -- print(math.pow(2, 3))
"hello" |> string.upper |> print     -- print(string.upper("hello"))
```

The left-hand value is inserted as the first argument of the right-hand call.

Use `_` to explicitly place the value in a specific position:

```venus
2 |> math.pow(3, _)                 -- math.pow(3, 2)
2 |> math.pow(_, 3)                 -- math.pow(2, 3) -- same as default
```

### `let` declarations

```venus
let x = 42
let a, b = 1, 2
let y = 2 |> math.pow(3)
```

### Functions

```venus
fn add(a, b) {
  a + b
}

fn greet(name) {
  "hello " .. name
}

print(add(2, 3))                    -- 5
```

The last expression in a function body is returned implicitly.

### Function overloading

Functions can be overloaded by value — define multiple `fn` with the same name and literal parameters:

```venus
fn fib(0) { 0 }
fn fib(1) { 1 }
fn fib(n) { fib(n-1) + fib(n-2) }

print(fib(10))                     -- 55
```

Literal params (`NUMBER`, `STRING`) are matched against the argument. Identifier params match any value and bind the argument to the name. The first matching overload wins. Non-literal overloads act as a fallback.

Overloads are collected at compile time into a single dispatch function — no runtime cost beyond a short if-else chain.

### Inline functions (lambdas)

```venus
let double = fn(x) { x * 2 }
map([1 2 3], fn(x) { x * 2 })
5 |> fn(x) { x * 2 }
```

Same syntax as named functions — just omit the name.

### Lists (`[]`)

```venus
let t = []                    -- empty list
let t = [1, 2, 3]            -- comma-separated values
let t = [1 [2 3]]            -- spaces also work (backward compat)
```

### Tables (`{}`)

Tables are a flexible data structure — they can be maps, objects, or both:

```venus
let t = {}                    -- empty table
let t = { "x" -> 1, "y" -> 2 }  -- string keys with values (map-like)
let t = { x -> 10 }            -- identifier key (same as "x")
```

Use `.` for field access: `t.x` retrieves the value at key `"x"`. Table keys are always literal strings — identifier keys are not variable lookups. You can store functions in tables to create objects.

### If / else if / else

```venus
fn describe(x) {
  if x == 0 {
    "zero"
  } else if x == 1 {
    "one"
  } else {
    "other"
  }
}
```

`if` is a statement (not an expression). Each branch is a `{ }` block; the last expression in each branch is returned. The `else` branch is optional.

### Comparison & Logical Operators

`==` `!=` `<` `>` `<=` `>=` `and` `or`

Comparisons and logicals compose naturally with arithmetic:

```venus
x > 0 and x < 10
x == 0 or x == 1
1 + 2 == 3
```

### Match (`match`)

```venus
match x {
  1 -> "one"
  2 -> "two"
  _ -> "other"          -- wildcard fallback
  y -> y                -- or bind to a variable
}
```

Patterns: literal numbers/strings, `_` wildcard, or a variable binding. Arms are separated by commas (optional). Use `match` when you need `if` as an expression (it returns a value).

### Literals & Operators

Numbers, strings (`"` or `'`), `nil`, `true`, `false`, `+`, `-`, `*`, `/`, `==`, `!=`, `<`, `>`, `<=`, `>=`, `and`, `or`, `( )`, member access (`.`), function calls, list literals (`[ ]`), table literals (`{ }`), `if`/`else`, match expressions, comments (`--`).

`nil` and `false` are falsy in conditionals; everything else is truthy.

## Project Structure

```
src/
  main.c     -- C harness (loads LuaJIT, runs main.lua)
  main.lua   -- CLI: flags, compile, run, REPL
  lexer.lua  -- tokenizer
  parser.lua -- recursive-descent parser
  codegen.lua -- code generator
test/
  test.lua   -- test runner
  util.lua   -- shared compile helper for tests
  test_*.lua -- tests per feature
```
