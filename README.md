<p align="center">
  <img src="vscode-venus/icon.png" alt="Venus" width="128" height="128">
</p>

# Venus

A small, functional-first language built on Chez Scheme.

## Build & Run

```sh
mise build           # compile src/chez_main.c -> bin/vs
./bin/vs file.vs     # compile and run
./bin/vs -c file.vs  # compile only (show Scheme output)
./bin/vs -e 'code'   # run inline Venus code
./bin/vs --help      # flags
```

## Language

### String interpolation

```venus
let name = "world"
print("hello #{name}")             // hello world
print("2 + 2 = #{2 + 2}")           // 2 + 2 = 4
```

Use `#{expr}` inside double-quoted (`"`) or triple-quoted (`"""`) strings to embed any expression. Single-quoted strings (`'`) are literal — no interpolation.

### Pipeline operator (`|>`)

```venus
2 |> Math.pow(3) |> print           // print(Math.pow(2, 3))
"hello" |> string.upper |> print     // print(string.upper("hello"))
```

The left-hand value is inserted as the first argument of the right-hand call.

Use `_` to explicitly place the value in a specific position:

```venus
2 |> Math.pow(3, _)                 // Math.pow(3, 2)
2 |> Math.pow(_, 3)                 // Math.pow(2, 3) // same as default
```

### `let` declarations

```venus
let x = 42
let a, b = 1, 2
let y = 2 |> Math.pow(3)
```

### Functions

```venus
fn add(a, b) {
  a + b
}

fn greet(name) {
  "hello #{name}"
}

print(add(2, 3))                    // 5
```

The last expression in a function body is returned implicitly.

### Function overloading

Functions can be overloaded by value — define multiple `fn` with the same name and literal parameters:

```venus
fn fib(0) { 0 }
fn fib(1) { 1 }
fn fib(n) { fib(n-1) + fib(n-2) }

print(fib(10))                     // 55
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
let t = []                    // empty list
let t = [1, 2, 3]            // comma-separated values
let t = [1 [2 3]]            // spaces also work (backward compat)
```

### Tables (`{}`)

Tables are a flexible data structure — they can be maps, objects, or both:

```venus
let t = {}                    // empty table
let t = { "x" -> 1, "y" -> 2 }  // string keys with values (map-like)
let t = { x -> 10 }            // identifier key (same as "x")
```

Use `.` for field access: `t.x` retrieves the value at key `"x"`. Use `?.` for safe navigation that returns `nil` instead of erroring when the left side is `nil`:

```venus
let t = { x -> 10 }
t?.x       // 10
t?.z       // nil (no error)
```

Table keys are always literal strings — identifier keys are not variable lookups. You can store functions in tables to create objects.

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
  _ -> "other"          // wildcard fallback
  y -> y                // or bind to a variable
}
```

Patterns: literal numbers/strings, `_` wildcard, or a variable binding. Arms are separated by commas (optional). Use `match` when you need `if` as an expression (it returns a value).

### Modules

Venus modules use `import` for importing and `export` for exporting:

```venus
import "math"                    // side-effect only (no return value)
let m = import "math"            // assign the returned module
print(m.pi)                      // 3.14159
```

Export a value to make a file a module:

```venus
// math_util.vs
fn add(a, b) { a + b }
fn sub(a, b) { a - b }

export { add -> add, sub -> sub }
```

```venus
// main.vs
let util = import "math_util"
print(util.add(2, 3))            // 5
```

`export` must be the last statement in the file (Lua requires `return` to be terminal). Use `import` anywhere an expression is expected.

### Multiline Strings (`"""`)

```venus
let s = """hello
world"""
print(s)                            // hello\nworld
```

Triple-quoted strings can span multiple lines and support interpolation: `"""#{expr}"""`.

## Standard Library

Built-in modules available as globals:

### `List`

| Function | Description |
|---|---|
| `List.add(t, v)` | Append `v` to list `t`, returns `t` |
| `List.get(t, i)` | Get element at 1-based index `i` |
| `List.len(t)` | Number of elements |
| `List.map(t, f)` | New list of `f(v)` for each element |
| `List.filter(t, f)` | New list of elements where `f(v)` is truthy |
| `List.reduce(t, f, init)` | Fold left: `f(acc, v)` for each element |
| `List.each(t, f)` | Call `f(v, i)` for each element, returns nothing |
| `List.join(t, sep?)` | Join elements into string, default separator is `""` |
| `List.remove(t, i)` | Remove element at index `i`, returns `t` |

### `Table`

| Function | Description |
|---|---|
| `Table.get(m, k)` | Get value at key `k` |
| `Table.set(m, k, v)` | Set `m[k] = v`, returns `m` |
| `Table.keys(m)` | List of keys |
| `Table.values(m)` | List of values |
| `Table.len(m)` | Number of entries |
| `Table.has(m, k)` | Whether key exists |
| `Table.remove(m, k)` | Remove key, returns `m` |
| `Table.each(m, f)` | Call `f(v, k)` for each entry, returns nothing |
| `Table.map(m, f)` | New list of `f(v)` for each entry |

### `String`

| Function | Description |
|---|---|
| `String.split(s, sep)` | Split string by separator into a list |
| `String.trim(s)` | Remove leading/trailing whitespace |
| `String.starts_with(s, prefix)` | Whether string starts with prefix |
| `String.ends_with(s, suffix)` | Whether string ends with suffix |
| `String.contains(s, sub)` | Whether string contains substring |
| `String.concat(...)` | Join varargs into a string |

### `Math`

| Function | Description |
|---|---|
| `Math.abs(x)` | Absolute value |
| `Math.floor(x)` | Round down |
| `Math.ceil(x)` | Round up |
| `Math.round(x)` | Round to nearest integer |
| `Math.sqrt(x)` | Square root |
| `Math.pow(x, y)` | `x` raised to `y` |
| `Math.max(x, y)` | Larger of two values |
| `Math.min(x, y)` | Smaller of two values |
| `Math.pi` | Constant 3.14159... |

`nil` and `false` are falsy in conditionals; everything else is truthy.


